import 'dart:math' as math;

import '../../shared/solver/grid_position.dart';
import '../../shared/solver/pathfinder.dart';
import '../../shared/solver/solver_action.dart';
import '../../shared/solver/solver_result.dart';
import 'top_view_level_grid.dart';

class TopViewSolver {
  final Pathfinder _pathfinder;

  const TopViewSolver({Pathfinder pathfinder = const Pathfinder()})
    : _pathfinder = pathfinder;

  SolverResult findShortestPath({
    required TopViewLevelGrid level,
    int maxExpandedStates = 20000,
    bool allowDiagonalMoves = false,
  }) {
    final collectableList = level.collectables.toList(growable: false);
    final collectableIndexes = <GridPosition, int>{
      for (var i = 0; i < collectableList.length; i += 1) collectableList[i]: i,
    };
    final allCollectedKey = _collectionKey(
      Set<int>.from(Iterable<int>.generate(collectableList.length)),
    );
    final startCollected = <int>{};
    final startCollectableIndex = collectableIndexes[level.start];
    if (startCollectableIndex != null) {
      startCollected.add(startCollectableIndex);
    }

    if (!level.isInBounds(level.start)) {
      return SolverResult.failure(
        message: 'The start position is outside the grid.',
        expandedStateCount: 0,
      );
    }

    if (!level.isInBounds(level.goal)) {
      return SolverResult.failure(
        message: 'The goal position is outside the grid.',
        expandedStateCount: 0,
      );
    }

    if (level.isBlocked(level.start)) {
      return SolverResult.failure(
        message: 'The start position is blocked by an obstacle.',
        expandedStateCount: 0,
      );
    }

    if (level.isBlocked(level.goal)) {
      return SolverResult.failure(
        message: 'The goal position is blocked by an obstacle.',
        expandedStateCount: 0,
      );
    }

    final searchPath = _pathfinder.search<_CollectingGridState, SolverAction>(
      start: _CollectingGridState(
        position: level.start,
        collectedIndexes: startCollected,
      ),
      stateKey: (state) => state.key,
      isGoal: (state) =>
          state.position == level.goal && state.collectedKey == allCollectedKey,
      neighborsFor: (state) => _neighborsFor(
        level,
        collectableIndexes,
        state,
        allowDiagonalMoves: allowDiagonalMoves,
      ),
      heuristic: (state) => _heuristic(
        level,
        collectableList,
        state,
        allowDiagonalMoves: allowDiagonalMoves,
      ),
      maxExpandedStates: maxExpandedStates,
    );

    if (searchPath == null) {
      return SolverResult.failure(
        message: 'No path collects all collectables and reaches the goal.',
        expandedStateCount: maxExpandedStates,
      );
    }

    return SolverResult.success(
      path: searchPath.states.map((state) => state.position).toList(),
      actions: searchPath.actions,
      expandedStateCount: searchPath.expandedStateCount,
    );
  }

  Iterable<SearchNeighbor<_CollectingGridState, SolverAction>> _neighborsFor(
    TopViewLevelGrid level,
    Map<GridPosition, int> collectableIndexes,
    _CollectingGridState state, {
    required bool allowDiagonalMoves,
  }) sync* {
    if (allowDiagonalMoves) {
      yield* _angleNeighborsFor(level, collectableIndexes, state);
      return;
    }

    final moves = <_TopViewMove>[
      _TopViewMove(type: SolverActionType.moveUp, dx: 0, dy: -1),
      _TopViewMove(type: SolverActionType.moveRight, dx: 1, dy: 0),
      _TopViewMove(type: SolverActionType.moveDown, dx: 0, dy: 1),
      _TopViewMove(type: SolverActionType.moveLeft, dx: -1, dy: 0),
    ];

    for (final move in moves) {
      final nextPosition = state.position.translate(dx: move.dx, dy: move.dy);
      if (!level.isInBounds(nextPosition) || level.isBlocked(nextPosition)) {
        continue;
      }

      final nextCollected = <int>{...state.collectedIndexes};
      final collectableIndex = collectableIndexes[nextPosition];
      if (collectableIndex != null) {
        nextCollected.add(collectableIndex);
      }

      yield SearchNeighbor<_CollectingGridState, SolverAction>(
        state: _CollectingGridState(
          position: nextPosition,
          collectedIndexes: nextCollected,
        ),
        action: SolverAction(
          type: move.type,
          from: state.position,
          to: nextPosition,
          visitedPositions: <GridPosition>[nextPosition],
        ),
        cost: math.max(move.dx.abs(), move.dy.abs()).toDouble(),
      );
    }
  }

  Iterable<SearchNeighbor<_CollectingGridState, SolverAction>>
  _angleNeighborsFor(
    TopViewLevelGrid level,
    Map<GridPosition, int> collectableIndexes,
    _CollectingGridState state,
  ) sync* {
    for (var y = 0; y < level.rows; y += 1) {
      for (var x = 0; x < level.columns; x += 1) {
        final nextPosition = GridPosition(x: x, y: y);
        if (nextPosition == state.position || level.isBlocked(nextPosition)) {
          continue;
        }
        if (!_hasClearStraightPath(level, state.position, nextPosition)) {
          continue;
        }

        final nextCollected = <int>{...state.collectedIndexes};
        final collectableIndex = collectableIndexes[nextPosition];
        if (collectableIndex != null) {
          nextCollected.add(collectableIndex);
        }

        yield SearchNeighbor<_CollectingGridState, SolverAction>(
          state: _CollectingGridState(
            position: nextPosition,
            collectedIndexes: nextCollected,
          ),
          action: SolverAction(
            type: _actionTypeForDelta(
              dx: nextPosition.x - state.position.x,
              dy: nextPosition.y - state.position.y,
            ),
            from: state.position,
            to: nextPosition,
            visitedPositions: <GridPosition>[nextPosition],
          ),
          cost: _distanceEstimate(
            state.position,
            nextPosition,
            allowDiagonalMoves: true,
          ),
        );
      }
    }
  }

  bool _hasClearStraightPath(
    TopViewLevelGrid level,
    GridPosition from,
    GridPosition to,
  ) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final stepCount = math.max(dx.abs(), dy.abs());
    final sampleCount = math.max(1, stepCount * 8);

    for (var i = 1; i <= sampleCount; i += 1) {
      final t = i / sampleCount;
      final x = from.x + 0.5 + dx * t;
      final y = from.y + 0.5 + dy * t;
      final position = GridPosition(x: x.floor(), y: y.floor());

      if (!level.isInBounds(position)) {
        return false;
      }
      if (position != from && level.isBlocked(position)) {
        return false;
      }
    }

    return true;
  }

  SolverActionType _actionTypeForDelta({required int dx, required int dy}) {
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? SolverActionType.moveRight : SolverActionType.moveLeft;
    }

    return dy >= 0 ? SolverActionType.moveDown : SolverActionType.moveUp;
  }

  double _heuristic(
    TopViewLevelGrid level,
    List<GridPosition> collectables,
    _CollectingGridState state, {
    required bool allowDiagonalMoves,
  }) {
    final uncollected = <GridPosition>[];
    for (var i = 0; i < collectables.length; i += 1) {
      if (!state.collectedIndexes.contains(i)) {
        uncollected.add(collectables[i]);
      }
    }

    if (uncollected.isEmpty) {
      return _distanceEstimate(
        state.position,
        level.goal,
        allowDiagonalMoves: allowDiagonalMoves,
      );
    }

    var nearestCollectableDistance = double.infinity;
    var nearestGoalDistance = double.infinity;
    for (final collectable in uncollected) {
      final collectableDistance = _distanceEstimate(
        state.position,
        collectable,
        allowDiagonalMoves: allowDiagonalMoves,
      );
      if (collectableDistance < nearestCollectableDistance) {
        nearestCollectableDistance = collectableDistance;
      }

      final goalDistance = _distanceEstimate(
        collectable,
        level.goal,
        allowDiagonalMoves: allowDiagonalMoves,
      );
      if (goalDistance < nearestGoalDistance) {
        nearestGoalDistance = goalDistance;
      }
    }

    return nearestCollectableDistance + nearestGoalDistance;
  }

  double _distanceEstimate(
    GridPosition from,
    GridPosition to, {
    required bool allowDiagonalMoves,
  }) {
    final dx = (from.x - to.x).abs();
    final dy = (from.y - to.y).abs();

    if (!allowDiagonalMoves) {
      return (dx + dy).toDouble();
    }

    final diagonalSteps = math.min(dx, dy);
    final straightSteps = (dx - dy).abs();
    return (diagonalSteps + straightSteps).toDouble();
  }
}

class _CollectingGridState {
  final GridPosition position;
  final Set<int> collectedIndexes;

  const _CollectingGridState({
    required this.position,
    required this.collectedIndexes,
  });

  String get collectedKey => _collectionKey(collectedIndexes);

  String get key => '${position.x},${position.y}|$collectedKey';
}

class _TopViewMove {
  final SolverActionType type;
  final int dx;
  final int dy;

  const _TopViewMove({required this.type, required this.dx, required this.dy});
}

String _collectionKey(Set<int> indexes) {
  if (indexes.isEmpty) {
    return '';
  }

  final sortedIndexes = indexes.toList()..sort();
  return sortedIndexes.join(',');
}
