import 'dart:convert';

import '../../front_view/shared/builder_character.dart';
import '../../front_view/shared/builder_collectable.dart';

enum FourthDemoStageTool { select, move, brush, eraser }

enum FourthDemoAssetTab { sprites, widgets, sounds, game }

enum FourthDemoPaletteTab { movement, events, display, control, operators }

enum FourthDemoPhysicsMode { none, arcade }

enum FourthDemoSpriteKind { player, collectible, prop }

enum FourthDemoSpriteFacing { left, right }

enum FourthDemoWidgetKind { counter, text, timer, clock, button, dialog }

enum FourthDemoActionType {
  step,
  jump,
  setX,
  setY,
  setRotation,
  setSpeed,
  setAllowGravity,
  show,
  hide,
  destroy,
  disable,
  enable,
  setScale,
  setBackground,
  say,
  wait,
  repeat,
  ifCondition,
  times,
  loop,
  ifTouching,
}

class FourthDemoProject {
  final String id;
  final String title;
  final int currentExercise;
  final FourthDemoGameSettings settings;
  final List<FourthDemoSprite> sprites;
  final List<FourthDemoScreenWidget> widgets;
  final List<FourthDemoSound> sounds;
  final FourthDemoTilemap tilemap;
  final String selectedSpriteId;
  final Map<String, String> codeBySpriteId;
  final List<FourthDemoEventHandler> events;

  const FourthDemoProject({
    required this.id,
    required this.title,
    required this.currentExercise,
    required this.settings,
    required this.sprites,
    required this.widgets,
    required this.sounds,
    required this.tilemap,
    required this.selectedSpriteId,
    required this.codeBySpriteId,
    required this.events,
  });

  static const starterCode = '@onKey = (key) =>\n    # Add code here';

  factory FourthDemoProject.sample() {
    return const FourthDemoProject(
      id: 'project-1',
      title: 'Mini Course Exercise 1',
      currentExercise: 1,
      settings: FourthDemoGameSettings(
        worldWidth: 600,
        worldHeight: 400,
        gravity: 0,
        physicsMode: FourthDemoPhysicsMode.arcade,
        cameraTargetId: 'polar',
        background: 'forest',
      ),
      sprites: <FourthDemoSprite>[
        FourthDemoSprite(
          id: 'polar',
          name: 'polar',
          kind: FourthDemoSpriteKind.player,
          assetId: defaultBuilderCharacterId,
          facing: FourthDemoSpriteFacing.right,
          x: 72,
          y: 284,
          startX: 72,
          startY: 284,
          width: 58,
          height: 58,
          colorValue: 0xFF9A5B26,
          speed: 34,
          draggable: true,
          collideWorldBounds: true,
          collideOtherSprites: true,
        ),
        FourthDemoSprite(
          id: 'banana',
          name: 'banana',
          kind: FourthDemoSpriteKind.collectible,
          assetId: defaultBuilderCollectableId,
          x: 462,
          y: 286,
          startX: 462,
          startY: 286,
          width: 48,
          height: 48,
          colorValue: 0xFFFFC928,
          immovable: true,
          draggable: true,
        ),
      ],
      widgets: <FourthDemoScreenWidget>[],
      sounds: <FourthDemoSound>[
        FourthDemoSound(id: 'collect', name: 'Collect sparkle'),
      ],
      tilemap: FourthDemoTilemap(
        columns: 15,
        rows: 10,
        tiles: <FourthDemoTile>[
          FourthDemoTile(x: 0, y: 9, type: 'ground'),
          FourthDemoTile(x: 1, y: 9, type: 'ground'),
          FourthDemoTile(x: 2, y: 9, type: 'ground'),
          FourthDemoTile(x: 3, y: 9, type: 'ground'),
          FourthDemoTile(x: 4, y: 9, type: 'ground'),
          FourthDemoTile(x: 5, y: 9, type: 'ground'),
          FourthDemoTile(x: 6, y: 9, type: 'ground'),
          FourthDemoTile(x: 7, y: 9, type: 'ground'),
          FourthDemoTile(x: 8, y: 9, type: 'ground'),
          FourthDemoTile(x: 9, y: 9, type: 'ground'),
          FourthDemoTile(x: 10, y: 9, type: 'ground'),
          FourthDemoTile(x: 11, y: 9, type: 'ground'),
          FourthDemoTile(x: 12, y: 9, type: 'ground'),
          FourthDemoTile(x: 13, y: 9, type: 'ground'),
          FourthDemoTile(x: 14, y: 9, type: 'ground'),
        ],
      ),
      selectedSpriteId: 'polar',
      codeBySpriteId: <String, String>{'polar': starterCode, 'banana': ''},
      events: <FourthDemoEventHandler>[],
    );
  }

  FourthDemoSprite? get selectedSprite {
    for (final sprite in sprites) {
      if (sprite.id == selectedSpriteId) {
        return sprite;
      }
    }
    return null;
  }

  FourthDemoProject copyWith({
    String? title,
    int? currentExercise,
    FourthDemoGameSettings? settings,
    List<FourthDemoSprite>? sprites,
    List<FourthDemoScreenWidget>? widgets,
    List<FourthDemoSound>? sounds,
    FourthDemoTilemap? tilemap,
    String? selectedSpriteId,
    Map<String, String>? codeBySpriteId,
    List<FourthDemoEventHandler>? events,
  }) {
    return FourthDemoProject(
      id: id,
      title: title ?? this.title,
      currentExercise: currentExercise ?? this.currentExercise,
      settings: settings ?? this.settings,
      sprites: sprites ?? this.sprites,
      widgets: widgets ?? this.widgets,
      sounds: sounds ?? this.sounds,
      tilemap: tilemap ?? this.tilemap,
      selectedSpriteId: selectedSpriteId ?? this.selectedSpriteId,
      codeBySpriteId: codeBySpriteId ?? this.codeBySpriteId,
      events: events ?? this.events,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (sprites.isEmpty) {
      errors.add('Add at least one sprite.');
    }
    if (!sprites.any((sprite) => sprite.id == selectedSpriteId)) {
      errors.add('No player sprite selected.');
    }
    if (settings.worldWidth <= 0 || settings.worldHeight <= 0) {
      errors.add('World size must be bigger than zero.');
    }
    return errors;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'currentExercise': currentExercise,
      'settings': settings.toJson(),
      'sprites': sprites.map((sprite) => sprite.toJson()).toList(),
      'widgets': widgets.map((widget) => widget.toJson()).toList(),
      'sounds': sounds.map((sound) => sound.toJson()).toList(),
      'tilemap': tilemap.toJson(),
      'selectedSpriteId': selectedSpriteId,
      'codeBySpriteId': codeBySpriteId,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  factory FourthDemoProject.fromJson(Map<String, dynamic> json) {
    final sprites = (json['sprites'] as List? ?? const <Object>[])
        .whereType<Map>()
        .map(
          (item) => FourthDemoSprite.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return FourthDemoProject(
      id: json['id']?.toString() ?? 'project-1',
      title: json['title']?.toString() ?? 'Mini Course Exercise 1',
      currentExercise: (json['currentExercise'] as num?)?.toInt() ?? 1,
      settings: FourthDemoGameSettings.fromJson(
        Map<String, dynamic>.from(
          json['settings'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      sprites: sprites.isEmpty ? FourthDemoProject.sample().sprites : sprites,
      widgets: (json['widgets'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) => FourthDemoScreenWidget.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      sounds: (json['sounds'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) => FourthDemoSound.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      tilemap: FourthDemoTilemap.fromJson(
        Map<String, dynamic>.from(
          json['tilemap'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      selectedSpriteId: json['selectedSpriteId']?.toString() ?? 'polar',
      codeBySpriteId: Map<String, String>.from(
        (json['codeBySpriteId'] as Map? ?? const <String, String>{}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      ),
      events: (json['events'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) => FourthDemoEventHandler.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class FourthDemoGameSettings {
  final double worldWidth;
  final double worldHeight;
  final double gravity;
  final FourthDemoPhysicsMode physicsMode;
  final String cameraTargetId;
  final String background;

  const FourthDemoGameSettings({
    required this.worldWidth,
    required this.worldHeight,
    required this.gravity,
    required this.physicsMode,
    required this.cameraTargetId,
    required this.background,
  });

  FourthDemoGameSettings copyWith({
    double? worldWidth,
    double? worldHeight,
    double? gravity,
    FourthDemoPhysicsMode? physicsMode,
    String? cameraTargetId,
    String? background,
  }) {
    return FourthDemoGameSettings(
      worldWidth: worldWidth ?? this.worldWidth,
      worldHeight: worldHeight ?? this.worldHeight,
      gravity: gravity ?? this.gravity,
      physicsMode: physicsMode ?? this.physicsMode,
      cameraTargetId: cameraTargetId ?? this.cameraTargetId,
      background: background ?? this.background,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'worldWidth': worldWidth,
      'worldHeight': worldHeight,
      'gravity': gravity,
      'physicsMode': physicsMode.name,
      'cameraTargetId': cameraTargetId,
      'background': background,
    };
  }

  factory FourthDemoGameSettings.fromJson(Map<String, dynamic> json) {
    return FourthDemoGameSettings(
      worldWidth: (json['worldWidth'] as num?)?.toDouble() ?? 600,
      worldHeight: (json['worldHeight'] as num?)?.toDouble() ?? 400,
      gravity: (json['gravity'] as num?)?.toDouble() ?? 0,
      physicsMode: FourthDemoPhysicsMode.values.firstWhere(
        (mode) => mode.name == json['physicsMode']?.toString(),
        orElse: () => FourthDemoPhysicsMode.arcade,
      ),
      cameraTargetId: json['cameraTargetId']?.toString() ?? 'polar',
      background: json['background']?.toString() ?? 'jungle',
    );
  }
}

class FourthDemoSprite {
  final String id;
  final String name;
  final FourthDemoSpriteKind kind;
  final String assetId;
  final FourthDemoSpriteFacing facing;
  final double x;
  final double y;
  final double startX;
  final double startY;
  final double width;
  final double height;
  final double rotation;
  final double scale;
  final bool visible;
  final bool allowGravity;
  final bool immovable;
  final bool collideWorldBounds;
  final bool collideOtherSprites;
  final bool draggable;
  final bool destroyed;
  final bool enabled;
  final String currentAnimation;
  final double speed;
  final int colorValue;

  const FourthDemoSprite({
    required this.id,
    required this.name,
    required this.kind,
    this.assetId = '',
    this.facing = FourthDemoSpriteFacing.right,
    required this.x,
    required this.y,
    required this.startX,
    required this.startY,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.scale = 1,
    this.visible = true,
    this.allowGravity = false,
    this.immovable = false,
    this.collideWorldBounds = false,
    this.collideOtherSprites = false,
    this.draggable = true,
    this.destroyed = false,
    this.enabled = true,
    this.currentAnimation = '',
    this.speed = 32,
    this.colorValue = 0xFF66B64A,
  });

  FourthDemoSprite copyWith({
    String? name,
    String? assetId,
    FourthDemoSpriteFacing? facing,
    double? x,
    double? y,
    double? startX,
    double? startY,
    double? width,
    double? height,
    double? rotation,
    double? scale,
    bool? visible,
    bool? allowGravity,
    bool? immovable,
    bool? collideWorldBounds,
    bool? collideOtherSprites,
    bool? draggable,
    bool? destroyed,
    bool? enabled,
    String? currentAnimation,
    double? speed,
    int? colorValue,
  }) {
    return FourthDemoSprite(
      id: id,
      name: name ?? this.name,
      kind: kind,
      assetId: assetId ?? this.assetId,
      facing: facing ?? this.facing,
      x: x ?? this.x,
      y: y ?? this.y,
      startX: startX ?? this.startX,
      startY: startY ?? this.startY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      visible: visible ?? this.visible,
      allowGravity: allowGravity ?? this.allowGravity,
      immovable: immovable ?? this.immovable,
      collideWorldBounds: collideWorldBounds ?? this.collideWorldBounds,
      collideOtherSprites: collideOtherSprites ?? this.collideOtherSprites,
      draggable: draggable ?? this.draggable,
      destroyed: destroyed ?? this.destroyed,
      enabled: enabled ?? this.enabled,
      currentAnimation: currentAnimation ?? this.currentAnimation,
      speed: speed ?? this.speed,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  FourthDemoSprite withId(String nextId) {
    return FourthDemoSprite(
      id: nextId,
      name: name,
      kind: kind,
      assetId: assetId,
      facing: facing,
      x: x,
      y: y,
      startX: startX,
      startY: startY,
      width: width,
      height: height,
      rotation: rotation,
      scale: scale,
      visible: visible,
      allowGravity: allowGravity,
      immovable: immovable,
      collideWorldBounds: collideWorldBounds,
      collideOtherSprites: collideOtherSprites,
      draggable: draggable,
      destroyed: destroyed,
      enabled: enabled,
      currentAnimation: currentAnimation,
      speed: speed,
      colorValue: colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'kind': kind.name,
      'assetId': assetId,
      'facing': facing.name,
      'x': x,
      'y': y,
      'startX': startX,
      'startY': startY,
      'width': width,
      'height': height,
      'rotation': rotation,
      'scale': scale,
      'visible': visible,
      'allowGravity': allowGravity,
      'immovable': immovable,
      'collideWorldBounds': collideWorldBounds,
      'collideOtherSprites': collideOtherSprites,
      'draggable': draggable,
      'destroyed': destroyed,
      'enabled': enabled,
      'currentAnimation': currentAnimation,
      'speed': speed,
      'colorValue': colorValue,
    };
  }

  factory FourthDemoSprite.fromJson(Map<String, dynamic> json) {
    return FourthDemoSprite(
      id:
          json['id']?.toString() ??
          'sprite-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'sprite',
      kind: FourthDemoSpriteKind.values.firstWhere(
        (kind) => kind.name == json['kind']?.toString(),
        orElse: () => FourthDemoSpriteKind.prop,
      ),
      assetId: json['assetId']?.toString() ?? '',
      facing: FourthDemoSpriteFacing.values.firstWhere(
        (facing) => facing.name == json['facing']?.toString(),
        orElse: () => FourthDemoSpriteFacing.right,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      startX:
          (json['startX'] as num?)?.toDouble() ??
          (json['x'] as num?)?.toDouble() ??
          0,
      startY:
          (json['startY'] as num?)?.toDouble() ??
          (json['y'] as num?)?.toDouble() ??
          0,
      width: (json['width'] as num?)?.toDouble() ?? 48,
      height: (json['height'] as num?)?.toDouble() ?? 48,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      visible: json['visible'] != false,
      allowGravity: json['allowGravity'] == true,
      immovable: json['immovable'] == true,
      collideWorldBounds: json['collideWorldBounds'] == true,
      collideOtherSprites: json['collideOtherSprites'] == true,
      draggable: json['draggable'] != false,
      destroyed: json['destroyed'] == true,
      enabled: json['enabled'] != false,
      currentAnimation: json['currentAnimation']?.toString() ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 32,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF66B64A,
    );
  }
}

class FourthDemoEventHandler {
  final String event;
  final String targetSpriteId;
  final List<FourthDemoAction> actions;

  const FourthDemoEventHandler({
    required this.event,
    required this.targetSpriteId,
    required this.actions,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': event,
      'targetSpriteId': targetSpriteId,
      'actions': actions.map((action) => action.toJson()).toList(),
    };
  }

  factory FourthDemoEventHandler.fromJson(Map<String, dynamic> json) {
    return FourthDemoEventHandler(
      event: json['event']?.toString() ?? 'onStart',
      targetSpriteId: json['targetSpriteId']?.toString() ?? 'polar',
      actions: (json['actions'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) =>
                FourthDemoAction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class FourthDemoAction {
  final FourthDemoActionType type;
  final double amount;
  final String text;
  final String target;
  final String receiver;
  final String condition;
  final List<FourthDemoAction> actions;
  final List<FourthDemoAction> elseActions;

  const FourthDemoAction({
    required this.type,
    this.amount = 0,
    this.text = '',
    this.target = '',
    this.receiver = '@',
    this.condition = '',
    this.actions = const <FourthDemoAction>[],
    this.elseActions = const <FourthDemoAction>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'amount': amount,
      'text': text,
      'target': target,
      'receiver': receiver,
      'condition': condition,
      'actions': actions.map((action) => action.toJson()).toList(),
      'elseActions': elseActions.map((action) => action.toJson()).toList(),
    };
  }

  factory FourthDemoAction.fromJson(Map<String, dynamic> json) {
    return FourthDemoAction(
      type: FourthDemoActionType.values.firstWhere(
        (type) => type.name == json['type']?.toString(),
        orElse: () => FourthDemoActionType.say,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      text: json['text']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      receiver: json['receiver']?.toString() ?? '@',
      condition: json['condition']?.toString() ?? '',
      actions: (json['actions'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) =>
                FourthDemoAction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      elseActions: (json['elseActions'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) =>
                FourthDemoAction.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class FourthDemoScreenWidget {
  final String id;
  final String name;
  final FourthDemoWidgetKind type;
  final double x;
  final double y;
  final bool visible;
  final double opacity;
  final int textColorValue;
  final String text;
  final double value;
  final int durationSeconds;

  const FourthDemoScreenWidget({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    this.visible = true,
    this.opacity = 1,
    this.textColorValue = 0xFF1F2937,
    this.text = '',
    this.value = 0,
    this.durationSeconds = 60,
  });

  FourthDemoScreenWidget copyWith({
    String? id,
    String? name,
    FourthDemoWidgetKind? type,
    double? x,
    double? y,
    bool? visible,
    double? opacity,
    int? textColorValue,
    String? text,
    double? value,
    int? durationSeconds,
  }) {
    return FourthDemoScreenWidget(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      textColorValue: textColorValue ?? this.textColorValue,
      text: text ?? this.text,
      value: value ?? this.value,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.name,
      'x': x,
      'y': y,
      'visible': visible,
      'opacity': opacity,
      'textColorValue': textColorValue,
      'text': text,
      'value': value,
      'durationSeconds': durationSeconds,
    };
  }

  factory FourthDemoScreenWidget.fromJson(Map<String, dynamic> json) {
    return FourthDemoScreenWidget(
      id:
          json['id']?.toString() ??
          'widget-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Widget',
      type: FourthDemoWidgetKind.values.firstWhere(
        (type) => type.name == json['type']?.toString(),
        orElse: () => FourthDemoWidgetKind.text,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] != false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      textColorValue: (json['textColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      text: json['text']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 60,
    );
  }
}

class FourthDemoSound {
  final String id;
  final String name;

  const FourthDemoSound({required this.id, required this.name});

  FourthDemoSound copyWith({String? name}) {
    return FourthDemoSound(id: id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};

  factory FourthDemoSound.fromJson(Map<String, dynamic> json) {
    return FourthDemoSound(
      id:
          json['id']?.toString() ??
          'sound-${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Sound',
    );
  }
}

class FourthDemoTilemap {
  final int columns;
  final int rows;
  final List<FourthDemoTile> tiles;

  const FourthDemoTilemap({
    required this.columns,
    required this.rows,
    required this.tiles,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'columns': columns,
      'rows': rows,
      'tiles': tiles.map((tile) => tile.toJson()).toList(),
    };
  }

  factory FourthDemoTilemap.fromJson(Map<String, dynamic> json) {
    return FourthDemoTilemap(
      columns: (json['columns'] as num?)?.toInt() ?? 15,
      rows: (json['rows'] as num?)?.toInt() ?? 10,
      tiles: (json['tiles'] as List? ?? const <Object>[])
          .whereType<Map>()
          .map(
            (item) => FourthDemoTile.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class FourthDemoTile {
  final int x;
  final int y;
  final String type;

  const FourthDemoTile({required this.x, required this.y, required this.type});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'type': type,
  };

  factory FourthDemoTile.fromJson(Map<String, dynamic> json) {
    return FourthDemoTile(
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'ground',
    );
  }
}
