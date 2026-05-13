import 'package:flutter/material.dart';

import '../controllers/builder_controller.dart';
import '../shared/builder_character.dart';
import '../shared/builder_collectable.dart';
import '../shared/builder_tool.dart';

class BuilderToolbar extends StatelessWidget {
  static const double _gridSpacing = 8;

  final BuilderController controller;
  final Axis direction;

  const BuilderToolbar({
    super.key,
    required this.controller,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    const tools = [
      _ToolbarTool(
        label: 'Ground',
        tool: BuilderTool.ground,
        icon: Icons.crop_square_rounded,
        color: Color(0xFF3E8D55),
      ),
      _ToolbarTool(
        label: 'Obstacle',
        tool: BuilderTool.obstacle,
        icon: Icons.grid_view_rounded,
        color: Color(0xFF64748B),
      ),
      _ToolbarTool(
        label: 'Player',
        tool: BuilderTool.player,
        icon: Icons.person_rounded,
        color: Color(0xFF2563EB),
      ),
      _ToolbarTool(
        label: 'Collect',
        tool: BuilderTool.collectable,
        icon: Icons.stars_rounded,
        color: Color(0xFFF59E0B),
      ),
      _ToolbarTool(
        label: 'Goal',
        tool: BuilderTool.goal,
        icon: Icons.flag_rounded,
        color: Color(0xFFEF4444),
      ),
    ];

    if (direction == Axis.vertical) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 220.0;
          final itemSize = ((availableWidth - (_gridSpacing * 2)) / 3)
              .clamp(64.0, 84.0)
              .toDouble();

          return Wrap(
            spacing: _gridSpacing,
            runSpacing: _gridSpacing,
            children: [
              for (final tool in tools)
                _toolButton(tool: tool, dimension: itemSize),
            ],
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.only(right: _gridSpacing),
              child: _toolButton(tool: tool, dimension: 72.0),
            ),
        ],
      ),
    );
  }

  Widget _toolButton({required _ToolbarTool tool, required double dimension}) {
    final isSelected = controller.currentTool == tool.tool;
    final isEnabled = !controller.isPlaybackRunning;
    final button = SizedBox.square(
      dimension: dimension,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(8),
          backgroundColor: isSelected
              ? tool.color.withValues(alpha: 0.94)
              : tool.color.withValues(alpha: 0.14),
          foregroundColor: isSelected ? Colors.white : tool.color,
          disabledBackgroundColor: tool.color.withValues(alpha: 0.08),
          disabledForegroundColor: tool.color.withValues(alpha: 0.45),
          side: BorderSide(
            color: isSelected
                ? tool.color.withValues(alpha: 0.94)
                : tool.color.withValues(alpha: 0.22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: isSelected ? 2 : 0,
        ),
        onPressed: isEnabled ? () => controller.setTool(tool.tool) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, size: 24),
            const SizedBox(height: 6),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );

    if (!isEnabled) {
      return button;
    }

    return Draggable<BuilderTool>(
      data: tool.tool,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: _toolDragFeedback(tool.tool, dimension),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: button),
      child: button,
    );
  }

  Widget _toolDragFeedback(BuilderTool tool, double dimension) {
    return Opacity(
      opacity: 0.88,
      child: SizedBox.square(
        dimension: dimension,
        child: _toolPreview(tool, dimension),
      ),
    );
  }

  Widget _toolPreview(BuilderTool tool, double dimension) {
    switch (tool) {
      case BuilderTool.ground:
        return Image.asset(
          'game_builder/terrain/grass.png',
          width: dimension,
          height: dimension,
          fit: BoxFit.fill,
          errorBuilder: _emptyImageFallback,
        );
      case BuilderTool.obstacle:
        return Image.asset(
          'game_builder/terrain/wood.png',
          width: dimension,
          height: dimension,
          fit: BoxFit.fill,
          errorBuilder: _emptyImageFallback,
        );
      case BuilderTool.player:
        return _playerPreview(dimension);
      case BuilderTool.collectable:
        final collectable = builderCollectableById(controller.collectableItemId);
        return Center(
          child: Image.asset(
            collectable.flutterAssetPath,
            width: dimension * 0.7,
            height: dimension * 0.7,
            fit: BoxFit.contain,
            errorBuilder: _emptyImageFallback,
          ),
        );
      case BuilderTool.goal:
        return Center(
          child: Image.asset(
            'game_builder/goal/chest_closed.png',
            width: dimension * 0.82,
            height: dimension * 0.82,
            fit: BoxFit.contain,
            errorBuilder: _emptyImageFallback,
          ),
        );
      case BuilderTool.select:
      case BuilderTool.erase:
        return const SizedBox.shrink();
    }
  }

  Widget _playerPreview(double dimension) {
    final character = builderCharacterById(controller.playerCharacterId);
    final image = Image.asset(
      character.idlePreviewAssetPath,
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
      errorBuilder: _emptyImageFallback,
    );

    if (controller.playerInitialDirection !=
        BuilderController.playerFacingRight) {
      return image;
    }

    return Transform.scale(
      alignment: Alignment.center,
      scaleX: -1,
      scaleY: 1,
      child: image,
    );
  }

  Widget _emptyImageFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const SizedBox.shrink();
  }
}

class _ToolbarTool {
  final String label;
  final BuilderTool tool;
  final IconData icon;
  final Color color;

  const _ToolbarTool({
    required this.label,
    required this.tool,
    required this.icon,
    required this.color,
  });
}
