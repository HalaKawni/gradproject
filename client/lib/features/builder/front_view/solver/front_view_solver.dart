import '../../shared/solver/grid_position.dart';
import '../../shared/solver/pathfinder.dart';
import '../../shared/solver/solver_action.dart';
import '../../shared/solver/solver_result.dart';
import '../models/builder_project.dart';
import '../models/entity_data.dart';
import '../models/logic_command.dart';

class FrontViewSolver {
  final Pathfinder _pathfinder;

  const FrontViewSolver({Pathfinder pathfinder = const Pathfinder()})
    : _pathfinder = pathfinder;

  SolverResult findShortestPath({
    required BuilderProject project,
    bool requireAllCollectablesForSuccess = true,
    int maxExpandedStates = 20000,
  }) {
    final playerStart = _firstEntityOfType(project.entities, 'playerStart');
    if (playerStart == null) {
      return SolverResult.failure(
        message: 'The level has no player start.',
        expandedStateCount: 0,
      );
    }

    final goal = _firstEntityOfType(project.entities, 'goal');
    if (goal == null) {
      return SolverResult.failure(
        message: 'The level has no goal.',
        expandedStateCount: 0,
      );
    }

    final solidTiles = <GridPosition>{
      for (final tile in project.tiles) GridPosition(x: tile.x, y: tile.y),
    };
    final collectableIndexes = _buildCollectableIndexes(project.entities);
    final allCollectedKey = _collectionKey(
      Set<int>.from(Iterable<int>.generate(collectableIndexes.length)),
    );
    final startPosition = GridPosition(x: playerStart.x, y: playerStart.y);
    final goalPosition = GridPosition(x: goal.x, y: goal.y);

    if (!_isInBounds(project, startPosition)) {
      return SolverResult.failure(
        message: 'The player start is outside the level.',
        expandedStateCount: 0,
      );
    }

    if (!_isInBounds(project, goalPosition)) {
      return SolverResult.failure(
        message: 'The goal is outside the level.',
        expandedStateCount: 0,
      );
    }

    if (solidTiles.contains(startPosition)) {
      return SolverResult.failure(
        message: 'The player start is blocked by a tile.',
        expandedStateCount: 0,
      );
    }

    if (solidTiles.contains(goalPosition)) {
      return SolverResult.failure(
        message: 'The goal is blocked by a tile.',
        expandedStateCount: 0,
      );
    }

    final startCollected = <int>{};
    final startCollectableIndex = collectableIndexes[startPosition];
    if (startCollectableIndex != null) {
      startCollected.add(startCollectableIndex);
    }

    final settledStart = _resolveFallingPosition(
      project: project,
      solidTiles: solidTiles,
      collectableIndexes: collectableIndexes,
      start: startPosition,
      collectedIndexes: startCollected,
    );

    if (settledStart == null) {
      return SolverResult.failure(
        message: 'The player start falls out of the level.',
        expandedStateCount: 0,
      );
    }

    final searchPath = _pathfinder.search<_FrontViewState, SolverAction>(
      start: _FrontViewState(
        position: settledStart.position,
        collectedIndexes: settledStart.collectedIndexes,
      ),
      stateKey: (state) => state.key,
      isGoal: (state) {
        final hasReachedGoal = state.position == goalPosition;
        if (!hasReachedGoal) {
          return false;
        }
        return !requireAllCollectablesForSuccess ||
            state.collectedKey == allCollectedKey;
      },
      neighborsFor: (state) => _neighborsFor(
        project: project,
        solidTiles: solidTiles,
        collectableIndexes: collectableIndexes,
        state: state,
      ),
      heuristic: (state) => _heuristic(
        goal: goalPosition,
        collectableIndexes: collectableIndexes,
        requireAllCollectablesForSuccess: requireAllCollectablesForSuccess,
        state: state,
      ),
      maxExpandedStates: maxExpandedStates,
    );

    if (searchPath == null) {
      return SolverResult.failure(
        message: requireAllCollectablesForSuccess
            ? 'No path collects all collectables and reaches the goal.'
            : 'No path reaches the goal.',
        expandedStateCount: maxExpandedStates,
      );
    }

    return SolverResult.success(
      path: searchPath.states.map((state) => state.position).toList(),
      actions: searchPath.actions,
      expandedStateCount: searchPath.expandedStateCount,
    );
  }

  Iterable<SearchNeighbor<_FrontViewState, SolverAction>> _neighborsFor({
    required BuilderProject project,
    required Set<GridPosition> solidTiles,
    required Map<GridPosition, int> collectableIndexes,
    required _FrontViewState state,
  }) sync* {
    const moves = <_FrontViewMove>[
      _FrontViewMove(
        actionType: SolverActionType.moveLeft,
        commandType: LogicCommandType.moveLeft,
      ),
      _FrontViewMove(
        actionType: SolverActionType.moveRight,
        commandType: LogicCommandType.moveRight,
      ),
      _FrontViewMove(
        actionType: SolverActionType.jumpUp,
        commandType: LogicCommandType.jumpUp,
      ),
      _FrontViewMove(
        actionType: SolverActionType.climbUpLeft,
        commandType: LogicCommandType.climbUpLeft,
      ),
      _FrontViewMove(
        actionType: SolverActionType.climbUpRight,
        commandType: LogicCommandType.climbUpRight,
      ),
    ];

    for (final move in moves) {
      final nextPosition = state.position.translate(
        dx: move.commandType.deltaX,
        dy: move.commandType.deltaY,
      );

      if (!_isInBounds(project, nextPosition) ||
          solidTiles.contains(nextPosition)) {
        continue;
      }

      final nextCollected = <int>{...state.collectedIndexes};
      final directCollectableIndex = collectableIndexes[nextPosition];
      if (directCollectableIndex != null) {
        nextCollected.add(directCollectableIndex);
      }

      final settledPosition = _resolveFallingPosition(
        project: project,
        solidTiles: solidTiles,
        collectableIndexes: collectableIndexes,
        start: nextPosition,
        collectedIndexes: nextCollected,
      );

      if (settledPosition == null) {
        continue;
      }

      yield SearchNeighbor<_FrontViewState, SolverAction>(
        state: _FrontViewState(
          position: settledPosition.position,
          collectedIndexes: settledPosition.collectedIndexes,
        ),
        action: SolverAction(
          type: move.actionType,
          from: state.position,
          to: settledPosition.position,
          visitedPositions: settledPosition.fallPath,
        ),
      );
    }
  }

  _ResolvedFrontViewPosition? _resolveFallingPosition({
    required BuilderProject project,
    required Set<GridPosition> solidTiles,
    required Map<GridPosition, int> collectableIndexes,
    required GridPosition start,
    required Set<int> collectedIndexes,
  }) {
    var current = start;
    final nextCollectedIndexes = <int>{...collectedIndexes};
    final fallPath = <GridPosition>[start];

    while (true) {
      final below = current.translate(dx: 0, dy: 1);
      if (below.y >= project.settings.rows) {
        return null;
      }

      if (solidTiles.contains(below)) {
        return _ResolvedFrontViewPosition(
          position: current,
          collectedIndexes: nextCollectedIndexes,
          fallPath: fallPath,
        );
      }

      current = below;
      fallPath.add(current);
      final collectableIndex = collectableIndexes[current];
      if (collectableIndex != null) {
        nextCollectedIndexes.add(collectableIndex);
      }
    }
  }

  double _heuristic({
    required GridPosition goal,
    required Map<GridPosition, int> collectableIndexes,
    required bool requireAllCollectablesForSuccess,
    required _FrontViewState state,
  }) {
    if (!requireAllCollectablesForSuccess) {
      return state.position.manhattanDistanceTo(goal).toDouble();
    }

    final uncollected = <GridPosition>[];
    for (final entry in collectableIndexes.entries) {
      if (!state.collectedIndexes.contains(entry.value)) {
        uncollected.add(entry.key);
      }
    }

    if (uncollected.isEmpty) {
      return state.position.manhattanDistanceTo(goal).toDouble();
    }

    var nearestCollectableDistance = double.infinity;
    var nearestGoalDistance = double.infinity;
    for (final collectable in uncollected) {
      final collectableDistance = state.position.manhattanDistanceTo(
        collectable,
      );
      if (collectableDistance < nearestCollectableDistance) {
        nearestCollectableDistance = collectableDistance.toDouble();
      }

      final goalDistance = collectable.manhattanDistanceTo(goal);
      if (goalDistance < nearestGoalDistance) {
        nearestGoalDistance = goalDistance.toDouble();
      }
    }

    return nearestCollectableDistance + nearestGoalDistance;
  }

  bool _isInBounds(BuilderProject project, GridPosition position) {
    return position.x >= 0 &&
        position.x < project.settings.columns &&
        position.y >= 0 &&
        position.y < project.settings.rows;
  }

  EntityData? _firstEntityOfType(List<EntityData> entities, String type) {
    for (final entity in entities) {
      if (entity.type == type) {
        return entity;
      }
    }
    return null;
  }

  Map<GridPosition, int> _buildCollectableIndexes(List<EntityData> entities) {
    final collectableIndexes = <GridPosition, int>{};
    var index = 0;

    for (final entity in entities) {
      if (entity.type != 'collectable') {
        continue;
      }

      collectableIndexes[GridPosition(x: entity.x, y: entity.y)] = index;
      index += 1;
    }

    return collectableIndexes;
  }
}

class _FrontViewState {
  final GridPosition position;
  final Set<int> collectedIndexes;

  const _FrontViewState({
    required this.position,
    required this.collectedIndexes,
  });

  String get collectedKey => _collectionKey(collectedIndexes);

  String get key => '${position.x},${position.y}|$collectedKey';
}

class _FrontViewMove {
  final SolverActionType actionType;
  final LogicCommandType commandType;

  const _FrontViewMove({required this.actionType, required this.commandType});
}

class _ResolvedFrontViewPosition {
  final GridPosition position;
  final Set<int> collectedIndexes;
  final List<GridPosition> fallPath;

  const _ResolvedFrontViewPosition({
    required this.position,
    required this.collectedIndexes,
    required this.fallPath,
  });
}

String _collectionKey(Set<int> indexes) {
  if (indexes.isEmpty) {
    return '';
  }

  final sortedIndexes = indexes.toList()..sort();
  return sortedIndexes.join(',');
}
