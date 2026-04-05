enum LogicCommandType {
  moveLeft,
  moveRight,
  jumpUp,
  climbUpLeft,
  climbUpRight,
}

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
