import 'dart:math' as math;

import 'package:client/core/models/auth_session.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/builder_controller.dart';
import '../flame/builder_game.dart';
import '../models/builder_playback_state.dart';
import '../models/builder_project.dart';
import '../models/level_settings.dart';
import '../models/logic_command.dart';

class BuilderPlayPage extends StatefulWidget {
  final AuthSession session;
  final String projectId;
  final String? initialTitle;

  const BuilderPlayPage({
    super.key,
    required this.session,
    required this.projectId,
    this.initialTitle,
  });

  @override
  State<BuilderPlayPage> createState() => _BuilderPlayPageState();
}

class _BuilderPlayPageState extends State<BuilderPlayPage> {
  static const double _rootLogicLaneHeight = 54;
  static const double _logicDropSnapPadding = 30;
  static const double _logicGhostProbeYOffset = -18;

  late final BuilderController controller;
  late final BuilderGame game;
  late final ScrollController horizontalScrollController;
  late final ScrollController verticalScrollController;
  late final VoidCallback controllerListener;
  final Map<_LogicDropTarget, GlobalKey> _logicDropTargetKeys =
      <_LogicDropTarget, GlobalKey>{};

  String? selectedSolutionCommandId;
  String? selectedLoopInsertionTargetId;
  bool hasPreparedLoadedProject = false;
  bool hasShownCompletionDialog = false;
  bool isLogicDragActive = false;
  _LogicDragData? activeLogicDragData;
  _LogicDropTarget? proximityLogicDropTarget;

  @override
  void initState() {
    super.initState();

    controller = BuilderController(
      project: BuilderProject.initial(),
      session: widget.session,
      requireAllCollectablesForSuccess: false,
    );
    game = BuilderGame(controller: controller);
    horizontalScrollController = ScrollController();
    verticalScrollController = ScrollController();
    controllerListener = _handleControllerChanged;
    controller.addListener(controllerListener);
    _loadProject();
  }

  @override
  void dispose() {
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
    controller.removeListener(controllerListener);
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    hasPreparedLoadedProject = false;
    hasShownCompletionDialog = false;
    selectedSolutionCommandId = null;
    selectedLoopInsertionTargetId = null;
    await controller.loadProject(widget.projectId);
  }

  void _handleControllerChanged() {
    _syncSelectedSolutionCommandSelection();
    _prepareLoadedProjectForPlay();
    _handleCompletionState();

    if (!mounted) {
      return;
    }

    setState(() {});
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

      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
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

  void _prepareLoadedProjectForPlay() {
    if (hasPreparedLoadedProject ||
        controller.isLoading ||
        controller.savedProjectId == null) {
      return;
    }

    hasPreparedLoadedProject = true;

    if (controller.solutionCommands.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      controller.clearSolutionCommands(statusMessage: null);
    });
  }

  void _handleCompletionState() {
    final playbackState = controller.playbackState;

    if (playbackState?.hasSucceeded == true) {
      if (hasShownCompletionDialog) {
        return;
      }

      hasShownCompletionDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showCompletionDialog(playbackState!);
      });
      return;
    }

    hasShownCompletionDialog = false;
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

  Future<void> _showCompletionDialog(BuilderPlaybackState playbackState) async {
    final totalCollectables = controller.totalCollectableCount;
    final collectedCollectables = playbackState.collectedCollectableIds.length;
    final score = totalCollectables == 0
        ? 100
        : ((collectedCollectables / totalCollectables) * 100).round();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Level Complete'),
          content: Text(
            totalCollectables == 0
                ? 'You reached the goal. Score: $score%.'
                : 'You reached the goal and collected $collectedCollectables of $totalCollectables collectables. Score: $score%.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.resetPlaybackPreview();
              },
              child: const Text('Replay'),
            ),
          ],
        );
      },
    );
  }

  String get _pageTitle {
    if (controller.savedProjectId != null && controller.project.title.isNotEmpty) {
      return controller.project.title;
    }

    final initialTitle = widget.initialTitle?.trim();
    if (initialTitle != null && initialTitle.isNotEmpty) {
      return initialTitle;
    }

    return 'Play Level';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFEAF6FF),
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.savedProjectId == null
                ? _buildLoadErrorState()
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1380),
                        child: Column(
                          children: [
                            _buildTopSummary(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Center(
                                child: _buildFixedGameWindow(controller.project),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildTrashBin() {
    final isVisible = isLogicDragActive;

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
        final isHighlighted = logicCandidateData.isNotEmpty;

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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                    color: isHighlighted ? Colors.white : Colors.red.shade600,
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
  }

  Widget _buildLoadErrorState() {
    final message = controller.lastMessage ?? 'Failed to load this game.';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _loadProject,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSummary() {
    final totalCollectables = controller.totalCollectableCount;
    final collectedCollectables = controller.collectedCollectableCount;
    final score = totalCollectables == 0
        ? 100
        : ((collectedCollectables / totalCollectables) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Reach the goal to complete the level. Collectables improve your score.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildSummaryPill(
            icon: Icons.star_rounded,
            label: totalCollectables == 0
                ? 'Score: $score%'
                : 'Collectables: $collectedCollectables / $totalCollectables',
            color: const Color(0xFFF59E0B),
          ),
          _buildSummaryPill(
            icon: Icons.emoji_events_outlined,
            label: 'Current score: $score%',
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
                              child: GameWidget(game: game, autofocus: false),
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

  Widget _buildLogicOverlay({
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
                      ? controller.stopPlayback
                      : controller.playSolution,
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
                      ? controller.resetPlaybackPreview
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
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildLogicSequenceStrip(
                        commands: commands,
                        parentLoopId: null,
                        selectedCommandId: selectedCommandId,
                        activeCommandId: activeCommandId,
                        canEditCommands: canEditCommands,
                        isRoot: true,
                        rootViewportWidth: constraints.maxWidth - 16,
                      ),
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
                            ? 'Add commands, then press play.'
                            : 'Loop selected. New commands will be added inside it.'),
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
                  tooltip: 'Delete',
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
