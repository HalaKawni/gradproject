import 'dart:math' as math;

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
    var currentHeadingDegrees = _normalizeDegrees(initialHeadingDegrees);
    var pendingStepDistance = 0.0;

    for (final action in actions) {
      final requiredHeadingDegrees = _headingDegreesForAction(action);
      if (requiredHeadingDegrees == null) {
        continue;
      }
      final stepDistance = _stepDistanceForAction(action);

      if (!_sameHeading(requiredHeadingDegrees, currentHeadingDegrees)) {
        if (pendingStepDistance > 0) {
          lines.add('step ${_formatNumber(pendingStepDistance)}');
          pendingStepDistance = 0;
        }
        lines.add(
          useTurnAngles
              ? 'turn ${_formatAngle(requiredHeadingDegrees)}'
              : 'turn ${_TopViewHeading.fromDegrees(requiredHeadingDegrees).commandName}',
        );
        currentHeadingDegrees = requiredHeadingDegrees;
      }

      pendingStepDistance += stepDistance;
    }

    if (pendingStepDistance > 0) {
      lines.add('step ${_formatNumber(pendingStepDistance)}');
    }

    return lines.join('\n');
  }

  double? _headingDegreesForAction(SolverAction action) {
    final dx = action.to.x - action.from.x;
    final dy = action.to.y - action.from.y;

    if (dx != 0 || dy != 0) {
      return _normalizeDegrees(math.atan2(-dy, dx) * 180 / math.pi);
    }

    switch (action.type) {
      case SolverActionType.moveRight:
        return _TopViewHeading.right.degrees.toDouble();
      case SolverActionType.moveUp:
        return _TopViewHeading.up.degrees.toDouble();
      case SolverActionType.moveLeft:
        return _TopViewHeading.left.degrees.toDouble();
      case SolverActionType.moveDown:
        return _TopViewHeading.down.degrees.toDouble();
      case SolverActionType.jumpUp:
      case SolverActionType.climbUpLeft:
      case SolverActionType.climbUpRight:
        return null;
    }
  }

  double _stepDistanceForAction(SolverAction action) {
    final dx = action.to.x - action.from.x;
    final dy = action.to.y - action.from.y;
    final distance = math.max(dx.abs(), dy.abs()).toDouble();
    return distance == 0 ? 1 : distance;
  }
}

bool _sameHeading(double a, double b) {
  return (_normalizeDegrees(a) - _normalizeDegrees(b)).abs() < 0.001;
}

double _normalizeDegrees(double value) {
  final normalized = value % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

String _formatNumber(double value) {
  if ((value - value.round()).abs() < 0.001) {
    return value.round().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatAngle(double value) {
  return _normalizeDegrees(value).round().toString();
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
