import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../models/auth_session.dart';
import '../controllers/builder_controller.dart';
import '../flame/builder_game.dart';
import '../models/builder_project.dart';
import '../models/level_settings.dart';
import '../models/logic_command.dart';
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

  late BuilderController controller;
  late BuilderGame game;
  late TextEditingController titleController;
  late final ScrollController horizontalScrollController;
  late final ScrollController verticalScrollController;
  late final VoidCallback controllerListener;
  int? selectedSolutionCommandIndex;
  int previousColumnCount = 0;
  bool hasAttemptedSave = false;

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
    _syncSelectedSolutionCommandIndex();

    if (!mounted) {
      return;
    }

    setState(() {});
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

  void _syncSelectedSolutionCommandIndex() {
    final commandCount = controller.project.solutionCommands.length;

    if (commandCount == 0) {
      selectedSolutionCommandIndex = null;
      return;
    }

    if (selectedSolutionCommandIndex == null) {
      return;
    }

    if (selectedSolutionCommandIndex! >= commandCount) {
      selectedSolutionCommandIndex = commandCount - 1;
    }
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
          : Container(
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
      selectedSolutionCommandIndex = null;
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
        _buildPanelSection(
          title: 'Level Actions',
          child: _buildLevelActions(),
        ),
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
                bottom: 6,
                child: _buildLogicOverlay(
                  project: project,
                  viewportHeight: viewportHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogicOverlay({
    required BuilderProject project,
    required double viewportHeight,
  }) {
    final commands = controller.solutionCommands;
    final playbackState = controller.playbackState;
    final selectedIndex = selectedSolutionCommandIndex;
    final activeCommandIndex = playbackState?.activeCommandIndex;
    final panelHeight = math.min(
      viewportHeight - 24,
      math.max(144.0, project.settings.tileSize + 52),
    );
    final canEditCommands = !controller.isPlaybackRunning;
    final hasSelectedCommand =
        selectedIndex != null && selectedIndex >= 0 && selectedIndex < commands.length;

    return Material(
      elevation: 10,
      color: Colors.transparent,
      child: Container(
        height: panelHeight,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
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
                            ),
                          ),
                        ],
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
                    controller.isPlaybackRunning ? Icons.stop : Icons.play_arrow,
                    color: controller.isPlaybackRunning
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  onPressed: canEditCommands && commands.isNotEmpty
                      ? () {
                          setState(() {
                            selectedSolutionCommandIndex = null;
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
            const SizedBox(height: 6),
            Expanded(
              child: commands.isEmpty
                  ? _buildEmptyLogicStrip()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: commands.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final command = commands[index];
                        final isSelected = index == selectedIndex;
                        final isActive = index == activeCommandIndex;

                        return GestureDetector(
                          onTap: canEditCommands
                              ? () {
                                  setState(() {
                                    selectedSolutionCommandIndex = index;
                                  });
                                }
                              : null,
                          child: _buildLogicCommandSquare(
                            command: command,
                            index: index,
                            isSelected: isSelected,
                            isActive: isActive,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.logicStatusMessage ??
                        'Add arrow blocks, tap one to select it, then arrange the solution.',
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
                  onPressed: canEditCommands &&
                          hasSelectedCommand &&
                          selectedIndex > 0
                      ? () {
                          controller.moveSolutionCommand(
                            selectedIndex,
                            selectedIndex - 1,
                          );
                          setState(() {
                            selectedSolutionCommandIndex = selectedIndex - 1;
                          });
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
                          controller.removeSolutionCommandAt(selectedIndex);
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
                  onPressed: canEditCommands &&
                          hasSelectedCommand &&
                          selectedIndex < commands.length - 1
                      ? () {
                          controller.moveSolutionCommand(
                            selectedIndex,
                            selectedIndex + 1,
                          );
                          setState(() {
                            selectedSolutionCommandIndex = selectedIndex + 1;
                          });
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
  }) {
    final baseColor = _logicCommandColor(command);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                final nextIndex = controller.project.solutionCommands.length;
                controller.addSolutionCommand(command);
                setState(() {
                  selectedSolutionCommandIndex = nextIndex;
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
  }

  Widget _buildLogicCommandSquare({
    required LogicCommandType command,
    required int index,
    required bool isSelected,
    required bool isActive,
  }) {
    final baseColor = _logicCommandColor(command);

    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.green.shade500
              : isSelected
              ? Colors.blue.shade600
              : baseColor.withValues(alpha: 0.35),
          width: isActive || isSelected ? 2 : 1.2,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Icon(_logicCommandIcon(command), color: baseColor, size: 16),
              const SizedBox(height: 3),
              Text(
                _logicCommandTokenLabel(command),
                style: TextStyle(
                  color: Colors.blueGrey.shade900,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLogicStrip() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, index) {
        return Container(
          width: 46,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: index == 0
                  ? Text(
                      'Add',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    )
                  : Icon(Icons.add, color: Colors.blueGrey.shade300, size: 18),
            ),
          ),
        );
      },
    );
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
