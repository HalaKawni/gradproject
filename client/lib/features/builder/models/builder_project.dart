import 'entity_data.dart';
import 'level_settings.dart';
import 'logic_command.dart';
import 'tile_data.dart';

class BuilderProject {
  final String id;
  final String title;
  final String description;
  final String status;
  final LevelSettings settings;
  final List<TileData> tiles;
  final List<EntityData> entities;
  final List<String> solutionCommands;

  const BuilderProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.settings,
    required this.tiles,
    required this.entities,
    required this.solutionCommands,
  });

  factory BuilderProject.initial() {
    final settings = LevelSettings.initial();

    return BuilderProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Level',
      description: '',
      status: 'draft',
      settings: settings,
      tiles: buildGroundTemplate(settings),
      entities: const [],
      solutionCommands: const [],
    );
  }

  static List<TileData> buildGroundTemplate(
    LevelSettings settings, {
    int startColumn = 0,
    int? endColumnExclusive,
  }) {
    if (settings.rows <= 0) {
      return const [];
    }

    final safeStartColumn = startColumn < 0 ? 0 : startColumn;
    final safeEndColumn = endColumnExclusive ?? settings.columns;

    if (safeEndColumn <= safeStartColumn) {
      return const [];
    }

    final groundRowCount = LevelSettings.requiredGroundRowsForTileSize(
      settings.tileSize,
    );
    final firstGroundRow = (settings.rows - groundRowCount).clamp(
      0,
      settings.rows - 1,
    );
    final tiles = <TileData>[];

    for (int y = firstGroundRow; y < settings.rows; y++) {
      for (int x = safeStartColumn; x < safeEndColumn; x++) {
        tiles.add(TileData(type: 'ground', x: x, y: y));
      }
    }

    return tiles;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'settings': settings.toJson(),
      'tiles': tiles.map((tile) => tile.toJson()).toList(),
      'entities': entities.map((entity) => entity.toJson()).toList(),
      'solutionCommands': solutionCommands,
    };
  }

  factory BuilderProject.fromJson(Map<String, dynamic> json) {
    return BuilderProject(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      status: json['status'] ?? 'draft',
      settings: LevelSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] ?? {}),
      ),
      tiles: (json['tiles'] as List<dynamic>? ?? [])
          .map((tile) => TileData.fromJson(Map<String, dynamic>.from(tile)))
          .toList(),
      entities: (json['entities'] as List<dynamic>? ?? [])
          .map(
            (entity) => EntityData.fromJson(Map<String, dynamic>.from(entity)),
          )
          .toList(),
      solutionCommands: (json['solutionCommands'] as List<dynamic>? ?? [])
          .whereType<String>()
          .map((command) => LogicCommandTypeExtension.fromString(command).value)
          .toList(),
    );
  }

  BuilderProject copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    LevelSettings? settings,
    List<TileData>? tiles,
    List<EntityData>? entities,
    List<String>? solutionCommands,
  }) {
    return BuilderProject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      tiles: tiles ?? this.tiles,
      entities: entities ?? this.entities,
      solutionCommands: solutionCommands ?? this.solutionCommands,
    );
  }
}
