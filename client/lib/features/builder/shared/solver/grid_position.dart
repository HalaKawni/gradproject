class GridPosition {
  final int x;
  final int y;

  const GridPosition({required this.x, required this.y});

  int manhattanDistanceTo(GridPosition other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  GridPosition translate({required int dx, required int dy}) {
    return GridPosition(x: x + dx, y: y + dy);
  }

  @override
  bool operator ==(Object other) {
    return other is GridPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'GridPosition(x: $x, y: $y)';
}
