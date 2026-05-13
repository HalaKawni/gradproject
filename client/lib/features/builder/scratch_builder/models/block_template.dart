import 'package:flutter/material.dart';

import 'block_type.dart';

enum BlockShape { hat, stack, reporter, boolean, cBlock, cap }

enum BlockInputType { number, text, variable, dropdown, boolean }

class BlockInput {
  final String key;
  final BlockInputType type;
  final String defaultValue;
  final List<String> options;

  const BlockInput({
    required this.key,
    required this.type,
    required this.defaultValue,
    this.options = const [],
  });
}

class BlockTemplate {
  final BlockType type;
  final String label;
  final Color color;
  final BlockShape shape;
  final bool isContainer;
  final List<BlockInput> inputs;

  const BlockTemplate({
    required this.type,
    required this.label,
    required this.color,
    this.shape = BlockShape.stack,
    this.isContainer = false,
    this.inputs = const [],
  });
}
