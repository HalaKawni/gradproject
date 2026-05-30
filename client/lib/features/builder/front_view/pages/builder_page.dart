import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../controllers/builder_controller.dart';
import '../flame/builder_game.dart';
import '../models/builder_playback_state.dart';
import '../models/builder_project.dart';
import '../models/custom_asset_data.dart';
import '../models/entity_data.dart';
import '../models/level_settings.dart';
import '../models/logic_command.dart';
import '../models/tile_data.dart';
import '../shared/builder_character.dart';
import '../shared/builder_collectable.dart';
import '../shared/builder_tool.dart';
import '../solver/front_view_solution_converter.dart';
import '../solver/front_view_solver.dart';
import '../widgets/builder_status_bar.dart';
import '../widgets/builder_toolbar.dart';

class BuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;

  const BuilderPage({
    super.key,
    required this.session,
    this.initialProjectId,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
  });

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  static const double _leftPanelWidth = 260;
  static const double _rootLogicLaneHeight = 54;
  static const double _logicDropSnapPadding = 30;
  static const double _logicGhostProbeYOffset = -18;
  static const String _defaultBackgroundId = 'forest';
  static const String _defaultBackgroundLabel = 'Forest background';
  static const String _defaultBackgroundAssetPath =
      'game_builder/background/backgroundColorForest.png';
  static const List<String> _difficultyOptions = <String>[
    'easy',
    'medium',
    'hard',
  ];

  late BuilderController controller;
  late BuilderGame game;
  late TextEditingController titleController;
  late final ScrollController horizontalScrollController;
  late final ScrollController verticalScrollController;
  late final VoidCallback controllerListener;
  Timer? titleSaveDebounce;
  String? lastAutoSavedTitle;
  final Map<_LogicDropTarget, Rect> _logicDropTargetRects =
      <_LogicDropTarget, Rect>{};
  String? selectedSolutionCommandId;
  String? selectedLoopInsertionTargetId;
  int previousColumnCount = 0;
  bool hasAttemptedSave = false;
  bool isBoardGridDragActive = false;
  bool isLogicDragActive = false;
  _LogicDragData? activeLogicDragData;
  _LogicDropTarget? proximityLogicDropTarget;

  @override
  void initState() {
    super.initState();

    final project = BuilderProject.initial(
      courseId: widget.initialCourseId ?? '',
      orderInCourse: widget.initialOrderInCourse ?? 0,
      difficulty: widget.initialDifficulty,
      status: widget.initialStatus,
    );
    titleController = TextEditingController(text: project.title);
    horizontalScrollController = ScrollController();
    verticalScrollController = ScrollController();
    controller = BuilderController(
      project: project,
      session: widget.session,
      initialSavedProjectId: widget.initialProjectId,
      useAdminLevelApi: widget.useAdminLevelApi,
    );
    game = BuilderGame(controller: controller);
    previousColumnCount = controller.project.settings.columns;
    controllerListener = _handleControllerChanged;
    controller.addListener(controllerListener);

    if (widget.initialProjectId != null) {
      controller.loadProject(widget.initialProjectId!);
    }
  }

  @override
  void dispose() {
    titleSaveDebounce?.cancel();
    titleController.dispose();
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
    controller.removeListener(controllerListener);
    controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    _syncTitleField();
    _syncHorizontalExpansion();
    _syncSelectedSolutionCommandSelection();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _handleBoardGridDragStateChanged(bool isDragging) {
    if (isBoardGridDragActive == isDragging) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isBoardGridDragActive = isDragging;
    });
  }

  void _handleLogicDragStateChanged(bool isDragging) {
    if (isLogicDragActive == isDragging) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLogicDragActive = isDragging;
    });
  }

  void _handleLogicDragStarted(_LogicDragData data) {
    activeLogicDragData = data;
    proximityLogicDropTarget = null;
    _handleLogicDragStateChanged(true);
  }

  void _handleLogicDropTargetRectChanged(_LogicDropTarget target, Rect? rect) {
    if (rect == null) {
      _logicDropTargetRects.remove(target);
      return;
    }

    _logicDropTargetRects[target] = rect;
  }

  void _handleLogicDragUpdated(_LogicDragData data, DragUpdateDetails details) {
    if (!mounted) {
      return;
    }

    final nextTarget = _findNearbyLogicDropTarget(
      data,
      details.globalPosition.translate(0, _logicGhostProbeYOffset),
    );

    if (nextTarget == proximityLogicDropTarget) {
      return;
    }

    setState(() {
      proximityLogicDropTarget = nextTarget;
    });
  }

  void _handleLogicDragEnded(_LogicDragData data, DraggableDetails details) {
    final effectiveData = activeLogicDragData ?? data;
    final target = proximityLogicDropTarget;
    activeLogicDragData = null;

    if (mounted) {
      setState(() {
        proximityLogicDropTarget = null;
      });
    } else {
      proximityLogicDropTarget = null;
    }

    _handleLogicDragStateChanged(false);

    if (details.wasAccepted || target == null) {
      return;
    }

    if (!_canAcceptLogicDrop(effectiveData, target)) {
      return;
    }

    _handleLogicDrop(effectiveData, target);
  }

  _LogicDropTarget? _findNearbyLogicDropTarget(
    _LogicDragData data,
    Offset globalPosition,
  ) {
    _LogicDropTarget? bestTarget;
    double bestScore = double.infinity;

    for (final entry in _logicDropTargetRects.entries) {
      final target = entry.key;
      if (!_canAcceptLogicDrop(data, target)) {
        continue;
      }

      final rect = entry.value;
      final expandedRect = rect.inflate(_logicDropSnapPadding);
      if (!expandedRect.contains(globalPosition)) {
        continue;
      }

      final distanceToRect = _distanceFromPointToRect(globalPosition, rect);
      final centerDistance = (globalPosition - rect.center).distance;
      final score = distanceToRect * 1000 + centerDistance;
      if (score >= bestScore) {
        continue;
      }

      bestScore = score;
      bestTarget = target;
    }

    return bestTarget;
  }

  double _distanceFromPointToRect(Offset point, Rect rect) {
    final dx = point.dx < rect.left
        ? rect.left - point.dx
        : point.dx > rect.right
        ? point.dx - rect.right
        : 0.0;
    final dy = point.dy < rect.top
        ? rect.top - point.dy
        : point.dy > rect.bottom
        ? point.dy - rect.bottom
        : 0.0;

    return math.sqrt(dx * dx + dy * dy);
  }

  bool _isLogicDropTargetHighlighted(
    _LogicDropTarget target,
    List<_LogicDragData?> candidateData,
  ) {
    if (candidateData.isNotEmpty) {
      return true;
    }

    return proximityLogicDropTarget == target;
  }

  Offset _logicGhostDragAnchorStrategy(
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return const Offset(24, 24);
    }

    final size = renderObject.size;
    return Offset(size.width / 2, size.height * 0.82);
  }

  void _syncTitleField() {
    if (titleController.text == controller.project.title) {
      return;
    }

    titleController.value = titleController.value.copyWith(
      text: controller.project.title,
      selection: TextSelection.collapsed(
        offset: controller.project.title.length,
      ),
      composing: TextRange.empty,
    );
  }

  void _handleTitleChanged(String title) {
    controller.setTitle(title);
    titleSaveDebounce?.cancel();
    titleSaveDebounce = Timer(const Duration(milliseconds: 700), () {
      _autoSaveTitle();
    });
  }

  Future<void> _autoSaveTitle() async {
    final normalizedTitle = titleController.text.trim().isEmpty
        ? 'Untitled'
        : titleController.text.trim();
    if (lastAutoSavedTitle == normalizedTitle || controller.isSaving) {
      return;
    }

    lastAutoSavedTitle = normalizedTitle;
    await controller.saveProject();
  }

  // Hot-reload compatibility shim: older in-memory listeners may still call
  // this removed method until the page is rebuilt or the app is restarted.
  // ignore: unused_element
  void _syncTileSizeField() {}

  void _syncHorizontalExpansion() {
    final currentColumns = controller.project.settings.columns;
    previousColumnCount = currentColumns;
  }

  void _syncSelectedSolutionCommandSelection() {
    final selectedCommandId = selectedSolutionCommandId;
    if (selectedCommandId == null) {
      final selectedLoopId = selectedLoopInsertionTargetId;
      if (selectedLoopId == null) {
        return;
      }

      final selectedLoopNode = controller.solutionCommandById(selectedLoopId);
      if (selectedLoopNode == null || !selectedLoopNode.isLoop) {
        selectedLoopInsertionTargetId = null;
      }
      return;
    }

    if (!controller.containsSolutionCommand(selectedCommandId)) {
      selectedSolutionCommandId = null;
    }

    final selectedLoopId = selectedLoopInsertionTargetId;
    if (selectedLoopId == null) {
      return;
    }

    final selectedLoopNode = controller.solutionCommandById(selectedLoopId);
    if (selectedLoopNode == null || !selectedLoopNode.isLoop) {
      selectedLoopInsertionTargetId = null;
    }
  }

  void _setLogicSelection(String? commandId, {String? loopInsertionTargetId}) {
    selectedSolutionCommandId = commandId;

    if (loopInsertionTargetId != null) {
      selectedLoopInsertionTargetId = loopInsertionTargetId;
      return;
    }

    if (commandId == null) {
      selectedLoopInsertionTargetId = null;
      return;
    }

    final selectedNode = controller.solutionCommandById(commandId);
    if (selectedNode?.isLoop == true) {
      selectedLoopInsertionTargetId = commandId;
      return;
    }

    selectedLoopInsertionTargetId = null;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    final project = controller.project;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: language.t('builder.gameName'),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.titleLarge,
            cursorColor: Colors.black,
            maxLines: 1,
            onChanged: _handleTitleChanged,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: controller.isSaving ? null : _handlePublishPressed,
                child: Text(
                  controller.isSaving
                      ? language.t('builder.saving')
                      : language.t('builder.publish'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: controller.isSaving ? null : _handleSavePressed,
                child: Text(
                  controller.isSaving
                      ? language.t('builder.saving')
                      : language.t('builder.save'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Container(
                    color: const Color(0xFFEAF6FF),
                    child: Row(
                      children: [
                        Container(
                          width: _leftPanelWidth,
                          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            border: Border(
                              right: BorderSide(
                                color: Colors.blueGrey.shade100,
                              ),
                            ),
                          ),
                          child: _buildLeftPanel(),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: _buildFixedGameWindow(project),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: Center(child: _buildTrashBin()),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleSavePressed() async {
    setState(() {
      hasAttemptedSave = true;
    });

    final saveSucceeded = await controller.saveProject();

    if (!mounted) {
      return;
    }

    if (saveSucceeded) {
      _showNotification(
        message:
            controller.lastMessage ??
            AppLanguage.instance.t('builder.savedSuccessfully'),
        backgroundColor: Colors.green.shade600,
      );
      return;
    }

    if (controller.hasBlockingValidationIssues) {
      _showNotification(
        message: _buildValidationNotificationMessage(),
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    _showNotification(
      message:
          controller.lastMessage ??
          AppLanguage.instance.t('builder.saveFailedGeneric'),
      backgroundColor: Colors.red.shade600,
    );
  }

  Future<void> _handlePublishPressed() async {
    setState(() {
      hasAttemptedSave = true;
    });

    if (controller.hasBlockingValidationIssues) {
      _showNotification(
        message: _buildValidationNotificationMessage(),
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final selectedDifficulty = await _showDifficultyPickerDialog(
      suggestedDifficulty: controller.suggestedDifficulty,
    );
    if (!mounted || selectedDifficulty == null) {
      return;
    }

    final publishSucceeded = await controller.publishProject(
      difficultyOverride: selectedDifficulty,
    );

    if (!mounted) {
      return;
    }

    if (publishSucceeded) {
      _showNotification(
        message:
            controller.lastMessage ??
            AppLanguage.instance.t('builder.publishedSuccessfully'),
        backgroundColor: Colors.green.shade600,
      );
      return;
    }

    if (controller.hasBlockingValidationIssues) {
      _showNotification(
        message: _buildValidationNotificationMessage(),
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    _showNotification(
      message:
          controller.lastMessage ??
          AppLanguage.instance.t('builder.publishFailedGeneric'),
      backgroundColor: Colors.red.shade600,
    );
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

    setState(() {
      hasAttemptedSave = false;
      _setLogicSelection(null);
    });

    controller.clearLevel();

    if (!mounted) {
      return;
    }

    _showNotification(
      message: AppLanguage.instance.t('builder.levelCleared'),
      backgroundColor: Colors.blueGrey.shade700,
    );
  }

  void _handlePrintSolutionPressed() {
    final result = const FrontViewSolver().findShortestPath(
      project: controller.project,
      requireAllCollectablesForSuccess:
          controller.requireAllCollectablesForSuccess,
    );

    if (!result.solved) {
      debugPrint('No solution found');
      return;
    }

    final commands = const FrontViewSolutionConverter().convert(result.actions);
    if (commands.isEmpty) {
      debugPrint('No solution found');
      return;
    }

    _setLogicSelection(null);
    controller.replaceSolutionCommands(commands);
    // debugPrint(_formatGeneratedSolutionCommands(commands).join('\n'));
  }

  // List<String> _formatGeneratedSolutionCommands(
  //   List<LogicCommandNode> commands, {
  //   int indent = 0,
  // }) {
  //   final lines = <String>[];
  //   final prefix = '  ' * indent;
  //
  //   for (final command in commands) {
  //     lines.add('$prefix${command.label}');
  //     if (command.children.isNotEmpty) {
  //       lines.addAll(
  //         _formatGeneratedSolutionCommands(
  //           command.children,
  //           indent: indent + 1,
  //         ),
  //       );
  //     }
  //   }
  //
  //   return lines;
  // }

  void _showNotification({
    required String message,
    required Color backgroundColor,
  }) {
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

  String _buildValidationNotificationMessage() {
    final issues = <String>[
      ...controller.validation.errors,
      ...controller.validation.warnings,
    ];

    if (issues.isEmpty) {
      return controller.lastMessage ??
          AppLanguage.instance.t('builder.addRequiredItems');
    }

    return AppLanguage.instance.t(
      'builder.addRequiredItemsPrefix',
      params: {'issues': issues.join(' ')},
    );
  }

  Widget _buildLeftPanel() {
    return ListView(
      children: [
        _buildPanelSection(
          title: AppLanguage.of(context).t('builder.tools'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuilderToolbar(controller: controller, direction: Axis.vertical),
              const SizedBox(height: 12),
              _buildCharacterControl(),
              const SizedBox(height: 12),
              _buildInitialDirectionControl(),
              const SizedBox(height: 12),
              _buildCollectableControl(),
              const SizedBox(height: 12),
              _buildBackgroundControl(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildPanelSection(
          title: 'Custom assets',
          child: _buildCustomAssetsPanel(),
        ),
        const SizedBox(height: 14),
        _buildPanelSection(
          title: AppLanguage.of(context).t('builder.grid'),
          child: _buildTileSizeControls(),
        ),
        const SizedBox(height: 14),
        _buildPanelSection(
          title: AppLanguage.of(context).t('builder.levelActions'),
          child: _buildLevelActions(),
        ),
        const SizedBox(height: 14),
        _buildPanelSection(
          title: AppLanguage.of(context).t('builder.levelInfo'),
          child: BuilderStatusBar(
            controller: controller,
            showValidation: hasAttemptedSave,
          ),
        ),
        if (controller.lastMessage != null) ...[
          const SizedBox(height: 14),
          _buildMessageCard(
            text: controller.lastMessage!,
            backgroundColor: Colors.blue.shade50,
            textColor: Colors.blueGrey.shade900,
          ),
        ],
        if (hasAttemptedSave && controller.hasBlockingValidationIssues) ...[
          const SizedBox(height: 14),
          _buildValidationCard(),
        ],
      ],
    );
  }

  Widget _buildFixedGameWindow(BuilderProject project) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = project.settings.columns * project.settings.tileSize;
        final boardHeight = project.settings.rows * project.settings.tileSize;
        final viewportWidth = math.min(
          project.settings.viewportWidth,
          constraints.maxWidth,
        );
        final viewportHeight = math.min(
          project.settings.viewportHeight,
          constraints.maxHeight,
        );
        final protectedGroundHeight =
            LevelSettings.requiredGroundRowsForTileSize(
              project.settings.tileSize,
            ) *
            project.settings.tileSize;
        final canvasWidth = math.max(boardWidth, viewportWidth);
        final canvasHeight = math.max(boardHeight, viewportHeight);

        return Container(
          width: viewportWidth,
          height: viewportHeight,
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              ClipRect(
                child: Scrollbar(
                  controller: verticalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: verticalScrollController,
                    child: Scrollbar(
                      controller: horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      notificationPredicate: (notification) {
                        return notification.metrics.axis == Axis.horizontal;
                      },
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: canvasWidth,
                          height: canvasHeight,
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: boardWidth,
                              height: boardHeight,
                              child: _buildBoardToolDropTarget(
                                project: project,
                                child: GameWidget(game: game, autofocus: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: -6,
                child: _buildLogicOverlay(
                  project: project,
                  viewportHeight: viewportHeight,
                  maxGroundOverlayHeight: protectedGroundHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrashBin() {
    final isVisible = isBoardGridDragActive || isLogicDragActive;

    return DragTarget<_BoardGridDragData>(
      onWillAcceptWithDetails: (details) => isBoardGridDragActive,
      onAcceptWithDetails: (details) {
        final dragData = details.data;
        if (dragData.isEntity) {
          controller.deleteEntity(dragData.entityId!);
          return;
        }

        controller.deleteTileAt(dragData.fromX, dragData.fromY);
      },
      builder: (context, boardCandidateData, rejectedData) {
        return DragTarget<_LogicDragData>(
          onWillAcceptWithDetails: (details) {
            return isLogicDragActive && details.data.existingCommandId != null;
          },
          onAcceptWithDetails: (details) {
            final commandId = details.data.existingCommandId;
            if (commandId == null) {
              return;
            }

            controller.removeSolutionCommand(commandId);
          },
          builder: (context, logicCandidateData, rejectedLogicData) {
            final isHighlighted =
                boardCandidateData.isNotEmpty || logicCandidateData.isNotEmpty;

            return AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              offset: isVisible ? Offset.zero : const Offset(0, 1.25),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: isVisible ? 1 : 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.red.shade600
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isHighlighted
                          ? Colors.red.shade300
                          : Colors.blueGrey.shade100,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isHighlighted ? 0.22 : 0.1,
                        ),
                        blurRadius: isHighlighted ? 28 : 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: isHighlighted
                            ? Colors.white
                            : Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLanguage.of(context).t('builder.dropToDelete'),
                        style: TextStyle(
                          color: isHighlighted
                              ? Colors.white
                              : Colors.blueGrey.shade900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogicOverlay({
    required BuilderProject project,
    required double viewportHeight,
    required double maxGroundOverlayHeight,
  }) {
    final commands = controller.solutionCommands;
    final playbackState = controller.playbackState;
    final selectedCommandId = selectedSolutionCommandId;
    final selectedLoopTargetId = selectedLoopInsertionTargetId;
    final selectedCommand = selectedCommandId == null
        ? null
        : controller.solutionCommandById(selectedCommandId);
    final selectedCommandKey = selectedCommand?.id;
    final activeCommandId = playbackState?.activeCommandId;
    final panelHeight = math.min(
      math.min(viewportHeight, maxGroundOverlayHeight),
      maxGroundOverlayHeight,
    );
    final canEditCommands = !controller.isPlaybackRunning;
    final hasSelectedCommand = selectedCommandKey != null;

    return Material(
      elevation: 10,
      color: Colors.transparent,
      child: Container(
        height: panelHeight,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: Colors.blueGrey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final command in LogicCommandType.values) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildLogicCommandPaletteButton(
                              command: command,
                              enabled: canEditCommands,
                              targetLoopId: selectedLoopTargetId,
                            ),
                          ),
                        ],
                        _buildLogicLoopPaletteButton(
                          enabled: canEditCommands,
                          targetLoopId: selectedLoopTargetId,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controller.isPlaybackRunning
                      ? () {
                          controller.stopPlayback();
                        }
                      : () {
                          controller.playSolution();
                        },
                  tooltip: controller.isPlaybackRunning
                      ? AppLanguage.of(context).t('builder.stop')
                      : AppLanguage.of(context).t('builder.play'),
                  style: IconButton.styleFrom(
                    backgroundColor: controller.isPlaybackRunning
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    side: BorderSide(
                      color: controller.isPlaybackRunning
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  ),
                  icon: Icon(
                    controller.isPlaybackRunning
                        ? Icons.stop
                        : Icons.play_arrow,
                    color: controller.isPlaybackRunning
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  onPressed: controller.playbackState != null
                      ? () {
                          controller.resetPlaybackPreview();
                        }
                      : null,
                  tooltip: AppLanguage.of(context).t('builder.reset'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.amber.shade50,
                    side: BorderSide(color: Colors.amber.shade200),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  ),
                  icon: Icon(
                    Icons.restart_alt_rounded,
                    color: Colors.amber.shade800,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  onPressed: canEditCommands && commands.isNotEmpty
                      ? () {
                          setState(() {
                            _setLogicSelection(null);
                          });
                          controller.clearSolutionCommands();
                        }
                      : null,
                  tooltip: AppLanguage.of(context).t('builder.clear'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade50,
                    side: BorderSide(color: Colors.blueGrey.shade100),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildLogicSequenceStrip(
                      commands: commands,
                      parentLoopId: null,
                      selectedCommandId: selectedCommandId,
                      activeCommandId: activeCommandId,
                      canEditCommands: canEditCommands,
                      isRoot: true,
                      rootViewportWidth: constraints.maxWidth,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.logicStatusMessage ??
                        (selectedLoopTargetId == null
                            ? AppLanguage.of(context).t('builder.logicHelp')
                            : AppLanguage.of(
                                context,
                              ).t('builder.logicLoopHelp')),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed:
                      canEditCommands &&
                          hasSelectedCommand &&
                          controller.canMoveSolutionCommand(
                            selectedCommandKey,
                            -1,
                          )
                      ? () {
                          controller.moveSolutionCommandByOffset(
                            selectedCommandKey,
                            -1,
                          );
                        }
                      : null,
                  tooltip: AppLanguage.of(context).t('builder.moveLeft'),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(4),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 16),
                ),
                IconButton(
                  onPressed: canEditCommands && hasSelectedCommand
                      ? () {
                          final commandId = selectedCommandKey;
                          final nextLoopTargetId =
                              selectedLoopInsertionTargetId == commandId
                              ? null
                              : selectedLoopInsertionTargetId;
                          setState(() {
                            _setLogicSelection(
                              null,
                              loopInsertionTargetId: nextLoopTargetId,
                            );
                          });
                          controller.removeSolutionCommand(commandId);
                        }
                      : null,
                  tooltip: AppLanguage.of(context).t('builder.remove'),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(4),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                ),
                IconButton(
                  onPressed:
                      canEditCommands &&
                          hasSelectedCommand &&
                          controller.canMoveSolutionCommand(
                            selectedCommandKey,
                            1,
                          )
                      ? () {
                          controller.moveSolutionCommandByOffset(
                            selectedCommandKey,
                            1,
                          );
                        }
                      : null,
                  tooltip: AppLanguage.of(context).t('builder.moveRight'),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(4),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardToolDropTarget({
    required BuilderProject project,
    required Widget child,
  }) {
    return _BoardToolDropLayer(
      controller: controller,
      project: project,
      onGridDragStateChanged: _handleBoardGridDragStateChanged,
      child: child,
    );
  }

  Widget _buildLogicCommandPaletteButton({
    required LogicCommandType command,
    required bool enabled,
    required String? targetLoopId,
  }) {
    final baseColor = _logicCommandColor(command);
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                final newCommandId = controller.addSolutionCommand(
                  command,
                  parentLoopId: targetLoopId,
                );
                setState(() {
                  _setLogicSelection(
                    newCommandId,
                    loopInsertionTargetId: targetLoopId,
                  );
                });
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: enabled ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: baseColor.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _logicCommandIcon(command),
                size: 12,
                color: enabled ? baseColor : baseColor.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 4),
              Text(
                _logicCommandChipLabel(command),
                style: TextStyle(
                  color: enabled
                      ? baseColor
                      : baseColor.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!enabled) {
      return chip;
    }

    final dragData = _LogicDragData.newAction(command);

    return Draggable<_LogicDragData>(
      data: dragData,
      dragAnchorStrategy: _logicGhostDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.95, child: chip),
      ),
      maxSimultaneousDrags: 1,
      childWhenDragging: Opacity(opacity: 0.45, child: chip),
      onDragStarted: () {
        _handleLogicDragStarted(dragData);
      },
      onDragUpdate: (details) {
        _handleLogicDragUpdated(dragData, details);
      },
      onDragEnd: (details) {
        _handleLogicDragEnded(dragData, details);
      },
      child: chip,
    );
  }

  Widget _buildLogicLoopPaletteButton({
    required bool enabled,
    required String? targetLoopId,
  }) {
    final loopColor = Colors.orange.shade700;
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                final newLoopId = controller.addLoopCommand(
                  parentLoopId: targetLoopId,
                );
                setState(() {
                  _setLogicSelection(
                    newLoopId,
                    loopInsertionTargetId: newLoopId,
                  );
                });
              }
            : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: loopColor.withValues(alpha: enabled ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: loopColor.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.loop,
                size: 13,
                color: enabled ? loopColor : loopColor.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 4),
              Text(
                AppLanguage.of(context).t('builder.loop'),
                style: TextStyle(
                  color: enabled
                      ? loopColor
                      : loopColor.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!enabled) {
      return chip;
    }

    const dragData = _LogicDragData.newLoop();

    return Draggable<_LogicDragData>(
      data: dragData,
      dragAnchorStrategy: _logicGhostDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.95, child: chip),
      ),
      maxSimultaneousDrags: 1,
      childWhenDragging: Opacity(opacity: 0.45, child: chip),
      onDragStarted: () {
        _handleLogicDragStarted(dragData);
      },
      onDragUpdate: (details) {
        _handleLogicDragUpdated(dragData, details);
      },
      onDragEnd: (details) {
        _handleLogicDragEnded(dragData, details);
      },
      child: chip,
    );
  }

  Widget _buildLogicSequenceStrip({
    required List<LogicCommandNode> commands,
    required String? parentLoopId,
    required String? selectedCommandId,
    required String? activeCommandId,
    required bool canEditCommands,
    required bool isRoot,
    double? rootViewportWidth,
  }) {
    if (commands.isEmpty) {
      return _buildLogicInsertZone(
        target: _LogicDropTarget(parentLoopId: parentLoopId, index: 0),
        canEditCommands: canEditCommands,
        isRoot: isRoot,
        isEmptySequence: true,
        preferredWidth: isRoot
            ? math.max(280.0, rootViewportWidth ?? 280.0)
            : null,
      );
    }

    final children = <Widget>[];
    for (int index = 0; index < commands.length; index++) {
      children.add(
        _buildLogicInsertZone(
          target: _LogicDropTarget(parentLoopId: parentLoopId, index: index),
          canEditCommands: canEditCommands,
          isRoot: isRoot,
          preferredWidth: isRoot ? 12.0 : null,
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: _buildDraggableLogicNode(
            node: commands[index],
            selectedCommandId: selectedCommandId,
            activeCommandId: activeCommandId,
            canEditCommands: canEditCommands,
            isRoot: isRoot,
          ),
        ),
      );
    }
    children.add(
      _buildLogicInsertZone(
        target: _LogicDropTarget(
          parentLoopId: parentLoopId,
          index: commands.length,
        ),
        canEditCommands: canEditCommands,
        isRoot: isRoot,
        preferredWidth: isRoot
            ? math.max(180.0, rootViewportWidth ?? 180.0)
            : null,
        showIdlePlaceholder: isRoot,
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isRoot
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: children,
    );

    if (!isRoot) {
      return row;
    }

    return IntrinsicHeight(child: row);
  }

  Widget _buildDraggableLogicNode({
    required LogicCommandNode node,
    required String? selectedCommandId,
    required String? activeCommandId,
    required bool canEditCommands,
    required bool isRoot,
  }) {
    final content = _buildLogicCommandNode(
      node: node,
      selectedCommandId: selectedCommandId,
      activeCommandId: activeCommandId,
      canEditCommands: canEditCommands,
      isRoot: isRoot,
    );

    if (!canEditCommands) {
      return content;
    }

    final dragData = _LogicDragData.existing(node.id);

    return Draggable<_LogicDragData>(
      data: dragData,
      dragAnchorStrategy: _logicGhostDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.94, child: content),
      ),
      maxSimultaneousDrags: 1,
      childWhenDragging: Opacity(opacity: 0.35, child: content),
      onDragStarted: () {
        _handleLogicDragStarted(dragData);
      },
      onDragUpdate: (details) {
        _handleLogicDragUpdated(dragData, details);
      },
      onDragEnd: (details) {
        _handleLogicDragEnded(dragData, details);
      },
      child: content,
    );
  }

  Widget _buildLogicCommandNode({
    required LogicCommandNode node,
    required String? selectedCommandId,
    required String? activeCommandId,
    required bool canEditCommands,
    required bool isRoot,
  }) {
    if (node.isLoop) {
      return _buildLoopLogicBlock(
        node: node,
        isSelected: node.id == selectedCommandId,
        isActive: _commandContainsId(node, activeCommandId),
        selectedCommandId: selectedCommandId,
        activeCommandId: activeCommandId,
        canEditCommands: canEditCommands,
        isRoot: isRoot,
      );
    }

    return _buildActionLogicBlock(
      node: node,
      isSelected: node.id == selectedCommandId,
      isActive: node.id == activeCommandId,
      canEditCommands: canEditCommands,
      isRoot: isRoot,
    );
  }

  Widget _buildActionLogicBlock({
    required LogicCommandNode node,
    required bool isSelected,
    required bool isActive,
    required bool canEditCommands,
    required bool isRoot,
  }) {
    final command = node.command!;
    final baseColor = _logicCommandColor(command);
    final blockWidth = isRoot ? 46.0 : 40.0;
    final horizontalPadding = isRoot ? 5.0 : 4.0;
    final verticalPadding = isRoot ? 6.0 : 2.0;
    final iconSize = isRoot ? 16.0 : 13.0;
    final spacing = isRoot ? 3.0 : 1.0;
    final labelFontSize = isRoot ? 9.0 : 8.0;

    return GestureDetector(
      onTap: canEditCommands
          ? () {
              setState(() {
                _setLogicSelection(node.id);
              });
            }
          : null,
      child: Container(
        width: blockWidth,
        constraints: isRoot
            ? const BoxConstraints(minHeight: _rootLogicLaneHeight)
            : null,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.green.shade500
                : isSelected
                ? Colors.blue.shade600
                : baseColor.withValues(alpha: 0.34),
            width: isActive || isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_logicCommandIcon(command), color: baseColor, size: iconSize),
            SizedBox(height: spacing),
            Text(
              _logicCommandTokenLabel(command),
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w700,
                fontSize: labelFontSize,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoopLogicBlock({
    required LogicCommandNode node,
    required bool isSelected,
    required bool isActive,
    required String? selectedCommandId,
    required String? activeCommandId,
    required bool canEditCommands,
    required bool isRoot,
  }) {
    final borderColor = isActive
        ? Colors.green.shade500
        : isSelected
        ? Colors.orange.shade700
        : Colors.orange.shade300;
    final outerPadding = isRoot
        ? const EdgeInsets.fromLTRB(4, 3, 4, 3)
        : const EdgeInsets.fromLTRB(6, 7, 5, 7);
    final innerPadding = isRoot
        ? const EdgeInsets.symmetric(horizontal: 2, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 3, vertical: 3);

    return GestureDetector(
      onTap: canEditCommands
          ? () {
              setState(() {
                _setLogicSelection(node.id, loopInsertionTargetId: node.id);
              });
            }
          : null,
      child: Container(
        constraints: isRoot
            ? const BoxConstraints(minHeight: _rootLogicLaneHeight)
            : null,
        padding: outerPadding,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isActive || isSelected ? 2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200.withValues(alpha: 0.34),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isRoot
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: innerPadding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.66),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: _buildLogicSequenceStrip(
                commands: node.children,
                parentLoopId: node.id,
                selectedCommandId: selectedCommandId,
                activeCommandId: activeCommandId,
                canEditCommands: canEditCommands,
                isRoot: false,
              ),
            ),
            SizedBox(width: isRoot ? 4 : 5),
            Container(
              width: isRoot ? 32 : 38,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.shade300,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade300.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.loop,
                color: Colors.white,
                size: isRoot ? 16 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicInsertZone({
    required _LogicDropTarget target,
    required bool canEditCommands,
    required bool isRoot,
    bool isEmptySequence = false,
    double? preferredWidth,
    bool showIdlePlaceholder = false,
  }) {
    return _LogicDropTargetMeasure(
      target: target,
      onRectChanged: _handleLogicDropTargetRectChanged,
      child: DragTarget<_LogicDragData>(
        onWillAcceptWithDetails: canEditCommands
            ? (details) => _canAcceptLogicDrop(details.data, target)
            : null,
        onAcceptWithDetails: canEditCommands
            ? (details) => _handleLogicDrop(details.data, target)
            : null,
        builder: (context, candidateData, rejectedData) {
          final isHighlighted = _isLogicDropTargetHighlighted(
            target,
            candidateData,
          );
          final width =
              preferredWidth ??
              (isEmptySequence
                  ? (isRoot ? 240.0 : 22.0)
                  : (isRoot ? 8.0 : 6.0));
          final showPlaceholder =
              isHighlighted ||
              (isRoot && isEmptySequence) ||
              (showIdlePlaceholder && isRoot);
          final showBackground =
              isHighlighted ||
              (isRoot && isEmptySequence) ||
              (showIdlePlaceholder && isRoot);
          final showWideLabel =
              isRoot && (isEmptySequence || showIdlePlaceholder);
          final labelText = isEmptySequence
              ? AppLanguage.of(context).t('builder.dropHere')
              : AppLanguage.of(context).t('builder.dropHereToAdd');
          final isIdleRootPlaceholder =
              showIdlePlaceholder &&
              isRoot &&
              !isHighlighted &&
              !isEmptySequence;
          final backgroundColor = !showBackground
              ? Colors.transparent
              : isHighlighted
              ? Colors.blue.shade50
              : isIdleRootPlaceholder
              ? Colors.blueGrey.shade50.withValues(alpha: 0.26)
              : Colors.blueGrey.shade50.withValues(alpha: 0.7);
          final borderColor = !showBackground
              ? Colors.transparent
              : isHighlighted
              ? Colors.blue.shade400
              : isIdleRootPlaceholder
              ? Colors.blueGrey.shade300.withValues(alpha: 0.42)
              : Colors.blueGrey.shade200;
          final placeholderColor = isHighlighted
              ? Colors.blue.shade700
              : isIdleRootPlaceholder
              ? Colors.blueGrey.shade500.withValues(alpha: 0.82)
              : Colors.blueGrey.shade600;
          final minHeight = isRoot ? _rootLogicLaneHeight : 44.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: width,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: showWideLabel && showPlaceholder
                ? EdgeInsets.symmetric(
                    horizontal: isRoot ? 10 : 8,
                    vertical: isRoot ? 10 : 8,
                  )
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(isEmptySequence ? 16 : 10),
              border: Border.all(
                color: borderColor,
                width: isHighlighted ? 2 : 1.2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: showPlaceholder
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final placeholderIcon = Icon(
                        Icons.add_rounded,
                        color: isHighlighted
                            ? Colors.blue.shade600
                            : placeholderColor,
                        size: isRoot ? 17 : 16,
                      );
                      final canShowWidePlaceholder =
                          showWideLabel && constraints.maxWidth >= 92;

                      if (!canShowWidePlaceholder) {
                        return Center(child: placeholderIcon);
                      }

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: isHighlighted
                                  ? Colors.blue.shade600
                                  : placeholderColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                labelText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: placeholderColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  bool _commandContainsId(LogicCommandNode node, String? commandId) {
    if (commandId == null) {
      return false;
    }

    if (node.id == commandId) {
      return true;
    }

    for (final child in node.children) {
      if (_commandContainsId(child, commandId)) {
        return true;
      }
    }

    return false;
  }

  bool _canAcceptLogicDrop(_LogicDragData data, _LogicDropTarget target) {
    if (data.existingCommandId == null) {
      return true;
    }

    if (target.parentLoopId == null) {
      return true;
    }

    return data.existingCommandId != target.parentLoopId;
  }

  void _handleLogicDrop(_LogicDragData data, _LogicDropTarget target) {
    if (data.existingCommandId != null) {
      final commandId = data.existingCommandId!;
      final didMove = controller.moveSolutionCommand(
        commandId: commandId,
        targetLoopId: target.parentLoopId,
        targetIndex: target.index,
      );
      if (!didMove || !mounted) {
        return;
      }

      setState(() {
        _setLogicSelection(
          commandId,
          loopInsertionTargetId: target.parentLoopId,
        );
      });
      return;
    }

    if (data.command != null) {
      final newCommandId = controller.addSolutionCommand(
        data.command!,
        parentLoopId: target.parentLoopId,
        targetIndex: target.index,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _setLogicSelection(
          newCommandId,
          loopInsertionTargetId: target.parentLoopId,
        );
      });
      return;
    }

    if (!data.isLoop) {
      return;
    }

    final newLoopId = controller.addLoopCommand(
      parentLoopId: target.parentLoopId,
      targetIndex: target.index,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _setLogicSelection(newLoopId, loopInsertionTargetId: newLoopId);
    });
  }

  IconData _logicCommandIcon(LogicCommandType command) {
    switch (command) {
      case LogicCommandType.moveLeft:
        return Icons.arrow_back;
      case LogicCommandType.moveRight:
        return Icons.arrow_forward;
      case LogicCommandType.jumpUp:
        return Icons.arrow_upward;
      case LogicCommandType.climbUpLeft:
        return Icons.north_west;
      case LogicCommandType.climbUpRight:
        return Icons.north_east;
    }
  }

  Color _logicCommandColor(LogicCommandType command) {
    switch (command) {
      case LogicCommandType.moveLeft:
        return const Color(0xFF0F766E);
      case LogicCommandType.moveRight:
        return const Color(0xFF2563EB);
      case LogicCommandType.jumpUp:
        return const Color(0xFFD97706);
      case LogicCommandType.climbUpLeft:
        return const Color(0xFF7C3AED);
      case LogicCommandType.climbUpRight:
        return const Color(0xFFDC2626);
    }
  }

  String _logicCommandChipLabel(LogicCommandType command) {
    switch (command) {
      case LogicCommandType.moveLeft:
        return AppLanguage.instance.t('builder.left');
      case LogicCommandType.moveRight:
        return AppLanguage.instance.t('builder.right');
      case LogicCommandType.jumpUp:
        return AppLanguage.instance.t('builder.jump');
      case LogicCommandType.climbUpLeft:
        return AppLanguage.instance.t('builder.upLeftShort');
      case LogicCommandType.climbUpRight:
        return AppLanguage.instance.t('builder.upRightShort');
    }
  }

  String _logicCommandTokenLabel(LogicCommandType command) {
    switch (command) {
      case LogicCommandType.moveLeft:
        return AppLanguage.instance.t('builder.leftShort');
      case LogicCommandType.moveRight:
        return AppLanguage.instance.t('builder.rightShort');
      case LogicCommandType.jumpUp:
        return AppLanguage.instance.t('builder.upShort');
      case LogicCommandType.climbUpLeft:
        return AppLanguage.instance.t('builder.upLeftToken');
      case LogicCommandType.climbUpRight:
        return AppLanguage.instance.t('builder.upRightToken');
    }
  }

  Widget _buildPanelSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTileSizeControls() {
    final settings = controller.project.settings;
    final selectedPreset = LevelSettings.closestPresetForTileSize(
      settings.tileSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.gridSquareSize'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final preset in BuilderGridSizePreset.values) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: preset == BuilderGridSizePreset.large ? 0 : 8,
                  ),
                  child: OutlinedButton(
                    onPressed: () => controller.setGridSizePreset(preset),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selectedPreset == preset
                          ? Colors.blue.shade600
                          : Colors.white,
                      foregroundColor: selectedPreset == preset
                          ? Colors.white
                          : Colors.blueGrey.shade900,
                      side: BorderSide(
                        color: selectedPreset == preset
                            ? Colors.blue.shade600
                            : Colors.blueGrey.shade200,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          preset.shortLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${preset.columns} x ${preset.rows}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          AppLanguage.of(context).t(
            'builder.tileSizeDescription',
            params: {
              'label': selectedPreset.label,
              'tileSize': settings.tileSize.round().toString(),
              'columns': settings.columns.toString(),
              'rows': settings.rows.toString(),
            },
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 6),
        Text(
          AppLanguage.of(context).t('builder.gridPresetDescription'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
        ),
      ],
    );
  }

  Widget _buildLevelActions() {
    final selectedPreset = LevelSettings.closestPresetForTileSize(
      controller.project.settings.tileSize,
    );
    final protectedGroundRows = selectedPreset.groundRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: _handlePrintSolutionPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
            minimumSize: const Size.fromHeight(46),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.layers_clear_outlined, size: 18),
          label: Text(
            AppLanguage.of(context).t('builder.clearLevel'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLanguage.of(context).t(
            'builder.clearLevelDescription',
            params: {
              'rows': protectedGroundRows.toString(),
              'label': selectedPreset.label.toLowerCase(),
            },
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
        ),
      ],
    );
  }

  Widget _buildInitialDirectionControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.direction'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            selected: <String>{controller.playerInitialDirection},
            segments: [
              ButtonSegment<String>(
                value: BuilderController.playerFacingLeft,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: AppLanguage.of(context).t('builder.faceLeft'),
              ),
              ButtonSegment<String>(
                value: BuilderController.playerFacingRight,
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: AppLanguage.of(context).t('builder.faceRight'),
              ),
            ],
            onSelectionChanged: controller.isPlaybackRunning
                ? null
                : (selection) {
                    controller.setPlayerInitialDirection(selection.first);
                  },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterControl() {
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
          key: ValueKey<String>(controller.playerCharacterId),
          initialValue: controller.playerCharacterId,
          isExpanded: true,
          items: [
            for (final character in builderCharacters)
              DropdownMenuItem<String>(
                value: character.id,
                child: _buildCharacterMenuItem(character),
              ),
          ],
          onChanged: controller.isPlaybackRunning
              ? null
              : (characterId) {
                  if (characterId == null) {
                    return;
                  }

                  controller.setPlayerCharacter(characterId);
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

  Widget _buildCharacterMenuItem(BuilderCharacter character) {
    return Row(
      children: [
        Image.asset(
          character.idlePreviewAssetPath,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 24, height: 24);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedBuilderCharacterLabel(
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

  Widget _buildCollectableControl() {
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
          key: ValueKey<String>(controller.collectableItemId),
          initialValue: controller.collectableItemId,
          isExpanded: true,
          items: [
            for (final collectable in builderCollectables)
              DropdownMenuItem<String>(
                value: collectable.id,
                child: _buildCollectableMenuItem(collectable),
              ),
          ],
          onChanged: controller.isPlaybackRunning
              ? null
              : (collectableId) {
                  if (collectableId == null) {
                    return;
                  }

                  controller.setCollectableItem(collectableId);
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

  Widget _buildCollectableMenuItem(BuilderCollectable collectable) {
    return Row(
      children: [
        Image.asset(
          collectable.flutterAssetPath,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(width: 22, height: 22);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            localizedBuilderCollectableLabel(
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

  Widget _buildBackgroundControl() {
    final activeBackgroundAsset = controller.customAssetById(
      controller.project.backgroundAssetId,
    );
    final selectedBackgroundId =
        activeBackgroundAsset?.id ?? _defaultBackgroundId;

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
            DropdownMenuItem<String>(
              value: _defaultBackgroundId,
              child: _buildDefaultBackgroundMenuItem(),
            ),
            if (activeBackgroundAsset != null)
              DropdownMenuItem<String>(
                value: activeBackgroundAsset.id,
                child: _buildCustomBackgroundMenuItem(activeBackgroundAsset),
              ),
          ],
          onChanged: controller.isPlaybackRunning
              ? null
              : (backgroundId) {
                  if (backgroundId == _defaultBackgroundId) {
                    controller.useDefaultBackground();
                  } else if (backgroundId != null) {
                    controller.setCustomBackgroundAsset(backgroundId);
                  }
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

  Widget _buildDefaultBackgroundMenuItem() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            _defaultBackgroundAssetPath,
            width: 30,
            height: 22,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 30, height: 22);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            _defaultBackgroundLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBackgroundMenuItem(CustomAssetData asset) {
    final bytes = controller.assetImageBytes(asset);
    if (bytes == null) {
      unawaited(controller.ensureAssetImageLoaded(asset));
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

  Widget _buildCustomAssetsPanel() {
    final assets = controller.project.customAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: controller.isPlaybackRunning ? null : _showAddAssetDialog,
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
    final isSelected = controller.currentCustomAssetId == asset.id;
    final accent = _customAssetTypeColor(asset.type);

    final item = InkWell(
      onTap: controller.isPlaybackRunning
          ? null
          : () {
              if (asset.type == CustomAssetType.background) {
                return;
              }

              controller.selectCustomAssetTool(asset.id);
            },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : Colors.blueGrey.shade100,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildFramedAssetPreview(
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
              onPressed: controller.isPlaybackRunning
                  ? null
                  : () => _showAssetEditorDialog(existingAsset: asset),
              icon: const Icon(Icons.settings_rounded, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );

    if (controller.isPlaybackRunning) {
      return item;
    }

    return Draggable<String>(
      data: asset.id,
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
                child: _buildFramedAssetPreview(
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
                subtitle: 'Use your creations or saved assets.',
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
                      Tab(text: 'Saved'),
                      Tab(text: 'Creations'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCollectionAssetList(
                          controller.savedCustomAssets,
                          dialogContext,
                        ),
                        _buildCollectionAssetList(
                          controller.createdCustomAssets,
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

    controller.useCustomAssetFromCollection(selectedAsset);
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
            child: _buildFramedAssetPreview(
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
      controller.setLastMessage('Image must be 2 MB or smaller.');
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
      controller.setLastMessage(
        uploadResult['message']?.toString() ?? 'Failed to upload asset.',
      );
      return;
    }

    final data = uploadResult['data'];
    final uploadedAssetId = data is Map
        ? (data['_id'] ?? data['id'])?.toString()
        : null;
    if (uploadedAssetId == null || uploadedAssetId.isEmpty) {
      controller.setLastMessage(
        'Upload finished but no asset id was returned.',
      );
      return;
    }

    final storedAsset = asset.copyWith(
      assetId: uploadedAssetId,
      imageBase64: '',
    );
    controller.cacheAssetImage(storedAsset.id, bytes);
    controller.addCustomAsset(storedAsset);
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
        (existingAsset == null
            ? null
            : controller.assetImageBytes(existingAsset));
    if (bytes == null) {
      return Future.value(null);
    }
    final nameController = TextEditingController(
      text: isEditing ? existingAsset.name : suggestedName,
    );
    var selectedType = existingAsset?.type ?? CustomAssetType.character;
    var frameScale = existingAsset?.frameScale ?? 1.0;
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

                      controller.removeCustomAssetFromLevel(existingAsset.id);
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
        controller.updateCustomAssetSettings(asset);
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

  Widget _buildFramedAssetPreview({
    required CustomAssetData asset,
    required double width,
    required double height,
  }) {
    final bytes = controller.assetImageBytes(asset);
    if (bytes == null) {
      unawaited(controller.ensureAssetImageLoaded(asset));
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
    return type == CustomAssetType.background
        ? controller.project.settings.viewportWidth /
              controller.project.settings.viewportHeight
        : 1;
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

  String _nameWithoutExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex <= 0) {
      return filename;
    }

    return filename.substring(0, dotIndex);
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

  Widget _buildMessageCard({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }

  Widget _buildValidationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.of(context)
                .t('builder.addRequiredItemsPrefix', params: {'issues': ''})
                .trim(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...controller.validation.errors.map(
            (error) =>
                Text('- $error', style: const TextStyle(color: Colors.red)),
          ),
          ...controller.validation.warnings.map(
            (warning) => Text(
              '- $warning',
              style: const TextStyle(color: Color(0xFF8A5A00)),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _BoardGridDragStateChanged = void Function(bool isDragging);

class _BoardToolDropLayer extends StatefulWidget {
  final BuilderController controller;
  final BuilderProject project;
  final _BoardGridDragStateChanged onGridDragStateChanged;
  final Widget child;

  const _BoardToolDropLayer({
    required this.controller,
    required this.project,
    required this.onGridDragStateChanged,
    required this.child,
  });

  @override
  State<_BoardToolDropLayer> createState() => _BoardToolDropLayerState();
}

class _BoardToolDropLayerState extends State<_BoardToolDropLayer> {
  final GlobalKey _boardDropTargetKey = GlobalKey();

  _BoardDropCell? hoveredToolCell;
  _BoardDropCell? hoveredGridDragCell;
  _BoardGridDragData? activeGridDrag;

  @override
  void dispose() {
    widget.onGridDragStateChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final tileSize = project.settings.tileSize;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !widget.controller.isPlaybackRunning &&
          widget.controller.customAssetById(details.data) != null,
      onMove: (details) {
        final asset = widget.controller.customAssetById(details.data);
        if (asset?.type == CustomAssetType.background) {
          _clearHoveredToolCell();
          return;
        }

        _updateHoveredToolCell(details.offset, project);
      },
      onLeave: (data) {
        _clearHoveredToolCell();
      },
      onAcceptWithDetails: (details) {
        if (widget.controller.isPlaybackRunning) {
          return;
        }

        final asset = widget.controller.customAssetById(details.data);
        if (asset?.type == CustomAssetType.background) {
          setState(() {
            hoveredToolCell = null;
          });
          widget.controller.setCustomBackgroundAsset(asset!.id);
          return;
        }

        final cell =
            hoveredToolCell ??
            _boardCellFromGlobalPosition(
              globalPosition: details.offset,
              project: project,
            );
        if (cell == null) {
          return;
        }

        setState(() {
          hoveredToolCell = null;
        });
        widget.controller.placeCustomAssetAt(details.data, cell.x, cell.y);
      },
      builder: (context, customCandidateData, rejectedCustomData) {
        return DragTarget<BuilderTool>(
          onWillAcceptWithDetails: (details) {
            return !widget.controller.isPlaybackRunning;
          },
          onMove: (details) {
            _updateHoveredToolCell(details.offset, project);
          },
          onLeave: (data) {
            _clearHoveredToolCell();
          },
          onAcceptWithDetails: (details) {
            if (widget.controller.isPlaybackRunning) {
              return;
            }

            final cell =
                hoveredToolCell ??
                _boardCellFromGlobalPosition(
                  globalPosition: details.offset,
                  project: project,
                );
            if (cell == null) {
              return;
            }

            setState(() {
              hoveredToolCell = null;
            });
            widget.controller.applyToolAt(details.data, cell.x, cell.y);
          },
          builder: (context, toolCandidateData, rejectedData) {
            return DragTarget<_BoardGridDragData>(
              onWillAcceptWithDetails: (details) {
                return !widget.controller.isPlaybackRunning;
              },
              onMove: (details) {
                final cell = _boardCellFromGlobalPosition(
                  globalPosition: details.offset,
                  project: project,
                );
                final hasChanged =
                    hoveredGridDragCell?.x != cell?.x ||
                    hoveredGridDragCell?.y != cell?.y;

                if (!hasChanged) {
                  return;
                }

                setState(() {
                  hoveredGridDragCell = cell;
                });
              },
              onLeave: (data) {
                if (hoveredGridDragCell == null) {
                  return;
                }

                setState(() {
                  hoveredGridDragCell = null;
                });
              },
              onAcceptWithDetails: (details) {
                final cell =
                    hoveredGridDragCell ??
                    _boardCellFromGlobalPosition(
                      globalPosition: details.offset,
                      project: project,
                    );
                final dragData = details.data;

                _stopGridDrag();

                if (cell == null) {
                  return;
                }

                if (dragData.isEntity) {
                  widget.controller.moveEntity(
                    dragData.entityId!,
                    cell.x,
                    cell.y,
                  );
                  return;
                }

                widget.controller.moveTile(
                  dragData.fromX,
                  dragData.fromY,
                  cell.x,
                  cell.y,
                );
              },
              builder: (context, _, rejectedGridData) {
                return SizedBox(
                  key: _boardDropTargetKey,
                  width: project.settings.columns * tileSize,
                  height: project.settings.rows * tileSize,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.child,
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            if (widget.controller.isPlaybackRunning ||
                                toolCandidateData.isNotEmpty ||
                                customCandidateData.isNotEmpty) {
                              return;
                            }

                            final cell = _boardCellFromLocalPosition(
                              localPosition: details.localPosition,
                              project: project,
                            );
                            if (cell == null) {
                              return;
                            }

                            _handleBoardTap(cell);
                          },
                        ),
                      ),
                      ..._buildGridItemDraggables(
                        tileSize: tileSize,
                        toolDragInProgress:
                            toolCandidateData.isNotEmpty ||
                            customCandidateData.isNotEmpty,
                      ),
                      if (activeGridDrag != null && hoveredGridDragCell != null)
                        Positioned(
                          left: hoveredGridDragCell!.x * tileSize,
                          top: hoveredGridDragCell!.y * tileSize,
                          child: IgnorePointer(
                            child: _buildDraggedGridPreview(
                              activeGridDrag!,
                              tileSize: tileSize,
                            ),
                          ),
                        ),
                      if (toolCandidateData.isNotEmpty &&
                          hoveredToolCell != null)
                        Positioned(
                          left: hoveredToolCell!.x * tileSize,
                          top: hoveredToolCell!.y * tileSize,
                          child: IgnorePointer(
                            child: _buildToolDropPreview(
                              toolCandidateData.first!,
                              tileSize: tileSize,
                            ),
                          ),
                        ),
                      if (customCandidateData.isNotEmpty &&
                          hoveredToolCell != null)
                        Positioned(
                          left: hoveredToolCell!.x * tileSize,
                          top: hoveredToolCell!.y * tileSize,
                          child: IgnorePointer(
                            child: _buildCustomAssetDropPreview(
                              customCandidateData.first!,
                              tileSize: tileSize,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateHoveredToolCell(Offset globalPosition, BuilderProject project) {
    final cell = _boardCellFromGlobalPosition(
      globalPosition: globalPosition,
      project: project,
    );
    final hasChanged =
        hoveredToolCell?.x != cell?.x || hoveredToolCell?.y != cell?.y;

    if (!hasChanged) {
      return;
    }

    setState(() {
      hoveredToolCell = cell;
    });
  }

  void _clearHoveredToolCell() {
    if (hoveredToolCell == null) {
      return;
    }

    setState(() {
      hoveredToolCell = null;
    });
  }

  List<Widget> _buildGridItemDraggables({
    required double tileSize,
    required bool toolDragInProgress,
  }) {
    final widgets = <Widget>[];
    final entityCells = <String>{};
    final playbackState = widget.controller.playbackState;

    for (final entity in widget.project.entities) {
      if (_shouldHideEntity(entity, playbackState)) {
        continue;
      }

      entityCells.add('${entity.x}:${entity.y}');
      widgets.add(_buildEntityDraggable(entity, tileSize, toolDragInProgress));
    }

    for (final tile in widget.project.tiles) {
      if (entityCells.contains('${tile.x}:${tile.y}')) {
        continue;
      }

      widgets.add(_buildTileDraggable(tile, tileSize, toolDragInProgress));
    }

    return widgets;
  }

  Widget _buildTileDraggable(
    TileData tile,
    double tileSize,
    bool toolDragInProgress,
  ) {
    return _buildBoardGridDraggable(
      left: tile.x * tileSize,
      top: tile.y * tileSize,
      tileSize: tileSize,
      dragData: _BoardGridDragData.tile(fromX: tile.x, fromY: tile.y),
      toolDragInProgress: toolDragInProgress,
      feedback: _buildGridTileFeedback(tile, tileSize),
      cell: _BoardDropCell(x: tile.x, y: tile.y),
    );
  }

  Widget _buildEntityDraggable(
    EntityData entity,
    double tileSize,
    bool toolDragInProgress,
  ) {
    return _buildBoardGridDraggable(
      left: entity.x * tileSize,
      top: entity.y * tileSize,
      tileSize: tileSize,
      dragData: _BoardGridDragData.entity(
        entityId: entity.id,
        fromX: entity.x,
        fromY: entity.y,
      ),
      toolDragInProgress: toolDragInProgress,
      feedback: _buildGridEntityFeedback(entity, tileSize),
      cell: _BoardDropCell(x: entity.x, y: entity.y),
    );
  }

  Widget _buildBoardGridDraggable({
    required double left,
    required double top,
    required double tileSize,
    required _BoardGridDragData dragData,
    required bool toolDragInProgress,
    required Widget feedback,
    required _BoardDropCell cell,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: tileSize,
      height: tileSize,
      child: Draggable<_BoardGridDragData>(
        data: dragData,
        maxSimultaneousDrags: 1,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(color: Colors.transparent, child: feedback),
        childWhenDragging: const SizedBox.expand(),
        onDragStarted: () {
          _startGridDrag(dragData, cell);
        },
        onDragEnd: (details) {
          _stopGridDrag();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (_) {
            if (widget.controller.isPlaybackRunning || toolDragInProgress) {
              return;
            }

            _handleBoardTap(cell);
          },
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  void _handleBoardTap(_BoardDropCell cell) {
    if (widget.controller.currentTool == BuilderTool.select) {
      widget.controller.selectAt(cell.x, cell.y);
      return;
    }

    widget.controller.placeAt(cell.x, cell.y);
  }

  void _startGridDrag(_BoardGridDragData dragData, _BoardDropCell cell) {
    widget.controller.selectAt(cell.x, cell.y);
    setState(() {
      activeGridDrag = dragData;
      hoveredGridDragCell = cell;
      hoveredToolCell = null;
    });
    _notifyGridDragState();
  }

  void _stopGridDrag() {
    if (activeGridDrag == null && hoveredGridDragCell == null) {
      return;
    }

    setState(() {
      activeGridDrag = null;
      hoveredGridDragCell = null;
    });
    _notifyGridDragState();
  }

  _BoardDropCell? _boardCellFromLocalPosition({
    required Offset localPosition,
    required BuilderProject project,
  }) {
    if (localPosition.dx.isNaN || localPosition.dy.isNaN) {
      return null;
    }

    final tileSize = project.settings.tileSize;
    final x = (localPosition.dx / tileSize).floor();
    final y = (localPosition.dy / tileSize).floor();

    if (x < 0 ||
        x >= project.settings.columns ||
        y < 0 ||
        y >= project.settings.rows) {
      return null;
    }

    return _BoardDropCell(x: x, y: y);
  }

  _BoardDropCell? _boardCellFromGlobalPosition({
    required Offset globalPosition,
    required BuilderProject project,
  }) {
    final targetContext = _boardDropTargetKey.currentContext;
    final renderBox = targetContext?.findRenderObject();

    if (renderBox is! RenderBox) {
      return null;
    }

    return _boardCellFromLocalPosition(
      localPosition: renderBox.globalToLocal(globalPosition),
      project: project,
    );
  }

  void _notifyGridDragState() {
    widget.onGridDragStateChanged(activeGridDrag != null);
  }

  Widget _buildGridTileFeedback(TileData tile, double tileSize) {
    final customAsset = widget.controller.customAssetById(
      tile.config['customAssetId']?.toString(),
    );
    if (customAsset != null) {
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: _buildCustomAssetTileImage(customAsset, tileSize),
      );
    }

    final terrainAssetPath = _terrainAssetPathForType(tile.type);
    if (terrainAssetPath != null) {
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: Image.asset(
          terrainAssetPath,
          width: tileSize,
          height: tileSize,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return _buildGridTileFallback(tile, tileSize);
          },
        ),
      );
    }

    return _buildGridTileFallback(tile, tileSize);
  }

  Widget _buildGridTileFallback(TileData tile, double tileSize) {
    return _buildFeedbackTileShell(
      tileSize: tileSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _tileColorForType(tile.type),
          borderRadius: BorderRadius.circular(tileSize * 0.08),
          border: Border.all(
            color: const Color(0x26000000),
            width: tileSize * 0.04 < 1 ? 1.0 : tileSize * 0.04,
          ),
        ),
      ),
    );
  }

  String? _terrainAssetPathForType(String type) {
    if (type == 'ground' || type == 'floor') {
      return 'game_builder/terrain/grass.png';
    }

    if (type == 'obstacle') {
      return 'game_builder/terrain/wood.png';
    }

    return null;
  }

  Widget _buildGridEntityFeedback(EntityData entity, double tileSize) {
    final customAsset = widget.controller.customAssetById(
      entity.config['customAssetId']?.toString(),
    );
    if (customAsset != null) {
      final image = _buildCustomAssetTileImage(customAsset, tileSize);
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: entity.type == 'playerStart'
            ? _maybeFlipPlayerPreview(
                image,
                entity.config['direction']?.toString(),
              )
            : image,
      );
    }

    if (entity.type == 'playerStart') {
      return _buildPlayerEntityFeedback(entity, tileSize);
    }

    if (entity.type == 'collectable') {
      final collectable = builderCollectableById(
        entity.config['item']?.toString(),
      );
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: Center(
          child: Image.asset(
            collectable.flutterAssetPath,
            width: tileSize * 0.68,
            height: tileSize * 0.68,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildGridEntityFallback(entity, tileSize);
            },
          ),
        ),
      );
    }

    if (entity.type == 'goal') {
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: Center(
          child: Image.asset(
            'game_builder/goal/chest_closed.png',
            width: tileSize * 0.82,
            height: tileSize * 0.82,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildGridEntityFallback(entity, tileSize);
            },
          ),
        ),
      );
    }

    return _buildGridEntityFallback(entity, tileSize);
  }

  Widget _buildDraggedGridPreview(
    _BoardGridDragData dragData, {
    required double tileSize,
  }) {
    Widget preview;
    if (dragData.isEntity) {
      final entity = widget.controller.entityById(dragData.entityId!);
      preview = entity == null
          ? _buildBoardHoverOverlay(
              tileSize: tileSize,
              fillColor: Colors.orange.withValues(alpha: 0.16),
              borderColor: Colors.orange.withValues(alpha: 0.78),
            )
          : _buildGridEntityFeedback(entity, tileSize);
    } else {
      final tile = widget.controller.tileAt(dragData.fromX, dragData.fromY);
      preview = tile == null
          ? _buildBoardHoverOverlay(
              tileSize: tileSize,
              fillColor: Colors.orange.withValues(alpha: 0.16),
              borderColor: Colors.orange.withValues(alpha: 0.78),
            )
          : _buildGridTileFeedback(tile, tileSize);
    }

    return Opacity(opacity: 0.74, child: preview);
  }

  Widget _buildToolDropPreview(BuilderTool tool, {required double tileSize}) {
    switch (tool) {
      case BuilderTool.ground:
        return Opacity(
          opacity: 0.74,
          child: _buildGridTileFeedback(
            TileData(type: 'ground', x: 0, y: 0),
            tileSize,
          ),
        );
      case BuilderTool.obstacle:
        return Opacity(
          opacity: 0.74,
          child: _buildGridTileFeedback(
            TileData(type: 'obstacle', x: 0, y: 0),
            tileSize,
          ),
        );
      case BuilderTool.player:
        return Opacity(
          opacity: 0.74,
          child: _buildPlayerEntityFeedback(
            EntityData(
              id: 'preview-player',
              type: 'playerStart',
              x: 0,
              y: 0,
              config: <String, dynamic>{
                'character': widget.controller.playerCharacterId,
                'direction': widget.controller.playerInitialDirection,
              },
            ),
            tileSize,
          ),
        );
      case BuilderTool.collectable:
        return Opacity(
          opacity: 0.74,
          child: _buildGridEntityFeedback(
            EntityData(
              id: 'preview-collectable',
              type: 'collectable',
              x: 0,
              y: 0,
              config: <String, dynamic>{
                'item': widget.controller.collectableItemId,
              },
            ),
            tileSize,
          ),
        );
      case BuilderTool.goal:
        return Opacity(
          opacity: 0.74,
          child: _buildGridEntityFeedback(
            const EntityData(id: 'preview-goal', type: 'goal', x: 0, y: 0),
            tileSize,
          ),
        );
      case BuilderTool.select:
      case BuilderTool.erase:
        return _buildBoardHoverOverlay(
          tileSize: tileSize,
          fillColor: Colors.white.withValues(alpha: 0.18),
          borderColor: Colors.blue.withValues(alpha: 0.65),
        );
    }
  }

  Widget _buildCustomAssetDropPreview(
    String assetId, {
    required double tileSize,
  }) {
    final asset = widget.controller.customAssetById(assetId);
    if (asset == null) {
      return _buildBoardHoverOverlay(
        tileSize: tileSize,
        fillColor: Colors.white.withValues(alpha: 0.18),
        borderColor: Colors.blue.withValues(alpha: 0.65),
      );
    }

    return Opacity(
      opacity: 0.74,
      child: _buildFeedbackTileShell(
        tileSize: tileSize,
        child: _buildCustomAssetTileImage(asset, tileSize),
      ),
    );
  }

  Widget _buildPlayerEntityFeedback(EntityData entity, double tileSize) {
    final customAsset = widget.controller.customAssetById(
      entity.config['customAssetId']?.toString(),
    );
    if (customAsset != null) {
      final image = _buildCustomAssetTileImage(customAsset, tileSize);
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: _maybeFlipPlayerPreview(
          image,
          entity.config['direction']?.toString(),
        ),
      );
    }

    final character = builderCharacterById(
      entity.config['character']?.toString(),
    );
    final image = Image.asset(
      character.idlePreviewAssetPath,
      width: tileSize,
      height: tileSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );

    return _buildFeedbackTileShell(
      tileSize: tileSize,
      child: Center(
        child: _maybeFlipPlayerPreview(
          image,
          entity.config['direction']?.toString(),
        ),
      ),
    );
  }

  Widget _maybeFlipPlayerPreview(Widget child, String? direction) {
    if (direction != BuilderController.playerFacingRight) {
      return child;
    }

    return Transform.scale(
      alignment: Alignment.center,
      scaleX: -1,
      scaleY: 1,
      child: child,
    );
  }

  Widget _buildGridEntityFallback(EntityData entity, double tileSize) {
    return _buildFeedbackTileShell(
      tileSize: tileSize,
      child: Center(
        child: Container(
          width: tileSize * 0.64,
          height: tileSize * 0.64,
          decoration: BoxDecoration(
            color: _entityColorForType(entity.type),
            borderRadius: BorderRadius.circular(tileSize * 0.08),
            border: Border.all(
              color: const Color(0x26000000),
              width: tileSize * 0.04 < 1 ? 1.0 : tileSize * 0.04,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAssetTileImage(CustomAssetData asset, double tileSize) {
    final bytes = widget.controller.assetImageBytes(asset);
    if (bytes == null) {
      return _buildFeedbackTileShell(
        tileSize: tileSize,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: tileSize * 0.44,
          color: Colors.blueGrey.shade400,
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: tileSize,
        height: tileSize,
        child: _CustomAssetFrameImage(
          bytes: bytes,
          scale: asset.frameScale,
          offsetX: asset.frameOffsetX,
          offsetY: asset.frameOffsetY,
          clipToFrame: false,
        ),
      ),
    );
  }

  Widget _buildFeedbackTileShell({
    required double tileSize,
    required Widget child,
  }) {
    return SizedBox(width: tileSize, height: tileSize, child: child);
  }

  Color _tileColorForType(String type) {
    if (type == 'ground' || type == 'floor') {
      return const Color(0xFF5FBF72);
    }

    if (type == 'obstacle') {
      return const Color(0xFF7C8796);
    }

    return const Color(0xFF9AA5B5);
  }

  Color _entityColorForType(String type) {
    switch (type) {
      case 'playerStart':
        return const Color(0xFF3B82F6);
      case 'collectable':
        return const Color(0xFFF59E0B);
      case 'goal':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  bool _shouldHideEntity(
    EntityData entity,
    BuilderPlaybackState? playbackState,
  ) {
    if (playbackState == null) {
      return false;
    }

    if (entity.type == 'playerStart') {
      return true;
    }

    return entity.type == 'collectable' &&
        playbackState.collectedCollectableIds.contains(entity.id);
  }

  Widget _buildBoardHoverOverlay({
    required double tileSize,
    required Color fillColor,
    required Color borderColor,
  }) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(tileSize * 0.08),
      ),
    );
  }
}

class _CustomAssetFrameImage extends StatelessWidget {
  final Uint8List bytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final bool clipToFrame;

  const _CustomAssetFrameImage({
    required this.bytes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    this.clipToFrame = true,
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

        final image = Transform.translate(
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
        );

        return clipToFrame ? ClipRect(child: image) : image;
      },
    );
  }
}

class _LogicDragData {
  final String? existingCommandId;
  final LogicCommandType? command;
  final bool isLoop;

  const _LogicDragData._({
    required this.existingCommandId,
    required this.command,
    required this.isLoop,
  });

  const _LogicDragData.newAction(LogicCommandType command)
    : this._(existingCommandId: null, command: command, isLoop: false);

  const _LogicDragData.newLoop()
    : this._(existingCommandId: null, command: null, isLoop: true);

  const _LogicDragData.existing(String commandId)
    : this._(existingCommandId: commandId, command: null, isLoop: false);
}

class _LogicDropTargetMeasure extends StatefulWidget {
  final _LogicDropTarget target;
  final void Function(_LogicDropTarget target, Rect? rect) onRectChanged;
  final Widget child;

  const _LogicDropTargetMeasure({
    required this.target,
    required this.onRectChanged,
    required this.child,
  });

  @override
  State<_LogicDropTargetMeasure> createState() =>
      _LogicDropTargetMeasureState();
}

class _LogicDropTargetMeasureState extends State<_LogicDropTargetMeasure> {
  Rect? _lastRect;
  bool _isReportQueued = false;

  @override
  void didUpdateWidget(covariant _LogicDropTargetMeasure oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.target != widget.target) {
      oldWidget.onRectChanged(oldWidget.target, null);
      _lastRect = null;
    }

    _queueReport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queueReport();
  }

  @override
  void dispose() {
    widget.onRectChanged(widget.target, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _queueReport();
    return widget.child;
  }

  void _queueReport() {
    if (_isReportQueued) {
      return;
    }

    _isReportQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isReportQueued = false;
      _reportRect();
    });
  }

  void _reportRect() {
    if (!mounted) {
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (_lastRect == rect) {
      return;
    }

    _lastRect = rect;
    widget.onRectChanged(widget.target, rect);
  }
}

class _LogicDropTarget {
  final String? parentLoopId;
  final int index;

  const _LogicDropTarget({required this.parentLoopId, required this.index});

  @override
  bool operator ==(Object other) {
    return other is _LogicDropTarget &&
        other.parentLoopId == parentLoopId &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(parentLoopId, index);
}

class _BoardDropCell {
  final int x;
  final int y;

  const _BoardDropCell({required this.x, required this.y});
}

class _BoardGridDragData {
  final String? entityId;
  final int fromX;
  final int fromY;

  bool get isEntity => entityId != null;

  const _BoardGridDragData.tile({required this.fromX, required this.fromY})
    : entityId = null;

  const _BoardGridDragData.entity({
    required this.entityId,
    required this.fromX,
    required this.fromY,
  });
}
