import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../models/block_template.dart';
import '../models/block_type.dart';
import '../painters/puzzle_block_painter.dart';

class ScratchBlock extends StatelessWidget {
  final BlockTemplate template;
  final String? blockId;
  final Map<String, String> inputValues;
  final void Function(String blockId, String inputKey, String value)?
  onInputChanged;

  const ScratchBlock({
    super.key,
    required this.template,
    this.blockId,
    this.inputValues = const {},
    this.onInputChanged,
  });

  bool get isEditable => blockId != null && onInputChanged != null;

  @override
  Widget build(BuildContext context) {
    final width = switch (template.shape) {
      BlockShape.reporter => 150.0,
      BlockShape.boolean => 160.0,
      BlockShape.cBlock => 230.0,
      _ => 210.0,
    };

    final height = template.isContainer ? 86.0 : 42.0;
    final topPadding = switch (template.shape) {
      BlockShape.hat => 18.0,
      BlockShape.cBlock => 9.0,
      _ => 0.0,
    };

    return CustomPaint(
      painter: PuzzleBlockPainter(color: template.color, shape: template.shape),
      child: Container(
        width: width,
        height: template.shape == BlockShape.hat ? height + 16 : height,
        padding: EdgeInsets.only(left: 16, right: 14, top: topPadding),
        alignment: template.isContainer
            ? Alignment.topLeft
            : Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildLabelParts(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLabelParts(BuildContext context) {
    final label = _localizedTemplateLabel(context, template.label);
    final widgets = <Widget>[
      Icon(_iconForType(template.type), size: 17, color: Colors.white),
      const SizedBox(width: 7),
    ];

    final regex = RegExp(r'\{(.*?)\}');
    final matches = regex.allMatches(label).toList();

    var currentIndex = 0;

    for (final match in matches) {
      final textBefore = label.substring(currentIndex, match.start);

      if (textBefore.isNotEmpty) {
        widgets.add(_TextPart(textBefore));
      }

      final key = match.group(1)!;
      final input = template.inputs.firstWhere((i) => i.key == key);

      widgets.add(
        _InputPart(
          input: input,
          value: inputValues[key] ?? input.defaultValue,
          editable: isEditable,
          onChanged: (value) {
            if (blockId == null || onInputChanged == null) return;
            onInputChanged!(blockId!, key, value);
          },
        ),
      );

      currentIndex = match.end;
    }

    final remaining = label.substring(currentIndex);

    if (remaining.isNotEmpty) {
      widgets.add(_TextPart(remaining));
    }

    return widgets;
  }

  String _localizedTemplateLabel(BuildContext context, String label) {
    final language = AppLanguage.of(context);
    return switch (label) {
      'When Start Clicked' => language.t('builder.block.whenStartClicked'),
      'Move {steps} Steps' => language.t('builder.block.moveSteps'),
      'Turn {degrees}°' => language.t('builder.block.turnDegrees'),
      'Go To X: {x} Y: {y}' => language.t('builder.block.goTo'),
      'Say {message}' => language.t('builder.block.say'),
      'Think {message}' => language.t('builder.block.think'),
      'Wait {seconds} Second' => language.t('builder.block.wait'),
      'Repeat {times} Times' => language.t('builder.block.repeat'),
      'Key {key} Pressed?' => language.t('builder.block.keyPressed'),
      '{a} + {b}' => language.t('builder.block.add'),
      '{a} > {b}' => language.t('builder.block.greaterThan'),
      'Set {variable} To {value}' => language.t('builder.block.setVariable'),
      'Change {variable} By {value}' => language.t(
        'builder.block.changeVariable',
      ),
      _ => label,
    };
  }

  IconData _iconForType(BlockType type) {
    switch (type) {
      case BlockType.event:
        return Icons.flag_rounded;
      case BlockType.motion:
        return Icons.near_me_rounded;
      case BlockType.looks:
        return Icons.chat_bubble_rounded;
      case BlockType.sound:
        return Icons.volume_up_rounded;
      case BlockType.control:
        return Icons.loop_rounded;
      case BlockType.sensing:
        return Icons.sensors_rounded;
      case BlockType.operators:
        return Icons.functions_rounded;
      case BlockType.variables:
        return Icons.data_object_rounded;
      case BlockType.lists:
        return Icons.format_list_bulleted_rounded;
    }
  }
}

class _TextPart extends StatelessWidget {
  final String text;

  const _TextPart(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InputPart extends StatelessWidget {
  final BlockInput input;
  final String value;
  final bool editable;
  final ValueChanged<String> onChanged;

  const _InputPart({
    required this.input,
    required this.value,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!editable) {
      return _InputBox(child: Text(_displayValue(context, value)));
    }

    if (input.type == BlockInputType.dropdown ||
        input.type == BlockInputType.variable) {
      return _InputBox(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            items: input.options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(_displayValue(context, option)),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
      );
    }

    return _InputBox(
      child: SizedBox(
        width: input.type == BlockInputType.number ? 38 : 70,
        child: TextFormField(
          initialValue: value,
          keyboardType: input.type == BlockInputType.number
              ? TextInputType.number
              : TextInputType.text,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _displayValue(BuildContext context, String value) {
    final language = AppLanguage.of(context);
    return switch (value) {
      'space' => language.t('builder.key.space'),
      'up' => language.t('builder.key.up'),
      'down' => language.t('builder.key.down'),
      'left' => language.t('builder.key.left'),
      'right' => language.t('builder.key.right'),
      _ => value,
    };
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;

  const _InputBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        child: child,
      ),
    );
  }
}
