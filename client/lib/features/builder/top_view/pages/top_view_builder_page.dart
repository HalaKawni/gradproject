import 'dart:math' as math;

import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';

class TopViewBuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;

  const TopViewBuilderPage({
    super.key,
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
  });

  @override
  State<TopViewBuilderPage> createState() => _TopViewBuilderPageState();
}

class _TopViewBuilderPageState extends State<TopViewBuilderPage> {
  static const double _leftPanelWidth = 280;
  static const int _cols = 26;
  static const int _rows = 20;
  static const double _rulerHandleInset = 10;
  static const double _editorFontSize = 18;
  static const double _editorLineHeight = 1.45;
  static const double _editorLineHeightPixels =
      _editorFontSize * _editorLineHeight;
  static const double _runTilesPerSecond = 6;
  static const double _runEaseTiles = 0.45;
  static const Duration _runFrameInterval = Duration(milliseconds: 16);
  static const StrutStyle _editorStrutStyle = StrutStyle(
    fontFamily: 'monospace',
    fontSize: _editorFontSize,
    height: _editorLineHeight,
    forceStrutHeight: true,
  );

  final Map<_Cell, _BoardItemType> _items = <_Cell, _BoardItemType>{};
  final List<_CodeBlock> _allowedBlocks = <_CodeBlock>[];
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final ScrollController _codeScrollController;
  late final ScrollController _lineNumberScrollController;
  late final FocusNode _codeFocusNode;

  bool _rulerActive = false;
  bool _isBoardItemDragging = false;
  bool _isSolutionTrayBlockDragging = false;
  bool _isRunningCode = false;
  bool _isLoadingProject = false;
  bool _isSavingProject = false;
  double _initialPlayerHeadingDegrees = 0;
  String? _savedProjectId;
  String _courseId = '';
  int _orderInCourse = 0;
  String _difficulty = 'medium';
  String? _loadedPossibleSolutionCode;
  int _runGeneration = 0;
  int? _activeCodeLine;
  _Cell? _rulerStart;
  _PlayerPreviewData? _playerPreview;
  late final ValueNotifier<_RulerOverlayData> _rulerOverlay;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'New Level');
    _codeController = TextEditingController();
    _codeScrollController = ScrollController()..addListener(_handleCodeScroll);
    _lineNumberScrollController = ScrollController();
    _codeFocusNode = FocusNode();
    _rulerOverlay = ValueNotifier<_RulerOverlayData>(const _RulerOverlayData());
    _courseId = widget.initialCourseId ?? '';
    _orderInCourse = widget.initialOrderInCourse ?? 0;
    _difficulty = widget.initialDifficulty;
    _codeController.addListener(_handleCodeChanged);
    if (widget.initialProjectId != null) {
      _loadProject(widget.initialProjectId!);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_handleCodeChanged);
    _titleController.dispose();
    _codeController.dispose();
    _codeScrollController
      ..removeListener(_handleCodeScroll)
      ..dispose();
    _lineNumberScrollController.dispose();
    _codeFocusNode.dispose();
    _rulerOverlay.dispose();
    super.dispose();
  }

  void _handleCodeScroll() {
    _syncLineNumberScroll();
    if (_activeCodeLine == null || !mounted) {
      return;
    }
    setState(() {});
  }

  void _syncLineNumberScroll() {
    if (!_lineNumberScrollController.hasClients ||
        !_codeScrollController.hasClients) {
      return;
    }

    final targetOffset = _codeScrollController.offset.clamp(
      0.0,
      _lineNumberScrollController.position.maxScrollExtent,
    );
    if ((_lineNumberScrollController.offset - targetOffset).abs() < 0.5) {
      return;
    }

    _lineNumberScrollController.jumpTo(targetOffset);
  }

  void _insertBlock(_CodeBlock block) {
    final value = _codeController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start;
    final end = selection.end;
    final insertedText = _buildInsertedCode(
      fullText: value.text,
      selectionStart: start,
      block: block,
    );
    final text = value.text.replaceRange(start, end, insertedText);
    _codeController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + insertedText.length),
    );
    _codeFocusNode.requestFocus();
  }

  String _buildInsertedCode({
    required String fullText,
    required int selectionStart,
    required _CodeBlock block,
  }) {
    final shouldStartOnNewLine =
        block.startsOnNewLine &&
        selectionStart > 0 &&
        !fullText.substring(0, selectionStart).endsWith('\n');
    final prefix = shouldStartOnNewLine ? '\n' : '';
    return '$prefix${block.insertText}';
  }

  void _clearCode() {
    _stopCodeRun();
    _codeController.clear();
  }

  void _handleCodeChanged() {
    if (_isRunningCode) {
      return;
    }
    if (_playerPreview == null && _activeCodeLine == null) {
      return;
    }
    setState(() {
      _activeCodeLine = null;
      _playerPreview = null;
    });
  }

  List<_CodeExecutionStep> _parseCodeSteps() {
    final steps = <_CodeExecutionStep>[];
    final lines = _codeController.text.split('\n');

    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index].trim().toLowerCase();
      if (line.isEmpty) {
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      final command = parts.first;

      if (command == 'turn') {
        if (parts.length < 2) {
          continue;
        }

        final angle = double.tryParse(parts[1]);
        if (angle != null) {
          steps.add(
            _CodeExecutionStep.turn(
              lineIndex: index,
              degrees: angle.roundToDouble(),
              absolute: true,
            ),
          );
          continue;
        }

        final directionDegrees = _screenDirectionDegrees(parts[1]);
        if (directionDegrees != null) {
          steps.add(
            _CodeExecutionStep.turn(
              lineIndex: index,
              degrees: directionDegrees,
              absolute: true,
            ),
          );
        }
        continue;
      }

      final directionDegrees = _screenDirectionDegrees(command);
      if (directionDegrees != null) {
        steps.add(
          _CodeExecutionStep.turn(
            lineIndex: index,
            degrees: directionDegrees,
            absolute: true,
          ),
        );
        continue;
      }

      if (command == 'step') {
        final amount = parts.length > 1
            ? (double.tryParse(parts[1]) ?? 1).roundToDouble()
            : 1.0;
        steps.add(_CodeExecutionStep.step(lineIndex: index, amount: amount));
      }
    }

    return steps;
  }

  double? _screenDirectionDegrees(String direction) {
    switch (direction) {
      case 'right':
        return 0;
      case 'up':
        return 90;
      case 'left':
        return 180;
      case 'down':
        return 270;
      default:
        return null;
    }
  }

  Future<void> _runCode() async {
    if (_isRunningCode) {
      _stopCodeRun();
      return;
    }

    final playerCell = _playerCell;
    if (playerCell == null) {
      return;
    }

    final steps = _parseCodeSteps();
    if (steps.isEmpty) {
      return;
    }

    final generation = _runGeneration + 1;
    final start = Offset(playerCell.column + 0.5, playerCell.row + 0.5);
    var position = start;
    var headingDegrees = _initialPlayerHeadingDegrees;
    final path = <Offset>[start];

    _runGeneration = generation;
    _codeFocusNode.unfocus();
    setState(() {
      _isRunningCode = true;
      _activeCodeLine = null;
      _playerPreview = _PlayerPreviewData(
        position: position,
        headingDegrees: headingDegrees,
        path: List<Offset>.from(path),
      );
    });

    for (final step in steps) {
      if (!mounted || generation != _runGeneration) {
        return;
      }

      _scrollToCodeLine(step.lineIndex);
      setState(() {
        _activeCodeLine = step.lineIndex;
      });

      if (step.type == _CodeExecutionType.turn) {
        final targetHeading = step.absoluteTurn
            ? _normalizeDegrees(step.value)
            : _normalizeDegrees(headingDegrees + step.value);
        headingDegrees = targetHeading;
        setState(() {
          _playerPreview = _PlayerPreviewData(
            position: position,
            headingDegrees: headingDegrees,
            path: List<Offset>.from(path),
          );
        });
        continue;
      }

      final direction = Offset(
        math.cos(_degreesToRadians(headingDegrees)),
        -math.sin(_degreesToRadians(headingDegrees)),
      );
      final stepDirection = step.value < 0 ? -1.0 : 1.0;
      var remainingTiles = step.value.abs();
      var hitBounds = false;

      while (remainingTiles > 0) {
        if (!mounted || generation != _runGeneration) {
          return;
        }

        final tileDistance = math.min(1.0, remainingTiles);
        final targetPosition =
            position + direction * (tileDistance * stepDirection);
        await _animateMove(
          generation: generation,
          fromPosition: position,
          toPosition: targetPosition,
          headingDegrees: headingDegrees,
          path: path,
        );
        position = targetPosition;
        path.add(position);

        if (!_isPlayerPositionInBounds(position)) {
          hitBounds = true;
          break;
        }

        remainingTiles -= tileDistance;
      }

      if (hitBounds) {
        break;
      }
    }

    if (!mounted || generation != _runGeneration) {
      return;
    }

    setState(() {
      _isRunningCode = false;
      _activeCodeLine = null;
    });
  }

  Future<void> _animateMove({
    required int generation,
    required Offset fromPosition,
    required Offset toPosition,
    required double headingDegrees,
    required List<Offset> path,
  }) async {
    final distanceTiles = (toPosition - fromPosition).distance.abs();
    if (distanceTiles == 0) {
      return;
    }

    final duration = _movementDurationForDistance(distanceTiles);
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < duration) {
      if (!mounted || generation != _runGeneration) {
        return;
      }
      final t = _movementProgressForElapsed(
        elapsed: stopwatch.elapsed,
        distanceTiles: distanceTiles,
      );
      final currentPosition = Offset.lerp(fromPosition, toPosition, t)!;
      setState(() {
        _playerPreview = _PlayerPreviewData(
          position: currentPosition,
          headingDegrees: headingDegrees,
          path: <Offset>[...path, currentPosition],
        );
      });
      await Future<void>.delayed(_runFrameInterval);
    }

    if (!mounted || generation != _runGeneration) {
      return;
    }

    setState(() {
      _playerPreview = _PlayerPreviewData(
        position: toPosition,
        headingDegrees: headingDegrees,
        path: <Offset>[...path, toPosition],
      );
    });
  }

  Duration _movementDurationForDistance(double distanceTiles) {
    final easeTiles = math.min(_runEaseTiles, distanceTiles / 2);
    final seconds = (distanceTiles + 2 * easeTiles) / _runTilesPerSecond;
    return Duration(milliseconds: math.max(160, (seconds * 1000).round()));
  }

  double _movementProgressForElapsed({
    required Duration elapsed,
    required double distanceTiles,
  }) {
    if (distanceTiles <= 0) {
      return 1;
    }

    final easeTiles = math.min(_runEaseTiles, distanceTiles / 2);
    final accelSeconds = 2 * easeTiles / _runTilesPerSecond;
    final cruiseSeconds =
        math.max(0.0, distanceTiles - 2 * easeTiles) / _runTilesPerSecond;
    final totalSeconds = 2 * accelSeconds + cruiseSeconds;
    final elapsedSeconds = math.min(
      elapsed.inMicroseconds / Duration.microsecondsPerSecond,
      totalSeconds,
    );

    if (accelSeconds == 0) {
      return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();
    }

    final acceleration = _runTilesPerSecond / accelSeconds;
    double traveledTiles;

    if (elapsedSeconds < accelSeconds) {
      traveledTiles = 0.5 * acceleration * elapsedSeconds * elapsedSeconds;
    } else if (elapsedSeconds < accelSeconds + cruiseSeconds) {
      traveledTiles =
          easeTiles + _runTilesPerSecond * (elapsedSeconds - accelSeconds);
    } else {
      final decelElapsed = elapsedSeconds - accelSeconds - cruiseSeconds;
      traveledTiles =
          easeTiles +
          (distanceTiles - 2 * easeTiles) +
          _runTilesPerSecond * decelElapsed -
          0.5 * acceleration * decelElapsed * decelElapsed;
    }

    return (traveledTiles / distanceTiles).clamp(0.0, 1.0).toDouble();
  }

  bool _isPlayerPositionInBounds(Offset position) {
    return position.dx >= 0.5 &&
        position.dx <= _cols - 0.5 &&
        position.dy >= 0.5 &&
        position.dy <= _rows - 0.5;
  }

  void _stopCodeRun() {
    _runGeneration += 1;
    if (!_isRunningCode && _activeCodeLine == null && _playerPreview == null) {
      return;
    }

    setState(() {
      _isRunningCode = false;
      _activeCodeLine = null;
      _playerPreview = null;
    });
  }

  void _resetRunState() {
    _stopCodeRun();
  }

  void _scrollToCodeLine(int lineIndex) {
    if (!_codeScrollController.hasClients) {
      return;
    }

    final targetOffset =
        (lineIndex - 2).clamp(0, lineIndex) * _editorLineHeightPixels;
    _codeScrollController.animateTo(
      targetOffset.clamp(0.0, _codeScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
  }

  _Cell? get _playerCell {
    for (final entry in _items.entries) {
      if (entry.value == _BoardItemType.player) {
        return entry.key;
      }
    }
    return null;
  }

  _Cell? get _goalCell {
    for (final entry in _items.entries) {
      if (entry.value == _BoardItemType.goal) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _handleSavePressed() async {
    await _persistProject(status: 'draft');
  }

  Future<void> _handlePublishPressed() async {
    final validationMessage = _validatePublishableLevel();
    if (validationMessage != null) {
      _showSnackBar(validationMessage, backgroundColor: Colors.red.shade600);
      return;
    }

    await _persistProject(status: 'published');
  }

  Future<void> _persistProject({required String status}) async {
    if (_isSavingProject) {
      return;
    }

    setState(() {
      _isSavingProject = true;
    });

    try {
      final projectJson = _buildProjectJson(status: status);
      final response = _savedProjectId == null
          ? await ApiService.createBuilderProject(
              authToken: widget.session.token,
              projectJson: projectJson,
            )
          : widget.useAdminLevelApi
          ? await ApiService.updateAdminLevel(
              authToken: widget.session.token,
              levelId: _savedProjectId!,
              levelJson: {
                'title': projectJson['title'],
                'description': projectJson['description'],
                'status': projectJson['status'],
                'builderType': projectJson['builderType'],
                'courseId': projectJson['courseId'],
                'orderInCourse': projectJson['orderInCourse'],
                'difficulty': projectJson['difficulty'],
                'draftData': projectJson,
              },
            )
          : await ApiService.updateBuilderProject(
              authToken: widget.session.token,
              projectId: _savedProjectId!,
              projectJson: projectJson,
            );

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['_id'] != null) {
          _savedProjectId = data['_id'].toString();
        }
        _loadedPossibleSolutionCode = _codeController.text;
        _showSnackBar(
          status == 'published'
              ? 'Top view game published successfully.'
              : 'Top view game saved successfully.',
          backgroundColor: Colors.green.shade600,
        );
      } else {
        final errors = response['errors'];
        final message = errors is List && errors.isNotEmpty
            ? errors.join('\n')
            : response['message']?.toString() ?? 'Failed to save game.';
        _showSnackBar(message, backgroundColor: Colors.red.shade600);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Save failed: $e', backgroundColor: Colors.red.shade600);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProject = false;
        });
      }
    }
  }

  Future<void> _loadProject(String projectId) async {
    setState(() {
      _isLoadingProject = true;
    });

    try {
      final response = widget.allowPublishedAccess
          ? await ApiService.getPublishedBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            )
          : widget.useAdminLevelApi
          ? await ApiService.getAdminLevelById(
              authToken: widget.session.token,
              levelId: projectId,
            )
          : await ApiService.getBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            );

      if (!mounted) {
        return;
      }

      if (response['success'] != true) {
        _showSnackBar(
          response['message']?.toString() ?? 'Failed to load top view game.',
          backgroundColor: Colors.red.shade600,
        );
        return;
      }

      final data = Map<String, dynamic>.from(response['data'] as Map);
      final rawDraftData = data['draftData'];
      final draftData = rawDraftData is Map
          ? Map<String, dynamic>.from(rawDraftData)
          : data;
      _applyProjectJson(data: data, draftData: draftData, projectId: projectId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Load failed: $e', backgroundColor: Colors.red.shade600);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProject = false;
        });
      }
    }
  }

  void _applyProjectJson({
    required Map<String, dynamic> data,
    required Map<String, dynamic> draftData,
    required String projectId,
  }) {
    final items = <_Cell, _BoardItemType>{};
    final rawItems = draftData['items'];
    if (rawItems is List) {
      for (final item in rawItems.whereType<Map>()) {
        final itemMap = Map<String, dynamic>.from(item);
        final type = _BoardItemTypeParser.fromId(itemMap['type']?.toString());
        final column = _readInt(itemMap['column']);
        final row = _readInt(itemMap['row']);
        if (type == null || column == null || row == null) {
          continue;
        }
        items[_Cell(column: column, row: row)] = type;
      }
    }

    final allowedBlocks = <_CodeBlock>[];
    final rawAllowedBlocks = draftData['allowedBlocks'];
    if (rawAllowedBlocks is List) {
      for (final rawBlock in rawAllowedBlocks) {
        final block = _codeBlockById(rawBlock.toString());
        if (block != null &&
            !allowedBlocks.any((item) => item.id == block.id)) {
          allowedBlocks.add(block);
        }
      }
    }

    setState(() {
      _savedProjectId = data['_id']?.toString() ?? projectId;
      _courseId =
          data['courseId']?.toString() ??
          draftData['courseId']?.toString() ??
          _courseId;
      _orderInCourse =
          _readInt(data['orderInCourse']) ??
          _readInt(draftData['orderInCourse']) ??
          _orderInCourse;
      _difficulty =
          data['difficulty']?.toString() ??
          draftData['difficulty']?.toString() ??
          _difficulty;
      _titleController.text =
          data['title']?.toString() ??
          draftData['title']?.toString() ??
          widget.initialTitle ??
          'New Level';
      _items
        ..clear()
        ..addAll(items);
      _allowedBlocks
        ..clear()
        ..addAll(allowedBlocks);
      _initialPlayerHeadingDegrees =
          (_readDouble(draftData['initialDirectionDegrees']) ?? 0) % 360;
      _loadedPossibleSolutionCode = draftData['solutionCode']?.toString() ?? '';
      _codeController.text = widget.playMode
          ? ''
          : (_loadedPossibleSolutionCode ?? '');
      _playerPreview = null;
      _activeCodeLine = null;
    });
  }

  Map<String, dynamic> _buildProjectJson({required String status}) {
    return {
      'builderType': 'topView',
      'title': _titleController.text.trim().isEmpty
          ? 'New Level'
          : _titleController.text.trim(),
      'description': '',
      'status': status,
      'courseId': _courseId,
      'orderInCourse': _orderInCourse,
      'difficulty': _difficulty,
      'settings': {'columns': _cols, 'rows': _rows},
      'items': _items.entries
          .map(
            (entry) => {
              'type': entry.value.id,
              'column': entry.key.column,
              'row': entry.key.row,
            },
          )
          .toList(),
      'allowedBlocks': _allowedBlocks.map((block) => block.id).toList(),
      'solutionCode': _codeController.text,
      'initialDirectionDegrees': _initialPlayerHeadingDegrees,
    };
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validatePublishableLevel() {
    final playerCell = _playerCell;
    if (playerCell == null) {
      return 'Add a player before publishing.';
    }

    final goalCell = _goalCell;
    if (goalCell == null) {
      return 'Add a goal before publishing.';
    }

    if (_allowedBlocks.isEmpty) {
      return 'Add solution blocks before publishing.';
    }

    final steps = _parseCodeSteps();
    if (steps.isEmpty) {
      return 'Write a possible solution before publishing.';
    }

    final result = _simulateTopViewSolution(
      steps: steps,
      playerCell: playerCell,
      goalCell: goalCell,
      collectableCells: _collectableCells,
    );

    return result.success ? null : result.message;
  }

  List<_Cell> get _collectableCells {
    return _items.entries
        .where((entry) => entry.value == _BoardItemType.collectable)
        .map((entry) => entry.key)
        .toList();
  }

  _TopViewSolutionResult _simulateTopViewSolution({
    required List<_CodeExecutionStep> steps,
    required _Cell playerCell,
    required _Cell goalCell,
    required List<_Cell> collectableCells,
  }) {
    var position = Offset(playerCell.column + 0.5, playerCell.row + 0.5);
    var headingDegrees = _initialPlayerHeadingDegrees;
    final collected = <_Cell>{};
    _collectAtPosition(position, collectableCells, collected);

    for (final step in steps) {
      if (step.type == _CodeExecutionType.turn) {
        headingDegrees = step.absoluteTurn
            ? _normalizeDegrees(step.value)
            : _normalizeDegrees(headingDegrees + step.value);
        continue;
      }

      final direction = Offset(
        math.cos(_degreesToRadians(headingDegrees)),
        -math.sin(_degreesToRadians(headingDegrees)),
      );
      final stepDirection = step.value < 0 ? -1.0 : 1.0;
      var remainingTiles = step.value.abs();

      while (remainingTiles > 0) {
        final tileDistance = math.min(1.0, remainingTiles);
        position += direction * (tileDistance * stepDirection);

        if (!_isPlayerPositionInBounds(position)) {
          return const _TopViewSolutionResult(
            success: false,
            message: 'The possible solution moves the player out of bounds.',
          );
        }

        _collectAtPosition(position, collectableCells, collected);
        remainingTiles -= tileDistance;
      }
    }

    if (collected.length != collectableCells.length) {
      return const _TopViewSolutionResult(
        success: false,
        message: 'The possible solution must collect all collectables.',
      );
    }

    if (!_positionMatchesCell(position, goalCell)) {
      return const _TopViewSolutionResult(
        success: false,
        message: 'The possible solution must finish on the goal.',
      );
    }

    return const _TopViewSolutionResult(success: true);
  }

  void _collectAtPosition(
    Offset position,
    List<_Cell> collectableCells,
    Set<_Cell> collected,
  ) {
    for (final cell in collectableCells) {
      if (_positionMatchesCell(position, cell)) {
        collected.add(cell);
      }
    }
  }

  bool _positionMatchesCell(Offset position, _Cell cell) {
    return (position.dx - (cell.column + 0.5)).abs() < 0.001 &&
        (position.dy - (cell.row + 0.5)).abs() < 0.001;
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  _CodeBlock? _codeBlockById(String id) {
    for (final block in _codeBlocks) {
      if (block.id == id) {
        return block;
      }
    }
    return null;
  }

  bool _acceptsBoardPayload(_Payload? payload) {
    if (widget.playMode || _rulerActive || payload == null) {
      return false;
    }
    return payload.kind == _PayloadKind.boardPalette ||
        payload.kind == _PayloadKind.boardItem;
  }

  void _handleBoardDrop(_Payload payload, _Cell target) {
    switch (payload.kind) {
      case _PayloadKind.boardPalette:
        if (payload.itemType != null) {
          _placeItem(payload.itemType!, target);
        }
      case _PayloadKind.boardItem:
        if (payload.itemType != null && payload.sourceCell != null) {
          _placeItem(payload.itemType!, target, source: payload.sourceCell);
        }
      case _PayloadKind.solutionBlock:
      case _PayloadKind.solutionTrayBlock:
        return;
    }
  }

  void _placeItem(_BoardItemType type, _Cell target, {_Cell? source}) {
    if (source == target && _items[target] == type) {
      return;
    }
    setState(() {
      if (source != null) {
        _items.remove(source);
      }
      if (type == _BoardItemType.player || type == _BoardItemType.goal) {
        _items.removeWhere((cell, item) => item == type && cell != target);
      }
      _items[target] = type;
    });
    _stopCodeRun();
  }

  void _deleteItem(_Cell cell) {
    final removed = _items[cell];
    if (removed == null) {
      return;
    }
    setState(() {
      _items.remove(cell);
    });
    _stopCodeRun();
  }

  void _deleteSolutionBlock(_CodeBlock block) {
    setState(() {
      _allowedBlocks.removeWhere((item) => item.id == block.id);
    });
  }

  void _toggleRuler([Offset? pointerPosition]) {
    setState(() {
      if (_rulerActive) {
        _rulerActive = false;
        _rulerStart = null;
        _rulerOverlay.value = const _RulerOverlayData();
        return;
      }

      _rulerActive = true;
      _rulerStart = null;
      _rulerOverlay.value = _RulerOverlayData(hoverPosition: pointerPosition);
    });
  }

  void _tapCell(_Cell cell, Offset boardPosition) {
    if (!_rulerActive) {
      return;
    }
    if (_rulerStart == null) {
      setState(() {
        _rulerStart = cell;
        _rulerOverlay.value = _RulerOverlayData(
          start: cell,
          hoverCell: cell,
          hoverPosition: boardPosition,
          distance: 0,
          angleDegrees: 0,
        );
      });
      return;
    }
    setState(() {
      _rulerStart = null;
      _rulerOverlay.value = _RulerOverlayData(
        hoverCell: cell,
        hoverPosition: boardPosition,
      );
    });
  }

  void _hoverCell(
    _Cell cell,
    Offset boardPosition,
    double cellWidth,
    double cellHeight,
  ) {
    if (!_rulerActive) {
      return;
    }
    final measurement = _rulerStart == null
        ? null
        : _measureRuler(
            start: _rulerStart!,
            hoverPosition: boardPosition,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          );
    final nextOverlay = _RulerOverlayData(
      start: _rulerStart,
      hoverCell: cell,
      hoverPosition: boardPosition,
      distance: measurement?.distance,
      angleDegrees: measurement?.angleDegrees,
    );
    if (_rulerOverlay.value == nextOverlay) {
      return;
    }
    _rulerOverlay.value = nextOverlay;
  }

  void _leaveBoard() {
    if (_rulerOverlay.value == const _RulerOverlayData()) {
      return;
    }
    _rulerOverlay.value = _RulerOverlayData(start: _rulerStart);
  }

  _RulerMeasurement _measureRuler({
    required _Cell start,
    required Offset hoverPosition,
    required double cellWidth,
    required double cellHeight,
  }) {
    final startCenter = Offset(
      (start.column + 0.5) * cellWidth,
      (start.row + 0.5) * cellHeight,
    );
    final vector = hoverPosition - startCenter;
    final distance = math
        .sqrt(
          math.pow(vector.dx / cellWidth, 2) +
              math.pow(vector.dy / cellHeight, 2),
        )
        .round();
    final angleDegrees = _angleFromPositiveXAxis(vector).round();

    return _RulerMeasurement(
      distance: distance,
      angleDegrees: angleDegrees == 360 ? 0 : angleDegrees,
    );
  }

  double _angleFromPositiveXAxis(Offset vector) {
    if (vector.dx == 0 && vector.dy == 0) {
      return 0;
    }
    return _normalizeDegrees(-math.atan2(vector.dy, vector.dx) * 180 / math.pi);
  }

  double _normalizeDegrees(double degrees) {
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void _addAllowedBlock(_CodeBlock block) {
    if (_allowedBlocks.any((item) => item.id == block.id)) {
      return;
    }
    setState(() {
      _allowedBlocks.add(block);
    });
  }

  void _removeAllowedBlock(_CodeBlock block) {
    setState(() {
      _allowedBlocks.removeWhere((item) => item.id == block.id);
    });
  }

  Future<void> _handleClearLevelPressed() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Level?'),
          content: const Text(
            'This will remove all placed pieces, solution blocks, and editor code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldClear != true) {
      return;
    }

    _runGeneration += 1;
    _codeController.clear();
    setState(() {
      _items.clear();
      _allowedBlocks.clear();
      _isRunningCode = false;
      _activeCodeLine = null;
      _rulerActive = false;
      _rulerStart = null;
      _playerPreview = null;
      _rulerOverlay.value = const _RulerOverlayData();
    });
  }

  Offset _boardOffset(
    _Cell cell,
    Offset localPosition,
    double cellWidth,
    double cellHeight,
  ) {
    return Offset(
      cell.column * cellWidth + localPosition.dx,
      cell.row * cellHeight + localPosition.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: widget.playMode
            ? Text(widget.initialTitle ?? _titleController.text)
            : TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'New Level',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleLarge,
                cursorColor: Colors.black,
                maxLines: 1,
              ),
        actions: widget.playMode
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextButton(
                    onPressed: _isSavingProject ? null : _handleSavePressed,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton(
                    onPressed: _isSavingProject ? null : _handlePublishPressed,
                    child: Text(_isSavingProject ? 'Saving...' : 'Publish'),
                  ),
                ),
              ],
      ),
      body: _isLoadingProject
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFEAF6FF),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 1280;
                      final tools = _buildToolsSidebar();
                      final grid = _buildGridPanel();
                      final editor = _buildCodeWorkspace();

                      if (compact) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!widget.playMode) ...[
                                SizedBox(height: 520, child: tools),
                                const SizedBox(height: 20),
                              ],
                              SizedBox(height: 700, child: grid),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: widget.playMode ? 920 : 760,
                                child: editor,
                              ),
                            ],
                          ),
                        );
                      }

                      return Row(
                        children: [
                          if (!widget.playMode)
                            Container(
                              width: _leftPanelWidth,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                12,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.blueGrey.shade100,
                                  ),
                                ),
                              ),
                              child: tools,
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 13, child: grid),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 7, child: editor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (!widget.playMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Center(child: _buildTrash()),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildToolsSidebar() {
    return ListView(
      children: [
        _buildSidebarSection(
          title: 'Tools',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _BoardItemType.values
                .map(_buildBoardPaletteItem)
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Instructions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _codeBlocks.map(_buildInstructionTool).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Player Direction',
          child: _buildInitialDirectionControl(),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Level Actions',
          child: FilledButton.icon(
            onPressed: _handleClearLevelPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.layers_clear_outlined, size: 18),
            label: const Text(
              'Clear Level',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: 'Level Info',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grid: $_cols columns x $_rows rows',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _rulerActive
                    ? 'Ruler mode is active. Press a tile to start measuring, then press again to clear.'
                    : 'Drag pieces into the board, then write the path in the code panel.',
                style: TextStyle(color: Colors.blueGrey.shade700, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridPanel() {
    return _windowFrame(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _cols / _rows,
                  child: _buildBoard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _cols;
        final cellHeight = constraints.maxHeight / _rows;
        return MouseRegion(
          onExit: (_) => _leaveBoard(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCADDF0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blueGrey.shade200, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cols * _rows,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ _cols;
                    final column = index % _cols;
                    final cell = _Cell(column: column, row: row);
                    final item = _items[cell];
                    final isPreviewedPlayer =
                        item == _BoardItemType.player && _playerPreview != null;
                    return DragTarget<_Payload>(
                      onWillAcceptWithDetails: (details) {
                        return _acceptsBoardPayload(details.data);
                      },
                      onAcceptWithDetails: (details) {
                        _handleBoardDrop(details.data, cell);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final highlight = candidateData.any(
                          _acceptsBoardPayload,
                        );
                        return MouseRegion(
                          onHover: (event) {
                            _hoverCell(
                              cell,
                              _boardOffset(
                                cell,
                                event.localPosition,
                                cellWidth,
                                cellHeight,
                              ),
                              cellWidth,
                              cellHeight,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: highlight
                                  ? const Color(0xFFE8F4FF)
                                  : item == _BoardItemType.obstacle
                                  ? const Color(0xFFDCE4EC)
                                  : const Color(0xFFCFE1F3),
                              border: Border.all(
                                color: const Color(0xFFA7C4DE),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) {
                                      _tapCell(
                                        cell,
                                        _boardOffset(
                                          cell,
                                          details.localPosition,
                                          cellWidth,
                                          cellHeight,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (item != null)
                                  Positioned.fill(
                                    child: Center(
                                      child: _rulerActive
                                          ? IgnorePointer(
                                              child: Opacity(
                                                opacity: isPreviewedPlayer
                                                    ? 0.35
                                                    : 1,
                                                child: _boardIcon(item),
                                              ),
                                            )
                                          : Draggable<_Payload>(
                                              data: _Payload.boardItem(
                                                item,
                                                cell,
                                              ),
                                              feedback: Material(
                                                color: Colors.transparent,
                                                child: _boardIcon(
                                                  item,
                                                  small: true,
                                                ),
                                              ),
                                              childWhenDragging:
                                                  const SizedBox.expand(),
                                              onDragStarted: () {
                                                setState(() {
                                                  _isBoardItemDragging = true;
                                                });
                                              },
                                              onDragEnd: (_) {
                                                if (!mounted) {
                                                  return;
                                                }
                                                setState(() {
                                                  _isBoardItemDragging = false;
                                                });
                                              },
                                              child: Opacity(
                                                opacity: isPreviewedPlayer
                                                    ? 0.35
                                                    : 1,
                                                child: _boardIcon(item),
                                              ),
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                if (_playerPreview != null)
                  _buildPlayerPreviewOverlay(cellWidth, cellHeight),
                ValueListenableBuilder<_RulerOverlayData>(
                  valueListenable: _rulerOverlay,
                  builder: (context, ruler, child) {
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (ruler.hasVisuals)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _RulerOverlayPainter(
                                      start: ruler.start,
                                      hoverCell: ruler.hoverCell,
                                      hoverPosition: ruler.hoverPosition,
                                      angleDegrees: ruler.angleDegrees,
                                      cellWidth: cellWidth,
                                      cellHeight: cellHeight,
                                    ),
                                  ),
                                ),
                              if (_rulerActive && ruler.hoverPosition != null)
                                _rulerGhost(position: ruler.hoverPosition!),
                              if (ruler.distance != null &&
                                  ruler.angleDegrees != null &&
                                  ruler.hoverPosition != null &&
                                  ruler.start != null)
                                _rulerMeasurementBubble(
                                  position: ruler.hoverPosition!,
                                  distance: ruler.distance!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: _rulerHandleInset,
                  left: _rulerHandleInset,
                  child: _buildRulerHandle(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerPreviewOverlay(double cellWidth, double cellHeight) {
    final preview = _playerPreview;
    if (preview == null) {
      return const SizedBox.shrink();
    }

    final iconSize = math.min(cellWidth, cellHeight) * 0.72;
    final left = preview.position.dx * cellWidth - iconSize / 2;
    final top = preview.position.dy * cellHeight - iconSize / 2;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              width: iconSize,
              height: iconSize,
              child: _playerPreviewIcon(
                headingDegrees: preview.headingDegrees,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeWorkspace() {
    return _windowFrame(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                FilledButton.icon(
                  onPressed: _runCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRunningCode
                        ? Colors.red.shade600
                        : Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    _isRunningCode ? Icons.stop_rounded : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(_isRunningCode ? 'Stop' : 'Run'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetRunState,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade900,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearCode,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: Colors.blueGrey.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueGrey.shade200, width: 2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 42,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _codeController,
                        builder: (context, value, child) {
                          final lineCount =
                              '\n'.allMatches(value.text).length + 1;
                          return SingleChildScrollView(
                            controller: _lineNumberScrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List<Widget>.generate(lineCount, (
                                  index,
                                ) {
                                  final isActiveLine = _activeCodeLine == index;
                                  return Text(
                                    '${index + 1}',
                                    strutStyle: _editorStrutStyle,
                                    style: TextStyle(
                                      color: isActiveLine
                                          ? Colors.teal.shade800
                                          : Colors.blueGrey.shade400,
                                      fontFamily: 'monospace',
                                      fontSize: _editorFontSize,
                                      height: _editorLineHeight,
                                      fontWeight: isActiveLine
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        children: [
                          if (_activeCodeLine != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              top:
                                  _activeCodeLine! * _editorLineHeightPixels -
                                  (_codeScrollController.hasClients
                                      ? _codeScrollController.offset
                                      : 0),
                              height: _editorLineHeightPixels,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.teal.shade200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: TextField(
                              controller: _codeController,
                              focusNode: _codeFocusNode,
                              scrollController: _codeScrollController,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              keyboardType: TextInputType.multiline,
                              textAlignVertical: TextAlignVertical.top,
                              strutStyle: _editorStrutStyle,
                              style: const TextStyle(
                                color: Colors.black,
                                fontFamily: 'monospace',
                                fontSize: _editorFontSize,
                                height: _editorLineHeight,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Solution Blocks',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildSolutionTray(),
            if (widget.playMode &&
                (_loadedPossibleSolutionCode ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPossibleSolutionPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPossibleSolutionPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200, width: 1.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Possible Solution',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _loadedPossibleSolutionCode ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionTray() {
    return DragTarget<_Payload>(
      onWillAcceptWithDetails: (details) {
        return !widget.playMode &&
            details.data.kind == _PayloadKind.solutionBlock;
      },
      onAcceptWithDetails: (details) {
        if (details.data.block != null) {
          _addAllowedBlock(details.data.block!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.any(
          (data) => data?.kind == _PayloadKind.solutionBlock,
        );

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? Colors.green.shade50 : Colors.blueGrey.shade50,
            border: Border.all(
              color: highlight
                  ? Colors.green.shade300
                  : Colors.blueGrey.shade200,
              width: highlight ? 2.4 : 1.8,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: _allowedBlocks.isEmpty
              ? Center(
                  child: Text(
                    widget.playMode
                        ? 'No solution blocks were provided'
                        : 'Drop instruction blocks here',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _allowedBlocks.map(_allowedChip).toList(),
                ),
        );
      },
    );
  }

  Widget _buildBoardPaletteItem(_BoardItemType item) {
    final tile = _toolTile(
      label: item.label,
      icon: item.icon,
      color: item.color,
    );
    return Draggable<_Payload>(
      data: _Payload.boardPalette(item),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 96,
          child: _toolTile(
            label: item.label,
            icon: item.icon,
            color: item.color,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }

  Widget _buildInitialDirectionControl() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<double>(
        showSelectedIcon: false,
        selected: <double>{_initialPlayerHeadingDegrees},
        segments: const [
          ButtonSegment<double>(
            value: 90,
            icon: Icon(Icons.keyboard_arrow_up_rounded),
            tooltip: 'Start facing up',
          ),
          ButtonSegment<double>(
            value: 0,
            icon: Icon(Icons.keyboard_arrow_right_rounded),
            tooltip: 'Start facing right',
          ),
          ButtonSegment<double>(
            value: 270,
            icon: Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: 'Start facing down',
          ),
          ButtonSegment<double>(
            value: 180,
            icon: Icon(Icons.keyboard_arrow_left_rounded),
            tooltip: 'Start facing left',
          ),
        ],
        onSelectionChanged: (selection) {
          final direction = selection.first;
          if (direction == _initialPlayerHeadingDegrees) {
            return;
          }

          _stopCodeRun();
          setState(() {
            _initialPlayerHeadingDegrees = direction;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionTool(_CodeBlock block) {
    final tile = _toolTile(
      label: block.label,
      color: block.color,
      icon: Icons.code_rounded,
      isInstruction: true,
    );

    return Draggable<_Payload>(
      data: _Payload.solutionBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 118,
          child: _toolTile(
            label: block.label,
            color: block.color,
            icon: Icons.code_rounded,
            isInstruction: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(14),
        child: tile,
      ),
    );
  }

  Widget _allowedChip(_CodeBlock block) {
    if (widget.playMode) {
      return InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(16),
        child: _buildAllowedChipVisual(block),
      );
    }

    return Draggable<_Payload>(
      data: _Payload.solutionTrayBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: _buildAllowedChipVisual(block),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildAllowedChipVisual(block),
      ),
      onDragStarted: () {
        setState(() {
          _isSolutionTrayBlockDragging = true;
        });
      },
      onDragEnd: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSolutionTrayBlockDragging = false;
        });
      },
      child: InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(16),
        child: _buildAllowedChipVisual(block),
      ),
    );
  }

  Widget _buildAllowedChipVisual(_CodeBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: block.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: block.color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_rounded, size: 16, color: block.color),
          const SizedBox(width: 8),
          Text(
            block.label,
            style: TextStyle(color: block.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          if (!widget.playMode)
            GestureDetector(
              onTap: () => _removeAllowedBlock(block),
              child: Icon(Icons.close, size: 16, color: block.color),
            ),
        ],
      ),
    );
  }

  Widget _toolTile({
    required String label,
    required Color color,
    IconData? icon,
    bool isInstruction = false,
  }) {
    return Container(
      width: isInstruction ? 92 : 78,
      height: isInstruction ? 70 : 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: isInstruction ? 18 : 22),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: isInstruction ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: isInstruction ? 13 : 12,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulerHandle() {
    return Tooltip(
      message: _rulerActive ? 'Deselect ruler' : 'Select ruler',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            _toggleRuler(
              Offset(
                _rulerHandleInset + details.localPosition.dx,
                _rulerHandleInset + details.localPosition.dy,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _rulerActive ? Colors.teal.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _rulerActive
                    ? Colors.teal.shade300
                    : Colors.blueGrey.shade200,
                width: 1.8,
              ),
            ),
            child: Icon(
              Icons.straighten,
              color: Colors.teal.shade700,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rulerGhost({required Offset position}) {
    return Positioned(
      left: position.dx - 12,
      top: position.dy - 26,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.65,
          child: Icon(
            Icons.straighten,
            color: Colors.teal.shade700.withValues(alpha: 0.58),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _rulerMeasurementBubble({
    required Offset position,
    required int distance,
  }) {
    return Positioned(
      left: position.dx + 12,
      top: position.dy - 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            '$distance tiles',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrash() {
    final isVisible = _isBoardItemDragging || _isSolutionTrayBlockDragging;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1.25),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: isVisible ? 1 : 0,
          child: DragTarget<_Payload>(
            onWillAcceptWithDetails: (details) {
              return details.data.kind == _PayloadKind.boardItem ||
                  details.data.kind == _PayloadKind.solutionTrayBlock;
            },
            onAcceptWithDetails: (details) {
              if (details.data.kind == _PayloadKind.boardItem &&
                  details.data.sourceCell != null) {
                _deleteItem(details.data.sourceCell!);
                return;
              }

              if (details.data.kind == _PayloadKind.solutionTrayBlock &&
                  details.data.block != null) {
                _deleteSolutionBlock(details.data.block!);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final highlight = candidateData.any(
                (data) =>
                    data?.kind == _PayloadKind.boardItem ||
                    data?.kind == _PayloadKind.solutionTrayBlock,
              );
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: highlight
                      ? Colors.red.shade600
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: highlight
                        ? Colors.red.shade600
                        : Colors.red.shade100,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      highlight ? Icons.delete : Icons.delete_outline,
                      color: highlight ? Colors.white : Colors.red.shade600,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Drop to delete',
                      style: TextStyle(
                        color: highlight ? Colors.white : Colors.red.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _boardIcon(_BoardItemType item, {bool small = false}) {
    final size = small ? 26.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(
          item == _BoardItemType.obstacle ? 5 : 8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _boardItemIcon(item, size: size * 0.56),
    );
  }

  Widget _boardItemIcon(_BoardItemType item, {required double size}) {
    final icon = Icon(item.icon, size: size, color: Colors.white);
    if (item != _BoardItemType.player) {
      return icon;
    }

    return Transform.rotate(
      angle: _degreesToRadians(90 - _initialPlayerHeadingDegrees),
      child: icon,
    );
  }

  Widget _playerPreviewIcon({
    required double headingDegrees,
    required double size,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _BoardItemType.player.color,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: _degreesToRadians(90 - headingDegrees),
        child: Icon(
          _BoardItemType.player.icon,
          size: size * 0.58,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSidebarSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _windowFrame({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

const List<_CodeBlock> _codeBlocks = <_CodeBlock>[
  _CodeBlock(
    id: 'step',
    label: 'step',
    insertText: 'step ',
    color: Color(0xFF1D4ED8),
    startsOnNewLine: true,
  ),
  _CodeBlock(
    id: 'turn',
    label: 'turn',
    insertText: 'turn ',
    color: Color(0xFF0F766E),
    startsOnNewLine: true,
  ),
  _CodeBlock(id: 'up', label: 'up', insertText: 'up', color: Color(0xFF0891B2)),
  _CodeBlock(
    id: 'left',
    label: 'left',
    insertText: 'left',
    color: Color(0xFF7C3AED),
  ),
  _CodeBlock(
    id: 'right',
    label: 'right',
    insertText: 'right',
    color: Color(0xFFB45309),
  ),
  _CodeBlock(
    id: 'down',
    label: 'down',
    insertText: 'down',
    color: Color(0xFFBE123C),
  ),
];

enum _BoardItemType {
  obstacle('Obstacle', Icons.crop_square_rounded, Color(0xFF475569)),
  player('Player', Icons.navigation_rounded, Color(0xFF2563EB)),
  collectable('Collectable', Icons.star_rounded, Color(0xFFF59E0B)),
  goal('Goal', Icons.flag_rounded, Color(0xFFDC2626));

  const _BoardItemType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

extension _BoardItemTypeId on _BoardItemType {
  String get id {
    switch (this) {
      case _BoardItemType.obstacle:
        return 'obstacle';
      case _BoardItemType.player:
        return 'player';
      case _BoardItemType.collectable:
        return 'collectable';
      case _BoardItemType.goal:
        return 'goal';
    }
  }
}

class _BoardItemTypeParser {
  static _BoardItemType? fromId(String? id) {
    switch (id) {
      case 'obstacle':
        return _BoardItemType.obstacle;
      case 'player':
        return _BoardItemType.player;
      case 'collectable':
        return _BoardItemType.collectable;
      case 'goal':
        return _BoardItemType.goal;
      default:
        return null;
    }
  }
}

enum _PayloadKind { boardPalette, boardItem, solutionBlock, solutionTrayBlock }

class _Payload {
  final _PayloadKind kind;
  final _BoardItemType? itemType;
  final _Cell? sourceCell;
  final _CodeBlock? block;

  const _Payload._({
    required this.kind,
    this.itemType,
    this.sourceCell,
    this.block,
  });

  const _Payload.boardPalette(_BoardItemType itemType)
    : this._(kind: _PayloadKind.boardPalette, itemType: itemType);
  const _Payload.boardItem(_BoardItemType itemType, _Cell sourceCell)
    : this._(
        kind: _PayloadKind.boardItem,
        itemType: itemType,
        sourceCell: sourceCell,
      );
  const _Payload.solutionBlock(_CodeBlock block)
    : this._(kind: _PayloadKind.solutionBlock, block: block);
  const _Payload.solutionTrayBlock(_CodeBlock block)
    : this._(kind: _PayloadKind.solutionTrayBlock, block: block);
}

class _CodeBlock {
  final String id;
  final String label;
  final String insertText;
  final Color color;
  final bool startsOnNewLine;

  const _CodeBlock({
    required this.id,
    required this.label,
    required this.insertText,
    required this.color,
    this.startsOnNewLine = false,
  });
}

enum _CodeExecutionType { turn, step }

class _CodeExecutionStep {
  final int lineIndex;
  final _CodeExecutionType type;
  final double value;
  final bool absoluteTurn;

  const _CodeExecutionStep._({
    required this.lineIndex,
    required this.type,
    required this.value,
    this.absoluteTurn = false,
  });

  const _CodeExecutionStep.turn({
    required int lineIndex,
    required double degrees,
    required bool absolute,
  }) : this._(
         lineIndex: lineIndex,
         type: _CodeExecutionType.turn,
         value: degrees,
         absoluteTurn: absolute,
       );

  const _CodeExecutionStep.step({
    required int lineIndex,
    required double amount,
  }) : this._(
         lineIndex: lineIndex,
         type: _CodeExecutionType.step,
         value: amount,
       );
}

class _PlayerPreviewData {
  final Offset position;
  final double headingDegrees;
  final List<Offset> path;

  const _PlayerPreviewData({
    required this.position,
    required this.headingDegrees,
    required this.path,
  });

  @override
  bool operator ==(Object other) {
    return other is _PlayerPreviewData &&
        other.position == position &&
        other.headingDegrees == headingDegrees &&
        _offsetListsAreEqual(other.path, path);
  }

  @override
  int get hashCode =>
      Object.hash(position, headingDegrees, Object.hashAll(path));
}

class _TopViewSolutionResult {
  final bool success;
  final String? message;

  const _TopViewSolutionResult({required this.success, this.message});
}

class _Cell {
  final int column;
  final int row;

  const _Cell({required this.column, required this.row});

  @override
  bool operator ==(Object other) {
    return other is _Cell && other.column == column && other.row == row;
  }

  @override
  int get hashCode => Object.hash(column, row);
}

class _RulerMeasurement {
  final int distance;
  final int angleDegrees;

  const _RulerMeasurement({required this.distance, required this.angleDegrees});
}

class _RulerOverlayData {
  final _Cell? start;
  final _Cell? hoverCell;
  final Offset? hoverPosition;
  final int? distance;
  final int? angleDegrees;

  const _RulerOverlayData({
    this.start,
    this.hoverCell,
    this.hoverPosition,
    this.distance,
    this.angleDegrees,
  });

  bool get hasVisuals =>
      start != null || hoverCell != null || hoverPosition != null;

  @override
  bool operator ==(Object other) {
    return other is _RulerOverlayData &&
        other.start == start &&
        other.hoverCell == hoverCell &&
        other.hoverPosition == hoverPosition &&
        other.distance == distance &&
        other.angleDegrees == angleDegrees;
  }

  @override
  int get hashCode =>
      Object.hash(start, hoverCell, hoverPosition, distance, angleDegrees);
}

class _RulerOverlayPainter extends CustomPainter {
  final _Cell? start;
  final _Cell? hoverCell;
  final Offset? hoverPosition;
  final int? angleDegrees;
  final double cellWidth;
  final double cellHeight;

  const _RulerOverlayPainter({
    required this.start,
    required this.hoverCell,
    required this.hoverPosition,
    required this.angleDegrees,
    required this.cellWidth,
    required this.cellHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset? lineStart;

    if (start != null) {
      _paintCell(
        canvas,
        start!,
        fill: const Color(0xFFDCFCE7).withValues(alpha: 0.62),
        stroke: const Color(0xFF33A167),
        strokeWidth: 2,
      );

      lineStart = Offset(
        (start!.column + 0.5) * cellWidth,
        (start!.row + 0.5) * cellHeight,
      );
    }

    if (hoverCell != null && hoverCell != start) {
      _paintCell(
        canvas,
        hoverCell!,
        fill: const Color(0xFFDFF3FF).withValues(alpha: 0.58),
        stroke: const Color(0xFF3B82F6),
        strokeWidth: 2,
      );
    }

    if (start == null || hoverPosition == null) {
      return;
    }

    final startPoint = lineStart!;
    final vector = hoverPosition! - startPoint;
    final lineLength = vector.distance;
    final shadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = const Color(0xFF0F766E).withValues(alpha: 0.82)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final markerPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.9);
    final axisPaint = Paint()
      ..color = const Color(0xFF0F766E).withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final arcPaint = Paint()
      ..color = const Color(0xFF14B8A6).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final axisLength = math.max(26.0, math.min(72.0, lineLength * 0.75));
    canvas.drawLine(startPoint, startPoint + Offset(axisLength, 0), axisPaint);

    if (lineLength > 1) {
      final screenAngle = math.atan2(vector.dy, vector.dx);
      final mathAngle = (-screenAngle) % (math.pi * 2);
      final sweepAngle = mathAngle == 0 ? 0.0 : -mathAngle;
      final arcRadius = math.max(18.0, math.min(58.0, lineLength * 0.34));
      canvas.drawArc(
        Rect.fromCircle(center: startPoint, radius: arcRadius),
        0,
        sweepAngle,
        false,
        arcPaint,
      );
      _paintAngleLabel(
        canvas: canvas,
        size: size,
        center: startPoint,
        radius: arcRadius,
        sweepAngle: sweepAngle,
      );
    }

    canvas
      ..drawLine(startPoint, hoverPosition!, shadowPaint)
      ..drawLine(startPoint, hoverPosition!, linePaint)
      ..drawCircle(startPoint, 6, markerPaint)
      ..drawCircle(hoverPosition!, 4, markerPaint);
  }

  void _paintAngleLabel({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double radius,
    required double sweepAngle,
  }) {
    final angle = angleDegrees;
    if (angle == null) {
      return;
    }

    final labelAngle = sweepAngle == 0 ? -0.22 : sweepAngle / 2;
    final labelCenter =
        center +
        Offset(math.cos(labelAngle), math.sin(labelAngle)) * (radius + 18);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$angle\u00B0',
        style: const TextStyle(
          color: Color(0xFF0F766E),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelOffset = Offset(
      (labelCenter.dx - textPainter.width / 2)
          .clamp(4.0, size.width - textPainter.width - 4)
          .toDouble(),
      (labelCenter.dy - textPainter.height / 2)
          .clamp(4.0, size.height - textPainter.height - 4)
          .toDouble(),
    );
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx - 5,
        labelOffset.dy - 4,
        textPainter.width + 10,
        textPainter.height + 8,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      backgroundRect,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
    textPainter.paint(canvas, labelOffset);
  }

  void _paintCell(
    Canvas canvas,
    _Cell cell, {
    required Color fill,
    required Color stroke,
    required double strokeWidth,
  }) {
    final rect = Rect.fromLTWH(
      cell.column * cellWidth,
      cell.row * cellHeight,
      cellWidth,
      cellHeight,
    );
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas
      ..drawRect(rect.deflate(strokeWidth / 2), fillPaint)
      ..drawRect(rect.deflate(strokeWidth / 2), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RulerOverlayPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.hoverCell != hoverCell ||
        oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.angleDegrees != angleDegrees ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.cellHeight != cellHeight;
  }
}

bool _offsetListsAreEqual(List<Offset> a, List<Offset> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
