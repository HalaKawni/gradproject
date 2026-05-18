import '../../shared/solver/grid_position.dart';

class TopViewLevelGrid {
  final int columns;
  final int rows;
  final GridPosition start;
  final GridPosition goal;
  final Set<GridPosition> obstacles;
  final Set<GridPosition> collectables;

  const TopViewLevelGrid({
    required this.columns,
    required this.rows,
    required this.start,
    required this.goal,
    this.obstacles = const {},
    this.collectables = const {},
  });

  bool isInBounds(GridPosition position) {
    return position.x >= 0 &&
        position.x < columns &&
        position.y >= 0 &&
        position.y < rows;
  }

  bool isBlocked(GridPosition position) {
    return obstacles.contains(position);
  }
}
