import 'package:flutter/material.dart';

import '../controllers/builder_controller.dart';
import '../shared/builder_tool.dart';

class BuilderToolbar extends StatelessWidget {
  final BuilderController controller;
  final Axis direction;

  const BuilderToolbar({
    super.key,
    required this.controller,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _toolButton('Select', BuilderTool.select),
      _toolButton('Erase', BuilderTool.erase),
      _toolButton('Ground', BuilderTool.ground),
      _toolButton('Obstacle', BuilderTool.obstacle),
      _toolButton('Player', BuilderTool.player),
      _toolButton('Collectable', BuilderTool.collectable),
      _toolButton('Goal', BuilderTool.goal),
    ];

    return SingleChildScrollView(
      scrollDirection: direction,
      child: direction == Axis.vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            )
          : Row(children: children),
    );
  }

  Widget _toolButton(String label, BuilderTool tool) {
    final isSelected = controller.currentTool == tool;
    final button = SizedBox(
      width: direction == Axis.vertical ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey,
          minimumSize: direction == Axis.vertical ? const Size(0, 44) : null,
        ),
        onPressed: () => controller.setTool(tool),
        child: Text(label),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: direction == Axis.vertical ? 0 : 4,
        vertical: 6,
      ),
      child: button,
    );
  }
}
