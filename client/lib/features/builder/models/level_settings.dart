enum BuilderGridSizePreset { medium, large }

extension BuilderGridSizePresetExtension on BuilderGridSizePreset {
  String get shortLabel {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 'S';
      case BuilderGridSizePreset.large:
        return 'L';
    }
  }

  String get label {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 'Small';
      case BuilderGridSizePreset.large:
        return 'Large';
    }
  }

  double get tileSize {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 40;
      case BuilderGridSizePreset.large:
        return 80;
    }
  }

  int get columns {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 24;
      case BuilderGridSizePreset.large:
        return 12;
    }
  }

  int get rows {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 14;
      case BuilderGridSizePreset.large:
        return 7;
    }
  }

  int get groundRows {
    switch (this) {
      case BuilderGridSizePreset.medium:
        return 4;
      case BuilderGridSizePreset.large:
        return 2;
    }
  }
}

class LevelSettings {
  static const double minTileSize = 20;
  static const double maxTileSize = 80;
  static const double defaultTileSize = 40;
  static const double defaultViewportWidth = 960;
  static const double defaultViewportHeight = 560;

  final int rows;
  final int columns;
  final double tileSize;
  final String theme;

  final double viewportWidth;
  final double viewportHeight;

  const LevelSettings({
    required this.rows,
    required this.columns,
    required this.tileSize,
    required this.theme,
    this.viewportWidth = defaultViewportWidth,
    this.viewportHeight = defaultViewportHeight,
  });

  factory LevelSettings.initial() {
    return const LevelSettings(
      rows: 14,
      columns: 24,
      tileSize: defaultTileSize,
      theme: 'forest',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'columns': columns,
      'tileSize': tileSize,
      'theme': theme,
      'viewportWidth': viewportWidth,
      'viewportHeight': viewportHeight,
    };
  }

  factory LevelSettings.fromJson(Map<String, dynamic> json) {
    return LevelSettings(
      rows: json['rows'] ?? 14,
      columns: json['columns'] ?? 24,
      tileSize: clampTileSize((json['tileSize'] ?? defaultTileSize).toDouble()),
      theme: json['theme'] ?? 'forest',
      viewportWidth:
          (json['viewportWidth'] ?? defaultViewportWidth).toDouble(),
      viewportHeight:
          (json['viewportHeight'] ?? defaultViewportHeight).toDouble(),
    );
  }

  static double clampTileSize(double value) {
    if (value < minTileSize) {
      return minTileSize;
    }

    if (value > maxTileSize) {
      return maxTileSize;
    }

    return value;
  }

  static BuilderGridSizePreset closestPresetForTileSize(double tileSize) {
    BuilderGridSizePreset closestPreset = BuilderGridSizePreset.medium;
    double closestDifference = double.infinity;

    for (final preset in BuilderGridSizePreset.values) {
      final difference = (preset.tileSize - tileSize).abs();
      if (difference < closestDifference) {
        closestPreset = preset;
        closestDifference = difference;
      }
    }

    return closestPreset;
  }

  static int requiredGroundRowsForTileSize(double tileSize) {
    return closestPresetForTileSize(tileSize).groundRows;
  }

  LevelSettings copyWith({
    int? rows,
    int? columns,
    double? tileSize,
    String? theme,
    double? viewportWidth,
    double? viewportHeight,
  }) {
    return LevelSettings(
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      tileSize: tileSize ?? this.tileSize,
      theme: theme ?? this.theme,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
    );
  }
}
