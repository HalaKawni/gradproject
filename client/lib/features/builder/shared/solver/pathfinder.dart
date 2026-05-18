typedef StateKey<TState> = Object Function(TState state);
typedef GoalTest<TState> = bool Function(TState state);
typedef NeighborBuilder<TState, TAction> =
    Iterable<SearchNeighbor<TState, TAction>> Function(TState state);
typedef Heuristic<TState> = double Function(TState state);

class SearchNeighbor<TState, TAction> {
  final TState state;
  final TAction action;
  final double cost;

  const SearchNeighbor({
    required this.state,
    required this.action,
    this.cost = 1,
  });
}

class SearchPath<TState, TAction> {
  final TState initialState;
  final TState finalState;
  final List<TState> states;
  final List<TAction> actions;
  final double totalCost;
  final int expandedStateCount;

  const SearchPath({
    required this.initialState,
    required this.finalState,
    required this.states,
    required this.actions,
    required this.totalCost,
    required this.expandedStateCount,
  });
}

class Pathfinder {
  const Pathfinder();

  SearchPath<TState, TAction>? search<TState, TAction>({
    required TState start,
    required StateKey<TState> stateKey,
    required GoalTest<TState> isGoal,
    required NeighborBuilder<TState, TAction> neighborsFor,
    Heuristic<TState>? heuristic,
    int maxExpandedStates = 20000,
  }) {
    final open = <_SearchNode<TState, TAction>>[
      _SearchNode<TState, TAction>(
        state: start,
        previous: null,
        action: null,
        costFromStart: 0,
        estimatedTotalCost: heuristic?.call(start) ?? 0,
      ),
    ];
    final bestCosts = <Object, double>{stateKey(start): 0};
    var expandedStateCount = 0;

    while (open.isNotEmpty && expandedStateCount < maxExpandedStates) {
      final current = _removeLowestCostNode(open);
      final currentKey = stateKey(current.state);
      final knownBestCost = bestCosts[currentKey];
      if (knownBestCost != null && current.costFromStart > knownBestCost) {
        continue;
      }

      expandedStateCount += 1;

      if (isGoal(current.state)) {
        return _buildPath(
          node: current,
          expandedStateCount: expandedStateCount,
        );
      }

      for (final neighbor in neighborsFor(current.state)) {
        if (neighbor.cost <= 0) {
          continue;
        }

        final nextCost = current.costFromStart + neighbor.cost;
        final nextKey = stateKey(neighbor.state);
        final previousBestCost = bestCosts[nextKey];
        if (previousBestCost != null && previousBestCost <= nextCost) {
          continue;
        }

        bestCosts[nextKey] = nextCost;
        open.add(
          _SearchNode<TState, TAction>(
            state: neighbor.state,
            previous: current,
            action: neighbor.action,
            costFromStart: nextCost,
            estimatedTotalCost:
                nextCost + (heuristic?.call(neighbor.state) ?? 0),
          ),
        );
      }
    }

    return null;
  }

  _SearchNode<TState, TAction> _removeLowestCostNode<TState, TAction>(
    List<_SearchNode<TState, TAction>> open,
  ) {
    var bestIndex = 0;
    var bestCost = open.first.estimatedTotalCost;

    for (var i = 1; i < open.length; i += 1) {
      final cost = open[i].estimatedTotalCost;
      if (cost < bestCost) {
        bestCost = cost;
        bestIndex = i;
      }
    }

    return open.removeAt(bestIndex);
  }

  SearchPath<TState, TAction> _buildPath<TState, TAction>({
    required _SearchNode<TState, TAction> node,
    required int expandedStateCount,
  }) {
    final states = <TState>[];
    final actions = <TAction>[];
    var current = node;

    while (true) {
      states.add(current.state);
      final action = current.action;
      if (action != null) {
        actions.add(action);
      }

      final previous = current.previous;
      if (previous == null) {
        break;
      }
      current = previous;
    }

    return SearchPath<TState, TAction>(
      initialState: states.last,
      finalState: states.first,
      states: List<TState>.unmodifiable(states.reversed),
      actions: List<TAction>.unmodifiable(actions.reversed),
      totalCost: node.costFromStart,
      expandedStateCount: expandedStateCount,
    );
  }
}

class _SearchNode<TState, TAction> {
  final TState state;
  final _SearchNode<TState, TAction>? previous;
  final TAction? action;
  final double costFromStart;
  final double estimatedTotalCost;

  const _SearchNode({
    required this.state,
    required this.previous,
    required this.action,
    required this.costFromStart,
    required this.estimatedTotalCost,
  });
}
