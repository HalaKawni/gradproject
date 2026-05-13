import 'package:flutter/material.dart';

import 'block_template.dart';

class WorkspaceBlock {
  final String id;
  final BlockTemplate template;
  final Offset position;
  final String? previousBlockId;
  final String? nextBlockId;
  final Map<String, String> inputValues;

  const WorkspaceBlock({
    required this.id,
    required this.template,
    required this.position,
    this.previousBlockId,
    this.nextBlockId,
    this.inputValues = const {},
  });

  WorkspaceBlock copyWith({
    String? id,
    BlockTemplate? template,
    Offset? position,
    String? previousBlockId,
    String? nextBlockId,
    Map<String, String>? inputValues,
    bool clearPreviousBlockId = false,
    bool clearNextBlockId = false,
  }) {
    return WorkspaceBlock(
      id: id ?? this.id,
      template: template ?? this.template,
      position: position ?? this.position,
      previousBlockId: clearPreviousBlockId
          ? null
          : previousBlockId ?? this.previousBlockId,
      nextBlockId: clearNextBlockId ? null : nextBlockId ?? this.nextBlockId,
      inputValues: inputValues ?? this.inputValues,
    );
  }
}
