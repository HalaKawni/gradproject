import 'grid_position.dart';
import 'solver_action.dart';

class SolverResult {
  final bool solved;
  final String? failureMessage;
  final List<GridPosition> path;
  final List<SolverAction> actions;
  final int expandedStateCount;

  const SolverResult._({
    required this.solved,
    required this.failureMessage,
    required this.path,
    required this.actions,
    required this.expandedStateCount,
  });

  factory SolverResult.success({
    required List<GridPosition> path,
    required List<SolverAction> actions,
    required int expandedStateCount,
  }) {
    return SolverResult._(
      solved: true,
      failureMessage: null,
      path: List<GridPosition>.unmodifiable(path),
      actions: List<SolverAction>.unmodifiable(actions),
      expandedStateCount: expandedStateCount,
    );
  }

  factory SolverResult.failure({
    required String message,
    required int expandedStateCount,
  }) {
    return SolverResult._(
      solved: false,
      failureMessage: message,
      path: const [],
      actions: const [],
      expandedStateCount: expandedStateCount,
    );
  }
}
