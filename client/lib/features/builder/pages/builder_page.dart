import 'dart:math' as math;

import 'package:client/core/models/auth_session.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../controllers/builder_controller.dart';
import '../flame/builder_game.dart';
import '../models/builder_playback_state.dart';
import '../models/builder_project.dart';
import '../models/entity_data.dart';
import '../models/level_settings.dart';
import '../models/logic_command.dart';
import '../models/tile_data.dart';
import '../shared/builder_tool.dart';
import '../widgets/builder_status_bar.dart';
import '../widgets/builder_toolbar.dart';

class BuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;

  const BuilderPage({super.key, required this.session, this.initialProjectId});

  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  static const double _leftPanelWidth = 260;
  static const double _rootLogicLaneHeight = 54;
  static const double _logicDropSnapPadding = 30;
  static const double _logicGhostProbeYOffset = -18;

  late BuilderController controller;
  late BuilderGame game;
  late TextEditingController titleController;
  late final ScrollController horizontalScrollController;
  late final ScrollController verticalScrollController;
  late final VoidCallback controllerListener;
  final Map<_LogicDropTarget, GlobalKey> _logicDropTargetKeys =
      <_LogicDropTarget, GlobalKey>{};
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

    final project = BuilderProject.initial();
    titleController = TextEditingController(text: project.title);
    horizontalScrollController = ScrollController();
    verticalScrollController = ScrollController();
    controller = BuilderController(project: project, session: widget.session);
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

  GlobalKey _logicDropTargetKeyFor(_LogicDropTarget target) {
    return _logicDropTargetKeys.putIfAbsent(target, () => GlobalKey());
  }

  void _handleLogicDragStarted(_LogicDragData data) {
    activeLogicDragData = data;
    proximityLogicDropTarget = null;
    _handleLogicDragStateChanged(true);
  }

  void _handleLogicDragUpdated(
    _LogicDragData data,
    DragUpdateDetails details,
  ) {
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

  void _handleLogicDragEnded(
    _LogicDragData data,
    DraggableDetails details,
  ) {
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

    for (final entry in _logicDropTargetKeys.entries) {
      final target = entry.key;
      if (!_canAcceptLogicDrop(data, target)) {
        continue;
      }

      final targetContext = entry.value.currentContext;
      final renderObject = targetContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }

      final rect =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;
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
    final project = controller.project;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Game Name',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
          cursorColor: Colors.black,
          maxLines: 1,
          onChanged: controller.setTitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: controller.isSaving ? null : _handleSavePressed,
              child: Text(
                controller.isSaving ? 'Saving...' : 'Save',
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
                            right: BorderSide(color: Colors.blueGrey.shade100),
                          ),
                        ),
                        child: _buildLeftPanel(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(child: _buildFixedGameWindow(project)),
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
        message: controller.lastMessage ?? 'Game saved successfully.',
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
      message: controller.lastMessage ?? 'Failed to save game.',
      backgroundColor: Colors.red.shade600,
    );
  }

  Future<void> _handleClearLevelPressed() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Level?'),
          content: const Text(
            'This will remove all placed items and logic steps, then rebuild the protected ground rows at the bottom.',
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

    setState(() {
      hasAttemptedSave = false;
      _setLogicSelection(null);
    });

    controller.clearLevel();

    if (!mounted) {
      return;
    }

    _showNotification(
      message: 'Level cleared.',
      backgroundColor: Colors.blueGrey.shade700,
    );
  }

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
      return controller.lastMessage ?? 'Add the required items before saving.';
    }

    return 'Add the required items before saving: ${issues.join(' ')}';
  }

  Widget _buildLeftPanel() {
    return ListView(
      children: [
        _buildPanelSection(
          title: 'Tools',
          child: BuilderToolbar(
            controller: controller,
            direction: Axis.vertical,
          ),
        ),
        const SizedBox(height: 14),
        _buildPanelSection(title: 'Grid', child: _buildTileSizeControls()),
        const SizedBox(height: 14),
        _buildPanelSection(title: 'Level Actions', child: _buildLevelActions()),
        const SizedBox(height: 14),
        _buildPanelSection(
          title: 'Level Info',
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
                        'Drop to delete',
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
                  tooltip: controller.isPlaybackRunning ? 'Stop' : 'Play',
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
                  tooltip: 'Reset',
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
                  tooltip: 'Clear',
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
                            ? 'Add blocks, drag them into place, or tap a loop then add commands directly inside it.'
                            : 'The selected loop is ready. New blocks will be added inside it, or you can drag commands into any gap.'),
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
                  tooltip: 'Move Left',
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
                  tooltip: 'Remove',
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
                  tooltip: 'Move Right',
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
                'Loop',
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

    return GestureDetector(
      onTap: canEditCommands
          ? () {
              setState(() {
                _setLogicSelection(node.id);
              });
            }
          : null,
      child: Container(
        width: 46,
        constraints: isRoot
            ? const BoxConstraints(minHeight: _rootLogicLaneHeight)
            : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
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
            Icon(_logicCommandIcon(command), color: baseColor, size: 16),
            const SizedBox(height: 3),
            Text(
              _logicCommandTokenLabel(command),
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 9,
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
    return DragTarget<_LogicDragData>(
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
            (isEmptySequence ? (isRoot ? 240.0 : 22.0) : (isRoot ? 8.0 : 6.0));
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
        final labelText = isEmptySequence ? 'Drop here' : 'Drop here to add';
        final isIdleRootPlaceholder =
            showIdlePlaceholder && isRoot && !isHighlighted && !isEmptySequence;
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
          key: _logicDropTargetKeyFor(target),
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
        return 'Left';
      case LogicCommandType.moveRight:
        return 'Right';
      case LogicCommandType.jumpUp:
        return 'Jump';
      case LogicCommandType.climbUpLeft:
        return 'Up-L';
      case LogicCommandType.climbUpRight:
        return 'Up-R';
    }
  }

  String _logicCommandTokenLabel(LogicCommandType command) {
    switch (command) {
      case LogicCommandType.moveLeft:
        return 'L';
      case LogicCommandType.moveRight:
        return 'R';
      case LogicCommandType.jumpUp:
        return 'UP';
      case LogicCommandType.climbUpLeft:
        return 'UL';
      case LogicCommandType.climbUpRight:
        return 'UR';
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
          'Grid Square Size',
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
          '${selectedPreset.label}: ${settings.tileSize.round()} px squares, ${settings.columns} columns, ${settings.rows} rows.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 6),
        Text(
          'Each preset refits the grid so it still fills the entire outer game rectangle.',
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
          label: const Text(
            'Clear Level',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Reset the level layout and logic. The bottom $protectedGroundRows rows will stay ground in ${selectedPreset.label.toLowerCase()} mode.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
        ),
      ],
    );
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
          const Text(
            'Add the required items before saving:',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
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

    return DragTarget<BuilderTool>(
      onWillAcceptWithDetails: (details) {
        return !widget.controller.isPlaybackRunning;
      },
      onMove: (details) {
        final targetContext = _boardDropTargetKey.currentContext;
        final renderBox = targetContext?.findRenderObject();
        if (renderBox is! RenderBox) {
          return;
        }

        final localPosition = renderBox.globalToLocal(details.offset);
        final nextCell = _boardCellFromLocalPosition(
          localPosition: localPosition,
          project: project,
        );
        final hasChanged =
            hoveredToolCell?.x != nextCell?.x ||
            hoveredToolCell?.y != nextCell?.y;

        if (!hasChanged) {
          return;
        }

        setState(() {
          hoveredToolCell = nextCell;
        });
      },
      onLeave: (data) {
        if (hoveredToolCell == null) {
          return;
        }

        setState(() {
          hoveredToolCell = null;
        });
      },
      onAcceptWithDetails: (details) {
        if (widget.controller.isPlaybackRunning) {
          return;
        }

        final targetContext = _boardDropTargetKey.currentContext;
        final renderBox = targetContext?.findRenderObject();
        if (renderBox is! RenderBox) {
          return;
        }

        final localPosition = renderBox.globalToLocal(details.offset);
        final cell =
            hoveredToolCell ??
            _boardCellFromLocalPosition(
              localPosition: localPosition,
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
      builder: (context, candidateData, rejectedData) {
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
                            candidateData.isNotEmpty) {
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
                    toolDragInProgress: candidateData.isNotEmpty,
                  ),
                  if (activeGridDrag != null && hoveredGridDragCell != null)
                    Positioned(
                      left: hoveredGridDragCell!.x * tileSize,
                      top: hoveredGridDragCell!.y * tileSize,
                      child: IgnorePointer(
                        child: _buildBoardHoverOverlay(
                          tileSize: tileSize,
                          fillColor: Colors.orange.withValues(alpha: 0.16),
                          borderColor: Colors.orange.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  if (candidateData.isNotEmpty && hoveredToolCell != null)
                    Positioned(
                      left: hoveredToolCell!.x * tileSize,
                      top: hoveredToolCell!.y * tileSize,
                      child: IgnorePointer(
                        child: _buildBoardHoverOverlay(
                          tileSize: tileSize,
                          fillColor: Colors.white.withValues(alpha: 0.18),
                          borderColor: Colors.blue.withValues(alpha: 0.65),
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
        feedback: Material(
          color: Colors.transparent,
          child: feedback,
        ),
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

  Widget _buildGridEntityFeedback(EntityData entity, double tileSize) {
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

  Widget _buildFeedbackTileShell({
    required double tileSize,
    required Widget child,
  }) {
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: child,
    );
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
