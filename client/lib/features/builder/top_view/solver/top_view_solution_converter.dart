import '../../shared/solver/path_to_solution_converter.dart';
import '../../shared/solver/solver_action.dart';

class TopViewSolutionConverter extends PathToSolutionConverter<String> {
  final double initialHeadingDegrees;
  final bool useTurnAngles;

  const TopViewSolutionConverter({
    this.initialHeadingDegrees = 0,
    this.useTurnAngles = false,
  });

  @override
  String convert(List<SolverAction> actions) {
    if (actions.isEmpty) {
      return '';
    }

    final lines = <String>[];
    var currentHeading = _TopViewHeading.fromDegrees(initialHeadingDegrees);
    var pendingStepCount = 0;

    for (final action in actions) {
      final requiredHeading = _headingForAction(action);
      if (requiredHeading == null) {
        continue;
      }

      if (requiredHeading != currentHeading) {
        if (pendingStepCount > 0) {
          lines.add('step $pendingStepCount');
          pendingStepCount = 0;
        }
        lines.add(
          useTurnAngles
              ? 'turn ${requiredHeading.degrees}'
              : 'turn ${requiredHeading.commandName}',
        );
        currentHeading = requiredHeading;
      }

      pendingStepCount += 1;
    }

    if (pendingStepCount > 0) {
      lines.add('step $pendingStepCount');
    }

    return lines.join('\n');
  }

  _TopViewHeading? _headingForAction(SolverAction action) {
    final dx = action.to.x - action.from.x;
    final dy = action.to.y - action.from.y;

    if (dx == 1 && dy == 0) {
      return _TopViewHeading.right;
    }
    if (dx == -1 && dy == 0) {
      return _TopViewHeading.left;
    }
    if (dx == 0 && dy == -1) {
      return _TopViewHeading.up;
    }
    if (dx == 0 && dy == 1) {
      return _TopViewHeading.down;
    }

    switch (action.type) {
      case SolverActionType.moveRight:
        return _TopViewHeading.right;
      case SolverActionType.moveUp:
        return _TopViewHeading.up;
      case SolverActionType.moveLeft:
        return _TopViewHeading.left;
      case SolverActionType.moveDown:
        return _TopViewHeading.down;
      case SolverActionType.jumpUp:
      case SolverActionType.climbUpLeft:
      case SolverActionType.climbUpRight:
        return null;
    }
  }
}

enum _TopViewHeading {
  right(0, 'right'),
  up(90, 'up'),
  left(180, 'left'),
  down(270, 'down');

  final int degrees;
  final String commandName;

  const _TopViewHeading(this.degrees, this.commandName);

  static _TopViewHeading fromDegrees(double value) {
    final normalized = value % 360;
    final positiveDegrees = normalized < 0 ? normalized + 360 : normalized;
    final roundedDegrees = positiveDegrees.round() % 360;

    switch (roundedDegrees) {
      case 90:
        return _TopViewHeading.up;
      case 180:
        return _TopViewHeading.left;
      case 270:
        return _TopViewHeading.down;
      case 0:
      default:
        return _TopViewHeading.right;
    }
  }
}
