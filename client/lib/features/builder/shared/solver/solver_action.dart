import 'grid_position.dart';

enum SolverActionType {
  moveUp,
  moveRight,
  moveDown,
  moveLeft,
  jumpUp,
  climbUpLeft,
  climbUpRight,
}

extension SolverActionTypeExtension on SolverActionType {
  String get label {
    switch (this) {
      case SolverActionType.moveUp:
        return 'Move Up';
      case SolverActionType.moveRight:
        return 'Move Right';
      case SolverActionType.moveDown:
        return 'Move Down';
      case SolverActionType.moveLeft:
        return 'Move Left';
      case SolverActionType.jumpUp:
        return 'Jump Up';
      case SolverActionType.climbUpLeft:
        return 'Climb Up Left';
      case SolverActionType.climbUpRight:
        return 'Climb Up Right';
    }
  }
}

class SolverAction {
  final SolverActionType type;
  final GridPosition from;
  final GridPosition to;
  final List<GridPosition> visitedPositions;

  const SolverAction({
    required this.type,
    required this.from,
    required this.to,
    this.visitedPositions = const [],
  });
}
