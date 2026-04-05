class TileData {
  final String type;
  final int x;
  final int y;

  const TileData({
    required this.type,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'x': x,
      'y': y,
    };
  }

  factory TileData.fromJson(Map<String, dynamic> json) {
    return TileData(
      type: json['type'] ?? 'floor',
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
    );
  }

  TileData copyWith({
    String? type,
    int? x,
    int? y,
  }) {
    return TileData(
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}