
class EntityData {
  final String id;
  final String type;
  final int x;
  final int y;
  final Map<String, dynamic> config;

  const EntityData({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.config = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'config': config,
    };
  }

  factory EntityData.fromJson(Map<String, dynamic> json) {
    return EntityData(
      id: json['id'] ?? '',
      type: json['type'] ?? 'goal',
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  EntityData copyWith({
    String? id,
    String? type,
    int? x,
    int? y,
    Map<String, dynamic>? config,
  }) {
    return EntityData(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      config: config ?? this.config,
    );
  }
}