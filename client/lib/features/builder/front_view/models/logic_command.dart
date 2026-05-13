enum LogicCommandType { moveLeft, moveRight, jumpUp, climbUpLeft, climbUpRight }

enum LogicCommandNodeType { action, loop }

extension LogicCommandTypeExtension on LogicCommandType {
  String get value {
    switch (this) {
      case LogicCommandType.moveLeft:
        return 'moveLeft';
      case LogicCommandType.moveRight:
        return 'moveRight';
      case LogicCommandType.jumpUp:
        return 'jumpUp';
      case LogicCommandType.climbUpLeft:
        return 'climbUpLeft';
      case LogicCommandType.climbUpRight:
        return 'climbUpRight';
    }
  }

  String get label {
    switch (this) {
      case LogicCommandType.moveLeft:
        return 'Move Left';
      case LogicCommandType.moveRight:
        return 'Move Right';
      case LogicCommandType.jumpUp:
        return 'Jump Up';
      case LogicCommandType.climbUpLeft:
        return 'Climb Up Left';
      case LogicCommandType.climbUpRight:
        return 'Climb Up Right';
    }
  }

  int get deltaX {
    switch (this) {
      case LogicCommandType.moveLeft:
        return -1;
      case LogicCommandType.moveRight:
        return 1;
      case LogicCommandType.jumpUp:
        return 0;
      case LogicCommandType.climbUpLeft:
        return -1;
      case LogicCommandType.climbUpRight:
        return 1;
    }
  }

  int get deltaY {
    switch (this) {
      case LogicCommandType.moveLeft:
      case LogicCommandType.moveRight:
        return 0;
      case LogicCommandType.jumpUp:
      case LogicCommandType.climbUpLeft:
      case LogicCommandType.climbUpRight:
        return -1;
    }
  }

  static LogicCommandType fromString(String value) {
    switch (value) {
      case 'moveLeft':
        return LogicCommandType.moveLeft;
      case 'moveRight':
        return LogicCommandType.moveRight;
      case 'jumpUp':
        return LogicCommandType.jumpUp;
      case 'climbUpLeft':
        return LogicCommandType.climbUpLeft;
      case 'climbUpRight':
      default:
        return LogicCommandType.climbUpRight;
    }
  }
}

class LogicCommandNode {
  final String id;
  final LogicCommandNodeType type;
  final LogicCommandType? command;
  final List<LogicCommandNode> children;

  const LogicCommandNode._({
    required this.id,
    required this.type,
    required this.command,
    required this.children,
  });

  factory LogicCommandNode.action({
    String? id,
    required LogicCommandType command,
  }) {
    return LogicCommandNode._(
      id: id ?? _createLogicCommandNodeId(),
      type: LogicCommandNodeType.action,
      command: command,
      children: const [],
    );
  }

  factory LogicCommandNode.loop({
    String? id,
    List<LogicCommandNode> children = const [],
  }) {
    return LogicCommandNode._(
      id: id ?? _createLogicCommandNodeId(),
      type: LogicCommandNodeType.loop,
      command: null,
      children: List<LogicCommandNode>.unmodifiable(children),
    );
  }

  bool get isLoop => type == LogicCommandNodeType.loop;

  bool get isAction => type == LogicCommandNodeType.action;

  String get label {
    if (isLoop) {
      return 'Loop';
    }

    return command?.label ?? 'Command';
  }

  LogicCommandNode copyWith({
    String? id,
    LogicCommandNodeType? type,
    Object? command = _logicCommandUnset,
    List<LogicCommandNode>? children,
  }) {
    final nextType = type ?? this.type;
    final nextCommand = identical(command, _logicCommandUnset)
        ? this.command
        : command as LogicCommandType?;
    final nextChildren = children ?? this.children;

    if (nextType == LogicCommandNodeType.loop) {
      return LogicCommandNode.loop(id: id ?? this.id, children: nextChildren);
    }

    return LogicCommandNode.action(
      id: id ?? this.id,
      command: nextCommand ?? LogicCommandType.moveRight,
    );
  }

  Map<String, dynamic> toJson() {
    if (isLoop) {
      return {
        'id': id,
        'type': 'loop',
        'children': children.map((child) => child.toJson()).toList(),
      };
    }

    return {'id': id, 'type': 'action', 'command': command?.value};
  }

  static LogicCommandNode? tryParse(dynamic input) {
    if (input is String) {
      return LogicCommandNode.action(
        command: LogicCommandTypeExtension.fromString(input),
      );
    }

    if (input is! Map<String, dynamic>) {
      return null;
    }

    final rawType = input['type'];
    if (rawType == 'loop') {
      final rawChildren = input['children'] as List<dynamic>? ?? const [];
      return LogicCommandNode.loop(
        id: input['id'] as String?,
        children: rawChildren
            .map(LogicCommandNode.tryParse)
            .whereType<LogicCommandNode>()
            .toList(),
      );
    }

    final rawCommand = input['command'];
    if (rawType == 'action' || rawCommand is String) {
      return LogicCommandNode.action(
        id: input['id'] as String?,
        command: LogicCommandTypeExtension.fromString(
          rawCommand is String ? rawCommand : LogicCommandType.moveRight.value,
        ),
      );
    }

    return null;
  }
}

const Object _logicCommandUnset = Object();

int _logicCommandNodeSeed = 0;

String _createLogicCommandNodeId() {
  _logicCommandNodeSeed += 1;
  return 'logic_${DateTime.now().microsecondsSinceEpoch}_$_logicCommandNodeSeed';
}
