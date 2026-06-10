import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:client/core/models/auth_session.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/builder/front_view/models/custom_asset_data.dart';
import 'package:client/features/builder/shared/level_score.dart';
import 'package:client/features/builder/shared/solver/grid_position.dart';
import 'package:client/features/builder/shared/widgets/course_level_nav_banner.dart';
import 'package:client/features/builder/shared/widgets/challenge_leave_dialog.dart';
import 'package:client/features/builder/shared/widgets/game_builder_back_icon.dart';
import 'package:client/features/builder/shared/widgets/game_builder_level_title_field.dart';
import 'package:client/features/builder/shared/widgets/kids_top_bar_style.dart';
import 'package:client/features/builder/shared/widgets/level_result_dialog.dart';
import 'package:client/features/builder/top_view/flame/top_view_builder_game.dart';
import 'package:client/features/builder/top_view/models/top_view_board_style.dart';
import 'package:client/features/builder/top_view/models/top_view_character.dart';
import 'package:client/features/builder/top_view/solver/top_view_level_grid.dart';
import 'package:client/features/builder/top_view/solver/top_view_solution_converter.dart';
import 'package:client/features/builder/top_view/solver/top_view_solver.dart';
import 'package:flame/game.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopViewBuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;

  const TopViewBuilderPage({
    super.key,
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
    this.courseProgressCourseId,
    this.courseProgressLevelId,
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
  static const double _runTilesPerSecond = 3;
  static const double _playerSpriteTileScale = 2.3;
  static const double _obstacleSpriteTileScale = 1.8;
  static const double _collectableSpriteTileScale = 1.8;
  static const double _goalSpriteTileScale = 1.8;
  static const List<String> _difficultyOptions = <String>[
    'easy',
    'medium',
    'hard',
  ];
  static const StrutStyle _editorStrutStyle = StrutStyle(
    fontFamily: 'monospace',
    fontSize: _editorFontSize,
    height: _editorLineHeight,
    forceStrutHeight: true,
  );

  final Map<_Cell, _BoardItemType> _items = <_Cell, _BoardItemType>{};
  final Map<_Cell, String> _obstacleStylesByCell = <_Cell, String>{};
  final Map<_Cell, String> _collectableStylesByCell = <_Cell, String>{};
  final Map<_Cell, String> _goalStylesByCell = <_Cell, String>{};
  final Map<_Cell, String> _customAssetIdsByCell = <_Cell, String>{};
  final Map<_Cell, int> _scoresByCell = <_Cell, int>{};
  final Map<String, Uint8List> _customAssetImageBytes = <String, Uint8List>{};
  final Map<String, Future<void>> _customAssetImageLoads =
      <String, Future<void>>{};
  final List<CustomAssetData> _customAssets = <CustomAssetData>[];
  List<CustomAssetData> _savedAssetLibrary = const <CustomAssetData>[];
  List<CustomAssetData> _favoriteAssetLibrary = const <CustomAssetData>[];
  final List<_CodeBlock> _allowedBlocks = <_CodeBlock>[];
  late final TextEditingController _titleController;
  late final TextEditingController _instructionController;
  late final TextEditingController _codeController;
  late final ScrollController _codeScrollController;
  late final ScrollController _lineNumberScrollController;
  late final FocusNode _codeFocusNode;
  late final TopViewBuilderGame _topViewGame;

  bool _rulerActive = false;
  bool _isBoardItemDragging = false;
  bool _isSolutionTrayBlockDragging = false;
  bool _isRunningCode = false;
  bool _hasSavedCourseProgress = false;
  bool _isSavingCourseProgress = false;
  bool _isLoadingProject = false;
  bool _isSavingProject = false;
  bool _useAnglesInGeneratedTurns = false;
  double _initialPlayerHeadingDegrees = 0;
  String? _savedProjectId;
  String _courseId = '';
  int _orderInCourse = 0;
  String _difficulty = 'medium';
  String _status = 'draft';
  String _playerCharacterId = defaultTopViewCharacterId;
  String _backgroundId = defaultTopViewBackgroundId;
  String _obstacleStyleId = defaultTopViewObstacleStyleId;
  String _collectableStyleId = defaultTopViewCollectableStyleId;
  String _goalStyleId = defaultTopViewGoalStyleId;
  String? _customBackgroundAssetId;
  String? _loadedPossibleSolutionCode;
  int _runGeneration = 0;
  int? _activeCodeLine;
  _Cell? _rulerStart;
  _PlayerPreviewData? _playerPreview;
  late final ValueNotifier<_RulerOverlayData> _rulerOverlay;
  Timer? _titleSaveDebounce;
  Timer? _hintPulseTimer;
  String? _lastAutoSavedTitle;
  bool _hintGlowOn = true;
  bool _hasShownInstructionDialog = false;
  String? _pendingHintBlockId;

  void _syncTopViewGame({bool resetPlayer = false}) {
    final playerCell = _playerCell;
    _topViewGame.syncBoard(
      items: _items.entries.map((entry) {
        final customAssetId = _customAssetIdsByCell[entry.key];
        final customAsset = _customAssetById(customAssetId);
        return TopViewRenderItem(
          type: entry.value.id,
          cell: TopViewRenderCell(column: entry.key.column, row: entry.key.row),
          obstacleStyleId: entry.value == _BoardItemType.obstacle
              ? _obstacleStylesByCell[entry.key]
              : null,
          collectableStyleId: entry.value == _BoardItemType.collectable
              ? _collectableStylesByCell[entry.key]
              : null,
          goalStyleId: entry.value == _BoardItemType.goal
              ? _goalStylesByCell[entry.key]
              : null,
          customAssetId: customAssetId,
          customAssetFrameScale: customAsset?.frameScale ?? 1,
          customAssetFrameOffsetX: customAsset?.frameOffsetX ?? 0,
          customAssetFrameOffsetY: customAsset?.frameOffsetY ?? 0,
        );
      }).toList(),
      playerCell: playerCell == null
          ? null
          : TopViewRenderCell(column: playerCell.column, row: playerCell.row),
      playerCharacterId: _playerCharacterId,
      backgroundId: _backgroundId,
      obstacleStyleId: _obstacleStyleId,
      collectableStyleId: _collectableStyleId,
      goalStyleId: _goalStyleId,
      playerHeadingDegrees: _initialPlayerHeadingDegrees,
      customBackgroundAssetId: _customBackgroundAssetId,
      customBackgroundFrameScale:
          _customAssetById(_customBackgroundAssetId)?.frameScale ?? 1,
      customBackgroundFrameOffsetX:
          _customAssetById(_customBackgroundAssetId)?.frameOffsetX ?? 0,
      customBackgroundFrameOffsetY:
          _customAssetById(_customBackgroundAssetId)?.frameOffsetY ?? 0,
      customAssetImages: _customAssetImageBytes,
    );

    if (resetPlayer) {
      _topViewGame.resetPlayerToCell(
        playerCell == null
            ? null
            : TopViewRenderCell(column: playerCell.column, row: playerCell.row),
        _initialPlayerHeadingDegrees,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: AppLanguage.instance.t('builder.newLevel'),
    );
    _instructionController = TextEditingController();
    _codeController = TextEditingController();
    _codeScrollController = ScrollController()..addListener(_handleCodeScroll);
    _lineNumberScrollController = ScrollController();
    _codeFocusNode = FocusNode();
    _topViewGame = TopViewBuilderGame(
      columns: _cols,
      rows: _rows,
      playerSpriteTileScale: _playerSpriteTileScale,
      obstacleSpriteTileScale: _obstacleSpriteTileScale,
      collectableSpriteTileScale: _collectableSpriteTileScale,
      goalSpriteTileScale: _goalSpriteTileScale,
      runTilesPerSecond: _runTilesPerSecond,
    );
    _rulerOverlay = ValueNotifier<_RulerOverlayData>(const _RulerOverlayData());
    _hintPulseTimer = Timer.periodic(const Duration(milliseconds: 820), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hintGlowOn = !_hintGlowOn;
      });
    });
    _courseId = widget.initialCourseId ?? '';
    _orderInCourse = widget.initialOrderInCourse ?? 0;
    _difficulty = widget.initialDifficulty;
    _codeController.addListener(_handleCodeChanged);
    _titleController.addListener(_handleTitleChanged);
    _syncTopViewGame(resetPlayer: true);
    unawaited(_loadSavedAssetLibrary());
    if (widget.initialProjectId != null) {
      _loadProject(widget.initialProjectId!);
    }
  }

  @override
  void dispose() {
    _titleSaveDebounce?.cancel();
    _codeController.removeListener(_handleCodeChanged);
    _titleController.removeListener(_handleTitleChanged);
    _titleController.dispose();
    _instructionController.dispose();
    _codeController.dispose();
    _codeScrollController
      ..removeListener(_handleCodeScroll)
      ..dispose();
    _lineNumberScrollController.dispose();
    _codeFocusNode.dispose();
    _rulerOverlay.dispose();
    _hintPulseTimer?.cancel();
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
    if (_pendingHintBlockId == block.id && mounted) {
      setState(() {
        _pendingHintBlockId = null;
      });
    }
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

  void _handleTitleChanged() {
    if (widget.playMode) {
      return;
    }

    _titleSaveDebounce?.cancel();
    _titleSaveDebounce = Timer(const Duration(milliseconds: 700), () {
      _autoSaveTitle();
    });
  }

  Future<void> _autoSaveTitle() async {
    final normalizedTitle = _titleController.text.trim().isEmpty
        ? 'New Level'
        : _titleController.text.trim();
    if (_lastAutoSavedTitle == normalizedTitle || _isSavingProject) {
      return;
    }

    _lastAutoSavedTitle = normalizedTitle;
    await _persistProject(status: _status, showFeedback: false);
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
              degrees: angle,
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
        final amount = parts.length > 1 ? double.tryParse(parts[1]) ?? 1 : 1.0;
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
    final collectableCells = _collectableCells;
    final collectedCells = <_Cell>{};
    final goalCell = _goalCell;

    _runGeneration = generation;
    _codeFocusNode.unfocus();
    _topViewGame.resetPlayerToCell(
      TopViewRenderCell(column: playerCell.column, row: playerCell.row),
      headingDegrees,
    );
    _collectAtPosition(position, collectableCells, collectedCells);
    _collectVisibleAtPosition(position, collectableCells);
    if (goalCell != null && _positionMatchesCell(position, goalCell)) {
      _topViewGame.openGoalChest();
    }
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
        _topViewGame.face(headingDegrees);
        _playerPreview = _PlayerPreviewData(
          position: position,
          headingDegrees: headingDegrees,
          path: List<Offset>.from(path),
        );
        continue;
      }

      final direction = _tileStepDirection(headingDegrees);
      var hitBounds = false;
      final targetPosition = _snapToNearbyTileCenter(
        position + direction * step.value,
      );

      if (!_isPlayerPositionInBounds(targetPosition)) {
        hitBounds = true;
      } else {
        await _topViewGame.movePlayerTo(targetPosition);
        if (!mounted || generation != _runGeneration) {
          return;
        }
        position = targetPosition;
        path.add(position);
        _collectAtPosition(position, collectableCells, collectedCells);
        _collectVisibleAtPosition(position, collectableCells);
        if (goalCell != null && _positionMatchesCell(position, goalCell)) {
          _topViewGame.openGoalChest();
        }
        _playerPreview = _PlayerPreviewData(
          position: position,
          headingDegrees: headingDegrees,
          path: List<Offset>.from(path),
        );
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
    if (widget.playMode) {
      final success =
          goalCell != null && _positionMatchesCell(position, goalCell);
      final scoreResult = _buildTopViewScoreResult(
        success: success,
        collectedCells: collectedCells,
        goalCell: goalCell,
      );
      await _showTopViewResultDialog(scoreResult);
    }
  }

  Future<void> _showTopViewResultDialog(LevelScoreResult result) async {
    if (result.success) {
      await _saveCourseProgress(result);
    }
    if (!mounted) {
      return;
    }

    final nextLevel = result.success
        ? await loadNextCourseBuilderLevel(
            session: widget.session,
            courseId: widget.courseProgressCourseId,
            currentLevelId: widget.courseProgressLevelId ?? _savedProjectId,
          )
        : null;
    if (!mounted) {
      return;
    }

    await showLevelResultDialog(
      context: context,
      success: result.success,
      score: result.score,
      totalScore: result.totalScore,
      stars: result.stars,
      onPlayAgain: _resetRunState,
      onNextLevel: nextLevel == null
          ? null
          : () => openCourseBuilderLevel(
              context: context,
              session: widget.session,
              courseId: widget.courseProgressCourseId!,
              level: nextLevel,
              replace: true,
            ),
    );
  }

  Future<void> _saveCourseProgress(LevelScoreResult result) async {
    if (_isSavingCourseProgress) {
      return;
    }
    final courseId = widget.courseProgressCourseId;
    final levelId = widget.courseProgressLevelId ?? _savedProjectId;
    if (courseId == null ||
        courseId.isEmpty ||
        levelId == null ||
        levelId.isEmpty) {
      return;
    }
    _isSavingCourseProgress = true;
    final apiResult = await ApiService.completePublicCourseLevel(
      authToken: widget.session.token,
      courseId: courseId,
      levelId: levelId,
      score: result.score,
      totalScore: result.totalScore,
      stars: result.stars,
    );
    _isSavingCourseProgress = false;
    if (apiResult['success'] != true) {
      return;
    } else if (mounted) {
      setState(() {
        _hasSavedCourseProgress = true;
      });
    }
  }

  bool _isPlayerPositionInBounds(Offset position) {
    return position.dx >= 0.5 &&
        position.dx <= _cols - 0.5 &&
        position.dy >= 0.5 &&
        position.dy <= _rows - 0.5;
  }

  void _stopCodeRun() {
    _runGeneration += 1;
    _syncTopViewGame(resetPlayer: true);
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

    final suggestedDifficulty = _difficultyForScore(
      _calculateDifficultyScore(),
    );
    final selectedDifficulty = await _showDifficultyPickerDialog(
      suggestedDifficulty: suggestedDifficulty,
    );
    if (!mounted || selectedDifficulty == null) {
      return;
    }

    _difficulty = selectedDifficulty;
    await _persistProject(status: 'published');
  }

  Future<void> _persistProject({
    required String status,
    bool showFeedback = true,
  }) async {
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
        _status = status;
        _loadedPossibleSolutionCode = _codeController.text;
        if (showFeedback) {
          _showSnackBar(
            status == 'published'
                ? AppLanguage.instance.t('builder.topViewPublishedSuccessfully')
                : AppLanguage.instance.t('builder.topViewSavedSuccessfully'),
            backgroundColor: Colors.green.shade600,
          );
        }
      } else {
        final errors = response['errors'];
        final message = errors is List && errors.isNotEmpty
            ? errors.join('\n')
            : response['message']?.toString() ??
                  AppLanguage.instance.t('builder.saveFailedGeneric');
        if (showFeedback) {
          _showSnackBar(message, backgroundColor: Colors.red.shade600);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (showFeedback) {
        _showSnackBar(
          AppLanguage.instance.t(
            'builder.saveFailed',
            params: {'error': e.toString()},
          ),
          backgroundColor: Colors.red.shade600,
        );
      }
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
          response['message']?.toString() ??
              AppLanguage.instance.t('builder.loadTopViewFailedGeneric'),
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
      _showSnackBar(
        AppLanguage.instance.t(
          'builder.loadFailed',
          params: {'error': e.toString()},
        ),
        backgroundColor: Colors.red.shade600,
      );
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
    final obstacleStylesByCell = <_Cell, String>{};
    final collectableStylesByCell = <_Cell, String>{};
    final goalStylesByCell = <_Cell, String>{};
    final customAssetIdsByCell = <_Cell, String>{};
    final scoresByCell = <_Cell, int>{};
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
        final cell = _Cell(column: column, row: row);
        items[cell] = type;
        if (type == _BoardItemType.obstacle) {
          obstacleStylesByCell[cell] = topViewObstacleStyleById(
            itemMap['obstacleStyle']?.toString() ??
                draftData['obstacleStyle']?.toString(),
          ).id;
        } else if (type == _BoardItemType.collectable) {
          collectableStylesByCell[cell] = topViewCollectableStyleById(
            itemMap['collectableStyle']?.toString() ??
                itemMap['item']?.toString() ??
                draftData['collectableStyle']?.toString(),
          ).id;
          scoresByCell[cell] = readScoreValue(
            itemMap['score'],
            fallback: defaultCollectableScore,
          );
        } else if (type == _BoardItemType.goal) {
          goalStylesByCell[cell] = topViewGoalStyleById(
            itemMap['goalStyle']?.toString() ??
                draftData['goalStyle']?.toString(),
          ).id;
          scoresByCell[cell] = readScoreValue(
            itemMap['score'],
            fallback: defaultGoalScore,
          );
        }
        final customAssetId = itemMap['customAssetId']?.toString();
        if (customAssetId != null && customAssetId.isNotEmpty) {
          customAssetIdsByCell[cell] = customAssetId;
        }
      }
    }

    final customAssets = <CustomAssetData>[];
    final rawCustomAssets = draftData['customAssets'];
    if (rawCustomAssets is List) {
      for (final rawAsset in rawCustomAssets.whereType<Map>()) {
        final asset = CustomAssetData.fromJson(
          Map<String, dynamic>.from(rawAsset),
        );
        if (asset.id.isNotEmpty &&
            (asset.hasEmbeddedImage || asset.hasUploadedAsset)) {
          customAssets.add(asset);
        }
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
      _status =
          data['status']?.toString() ??
          draftData['status']?.toString() ??
          _status;
      _playerCharacterId = topViewCharacterById(
        draftData['playerCharacter']?.toString(),
      ).id;
      _backgroundId = topViewBackgroundById(
        draftData['background']?.toString(),
      ).id;
      _customBackgroundAssetId = draftData['customBackgroundAssetId']
          ?.toString();
      _obstacleStyleId = topViewObstacleStyleById(
        draftData['obstacleStyle']?.toString(),
      ).id;
      _collectableStyleId = topViewCollectableStyleById(
        draftData['collectableStyle']?.toString(),
      ).id;
      _goalStyleId = topViewGoalStyleById(
        draftData['goalStyle']?.toString(),
      ).id;
      _titleController.text =
          data['title']?.toString() ??
          draftData['title']?.toString() ??
          widget.initialTitle ??
          AppLanguage.instance.t('builder.newLevel');
      _items
        ..clear()
        ..addAll(items);
      _obstacleStylesByCell
        ..clear()
        ..addAll(obstacleStylesByCell);
      _collectableStylesByCell
        ..clear()
        ..addAll(collectableStylesByCell);
      _goalStylesByCell
        ..clear()
        ..addAll(goalStylesByCell);
      _customAssetIdsByCell
        ..clear()
        ..addAll(customAssetIdsByCell);
      _scoresByCell
        ..clear()
        ..addAll(scoresByCell);
      _customAssets
        ..clear()
        ..addAll(customAssets);
      _customAssetImageBytes.clear();
      for (final asset in _customAssets) {
        if (asset.hasEmbeddedImage) {
          _customAssetImageBytes[asset.id] = asset.imageBytes;
        } else {
          unawaited(_ensureAssetImageLoaded(asset));
        }
      }
      _allowedBlocks
        ..clear()
        ..addAll(allowedBlocks);
      _initialPlayerHeadingDegrees =
          (_readDouble(draftData['initialDirectionDegrees']) ?? 0) % 360;
      _loadedPossibleSolutionCode = draftData['solutionCode']?.toString() ?? '';
      _instructionController.text =
          data['description']?.toString() ??
          draftData['description']?.toString() ??
          '';
      _pendingHintBlockId = null;
      _codeController.text = widget.playMode
          ? ''
          : (_loadedPossibleSolutionCode ?? '');
      _playerPreview = null;
      _activeCodeLine = null;
    });
    _syncTopViewGame(resetPlayer: true);
    _maybeShowInstructionDialog();
  }

  Map<String, dynamic> _buildProjectJson({required String status}) {
    return {
      'builderType': 'topView',
      'title': _titleController.text.trim().isEmpty
          ? AppLanguage.instance.t('builder.newLevel')
          : _titleController.text.trim(),
      'description': _instructionController.text.trim(),
      'status': status,
      'courseId': _courseId,
      'orderInCourse': _orderInCourse,
      'difficulty': _difficulty,
      'playerCharacter': _playerCharacterId,
      'background': _backgroundId,
      'customBackgroundAssetId': _customBackgroundAssetId,
      'obstacleStyle': _obstacleStyleId,
      'collectableStyle': _collectableStyleId,
      'goalStyle': _goalStyleId,
      'settings': {'columns': _cols, 'rows': _rows},
      'items': _items.entries
          .map(
            (entry) => {
              'type': entry.value.id,
              'column': entry.key.column,
              'row': entry.key.row,
              if (entry.value == _BoardItemType.obstacle)
                'obstacleStyle':
                    _obstacleStylesByCell[entry.key] ?? _obstacleStyleId,
              if (entry.value == _BoardItemType.collectable)
                'collectableStyle':
                    _collectableStylesByCell[entry.key] ?? _collectableStyleId,
              if (entry.value == _BoardItemType.goal)
                'goalStyle': _goalStylesByCell[entry.key] ?? _goalStyleId,
              if (entry.value == _BoardItemType.collectable ||
                  entry.value == _BoardItemType.goal)
                'score': _scoreForCell(entry.key, entry.value),
              if (_customAssetIdsByCell[entry.key] != null)
                'customAssetId': _customAssetIdsByCell[entry.key],
              if (_customAssetIdsByCell[entry.key] != null &&
                  _customAssetById(_customAssetIdsByCell[entry.key])?.assetId !=
                      null)
                'uploadedAssetId': _customAssetById(
                  _customAssetIdsByCell[entry.key],
                )!.assetId,
            },
          )
          .toList(),
      'customAssets': _customAssets.map((asset) => asset.toJson()).toList(),
      'allowedBlocks': _allowedBlocks.map((block) => block.id).toList(),
      'solutionCode': _codeController.text,
      'initialDirectionDegrees': _initialPlayerHeadingDegrees,
    };
  }

  int _calculateDifficultyScore() {
    final solutionScore = _scoreTopViewSolutionCode(_codeController.text);
    final obstacleScore = _items.values
        .where((item) => item == _BoardItemType.obstacle)
        .length;
    final collectableScore = _items.values
        .where((item) => item == _BoardItemType.collectable)
        .length;

    return solutionScore + obstacleScore + collectableScore;
  }

  int _scoreTopViewSolutionCode(String code) {
    var score = 0;
    final lines = code.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim().toLowerCase();
      if (line.isEmpty) {
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      final command = parts.first;

      if (command == 'step') {
        score += 1;
        continue;
      }

      if (command == 'turn') {
        if (parts.length > 1 && double.tryParse(parts[1]) != null) {
          score += 3;
        } else {
          score += 2;
        }
        continue;
      }

      if (_screenDirectionDegrees(command) != null) {
        score += 2;
      }
    }

    return score;
  }

  String _difficultyForScore(int score) {
    if (score <= 10) {
      return 'easy';
    }

    if (score <= 20) {
      return 'medium';
    }

    return 'hard';
  }

  Future<String?> _showDifficultyPickerDialog({
    required String suggestedDifficulty,
  }) {
    var selectedDifficulty = suggestedDifficulty;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                AppLanguage.of(context).t('builder.chooseDifficulty'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: AppLanguage.of(
                              context,
                            ).t('builder.suggested'),
                          ),
                          TextSpan(
                            text: _difficultyLabel(suggestedDifficulty),
                            style: TextStyle(
                              color: _difficultyColor(suggestedDifficulty),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final difficulty in _difficultyOptions) ...[
                        if (difficulty != _difficultyOptions.first)
                          const SizedBox(width: 8),
                        _buildDifficultyOption(
                          difficulty: difficulty,
                          isSelected: selectedDifficulty == difficulty,
                          onSelected: () {
                            setDialogState(() {
                              selectedDifficulty = difficulty;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLanguage.of(context).t('builder.cancel')),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedDifficulty),
                  child: Text(AppLanguage.of(context).t('builder.publish')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDifficultyOption({
    required String difficulty,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final color = _difficultyColor(difficulty);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _difficultyLabel(difficulty),
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _difficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppLanguage.instance.t('builder.easy');
      case 'hard':
        return AppLanguage.instance.t('builder.hard');
      case 'medium':
      default:
        return AppLanguage.instance.t('builder.medium');
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green.shade700;
      case 'hard':
        return Colors.red.shade700;
      case 'medium':
      default:
        return Colors.amber.shade800;
    }
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

  void _maybeShowInstructionDialog() {
    if (!widget.playMode || _hasShownInstructionDialog) {
      return;
    }

    final message = _instructionController.text.trim();
    if (message.isEmpty) {
      return;
    }

    _hasShownInstructionDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showInstructionDialog();
    });
  }

  Future<void> _showInstructionDialog() async {
    final message = _instructionController.text.trim();
    if (message.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF2),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE6D8A8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE3F2FF),
                      child: ClipOval(
                        child: _buildInstructionCharacterAvatar(size: 48),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'How to play',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF3A241D),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7E5D4)),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF66B64A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionCharacterAvatar({double size = 48}) {
    final character = topViewCharacterById(_playerCharacterId);
    return Image.asset(
      character.stillAssetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.support_agent_rounded, size: size * 0.7);
      },
    );
  }

  List<String> _solutionBlockSequenceFromCode(String code) {
    final tokens = <String>[];
    for (final rawLine in code.split('\n')) {
      final line = rawLine.trim().toLowerCase();
      if (line.isEmpty) {
        continue;
      }
      final parts = line.split(RegExp(r'\s+'));
      final command = parts.first;
      if (command == 'turn') {
        tokens.add('turn');
        if (parts.length > 1 && double.tryParse(parts[1]) == null) {
          tokens.add(parts[1]);
        }
        continue;
      }
      if (command == 'step') {
        tokens.add('step');
        continue;
      }
      if (_screenDirectionDegrees(command) != null) {
        tokens.add(command);
      }
    }
    return tokens;
  }

  String? _nextTopViewHintBlockId() {
    final expected = _solutionBlockSequenceFromCode(
      _loadedPossibleSolutionCode ?? '',
    );
    if (expected.isEmpty) {
      return null;
    }
    final current = _solutionBlockSequenceFromCode(_codeController.text);
    var index = 0;
    while (index < expected.length &&
        index < current.length &&
        expected[index] == current[index]) {
      index += 1;
    }
    return index < expected.length ? expected[index] : null;
  }

  void _requestTopViewHint() {
    final nextHint = _nextTopViewHintBlockId();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingHintBlockId = nextHint;
    });
  }

  String? _validatePublishableLevel() {
    final playerCell = _playerCell;
    if (playerCell == null) {
      return AppLanguage.instance.t('builder.validation.addPlayer');
    }

    final goalCell = _goalCell;
    if (goalCell == null) {
      return AppLanguage.instance.t('builder.validation.addGoal');
    }

    if (_allowedBlocks.isEmpty) {
      return AppLanguage.instance.t('builder.validation.addSolutionBlocks');
    }

    final steps = _parseCodeSteps();
    if (steps.isEmpty) {
      return AppLanguage.instance.t('builder.validation.writeSolution');
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

  int _scoreForCell(_Cell cell, _BoardItemType type) {
    return readScoreValue(
      _scoresByCell[cell],
      fallback: type == _BoardItemType.goal
          ? defaultGoalScore
          : defaultCollectableScore,
    );
  }

  int get _totalLevelScore {
    var total = 0;
    for (final entry in _items.entries) {
      if (entry.value == _BoardItemType.collectable ||
          entry.value == _BoardItemType.goal) {
        total += _scoreForCell(entry.key, entry.value);
      }
    }
    return total;
  }

  int _collectableScoreFor(Set<_Cell> collectedCells) {
    var score = 0;
    for (final cell in collectedCells) {
      if (_items[cell] == _BoardItemType.collectable) {
        score += _scoreForCell(cell, _BoardItemType.collectable);
      }
    }
    return score;
  }

  LevelScoreResult _buildTopViewScoreResult({
    required bool success,
    required Set<_Cell> collectedCells,
    required _Cell? goalCell,
  }) {
    final goalScore = success && goalCell != null
        ? _scoreForCell(goalCell, _BoardItemType.goal)
        : 0;
    final score = _collectableScoreFor(collectedCells) + goalScore;
    final totalScore = _totalLevelScore;
    return LevelScoreResult(
      success: success,
      score: score,
      totalScore: totalScore,
      stars: starsForScore(score: score, totalScore: totalScore),
    );
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

      final direction = _tileStepDirection(headingDegrees);
      final stepDirection = step.value < 0 ? -1.0 : 1.0;
      var remainingTiles = step.value.abs();

      while (remainingTiles > 0) {
        final tileDistance = math.min(1.0, remainingTiles);
        position = _snapToNearbyTileCenter(
          position + direction * (tileDistance * stepDirection),
        );

        if (!_isPlayerPositionInBounds(position)) {
          return _TopViewSolutionResult(
            success: false,
            message: AppLanguage.instance.t(
              'builder.validation.solutionOutOfBounds',
            ),
          );
        }

        _collectAtPosition(position, collectableCells, collected);
        remainingTiles -= tileDistance;
      }
    }

    if (collected.length != collectableCells.length) {
      return _TopViewSolutionResult(
        success: false,
        message: AppLanguage.instance.t(
          'builder.validation.solutionCollectAll',
        ),
      );
    }

    if (!_positionMatchesCell(position, goalCell)) {
      return _TopViewSolutionResult(
        success: false,
        message: AppLanguage.instance.t('builder.validation.solutionOnGoal'),
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

  void _collectVisibleAtPosition(
    Offset position,
    List<_Cell> collectableCells,
  ) {
    for (final cell in collectableCells) {
      if (_positionMatchesCell(position, cell)) {
        _topViewGame.collectAtCell(cell.column, cell.row);
      }
    }
  }

  bool _positionMatchesCell(Offset position, _Cell cell) {
    return (position.dx - (cell.column + 0.5)).abs() < 0.001 &&
        (position.dy - (cell.row + 0.5)).abs() < 0.001;
  }

  Offset _tileStepDirection(double headingDegrees) {
    final rawDirection = Offset(
      math.cos(_degreesToRadians(headingDegrees)),
      -math.sin(_degreesToRadians(headingDegrees)),
    );
    final dominantAxisDistance = math.max(
      rawDirection.dx.abs(),
      rawDirection.dy.abs(),
    );

    if (dominantAxisDistance == 0) {
      return Offset.zero;
    }

    return rawDirection / dominantAxisDistance;
  }

  Offset _snapToNearbyTileCenter(Offset position) {
    return Offset(
      _snapAxisToNearbyTileCenter(position.dx, maxCellIndex: _cols - 1),
      _snapAxisToNearbyTileCenter(position.dy, maxCellIndex: _rows - 1),
    );
  }

  double _snapAxisToNearbyTileCenter(
    double value, {
    required int maxCellIndex,
  }) {
    const snapTolerance = 0.28;
    final nearestCellIndex = (value - 0.5).round().clamp(0, maxCellIndex);
    final nearestCenter = nearestCellIndex + 0.5;

    if ((value - nearestCenter).abs() <= snapTolerance) {
      return nearestCenter;
    }

    return value;
  }

  CustomAssetData? _customAssetById(String? assetId) {
    if (assetId == null || assetId.isEmpty) {
      return null;
    }
    for (final asset in _customAssets) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return null;
  }

  CustomAssetData? _customAssetByUploadedAssetId(String? uploadedAssetId) {
    if (uploadedAssetId == null || uploadedAssetId.isEmpty) {
      return null;
    }
    for (final asset in _customAssets) {
      if (asset.assetId == uploadedAssetId) {
        return asset;
      }
    }
    return null;
  }

  List<CustomAssetData> get _createdCustomAssets {
    final projectAssetIds = _customAssets
        .map((asset) => asset.assetId)
        .whereType<String>()
        .toSet();

    return _dedupeCustomAssets([
      ..._customAssets.where((asset) => asset.isCreatedByUser),
      ..._savedAssetLibrary.where(
        (asset) =>
            asset.isCreatedByUser && !projectAssetIds.contains(asset.assetId),
      ),
      ..._favoriteAssetLibrary.where(
        (asset) =>
            asset.isCreatedByUser && !projectAssetIds.contains(asset.assetId),
      ),
    ]);
  }

  List<CustomAssetData> get _favoriteCustomAssets {
    final projectAssetIds = _customAssets
        .map((asset) => asset.assetId)
        .whereType<String>()
        .toSet();

    return _dedupeCustomAssets([
      ..._customAssets.where(
        (asset) =>
            asset.assetId != null &&
            _favoriteAssetLibrary.any(
              (favorite) => favorite.assetId == asset.assetId,
            ),
      ),
      ..._favoriteAssetLibrary.where(
        (asset) => !projectAssetIds.contains(asset.assetId),
      ),
    ]);
  }

  List<CustomAssetData> _dedupeCustomAssets(List<CustomAssetData> assets) {
    final byUploadedId = <String, CustomAssetData>{};
    final withoutUploadedId = <CustomAssetData>[];

    for (final asset in assets) {
      final uploadedAssetId = asset.assetId;
      if (uploadedAssetId == null || uploadedAssetId.isEmpty) {
        withoutUploadedId.add(asset);
        continue;
      }
      byUploadedId.putIfAbsent(uploadedAssetId, () => asset);
    }

    return [...byUploadedId.values, ...withoutUploadedId];
  }

  Uint8List? _assetImageBytes(CustomAssetData asset) {
    final cached = _customAssetImageBytes[asset.id];
    if (cached != null) {
      return cached;
    }
    if (asset.hasEmbeddedImage) {
      final bytes = asset.imageBytes;
      _customAssetImageBytes[asset.id] = bytes;
      return bytes;
    }
    return null;
  }

  Future<void> _ensureAssetImageLoaded(CustomAssetData asset) {
    if (_assetImageBytes(asset) != null) {
      return Future.value();
    }
    final uploadedAssetId = asset.assetId;
    if (uploadedAssetId == null || uploadedAssetId.isEmpty) {
      return Future.value();
    }
    final existingLoad = _customAssetImageLoads[asset.id];
    if (existingLoad != null) {
      return existingLoad;
    }
    final load =
        ApiService.getBuilderAssetData(
              authToken: widget.session.token,
              assetId: uploadedAssetId,
            )
            .then((bytes) {
              if (bytes == null || bytes.isEmpty) {
                return;
              }
              _customAssetImageBytes[asset.id] = bytes;
              if (mounted) {
                setState(() {});
                _syncTopViewGame();
              }
            })
            .whenComplete(() {
              _customAssetImageLoads.remove(asset.id);
            });
    _customAssetImageLoads[asset.id] = load;
    return load;
  }

  Future<void> _loadSavedAssetLibrary() async {
    final response = await ApiService.getBuilderAssets(
      authToken: widget.session.token,
    );
    if (response['success'] != true || response['data'] is! List) {
      return;
    }

    final assets = <CustomAssetData>[];
    for (final rawAsset in (response['data'] as List).whereType<Map>()) {
      final asset = _customAssetFromApiJson(
        rawAsset,
        idPrefix: 'saved',
        fallbackCreatedByUser: true,
      );
      if (asset != null) {
        assets.add(asset);
      }
    }
    final favoriteAssets = await _loadFavoriteAssetLibrary();

    if (!mounted) {
      return;
    }

    setState(() {
      _savedAssetLibrary = assets;
      _favoriteAssetLibrary = favoriteAssets;
    });
    for (final asset in [...assets, ...favoriteAssets]) {
      unawaited(_ensureAssetImageLoaded(asset));
    }
  }

  Future<List<CustomAssetData>> _loadFavoriteAssetLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteAssetIds =
        prefs
            .getStringList(
              'dashboard.discoverFavorites.${widget.session.user.id}.assets',
            )
            ?.toSet() ??
        <String>{};
    if (favoriteAssetIds.isEmpty) {
      return const <CustomAssetData>[];
    }

    final response = await ApiService.getPublishedBuilderAssets(
      authToken: widget.session.token,
    );
    final data = response['data'];
    if (response['success'] != true || data is! List) {
      return const <CustomAssetData>[];
    }

    return data
        .whereType<Map>()
        .map(
          (assetJson) => _customAssetFromApiJson(
            assetJson,
            idPrefix: 'favorite',
            fallbackCreatedByUser: false,
          ),
        )
        .whereType<CustomAssetData>()
        .where((asset) => favoriteAssetIds.contains(asset.assetId))
        .toList();
  }

  CustomAssetData? _customAssetFromApiJson(
    Map<dynamic, dynamic> assetJson, {
    required String idPrefix,
    required bool fallbackCreatedByUser,
  }) {
    final assetId = (assetJson['_id'] ?? assetJson['id'])?.toString();
    if (assetId == null || assetId.isEmpty) {
      return null;
    }

    return CustomAssetData(
      id: '$idPrefix-$assetId',
      assetId: assetId,
      name: assetJson['name']?.toString() ?? 'Untitled asset',
      type: CustomAssetTypeExtension.fromString(assetJson['type']?.toString()),
      mimeType: assetJson['mimeType']?.toString() ?? 'image/png',
      isCreatedByUser:
          assetJson['ownerId']?.toString() == widget.session.user.id ||
          fallbackCreatedByUser,
      isPublic: assetJson['isPublic'] == true,
    );
  }

  void _addCustomAssetToLevel(CustomAssetData asset, {Uint8List? bytes}) {
    final existingUploadedAsset = _customAssetByUploadedAssetId(asset.assetId);
    final assetToStore = existingUploadedAsset == null
        ? asset
        : asset.copyWith(id: existingUploadedAsset.id);

    setState(() {
      _customAssets
        ..removeWhere(
          (existing) =>
              existing.id == assetToStore.id ||
              (existing.assetId != null &&
                  existing.assetId == assetToStore.assetId &&
                  existing.id != assetToStore.id),
        )
        ..add(assetToStore);
      if (bytes != null) {
        _customAssetImageBytes[assetToStore.id] = bytes;
      }
    });
    _syncTopViewGame(resetPlayer: true);
  }

  void _useCustomAssetFromCollection(CustomAssetData asset) {
    final existingAsset =
        _customAssetById(asset.id) ??
        _customAssetByUploadedAssetId(asset.assetId);
    if (existingAsset != null) {
      return;
    }

    final levelAsset = asset.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageBase64: '',
    );
    _addCustomAssetToLevel(levelAsset, bytes: _assetImageBytes(asset));
  }

  void _updateCustomAssetSettings(CustomAssetData asset) {
    setState(() {
      final index = _customAssets.indexWhere((item) => item.id == asset.id);
      if (index >= 0) {
        _customAssets[index] = asset;
      }
    });
    _syncTopViewGame(resetPlayer: true);
  }

  void _removeCustomAssetFromLevel(String assetId) {
    setState(() {
      final cellsUsingAsset = _customAssetIdsByCell.entries
          .where((entry) => entry.value == assetId)
          .map((entry) => entry.key)
          .toList();
      _customAssets.removeWhere((asset) => asset.id == assetId);
      for (final cell in cellsUsingAsset) {
        _customAssetIdsByCell.remove(cell);
        _items.remove(cell);
        _scoresByCell.remove(cell);
      }
      if (_customBackgroundAssetId == assetId) {
        _customBackgroundAssetId = null;
      }
      _customAssetImageBytes.remove(assetId);
    });
    _syncTopViewGame(resetPlayer: true);
  }

  Future<void> _pickAndCreateCustomAsset() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (!mounted || file == null || bytes == null) {
      return;
    }
    if (bytes.length > 2 * 1024 * 1024) {
      _showSnackBar(
        'Image must be 2 MB or smaller.',
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final asset = await _showAssetEditorDialog(
      imageBytes: bytes,
      suggestedName: _nameWithoutExtension(file.name),
      mimeType: _mimeTypeForName(file.name),
    );
    if (asset == null) {
      return;
    }

    final uploadResult = await ApiService.uploadBuilderAsset(
      authToken: widget.session.token,
      name: asset.name,
      type: asset.type.value,
      mimeType: asset.mimeType,
      imageBase64: base64Encode(bytes),
      isPublic: asset.isPublic,
    );
    if (uploadResult['success'] != true) {
      _showSnackBar(
        uploadResult['message']?.toString() ?? 'Failed to upload asset.',
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final data = uploadResult['data'];
    final uploadedAssetId = data is Map
        ? (data['_id'] ?? data['id'])?.toString()
        : null;
    if (uploadedAssetId == null || uploadedAssetId.isEmpty) {
      return;
    }

    final storedAsset = asset.copyWith(
      assetId: uploadedAssetId,
      imageBase64: '',
    );
    _addCustomAssetToLevel(storedAsset, bytes: bytes);
  }

  Future<CustomAssetData?> _showAssetEditorDialog({
    CustomAssetData? existingAsset,
    Uint8List? imageBytes,
    String suggestedName = '',
    String mimeType = 'image/png',
  }) {
    final isEditing = existingAsset != null;
    final bytes =
        imageBytes ??
        (existingAsset == null ? null : _assetImageBytes(existingAsset));
    if (bytes == null) {
      return Future.value(null);
    }
    final nameController = TextEditingController(
      text: isEditing ? existingAsset.name : suggestedName,
    );
    var selectedType = existingAsset?.type ?? CustomAssetType.character;
    var frameScale =
        existingAsset?.frameScale ?? _defaultFrameScaleForType(selectedType);
    var frameOffsetX = existingAsset?.frameOffsetX ?? 0.0;
    var frameOffsetY = existingAsset?.frameOffsetY ?? 0.0;

    return showDialog<CustomAssetData>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewSize = _assetEditorPreviewSize(
              selectedType,
              MediaQuery.sizeOf(context),
            );

            return AlertDialog(
              title: Text(isEditing ? 'Asset settings' : 'Create asset'),
              content: SizedBox(
                width: math.min(MediaQuery.sizeOf(context).width * 0.82, 640),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: math.min(
                      MediaQuery.sizeOf(context).height * 0.78,
                      720,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox(
                            width: previewSize.width,
                            height: previewSize.height,
                            child: LayoutBuilder(
                              builder: (context, previewConstraints) {
                                final previewWidth =
                                    previewConstraints.maxWidth.isFinite
                                    ? previewConstraints.maxWidth
                                    : 1.0;
                                final previewHeight =
                                    previewConstraints.maxHeight.isFinite
                                    ? previewConstraints.maxHeight
                                    : 1.0;

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanUpdate: (details) {
                                    setDialogState(() {
                                      frameOffsetX =
                                          (frameOffsetX +
                                                  details.delta.dx /
                                                      (previewWidth * 0.5))
                                              .clamp(-1.0, 1.0)
                                              .toDouble();
                                      frameOffsetY =
                                          (frameOffsetY +
                                                  details.delta.dy /
                                                      (previewHeight * 0.5))
                                              .clamp(-1.0, 1.0)
                                              .toDouble();
                                    });
                                  },
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.move,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blueGrey.shade200,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _buildFramedImagePreview(
                                        bytes: bytes,
                                        scale: frameScale,
                                        offsetX: frameOffsetX,
                                        offsetY: frameOffsetY,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Drag the image to position it in the frame.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.blueGrey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: nameController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Asset name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<CustomAssetType>(
                          initialValue: selectedType,
                          isExpanded: true,
                          items: [
                            for (final type in CustomAssetType.values)
                              DropdownMenuItem<CustomAssetType>(
                                value: type,
                                child: Text(type.label),
                              ),
                          ],
                          onChanged: (type) {
                            if (type == null) {
                              return;
                            }

                            setDialogState(() {
                              selectedType = type;
                              frameScale = _defaultFrameScaleForType(type);
                              frameOffsetX = 0;
                              frameOffsetY = 0;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAssetSlider(
                          label: 'Zoom',
                          value: frameScale,
                          min: 0.5,
                          max: 3,
                          onChanged: (value) {
                            setDialogState(() => frameScale = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton.icon(
                    onPressed: () async {
                      final shouldRemove = await _confirmRemoveAssetFromLevel(
                        dialogContext,
                        existingAsset,
                      );
                      if (!shouldRemove || !dialogContext.mounted) {
                        return;
                      }

                      _removeCustomAssetFromLevel(existingAsset.id);
                      Navigator.of(dialogContext).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove from level'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      CustomAssetData(
                        id:
                            existingAsset?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        assetId: existingAsset?.assetId,
                        name: existingAsset?.name ?? name,
                        type: selectedType,
                        imageBase64:
                            existingAsset?.imageBase64 ?? base64Encode(bytes),
                        mimeType: existingAsset?.mimeType ?? mimeType,
                        isCreatedByUser: existingAsset?.isCreatedByUser ?? true,
                        isPublic: existingAsset?.isPublic ?? false,
                        frameScale: frameScale,
                        frameOffsetX: frameOffsetX,
                        frameOffsetY: frameOffsetY,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Save settings' : 'Save asset'),
                ),
              ],
            );
          },
        );
      },
    ).then((asset) {
      nameController.dispose();
      if (asset != null && isEditing) {
        _updateCustomAssetSettings(asset);
      }
      return asset;
    });
  }

  Future<bool> _confirmRemoveAssetFromLevel(
    BuildContext context,
    CustomAssetData asset,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (confirmContext) {
            return AlertDialog(
              title: const Text('Remove from level?'),
              content: Text(
                'This will remove "${asset.name}" from the current level only. It will stay in your assets.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(confirmContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(confirmContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  child: const Text('Remove from level'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildAssetSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _nameWithoutExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    return dotIndex <= 0 ? filename : filename.substring(0, dotIndex);
  }

  String _mimeTypeForName(String filename) {
    final lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/png';
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
        payload.kind == _PayloadKind.boardItem ||
        payload.kind == _PayloadKind.customAsset;
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
      case _PayloadKind.customAsset:
        if (payload.customAssetId != null) {
          _placeCustomAsset(payload.customAssetId!, target);
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
      final movedObstacleStyle = source == null
          ? null
          : _obstacleStylesByCell[source];
      final movedCollectableStyle = source == null
          ? null
          : _collectableStylesByCell[source];
      final movedGoalStyle = source == null ? null : _goalStylesByCell[source];
      final movedCustomAssetId = source == null
          ? null
          : _customAssetIdsByCell[source];
      final movedScore = source == null ? null : _scoresByCell[source];
      if (source != null) {
        _items.remove(source);
        _obstacleStylesByCell.remove(source);
        _collectableStylesByCell.remove(source);
        _goalStylesByCell.remove(source);
        _customAssetIdsByCell.remove(source);
        _scoresByCell.remove(source);
      }
      if (type == _BoardItemType.player || type == _BoardItemType.goal) {
        final removedCells = _items.entries
            .where((entry) => entry.value == type && entry.key != target)
            .map((entry) => entry.key)
            .toList();
        _items.removeWhere((cell, item) => item == type && cell != target);
        for (final cell in removedCells) {
          _obstacleStylesByCell.remove(cell);
          _collectableStylesByCell.remove(cell);
          _goalStylesByCell.remove(cell);
          _customAssetIdsByCell.remove(cell);
          _scoresByCell.remove(cell);
        }
      }
      _items[target] = type;
      if (movedCustomAssetId == null) {
        _customAssetIdsByCell.remove(target);
      } else {
        _customAssetIdsByCell[target] = movedCustomAssetId;
      }
      if (type == _BoardItemType.obstacle) {
        _obstacleStylesByCell[target] = movedObstacleStyle ?? _obstacleStyleId;
      } else {
        _obstacleStylesByCell.remove(target);
      }
      if (type == _BoardItemType.collectable) {
        _collectableStylesByCell[target] =
            movedCollectableStyle ?? _collectableStyleId;
        _scoresByCell[target] = movedScore ?? defaultCollectableScore;
      } else {
        _collectableStylesByCell.remove(target);
      }
      if (type == _BoardItemType.goal) {
        _goalStylesByCell[target] = movedGoalStyle ?? _goalStyleId;
        _scoresByCell[target] = movedScore ?? defaultGoalScore;
      } else {
        _goalStylesByCell.remove(target);
      }
      if (type != _BoardItemType.collectable && type != _BoardItemType.goal) {
        _scoresByCell.remove(target);
      }
    });
    _syncTopViewGame(resetPlayer: true);
    _stopCodeRun();
  }

  void _placeCustomAsset(String assetId, _Cell target) {
    final asset = _customAssetById(assetId);
    if (asset == null) {
      return;
    }
    if (asset.type == CustomAssetType.background) {
      setState(() {
        _customBackgroundAssetId = asset.id;
      });
      _syncTopViewGame(resetPlayer: true);
      return;
    }
    final type = switch (asset.type) {
      CustomAssetType.character => _BoardItemType.player,
      CustomAssetType.obstacle => _BoardItemType.obstacle,
      CustomAssetType.collectable => _BoardItemType.collectable,
      CustomAssetType.goal => _BoardItemType.goal,
      CustomAssetType.background => _BoardItemType.obstacle,
    };
    setState(() {
      if (type == _BoardItemType.player || type == _BoardItemType.goal) {
        final removedCells = _items.entries
            .where((entry) => entry.value == type && entry.key != target)
            .map((entry) => entry.key)
            .toList();
        _items.removeWhere((cell, item) => item == type && cell != target);
        for (final cell in removedCells) {
          _obstacleStylesByCell.remove(cell);
          _collectableStylesByCell.remove(cell);
          _goalStylesByCell.remove(cell);
          _customAssetIdsByCell.remove(cell);
          _scoresByCell.remove(cell);
        }
      }
      _items[target] = type;
      _customAssetIdsByCell[target] = asset.id;
      if (type == _BoardItemType.obstacle) {
        _obstacleStylesByCell[target] = _obstacleStyleId;
      } else {
        _obstacleStylesByCell.remove(target);
      }
      if (type == _BoardItemType.collectable) {
        _collectableStylesByCell[target] = _collectableStyleId;
        _scoresByCell[target] = defaultCollectableScore;
      } else {
        _collectableStylesByCell.remove(target);
      }
      if (type == _BoardItemType.goal) {
        _goalStylesByCell[target] = _goalStyleId;
        _scoresByCell[target] = defaultGoalScore;
      } else {
        _goalStylesByCell.remove(target);
      }
      if (type != _BoardItemType.collectable && type != _BoardItemType.goal) {
        _scoresByCell.remove(target);
      }
    });
    _syncTopViewGame(resetPlayer: true);
    _stopCodeRun();
  }

  void _deleteItem(_Cell cell) {
    final removed = _items[cell];
    if (removed == null) {
      return;
    }
    setState(() {
      _items.remove(cell);
      _obstacleStylesByCell.remove(cell);
      _collectableStylesByCell.remove(cell);
      _goalStylesByCell.remove(cell);
      _customAssetIdsByCell.remove(cell);
      _scoresByCell.remove(cell);
    });
    _syncTopViewGame(resetPlayer: true);
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
          title: Text(AppLanguage.of(context).t('builder.clearLevel')),
          content: Text(AppLanguage.of(context).t('builder.clearLevelBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLanguage.of(context).t('builder.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: Text(AppLanguage.of(context).t('builder.clear')),
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
      _obstacleStylesByCell.clear();
      _collectableStylesByCell.clear();
      _goalStylesByCell.clear();
      _customAssetIdsByCell.clear();
      _scoresByCell.clear();
      _customAssets.clear();
      _customAssetImageBytes.clear();
      _customBackgroundAssetId = null;
      _allowedBlocks.clear();
      _isRunningCode = false;
      _activeCodeLine = null;
      _rulerActive = false;
      _rulerStart = null;
      _playerPreview = null;
      _rulerOverlay.value = const _RulerOverlayData();
    });
    _syncTopViewGame(resetPlayer: true);
  }

  void _handlePrintSolutionPressed() {
    final playerCell = _playerCell;
    final goalCell = _goalCell;
    if (playerCell == null || goalCell == null) {
      debugPrint('No solution found');
      return;
    }

    final level = TopViewLevelGrid(
      columns: _cols,
      rows: _rows,
      start: GridPosition(x: playerCell.column, y: playerCell.row),
      goal: GridPosition(x: goalCell.column, y: goalCell.row),
      obstacles: _items.entries
          .where((entry) => entry.value == _BoardItemType.obstacle)
          .map((entry) => GridPosition(x: entry.key.column, y: entry.key.row))
          .toSet(),
      collectables: _collectableCells
          .map((cell) => GridPosition(x: cell.column, y: cell.row))
          .toSet(),
    );

    final result = const TopViewSolver().findShortestPath(
      level: level,
      allowDiagonalMoves: _useAnglesInGeneratedTurns,
    );
    if (!result.solved) {
      debugPrint('No solution found');
      return;
    }

    final solutionCode = TopViewSolutionConverter(
      initialHeadingDegrees: _initialPlayerHeadingDegrees,
      useTurnAngles: _useAnglesInGeneratedTurns,
    ).convert(result.actions);
    if (solutionCode.isEmpty) {
      debugPrint('No solution found');
      return;
    }

    _stopCodeRun();
    final generatedBlocks = _codeBlocksUsedBySolution(solutionCode);
    setState(() {
      _allowedBlocks
        ..clear()
        ..addAll(generatedBlocks);
      _codeController.text = solutionCode;
      _codeController.selection = TextSelection.collapsed(
        offset: solutionCode.length,
      );
    });
    // debugPrint(solutionCode);
  }

  List<_CodeBlock> _codeBlocksUsedBySolution(String code) {
    final usedBlockIds = <String>{};

    for (final rawLine in code.split('\n')) {
      final line = rawLine.trim().toLowerCase();
      if (line.isEmpty) {
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      final command = parts.first;

      if (command == 'step') {
        usedBlockIds.add('step');
        continue;
      }

      if (command == 'turn') {
        usedBlockIds.add('turn');
        if (parts.length > 1 && double.tryParse(parts[1]) == null) {
          usedBlockIds.add(parts[1]);
        }
        continue;
      }

      if (_screenDirectionDegrees(command) != null) {
        usedBlockIds.add(command);
      }
    }

    return _codeBlocks
        .where((block) => usedBlockIds.contains(block.id))
        .toList();
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

  Future<void> _handleLeaveRequested() async {
    final projectId = _savedProjectId ?? widget.initialProjectId;
    if (!widget.playMode || projectId == null || projectId.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (!widget.showRatingOnLeave || widget.courseProgressCourseId != null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldLeave = await showChallengeLeaveDialog(
      context: context,
      title: (widget.initialTitle ?? _titleController.text).trim().isEmpty
          ? AppLanguage.instance.t('builder.newLevel')
          : (widget.initialTitle ?? _titleController.text).trim(),
      onSubmitRating: (rating) async {
        final result = await ApiService.rateBuilderProject(
          authToken: widget.session.token,
          projectId: projectId,
          rating: rating,
        );
        if (result['success'] == true) {
          return null;
        }
        return result['message']?.toString() ?? 'Failed to save rating.';
      },
    );

    if (shouldLeave && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return PopScope(
      canPop: !widget.playMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !widget.playMode) {
          return;
        }
        unawaited(_handleLeaveRequested());
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: KidsTopBarStyle.toolbarHeight,
            backgroundColor: KidsTopBarStyle.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            bottom: KidsTopBarStyle.appBarBottom(),
            leading: IconButton(
              onPressed: widget.playMode
                  ? _handleLeaveRequested
                  : () => Navigator.of(context).maybePop(),
              icon: const GameBuilderBackIcon(),
            ),
            title: widget.playMode
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.initialTitle ?? _titleController.text,
                          style: KidsTopBarStyle.titleTextStyle,
                        ),
                      ),
                      CourseLevelNavBanner(
                        session: widget.session,
                        courseId: widget.courseProgressCourseId,
                        currentLevelId:
                            widget.courseProgressLevelId ?? _savedProjectId,
                        currentLevelSolved: _hasSavedCourseProgress,
                        topBarMode: true,
                      ),
                    ],
                  )
                : GameBuilderLevelTitleField(
                    controller: _titleController,
                    hintText: language.t('builder.newLevel'),
                  ),
            actions: widget.playMode
                ? null
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton(
                        onPressed: _isSavingProject ? null : _handleSavePressed,
                        style: KidsTopBarStyle.playfulText(
                          KidsTopBarStyle.blue,
                        ),
                        child: Text(language.t('builder.save')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FilledButton(
                        onPressed: _isSavingProject
                            ? null
                            : _handlePublishPressed,
                        style: KidsTopBarStyle.playfulFilled(
                          KidsTopBarStyle.green,
                        ),
                        child: Text(
                          _isSavingProject
                              ? language.t('builder.saving')
                              : language.t('builder.publish'),
                        ),
                      ),
                    ),
                  ],
          ),
          body: _isLoadingProject
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  color: const Color(0xFFEAF6FF),
                  child: Column(
                    children: [
                      Expanded(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
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
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
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
                            if (widget.playMode)
                              Positioned(
                                left: 18,
                                bottom: 18,
                                child: _buildInstructionHelperButton(),
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
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildToolsSidebar() {
    return ListView(
      children: [
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.tools'),
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
          title: 'Custom assets',
          child: _buildCustomAssetsPanel(),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.boardStyle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBackgroundControl(),
              const SizedBox(height: 14),
              _buildObstacleStyleControl(),
              const SizedBox(height: 14),
              _buildCollectableStyleControl(),
              const SizedBox(height: 14),
              _buildGoalStyleControl(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(title: 'Scores', child: _buildScoreControls()),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.instructions'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _codeBlocks.map(_buildInstructionTool).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.playerDirection'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCharacterControl(),
              const SizedBox(height: 14),
              _buildInitialDirectionControl(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.levelActions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                value: _useAnglesInGeneratedTurns,
                onChanged: (value) {
                  setState(() {
                    _useAnglesInGeneratedTurns = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  AppLanguage.of(context).t('builder.useTurnAngles'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _handlePrintSolutionPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.route_rounded, size: 18),
                label: Text(
                  AppLanguage.of(context).t('builder.printSolution'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
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
                label: Text(
                  AppLanguage.of(context).t('builder.clearLevel'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildSidebarSection(
          title: AppLanguage.of(context).t('builder.levelInfo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLanguage.of(context).t(
                  'builder.gridSummary',
                  params: {'columns': '$_cols', 'rows': '$_rows'},
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _rulerActive
                    ? AppLanguage.of(context).t('builder.rulerActiveHelp')
                    : AppLanguage.of(context).t('builder.topViewHelp'),
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
                Positioned.fill(
                  child: GameWidget(game: _topViewGame, autofocus: false),
                ),
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
                    final shouldRenderTileItem =
                        item != null && _playerPreview == null;
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
                                  ? const Color(0x99E8F4FF)
                                  : Colors.transparent,
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
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
                                if (item != null && shouldRenderTileItem)
                                  Positioned.fill(
                                    child: _buildPlacedBoardItemDragHandle(
                                      item: item,
                                      cell: cell,
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
                if (!_isRunningCode && _playerPreview != null)
                  ..._finalGoalAndPlayerOverlays(
                    preview: _playerPreview!,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
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

  List<Widget> _finalGoalAndPlayerOverlays({
    required _PlayerPreviewData preview,
    required double cellWidth,
    required double cellHeight,
  }) {
    final goalCell = _goalCell;
    return <Widget>[
      if (goalCell != null && _positionMatchesCell(preview.position, goalCell))
        _finalGoalPreviewOverlay(
          cell: goalCell,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        ),
      _finalPlayerPreviewOverlay(
        preview: preview,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
      ),
    ];
  }

  Widget _finalGoalPreviewOverlay({
    required _Cell cell,
    required double cellWidth,
    required double cellHeight,
  }) {
    final shortestSide = math.min(cellWidth, cellHeight);
    final goalSize = shortestSide * _goalSpriteTileScale * 0.78;
    final center = Offset(
      (cell.column + 0.5) * cellWidth,
      (cell.row + 0.5) * cellHeight,
    );

    return Positioned(
      left: center.dx - goalSize / 2,
      top: center.dy - goalSize / 2,
      width: goalSize,
      height: goalSize,
      child: IgnorePointer(
        child: Image.asset(
          'game_builder/goal/chest_open_gold.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            final goal = topViewGoalStyleById(
              _goalStylesByCell[cell] ?? _goalStyleId,
            );
            return Image.asset(
              goal.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.flag_rounded,
                  color: _BoardItemType.goal.color,
                  size: goalSize * 0.52,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _finalPlayerPreviewOverlay({
    required _PlayerPreviewData preview,
    required double cellWidth,
    required double cellHeight,
  }) {
    final shortestSide = math.min(cellWidth, cellHeight);
    final playerSize = shortestSide * _playerSpriteTileScale;
    final center = Offset(
      preview.position.dx * cellWidth,
      preview.position.dy * cellHeight,
    );

    return Positioned(
      left: center.dx - playerSize / 2,
      top: center.dy - playerSize / 2,
      width: playerSize,
      height: playerSize,
      child: IgnorePointer(
        child: _topViewCharacterImage(
          headingDegrees: preview.headingDegrees,
          withShadow: true,
        ),
      ),
    );
  }

  Widget _buildPlacedBoardItemDragHandle({
    required _BoardItemType item,
    required _Cell cell,
  }) {
    if (_rulerActive) {
      return const SizedBox.expand();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_Payload>(
        data: _Payload.boardItem(item, cell),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: _boardIcon(item, small: true),
        ),
        childWhenDragging: const SizedBox.expand(),
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
        child: const ColoredBox(color: Colors.transparent),
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
                  label: Text(
                    _isRunningCode
                        ? AppLanguage.of(context).t('builder.stop')
                        : AppLanguage.of(context).t('builder.run'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetRunState,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade900,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(AppLanguage.of(context).t('builder.reset')),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearCode,
                  child: Text(
                    AppLanguage.of(context).t('builder.clear'),
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
            if (!widget.playMode) ...[
              _buildInstructionEditorCard(),
              const SizedBox(height: 16),
            ],
            Text(
              AppLanguage.of(context).t('builder.solutionBlocks'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.playMode) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _nextTopViewHintBlockId() == null
                      ? null
                      : _requestTopViewHint,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0F5E9C),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: const Text('Hint'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildSolutionTray(),
          ],
        ),
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
                        ? AppLanguage.of(context).t('builder.noSolutionBlocks')
                        : AppLanguage.of(
                            context,
                          ).t('builder.dropInstructionBlocks'),
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

  Widget _buildInstructionEditorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.shade100, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.of(context).t('builder.instructions'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _instructionController,
            minLines: 5,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Tell the player what to do in this level.',
              filled: true,
              fillColor: Colors.blueGrey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blueGrey.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionHelperButton() {
    if (_instructionController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showInstructionDialog,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.blueGrey.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE3F2FF),
                child: ClipOval(
                  child: _buildInstructionCharacterAvatar(size: 34),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Help',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardPaletteItem(_BoardItemType item) {
    final tile = _toolTile(
      label: _localizedBoardItemLabel(item),
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
            label: _localizedBoardItemLabel(item),
            icon: item.icon,
            color: item.color,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }

  Widget _buildCustomAssetsPanel() {
    final assets = _customAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: widget.playMode ? null : _showAddAssetDialog,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Add asset'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (assets.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Uploaded or saved assets will appear here.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade500),
          ),
        ] else ...[
          const SizedBox(height: 12),
          for (final asset in assets) ...[
            _buildCustomAssetListItem(asset),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildCustomAssetListItem(CustomAssetData asset) {
    final bytes = _assetImageBytes(asset);
    if (bytes == null) {
      unawaited(_ensureAssetImageLoaded(asset));
    }
    final accent = _customAssetTypeColor(asset.type);
    final isBackground = _customBackgroundAssetId == asset.id;
    final item = InkWell(
      onTap: widget.playMode
          ? null
          : () {
              if (asset.type == CustomAssetType.background) {
                return;
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isBackground ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBackground ? accent : Colors.blueGrey.shade100,
            width: isBackground ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCustomAssetPreview(
                asset: asset,
                width: 44,
                height: asset.type == CustomAssetType.background ? 30 : 44,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    asset.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Asset settings',
              onPressed: widget.playMode
                  ? null
                  : () => _showAssetEditorDialog(existingAsset: asset),
              icon: const Icon(Icons.settings_rounded, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );

    if (widget.playMode) {
      return item;
    }

    return Draggable<_Payload>(
      data: _Payload.customAsset(asset.id),
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: 64,
            height: asset.type == CustomAssetType.background ? 42 : 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCustomAssetPreview(
                  asset: asset,
                  width: 64,
                  height: asset.type == CustomAssetType.background ? 42 : 64,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: item),
      child: item,
    );
  }

  Future<void> _showAddAssetDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAssetChoiceTile(
                icon: Icons.collections_bookmark_rounded,
                title: 'Browse collections',
                subtitle: 'Use your favorites, creations, or saved assets.',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showCollectionPickerDialog();
                },
              ),
              const SizedBox(height: 10),
              _buildAssetChoiceTile(
                icon: Icons.upload_file_rounded,
                title: 'Upload new asset',
                subtitle: 'Choose an image from this device.',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _pickAndCreateCustomAsset();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetChoiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.blueGrey.shade50,
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }

  Future<void> _showCollectionPickerDialog() async {
    final selectedAsset = await showDialog<CustomAssetData>(
      context: context,
      builder: (dialogContext) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: const Text('Asset collection'),
            content: SizedBox(
              width: 420,
              height: 360,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Favorites'),
                      Tab(text: 'Creations'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCollectionAssetList(
                          _favoriteCustomAssets,
                          dialogContext,
                        ),
                        _buildCollectionAssetList(
                          _createdCustomAssets,
                          dialogContext,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedAsset == null) {
      return;
    }
    _useCustomAssetFromCollection(selectedAsset);
  }

  Widget _buildCollectionAssetList(
    List<CustomAssetData> assets,
    BuildContext dialogContext,
  ) {
    if (assets.isEmpty) {
      return Center(
        child: Text(
          'No assets yet.',
          style: TextStyle(color: Colors.blueGrey.shade500),
        ),
      );
    }

    return ListView.separated(
      itemCount: assets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return ListTile(
          onTap: () => Navigator.of(dialogContext).pop(asset),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.blueGrey.shade50,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildCustomAssetPreview(
              asset: asset,
              width: 44,
              height: 44,
            ),
          ),
          title: Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(asset.type.label),
        );
      },
    );
  }

  Widget _buildCustomAssetPreview({
    required CustomAssetData asset,
    required double width,
    required double height,
  }) {
    final bytes = _assetImageBytes(asset);
    if (bytes == null) {
      unawaited(_ensureAssetImageLoaded(asset));
    }

    return SizedBox(
      width: width,
      height: height,
      child: bytes == null
          ? ColoredBox(
              color: Colors.blueGrey.shade50,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.blueGrey.shade400,
              ),
            )
          : _buildFramedImagePreview(
              bytes: bytes,
              scale: asset.frameScale,
              offsetX: asset.frameOffsetX,
              offsetY: asset.frameOffsetY,
            ),
    );
  }

  Widget _buildFramedImagePreview({
    required Uint8List bytes,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) {
    return _CustomAssetFrameImage(
      bytes: bytes,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }

  Color _customAssetTypeColor(CustomAssetType type) {
    switch (type) {
      case CustomAssetType.character:
        return const Color(0xFF2563EB);
      case CustomAssetType.obstacle:
        return const Color(0xFF64748B);
      case CustomAssetType.collectable:
        return const Color(0xFFF59E0B);
      case CustomAssetType.goal:
        return const Color(0xFFEF4444);
      case CustomAssetType.background:
        return const Color(0xFF0F766E);
    }
  }

  double _frameAspectForAssetType(CustomAssetType type) {
    return type == CustomAssetType.background ? _cols / _rows : 1;
  }

  Size _assetEditorPreviewSize(CustomAssetType type, Size screenSize) {
    final maxDialogWidth = math.min(screenSize.width * 0.72, 560.0);
    final maxDialogHeight = math.min(screenSize.height * 0.42, 360.0);
    final aspect = _frameAspectForAssetType(type);

    double targetWidth;
    double targetHeight;
    switch (type) {
      case CustomAssetType.background:
        targetWidth = math.min(maxDialogWidth, 520);
        targetHeight = math.min(targetWidth / aspect, 220);
        targetWidth = targetHeight * aspect;
        break;
      case CustomAssetType.character:
        targetHeight = math.min(maxDialogHeight, 340);
        targetWidth = targetHeight;
        break;
      case CustomAssetType.obstacle:
      case CustomAssetType.goal:
        targetHeight = math.min(maxDialogHeight, 300);
        targetWidth = targetHeight;
        break;
      case CustomAssetType.collectable:
        targetHeight = math.min(maxDialogHeight, 260);
        targetWidth = targetHeight;
        break;
    }

    if (targetWidth > maxDialogWidth) {
      targetWidth = maxDialogWidth;
      targetHeight = targetWidth / aspect;
    }

    return Size(targetWidth, targetHeight);
  }

  double _defaultFrameScaleForType(CustomAssetType type) {
    switch (type) {
      case CustomAssetType.character:
        return 1.25;
      case CustomAssetType.goal:
      case CustomAssetType.obstacle:
        return 1.05;
      case CustomAssetType.background:
        return 1;
      case CustomAssetType.collectable:
        return 1.2;
    }
  }

  Widget _buildInitialDirectionControl() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<double>(
        showSelectedIcon: false,
        selected: <double>{_initialPlayerHeadingDegrees},
        segments: [
          ButtonSegment<double>(
            value: 90,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            tooltip: AppLanguage.of(context).t('builder.startFacingUp'),
          ),
          ButtonSegment<double>(
            value: 0,
            icon: const Icon(Icons.keyboard_arrow_right_rounded),
            tooltip: AppLanguage.of(context).t('builder.startFacingRight'),
          ),
          ButtonSegment<double>(
            value: 270,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            tooltip: AppLanguage.of(context).t('builder.startFacingDown'),
          ),
          ButtonSegment<double>(
            value: 180,
            icon: const Icon(Icons.keyboard_arrow_left_rounded),
            tooltip: AppLanguage.of(context).t('builder.startFacingLeft'),
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
          _syncTopViewGame(resetPlayer: true);
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

  Widget _buildCharacterControl() {
    final selectedCharacter = topViewCharacterById(_playerCharacterId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.character'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_playerCharacterId),
          initialValue: selectedCharacter.id,
          isExpanded: true,
          items: [
            for (final character in topViewCharacters)
              DropdownMenuItem<String>(
                value: character.id,
                child: _buildCharacterMenuItem(character),
              ),
          ],
          onChanged: (characterId) {
            if (characterId == null ||
                characterId == _playerCharacterId ||
                widget.playMode) {
              return;
            }

            _stopCodeRun();
            setState(() {
              _playerCharacterId = topViewCharacterById(characterId).id;
            });
            _syncTopViewGame(resetPlayer: true);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Image.asset(
                  selectedCharacter.previewAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.pets_rounded,
                      color: Colors.blueGrey.shade400,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  localizedTopViewCharacterLabel(
                    AppLanguage.of(context),
                    selectedCharacter.id,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey.shade900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundControl() {
    final selectedBackground = topViewBackgroundById(_backgroundId);
    final activeCustomBackground = _customAssetById(_customBackgroundAssetId);
    final selectedBackgroundId =
        activeCustomBackground?.id ?? selectedBackground.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.background'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('background-$selectedBackgroundId'),
          initialValue: selectedBackgroundId,
          isExpanded: true,
          items: [
            for (final background in topViewBackgrounds)
              DropdownMenuItem<String>(
                value: background.id,
                child: _buildBackgroundMenuItem(background),
              ),
            if (activeCustomBackground != null)
              DropdownMenuItem<String>(
                value: activeCustomBackground.id,
                child: _buildCustomBackgroundMenuItem(activeCustomBackground),
              ),
          ],
          onChanged: (backgroundId) {
            if (backgroundId == null || widget.playMode) {
              return;
            }

            _stopCodeRun();
            setState(() {
              final customBackground = _customAssetById(backgroundId);
              if (customBackground?.type == CustomAssetType.background) {
                _customBackgroundAssetId = customBackground!.id;
              } else {
                _backgroundId = topViewBackgroundById(backgroundId).id;
                _customBackgroundAssetId = null;
              }
            });
            _syncTopViewGame(resetPlayer: true);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildObstacleStyleControl() {
    final selectedObstacle = topViewObstacleStyleById(_obstacleStyleId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.obstacle'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('obstacle-$_obstacleStyleId'),
          initialValue: selectedObstacle.id,
          isExpanded: true,
          items: [
            for (final obstacle in topViewObstacleStyles)
              DropdownMenuItem<String>(
                value: obstacle.id,
                child: _buildObstacleMenuItem(obstacle),
              ),
          ],
          onChanged: (obstacleId) {
            if (obstacleId == null ||
                obstacleId == _obstacleStyleId ||
                widget.playMode) {
              return;
            }

            _stopCodeRun();
            setState(() {
              _obstacleStyleId = topViewObstacleStyleById(obstacleId).id;
            });
            _syncTopViewGame(resetPlayer: true);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectableStyleControl() {
    final selectedCollectable = topViewCollectableStyleById(
      _collectableStyleId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.collectable'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('collectable-$_collectableStyleId'),
          initialValue: selectedCollectable.id,
          isExpanded: true,
          items: [
            for (final collectable in topViewCollectableStyles)
              DropdownMenuItem<String>(
                value: collectable.id,
                child: _buildCollectableMenuItem(collectable),
              ),
          ],
          onChanged: (collectableId) {
            if (collectableId == null ||
                collectableId == _collectableStyleId ||
                widget.playMode) {
              return;
            }

            _stopCodeRun();
            setState(() {
              _collectableStyleId = topViewCollectableStyleById(
                collectableId,
              ).id;
            });
            _syncTopViewGame(resetPlayer: true);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStyleControl() {
    final selectedGoal = topViewGoalStyleById(_goalStyleId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.goal'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('goal-$_goalStyleId'),
          initialValue: selectedGoal.id,
          isExpanded: true,
          items: [
            for (final goal in topViewGoalStyles)
              DropdownMenuItem<String>(
                value: goal.id,
                child: _buildGoalMenuItem(goal),
              ),
          ],
          onChanged: (goalId) {
            if (goalId == null || goalId == _goalStyleId || widget.playMode) {
              return;
            }

            _stopCodeRun();
            setState(() {
              _goalStyleId = topViewGoalStyleById(goalId).id;
            });
            _syncTopViewGame(resetPlayer: true);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreControls() {
    final scoreEntries =
        _items.entries
            .where(
              (entry) =>
                  entry.value == _BoardItemType.collectable ||
                  entry.value == _BoardItemType.goal,
            )
            .toList()
          ..sort((a, b) {
            final rowCompare = a.key.row.compareTo(b.key.row);
            if (rowCompare != 0) {
              return rowCompare;
            }
            return a.key.column.compareTo(b.key.column);
          });

    if (scoreEntries.isEmpty) {
      return Text(
        'Add collectables or a goal to set points.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.blueGrey.shade600,
          height: 1.25,
        ),
      );
    }

    return Column(
      children: [
        for (final entry in scoreEntries) ...[
          _buildCellScoreField(entry.key, entry.value),
          if (entry != scoreEntries.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCellScoreField(_Cell cell, _BoardItemType type) {
    return Row(
      children: [
        _buildCellScorePreview(cell, type),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '(${cell.column}, ${cell.row})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 74,
          child: TextFormField(
            key: ValueKey<String>('top-score-${cell.column}-${cell.row}'),
            initialValue: _scoreForCell(cell, type).toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final score = int.tryParse(value.trim());
              if (score == null) {
                return;
              }
              _setCellScore(cell, score);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCellScorePreview(_Cell cell, _BoardItemType type) {
    final customAsset = _customAssetById(_customAssetIdsByCell[cell]);
    Widget child;
    if (customAsset != null) {
      final bytes = _assetImageBytes(customAsset);
      if (bytes == null) {
        unawaited(_ensureAssetImageLoaded(customAsset));
      }
      child = bytes == null
          ? Icon(
              Icons.image_not_supported_outlined,
              size: 18,
              color: Colors.blueGrey.shade400,
            )
          : _buildFramedImagePreview(
              bytes: bytes,
              scale: customAsset.frameScale,
              offsetX: customAsset.frameOffsetX,
              offsetY: customAsset.frameOffsetY,
            );
    } else if (type == _BoardItemType.collectable) {
      final collectable = topViewCollectableStyleById(
        _collectableStylesByCell[cell] ?? _collectableStyleId,
      );
      child = Image.asset(
        collectable.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported_outlined,
            size: 18,
            color: Colors.blueGrey.shade400,
          );
        },
      );
    } else {
      final goal = topViewGoalStyleById(
        _goalStylesByCell[cell] ?? _goalStyleId,
      );
      child = Image.asset(
        goal.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported_outlined,
            size: 18,
            color: Colors.blueGrey.shade400,
          );
        },
      );
    }

    return _buildCellScorePreviewShell(child: child);
  }

  Widget _buildCellScorePreviewShell({required Widget child}) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  void _setCellScore(_Cell cell, int score) {
    if (widget.playMode) {
      return;
    }
    final type = _items[cell];
    if (type != _BoardItemType.collectable && type != _BoardItemType.goal) {
      return;
    }
    setState(() {
      _scoresByCell[cell] = score < 0 ? 0 : score;
    });
  }

  Widget _buildCharacterMenuItem(TopViewCharacter character) {
    return Row(
      children: [
        Image.asset(
          character.previewAssetPath,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 26, height: 26);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedTopViewCharacterLabel(
              AppLanguage.of(context),
              character.id,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundMenuItem(TopViewBackground background) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            background.assetPath,
            width: 30,
            height: 22,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 30, height: 22);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedTopViewBackgroundLabel(
              AppLanguage.of(context),
              background.id,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBackgroundMenuItem(CustomAssetData asset) {
    final bytes = _assetImageBytes(asset);
    if (bytes == null) {
      unawaited(_ensureAssetImageLoaded(asset));
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 30,
            height: 22,
            child: bytes == null
                ? ColoredBox(
                    color: Colors.blueGrey.shade50,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 16,
                      color: Colors.blueGrey.shade400,
                    ),
                  )
                : _buildFramedImagePreview(
                    bytes: bytes,
                    scale: asset.frameScale,
                    offsetX: asset.frameOffsetX,
                    offsetY: asset.frameOffsetY,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildObstacleMenuItem(TopViewObstacleStyle obstacle) {
    return Row(
      children: [
        Image.asset(
          obstacle.assetPath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 28, height: 28);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedTopViewObstacleLabel(AppLanguage.of(context), obstacle.id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectableMenuItem(TopViewCollectableStyle collectable) {
    return Row(
      children: [
        Image.asset(
          collectable.assetPath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 28, height: 28);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedTopViewCollectableLabel(
              AppLanguage.of(context),
              collectable.id,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalMenuItem(TopViewGoalStyle goal) {
    return Row(
      children: [
        Image.asset(
          goal.assetPath,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 28, height: 28);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedTopViewGoalLabel(AppLanguage.of(context), goal.id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionTool(_CodeBlock block) {
    final tile = _toolTile(
      label: _localizedCodeBlockLabel(block),
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
            label: _localizedCodeBlockLabel(block),
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
    final hintedBlockId = _pendingHintBlockId;
    final highlightForHint =
        widget.playMode && _hintGlowOn && hintedBlockId == block.id;
    if (widget.playMode) {
      return InkWell(
        onTap: () => _insertBlock(block),
        borderRadius: BorderRadius.circular(16),
        child: _buildAllowedChipVisual(
          block,
          highlightForHint: highlightForHint,
        ),
      );
    }

    return Draggable<_Payload>(
      data: _Payload.solutionTrayBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: _buildAllowedChipVisual(
          block,
          highlightForHint: highlightForHint,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildAllowedChipVisual(
          block,
          highlightForHint: highlightForHint,
        ),
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
        child: _buildAllowedChipVisual(
          block,
          highlightForHint: highlightForHint,
        ),
      ),
    );
  }

  Widget _buildAllowedChipVisual(
    _CodeBlock block, {
    bool highlightForHint = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: block.color.withValues(alpha: highlightForHint ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightForHint
              ? Colors.amber.shade600
              : block.color.withValues(alpha: 0.32),
          width: highlightForHint ? 2.4 : 1,
        ),
        boxShadow: highlightForHint
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_rounded, size: 16, color: block.color),
          const SizedBox(width: 8),
          Text(
            _localizedCodeBlockLabel(block),
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
    Uint8List? imageBytes,
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
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageBytes,
                width: isInstruction ? 20 : 28,
                height: isInstruction ? 20 : 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
          ] else if (icon != null) ...[
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
      message: _rulerActive
          ? AppLanguage.of(context).t('builder.deselectRuler')
          : AppLanguage.of(context).t('builder.selectRuler'),
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
            AppLanguage.of(
              context,
            ).t('builder.tiles', params: {'count': '$distance'}),
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
                      AppLanguage.of(context).t('builder.dropToDelete'),
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
    if (item == _BoardItemType.player) {
      final playerSize = small ? size * 2.25 : size * 3.4;
      return SizedBox(
        width: playerSize,
        height: playerSize,
        child: _topViewCharacterImage(
          headingDegrees: _initialPlayerHeadingDegrees,
        ),
      );
    }

    if (item == _BoardItemType.obstacle) {
      final obstacle = topViewObstacleStyleById(_obstacleStyleId);
      return SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Image.asset(
          obstacle.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackBoardIcon(item, size: size);
          },
        ),
      );
    }

    if (item == _BoardItemType.collectable) {
      final collectable = topViewCollectableStyleById(_collectableStyleId);
      return SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Image.asset(
          collectable.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackBoardIcon(item, size: size);
          },
        ),
      );
    }

    if (item == _BoardItemType.goal) {
      final goal = topViewGoalStyleById(_goalStyleId);
      return SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Image.asset(
          goal.assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackBoardIcon(item, size: size);
          },
        ),
      );
    }

    return _fallbackBoardIcon(item, size: size);
  }

  Widget _fallbackBoardIcon(_BoardItemType item, {required double size}) {
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
    return Icon(item.icon, size: size, color: Colors.white);
  }

  Widget _topViewCharacterImage({
    required double headingDegrees,
    bool withShadow = false,
  }) {
    final character = topViewCharacterById(_playerCharacterId);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Transform.rotate(
        angle: _degreesToRadians(90 - headingDegrees),
        child: Image.asset(
          character.stillAssetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: _BoardItemType.player.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.navigation_rounded, color: Colors.white),
            );
          },
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

  String _localizedBoardItemLabel(_BoardItemType item) {
    final language = AppLanguage.of(context);
    return switch (item) {
      _BoardItemType.obstacle => language.t('builder.obstacle'),
      _BoardItemType.player => language.t('builder.player'),
      _BoardItemType.collectable => language.t('builder.collectable'),
      _BoardItemType.goal => language.t('builder.goal'),
    };
  }

  String _localizedCodeBlockLabel(_CodeBlock block) {
    final language = AppLanguage.of(context);
    return language.tr('builder.codeBlock.${block.id}', block.label);
  }
}

class _CustomAssetFrameImage extends StatelessWidget {
  final Uint8List bytes;
  final double scale;
  final double offsetX;
  final double offsetY;

  const _CustomAssetFrameImage({
    required this.bytes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final frameHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;

        return ClipRect(
          child: Transform.translate(
            offset: Offset(
              offsetX * frameWidth * 0.5,
              offsetY * frameHeight * 0.5,
            ),
            child: Transform.scale(
              scale: scale,
              child: SizedBox.expand(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
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

enum _PayloadKind {
  boardPalette,
  boardItem,
  customAsset,
  solutionBlock,
  solutionTrayBlock,
}

class _Payload {
  final _PayloadKind kind;
  final _BoardItemType? itemType;
  final _Cell? sourceCell;
  final String? customAssetId;
  final _CodeBlock? block;

  const _Payload._({
    required this.kind,
    this.itemType,
    this.sourceCell,
    this.customAssetId,
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
  const _Payload.customAsset(String customAssetId)
    : this._(kind: _PayloadKind.customAsset, customAssetId: customAssetId);
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
