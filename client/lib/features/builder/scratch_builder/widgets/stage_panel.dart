import 'dart:math' as math;

import 'package:client/core/localization/app_language.dart';
import 'package:flutter/material.dart';

import '../../front_view/shared/builder_character.dart';
import '../../front_view/shared/builder_collectable.dart';
import '../../shared/widgets/game_builder_back_icon.dart';

enum ScratchStageTool { select, move, brush, eraser }

enum ScratchAssetTab { sprites, widgets, sounds, game }

enum ScratchSpriteKind { player, collectible, prop }

enum ScratchSpriteFacing { left, right }

enum ScratchWidgetKind { counter, text, timer, clock, button, dialog }

class ScratchGameSettings {
  final double worldWidth;
  final double worldHeight;
  final double gravity;
  final String physicsMode;
  final String cameraTargetId;
  final String background;

  const ScratchGameSettings({
    this.worldWidth = 600,
    this.worldHeight = 400,
    this.gravity = 0,
    this.physicsMode = 'arcade',
    this.cameraTargetId = 'polar',
    this.background = 'forest',
  });

  ScratchGameSettings copyWith({
    double? worldWidth,
    double? worldHeight,
    double? gravity,
    String? physicsMode,
    String? cameraTargetId,
    String? background,
  }) {
    return ScratchGameSettings(
      worldWidth: worldWidth ?? this.worldWidth,
      worldHeight: worldHeight ?? this.worldHeight,
      gravity: gravity ?? this.gravity,
      physicsMode: physicsMode ?? this.physicsMode,
      cameraTargetId: cameraTargetId ?? this.cameraTargetId,
      background: background ?? this.background,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worldWidth': worldWidth,
      'worldHeight': worldHeight,
      'gravity': gravity,
      'physicsMode': physicsMode,
      'cameraTargetId': cameraTargetId,
      'background': background,
    };
  }

  factory ScratchGameSettings.fromJson(Map<String, dynamic> json) {
    return ScratchGameSettings(
      worldWidth:
          (json['worldWidth'] as num?)?.toDouble() ??
          (json['stageWidth'] as num?)?.toDouble() ??
          600,
      worldHeight:
          (json['worldHeight'] as num?)?.toDouble() ??
          (json['stageHeight'] as num?)?.toDouble() ??
          400,
      gravity: (json['gravity'] as num?)?.toDouble() ?? 0,
      physicsMode: json['physicsMode']?.toString() ?? 'arcade',
      cameraTargetId: json['cameraTargetId']?.toString() ?? 'polar',
      background: json['background']?.toString() ?? 'forest',
    );
  }
}

class _FourthStyleStage {
  static const int columns = 15;
  static const int rows = 10;
  static const double playerMaxWidthScale = 1.35;
  static const double playerMaxHeightScale = 1.7;
  static const double playerFacingLeftOffsetXScale = 0.20;
  static const double playerFacingRightOffsetXScale = -0.1;
  static const double playerOffsetYScale = 0.17;
}

class ScratchStageSprite {
  final String id;
  final String name;
  final ScratchSpriteKind kind;
  final String assetId;
  final ScratchSpriteFacing facing;
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
  final String text;
  final int colorValue;

  const ScratchStageSprite({
    required this.id,
    required this.name,
    required this.kind,
    required this.assetId,
    this.facing = ScratchSpriteFacing.right,
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
    this.text = '',
    this.colorValue = 0xFF66B64A,
  });

  static List<ScratchStageSprite> starterSprites() {
    return const [
      ScratchStageSprite(
        id: 'polar',
        name: 'polar',
        kind: ScratchSpriteKind.player,
        assetId: defaultBuilderCharacterId,
        x: 72,
        y: 284,
        startX: 72,
        startY: 284,
        width: 58,
        height: 58,
        collideWorldBounds: true,
        collideOtherSprites: true,
      ),
      ScratchStageSprite(
        id: 'banana',
        name: 'banana',
        kind: ScratchSpriteKind.collectible,
        assetId: defaultBuilderCollectableId,
        x: 462,
        y: 286,
        startX: 462,
        startY: 286,
        width: 48,
        height: 48,
        immovable: true,
        colorValue: 0xFFFFC928,
      ),
    ];
  }

  factory ScratchStageSprite.fromChoice({
    required String id,
    required ScratchSpriteAssetChoice choice,
    required double x,
    required double y,
  }) {
    final isPlayer = choice.kind == ScratchSpriteKind.player;
    return ScratchStageSprite(
      id: id,
      name: choice.label,
      kind: choice.kind,
      assetId: choice.id,
      x: x,
      y: y,
      startX: x,
      startY: y,
      width: isPlayer ? 58 : 48,
      height: isPlayer ? 58 : 48,
      collideWorldBounds: isPlayer,
      collideOtherSprites: isPlayer,
      immovable: !isPlayer,
      colorValue: isPlayer ? 0xFF66B64A : 0xFFFFC928,
    );
  }

  String get assetPath {
    return switch (kind) {
      ScratchSpriteKind.player => builderCharacterById(
        assetId,
      ).idlePreviewAssetPath,
      ScratchSpriteKind.collectible => builderCollectableById(
        assetId,
      ).flutterAssetPath,
      ScratchSpriteKind.prop => '',
    };
  }

  ScratchStageSprite copyWith({
    String? id,
    String? name,
    ScratchSpriteKind? kind,
    String? assetId,
    ScratchSpriteFacing? facing,
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
    String? text,
    int? colorValue,
  }) {
    return ScratchStageSprite(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
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
      text: text ?? this.text,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'text': text,
      'colorValue': colorValue,
    };
  }

  Map<String, dynamic> toLegacyJson() {
    return {'x': x, 'y': y, 'rotation': rotation, 'text': text};
  }

  factory ScratchStageSprite.fromJson(Map<String, dynamic> json) {
    return ScratchStageSprite(
      id:
          json['id']?.toString() ??
          'sprite_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'sprite',
      kind: ScratchSpriteKind.values.firstWhere(
        (kind) => kind.name == json['kind']?.toString(),
        orElse: () => ScratchSpriteKind.player,
      ),
      assetId: json['assetId']?.toString() ?? defaultBuilderCharacterId,
      facing: ScratchSpriteFacing.values.firstWhere(
        (facing) => facing.name == json['facing']?.toString(),
        orElse: () => ScratchSpriteFacing.right,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 80,
      y: (json['y'] as num?)?.toDouble() ?? 80,
      startX:
          (json['startX'] as num?)?.toDouble() ??
          (json['x'] as num?)?.toDouble() ??
          80,
      startY:
          (json['startY'] as num?)?.toDouble() ??
          (json['y'] as num?)?.toDouble() ??
          80,
      width: (json['width'] as num?)?.toDouble() ?? 58,
      height: (json['height'] as num?)?.toDouble() ?? 58,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      visible: json['visible'] != false,
      allowGravity: json['allowGravity'] == true,
      immovable: json['immovable'] == true,
      collideWorldBounds: json['collideWorldBounds'] == true,
      collideOtherSprites: json['collideOtherSprites'] == true,
      draggable: json['draggable'] != false,
      text: json['text']?.toString() ?? '',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF66B64A,
    );
  }
}

class ScratchScreenWidget {
  final String id;
  final String name;
  final ScratchWidgetKind type;
  final double x;
  final double y;
  final bool visible;
  final double opacity;
  final int textColorValue;
  final String text;
  final double value;

  const ScratchScreenWidget({
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
  });

  ScratchScreenWidget copyWith({
    String? id,
    String? name,
    ScratchWidgetKind? type,
    double? x,
    double? y,
    bool? visible,
    double? opacity,
    int? textColorValue,
    String? text,
    double? value,
  }) {
    return ScratchScreenWidget(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory ScratchScreenWidget.fromJson(Map<String, dynamic> json) {
    return ScratchScreenWidget(
      id:
          json['id']?.toString() ??
          'widget_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Widget',
      type: ScratchWidgetKind.values.firstWhere(
        (type) => type.name == json['type']?.toString(),
        orElse: () => ScratchWidgetKind.text,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] != false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      textColorValue: (json['textColorValue'] as num?)?.toInt() ?? 0xFF1F2937,
      text: json['text']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ScratchSound {
  final String id;
  final String name;

  const ScratchSound({required this.id, required this.name});

  ScratchSound copyWith({String? id, String? name}) {
    return ScratchSound(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ScratchSound.fromJson(Map<String, dynamic> json) {
    return ScratchSound(
      id:
          json['id']?.toString() ??
          'sound_${DateTime.now().microsecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Sound',
    );
  }
}

class StagePanel extends StatefulWidget {
  final List<ScratchStageSprite> sprites;
  final List<ScratchScreenWidget> widgets;
  final List<ScratchSound> sounds;
  final ScratchGameSettings settings;
  final String selectedSpriteId;
  final ScratchAssetTab assetTab;
  final ScratchStageTool stageTool;
  final ValueChanged<String> onSelectSprite;
  final ValueChanged<ScratchStageSprite> onUpdateSprite;
  final ScratchStageSprite Function(ScratchSpriteAssetChoice choice)
  onAddSprite;
  final bool Function(String id) onDeleteSprite;
  final ScratchStageSprite? Function(String id) onDuplicateSprite;
  final ValueChanged<ScratchAssetTab> onSetAssetTab;
  final ValueChanged<ScratchStageTool> onSetStageTool;
  final ScratchScreenWidget Function(ScratchWidgetKind type) onAddWidget;
  final ValueChanged<ScratchScreenWidget> onUpdateWidget;
  final ValueChanged<String> onDeleteWidget;
  final ScratchScreenWidget? Function(String id) onDuplicateWidget;
  final ScratchSound Function(String name) onAddSound;
  final ValueChanged<ScratchSound> onUpdateSound;
  final ValueChanged<String> onDeleteSound;
  final ValueChanged<ScratchGameSettings> onUpdateSettings;

  const StagePanel({
    super.key,
    required this.sprites,
    required this.widgets,
    required this.sounds,
    required this.settings,
    required this.selectedSpriteId,
    required this.assetTab,
    required this.stageTool,
    required this.onSelectSprite,
    required this.onUpdateSprite,
    required this.onAddSprite,
    required this.onDeleteSprite,
    required this.onDuplicateSprite,
    required this.onSetAssetTab,
    required this.onSetStageTool,
    required this.onAddWidget,
    required this.onUpdateWidget,
    required this.onDeleteWidget,
    required this.onDuplicateWidget,
    required this.onAddSound,
    required this.onUpdateSound,
    required this.onDeleteSound,
    required this.onUpdateSettings,
  });

  @override
  State<StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<StagePanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  String? _editingSpriteId;
  String? _editingWidgetId;
  String? _editingSoundId;

  ScratchStageSprite? get selectedSprite => widget.sprites.firstWhereOrNull(
    (sprite) => sprite.id == widget.selectedSpriteId,
  );

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F1),
      child: Column(
        children: [
          Expanded(flex: 11, child: _buildStage(context)),
          Expanded(flex: 9, child: _buildAssetManager(context)),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final worldWidth = math.max(
                  widget.settings.worldWidth,
                  constraints.maxWidth,
                );
                final worldHeight = math.max(
                  widget.settings.worldHeight,
                  constraints.maxHeight,
                );
                return Scrollbar(
                  controller: _verticalController,
                  thumbVisibility:
                      widget.settings.worldHeight > constraints.maxHeight,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility:
                          widget.settings.worldWidth > constraints.maxWidth,
                      notificationPredicate: (notification) =>
                          notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: worldWidth,
                          height: worldHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    'game_builder/background/backgroundColorForest.png',
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _FourthStyleTilemapPainter(),
                                  ),
                                ),
                                for (final sprite in widget.sprites)
                                  if (sprite.visible)
                                    _StageSpriteView(
                                      sprite: sprite,
                                      selected:
                                          sprite.id == widget.selectedSpriteId,
                                      onTap: () =>
                                          widget.onSelectSprite(sprite.id),
                                      onDrag: (delta) {
                                        widget.onSelectSprite(sprite.id);
                                        if (widget.stageTool !=
                                                ScratchStageTool.move &&
                                            widget.stageTool !=
                                                ScratchStageTool.select) {
                                          return;
                                        }
                                        widget.onUpdateSprite(
                                          sprite.copyWith(
                                            x: (sprite.x + delta.dx).clamp(
                                              0,
                                              worldWidth - sprite.width,
                                            ),
                                            y: (sprite.y + delta.dy).clamp(
                                              0,
                                              worldHeight - sprite.height,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                for (final item in widget.widgets)
                                  if (item.visible)
                                    _StageWidgetView(item: item),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.north_west,
                  active: widget.stageTool == ScratchStageTool.select,
                  onTap: () => widget.onSetStageTool(ScratchStageTool.select),
                ),
                _ToolButton(
                  icon: Icons.open_with,
                  active: widget.stageTool == ScratchStageTool.move,
                  onTap: () => widget.onSetStageTool(ScratchStageTool.move),
                ),
                _ToolButton(
                  icon: Icons.auto_fix_off,
                  active: widget.stageTool == ScratchStageTool.eraser,
                  onTap: () => widget.onSetStageTool(ScratchStageTool.eraser),
                ),
                _ToolButton(
                  icon: Icons.brush,
                  active: widget.stageTool == ScratchStageTool.brush,
                  onTap: () => widget.onSetStageTool(ScratchStageTool.brush),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetManager(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in ScratchAssetTab.values)
                _TabButton(
                  text: _assetLabel(context, tab),
                  active: widget.assetTab == tab,
                  onTap: () {
                    setState(_clearEditing);
                    widget.onSetAssetTab(tab);
                  },
                ),
            ],
          ),
          Expanded(
            child: switch (widget.assetTab) {
              ScratchAssetTab.sprites =>
                _editingSpriteId == null
                    ? _buildSpritesGrid(context)
                    : _buildSpriteSettings(context),
              ScratchAssetTab.widgets =>
                _editingWidgetId == null
                    ? _buildWidgetsGrid(context)
                    : _buildWidgetSettings(context),
              ScratchAssetTab.sounds =>
                _editingSoundId == null
                    ? _buildSoundsGrid(context)
                    : _buildSoundSettings(context),
              ScratchAssetTab.game => _GameTab(
                settings: widget.settings,
                onChanged: widget.onUpdateSettings,
              ),
            },
          ),
        ],
      ),
    );
  }

  void _clearEditing() {
    _editingSpriteId = null;
    _editingWidgetId = null;
    _editingSoundId = null;
  }

  static String _assetLabel(BuildContext context, ScratchAssetTab tab) {
    final language = AppLanguage.of(context);
    return switch (tab) {
      ScratchAssetTab.sprites => language.t('builder.sprites'),
      ScratchAssetTab.widgets => language.t('builder.widgets'),
      ScratchAssetTab.sounds => language.t('builder.sounds'),
      ScratchAssetTab.game => language.t('builder.game'),
    };
  }

  Widget _buildSpritesGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSprite(context)),
            for (final sprite in widget.sprites)
              _SpriteCard(
                sprite: sprite,
                selected: sprite.id == widget.selectedSpriteId,
                onTap: () => widget.onSelectSprite(sprite.id),
                onSettings: () => setState(() => _editingSpriteId = sprite.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSprite(BuildContext context) async {
    final choice = await showScratchSpriteChoiceDialog(context);
    if (choice == null || !context.mounted) {
      return;
    }
    final sprite = widget.onAddSprite(choice);
    setState(() => _editingSpriteId = sprite.id);
  }

  Widget _buildWidgetsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddWidget(context)),
            for (final item in widget.widgets)
              _MiniAssetCard(
                title: item.name,
                icon: scratchWidgetIcon(item.type),
                onTap: () => setState(() => _editingWidgetId = item.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddWidget(BuildContext context) async {
    final type = await showScratchWidgetChoiceDialog(context);
    if (type == null || !context.mounted) {
      return;
    }
    final item = widget.onAddWidget(type);
    setState(() => _editingWidgetId = item.id);
  }

  Widget _buildSoundsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSound(context)),
            for (final sound in widget.sounds)
              _MiniAssetCard(
                title: sound.name,
                icon: Icons.play_arrow,
                onTap: () => setState(() => _editingSoundId = sound.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSound(BuildContext context) async {
    final name = await showScratchSoundChoiceDialog(context);
    if (name == null || !context.mounted) {
      return;
    }
    final sound = widget.onAddSound(name);
    setState(() => _editingSoundId = sound.id);
  }

  Widget _buildSpriteSettings(BuildContext context) {
    final sprite = widget.sprites.firstWhereOrNull(
      (sprite) => sprite.id == _editingSpriteId,
    );
    if (sprite == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingSpriteId = null);
      });
      return const SizedBox.shrink();
    }
    return _SpriteInlineSettings(
      sprite: sprite,
      onBack: () => setState(() => _editingSpriteId = null),
      onChanged: widget.onUpdateSprite,
      onDelete: () {
        if (widget.onDeleteSprite(sprite.id)) {
          setState(() => _editingSpriteId = null);
        }
      },
      onDuplicate: () {
        final copy = widget.onDuplicateSprite(sprite.id);
        if (copy != null) {
          setState(() => _editingSpriteId = copy.id);
        }
      },
    );
  }

  Widget _buildWidgetSettings(BuildContext context) {
    final item = widget.widgets.firstWhereOrNull(
      (item) => item.id == _editingWidgetId,
    );
    if (item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingWidgetId = null);
      });
      return const SizedBox.shrink();
    }
    return _WidgetInlineSettings(
      widget: item,
      onBack: () => setState(() => _editingWidgetId = null),
      onChanged: widget.onUpdateWidget,
      onDelete: () {
        widget.onDeleteWidget(item.id);
        setState(() => _editingWidgetId = null);
      },
      onDuplicate: () {
        final copy = widget.onDuplicateWidget(item.id);
        if (copy != null) {
          setState(() => _editingWidgetId = copy.id);
        }
      },
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    final sound = widget.sounds.firstWhereOrNull(
      (sound) => sound.id == _editingSoundId,
    );
    if (sound == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingSoundId = null);
      });
      return const SizedBox.shrink();
    }
    return _SoundInlineSettings(
      sound: sound,
      onBack: () => setState(() => _editingSoundId = null),
      onChanged: widget.onUpdateSound,
      onDelete: () {
        widget.onDeleteSound(sound.id);
        setState(() => _editingSoundId = null);
      },
    );
  }
}

class _StageSpriteView extends StatelessWidget {
  final ScratchStageSprite sprite;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const _StageSpriteView({
    required this.sprite,
    required this.selected,
    required this.onTap,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final scaledWidth = sprite.width * sprite.scale;
    final scaledHeight = sprite.height * sprite.scale;
    return Positioned(
      left: sprite.x,
      top: sprite.y,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) => onDrag(details.delta),
        child: SizedBox(
          width: scaledWidth,
          height: scaledHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF66B64A),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (sprite.text.isNotEmpty)
                Positioned(
                  left: -12,
                  right: -12,
                  bottom: scaledHeight + 8,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Text(sprite.text),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Transform.rotate(
                  angle: sprite.rotation * math.pi / 180,
                  child: _StageSpriteArtwork(sprite: sprite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageSpriteArtwork extends StatelessWidget {
  final ScratchStageSprite sprite;

  const _StageSpriteArtwork({required this.sprite});

  @override
  Widget build(BuildContext context) {
    return switch (sprite.kind) {
      ScratchSpriteKind.player => _StagePlayerArtwork(sprite: sprite),
      ScratchSpriteKind.collectible => _StageCollectibleArtwork(sprite: sprite),
      ScratchSpriteKind.prop => _StagePropArtwork(sprite: sprite),
    };
  }
}

class _StagePlayerArtwork extends StatelessWidget {
  final ScratchStageSprite sprite;

  const _StagePlayerArtwork({required this.sprite});

  @override
  Widget build(BuildContext context) {
    final character = builderCharacterById(
      sprite.assetId.isEmpty ? defaultBuilderCharacterId : sprite.assetId,
    );
    final config = character.spriteRect;
    final maxWidth =
        sprite.width *
        sprite.scale *
        (config.maxWidthScale ?? _FourthStyleStage.playerMaxWidthScale);
    final maxHeight =
        sprite.height *
        sprite.scale *
        (config.maxHeightScale ?? _FourthStyleStage.playerMaxHeightScale);
    final offsetX =
        sprite.width *
        sprite.scale *
        (sprite.facing == ScratchSpriteFacing.right
            ? config.facingRightOffsetXScale ??
                  _FourthStyleStage.playerFacingRightOffsetXScale
            : config.facingLeftOffsetXScale ??
                  _FourthStyleStage.playerFacingLeftOffsetXScale);
    final offsetY =
        sprite.height *
        sprite.scale *
        (config.offsetYScale ?? _FourthStyleStage.playerOffsetYScale);

    return OverflowBox(
      minWidth: 0,
      minHeight: 0,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Transform.scale(
          scaleX: sprite.facing == ScratchSpriteFacing.right ? -1 : 1,
          child: Image.asset(
            character.idlePreviewAssetPath,
            width: maxWidth,
            height: maxHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}

class _StageCollectibleArtwork extends StatelessWidget {
  final ScratchStageSprite sprite;

  const _StageCollectibleArtwork({required this.sprite});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(math.min(sprite.width, sprite.height) * 0.04),
      child: Image.asset(
        builderCollectableById(sprite.assetId).flutterAssetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _StagePropArtwork extends StatelessWidget {
  final ScratchStageSprite sprite;

  const _StagePropArtwork({required this.sprite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color(sprite.colorValue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.36,
          heightFactor: 0.36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _FourthStyleTilemapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tileWidth = size.width / _FourthStyleStage.columns;
    final tileHeight = size.height / _FourthStyleStage.rows;
    final y = _FourthStyleStage.rows - 1;

    for (var x = 0; x < _FourthStyleStage.columns; x += 1) {
      final rect = Rect.fromLTWH(
        x * tileWidth,
        y * tileHeight,
        tileWidth,
        tileHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        Paint()..color = const Color(0xFF2F6B22),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.23),
        Paint()..color = const Color(0xFF73CA55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FourthStyleTilemapPainter oldDelegate) => false;
}

class _StageWidgetView extends StatelessWidget {
  final ScratchScreenWidget item;

  const _StageWidgetView({required this.item});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: item.x,
      top: item.y,
      child: Opacity(
        opacity: item.opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD9DEE2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                scratchWidgetIcon(item.type),
                size: 16,
                color: Color(item.textColorValue),
              ),
              const SizedBox(width: 6),
              Text(
                item.text.isEmpty ? item.name : item.text,
                style: TextStyle(
                  color: Color(item.textColorValue),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpriteCard extends StatelessWidget {
  final ScratchStageSprite sprite;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _SpriteCard({
    required this.sprite,
    required this.selected,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF66B64A) : const Color(0xFFD9DEE2),
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            _SpriteAvatar(sprite: sprite, size: 54),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sprite.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: AppLanguage.of(context).t('builder.settings'),
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteInlineSettings extends StatelessWidget {
  final ScratchStageSprite sprite;
  final VoidCallback onBack;
  final ValueChanged<ScratchStageSprite> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SpriteInlineSettings({
    required this.sprite,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return _InlineSettingsScaffold(
      title: language.t('builder.spriteSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetTextField(
            label: language.t('builder.name').toUpperCase(),
            value: sprite.name,
            onChanged: (value) => onChanged(
              sprite.copyWith(
                name: value.trim().isEmpty ? sprite.name : value.trim(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _NumberStepperField(
                label: 'X',
                value: sprite.x,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(x: value, startX: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: sprite.y,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(y: value, startY: value)),
              ),
              _NumberStepperField(
                label: language.t('builder.scale').toUpperCase(),
                value: sprite.scale,
                step: 0.1,
                min: 0.1,
                decimals: 1,
                onChanged: (value) => onChanged(sprite.copyWith(scale: value)),
              ),
              _NumberStepperField(
                label: language.t('builder.rotation').toUpperCase(),
                value: sprite.rotation,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(rotation: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DirectionSelector(
            value: sprite.facing,
            onChanged: (value) => onChanged(sprite.copyWith(facing: value)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              _BoolOption(
                label: language.t('builder.allowGravity'),
                value: sprite.allowGravity,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(allowGravity: value)),
              ),
              _BoolOption(
                label: language.t('builder.collideWorldBounds'),
                value: sprite.collideWorldBounds,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideWorldBounds: value)),
              ),
              _BoolOption(
                label: language.t('builder.immovable'),
                value: sprite.immovable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(immovable: value)),
              ),
              _BoolOption(
                label: language.t('builder.show'),
                value: sprite.visible,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(visible: value)),
              ),
              _BoolOption(
                label: language.t('builder.collideOtherSprites'),
                value: sprite.collideOtherSprites,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideOtherSprites: value)),
              ),
              _BoolOption(
                label: language.t('builder.draggable'),
                value: sprite.draggable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(draggable: value)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  final ScratchSpriteFacing value;
  final ValueChanged<ScratchSpriteFacing> onChanged;

  const _DirectionSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.t('builder.direction').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SegmentedButton<ScratchSpriteFacing>(
          segments: [
            ButtonSegment(
              value: ScratchSpriteFacing.left,
              icon: const Icon(Icons.arrow_back),
              label: Text(language.t('builder.left')),
            ),
            ButtonSegment(
              value: ScratchSpriteFacing.right,
              icon: const Icon(Icons.arrow_forward),
              label: Text(language.t('builder.right')),
            ),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _WidgetInlineSettings extends StatelessWidget {
  final ScratchScreenWidget widget;
  final VoidCallback onBack;
  final ValueChanged<ScratchScreenWidget> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _WidgetInlineSettings({
    required this.widget,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return _InlineSettingsScaffold(
      title: language.t('builder.widgetSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  scratchWidgetIcon(widget.type),
                  color: const Color(0xFF24465A),
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _AssetTextField(
                      label: language.t('builder.name').toUpperCase(),
                      value: widget.name,
                      onChanged: (value) => onChanged(
                        widget.copyWith(
                          name: value.trim().isEmpty
                              ? widget.name
                              : value.trim(),
                        ),
                      ),
                    ),
                    _AssetTextField(
                      label: language.t('builder.text').toUpperCase(),
                      value: widget.text,
                      onChanged: (value) =>
                          onChanged(widget.copyWith(text: value)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _NumberStepperField(
                label: 'X',
                value: widget.x,
                onChanged: (value) => onChanged(widget.copyWith(x: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: widget.y,
                onChanged: (value) => onChanged(widget.copyWith(y: value)),
              ),
              _NumberStepperField(
                label: language.t('builder.value').toUpperCase(),
                value: widget.value,
                onChanged: (value) => onChanged(widget.copyWith(value: value)),
              ),
              _NumberStepperField(
                label: language.t('builder.opacity').toUpperCase(),
                value: widget.opacity,
                step: 0.1,
                min: 0,
                max: 1,
                decimals: 1,
                onChanged: (value) =>
                    onChanged(widget.copyWith(opacity: value)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BoolOption(
                label: language.t('builder.show'),
                value: widget.visible,
                onChanged: (value) =>
                    onChanged(widget.copyWith(visible: value)),
              ),
              const Spacer(),
              Text(
                language.t('builder.textColor'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              _ColorPickerButton(
                color: Color(widget.textColorValue),
                onChanged: (color) => onChanged(
                  widget.copyWith(textColorValue: color.toARGB32()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _SoundInlineSettings extends StatelessWidget {
  final ScratchSound sound;
  final VoidCallback onBack;
  final ValueChanged<ScratchSound> onChanged;
  final VoidCallback onDelete;

  const _SoundInlineSettings({
    required this.sound,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return _InlineSettingsScaffold(
      title: language.t('builder.soundSettings'),
      onBack: onBack,
      child: Column(
        children: [
          _AssetTextField(
            label: language.t('builder.name').toUpperCase(),
            value: sound.name,
            onChanged: (value) => onChanged(
              sound.copyWith(
                name: value.trim().isEmpty ? sound.name : value.trim(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.cancel),
              label: Text(language.t('builder.delete').toUpperCase()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineSettingsScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _InlineSettingsScaffold({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFD9DEE2))),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: AppLanguage.of(context).t('builder.back'),
                onPressed: onBack,
                icon: const GameBuilderBackIcon(),
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _AssetTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _AssetTextField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_AssetTextField> createState() => _AssetTextFieldState();
}

class _AssetTextFieldState extends State<_AssetTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _AssetTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        decoration: _fieldDecoration(widget.label),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _NumberStepperField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double? min;
  final double? max;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumberStepperField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min,
    this.max,
    this.decimals = 0,
  });

  @override
  State<_NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<_NumberStepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _format(widget.value);
    if (oldWidget.value != widget.value && _controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _fieldDecoration(widget.label).copyWith(
          suffixIcon: SizedBox(
            width: 26,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _nudge(widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
                InkWell(
                  onTap: () => _nudge(-widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
              ],
            ),
          ),
        ),
        onChanged: (raw) {
          final value = double.tryParse(raw);
          if (value != null) {
            widget.onChanged(_clamp(value));
          }
        },
      ),
    );
  }

  void _nudge(double amount) {
    final current = double.tryParse(_controller.text) ?? widget.value;
    final next = _clamp(current + amount);
    _controller.text = _format(next);
    widget.onChanged(next);
  }

  double _clamp(double value) {
    final min = widget.min;
    final max = widget.max;
    var next = value;
    if (min != null && next < min) next = min;
    if (max != null && next > max) next = max;
    return next;
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);
}

class _BoolOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BoolOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SettingsActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SettingsActions({required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.cancel),
          label: Text(language.t('builder.delete').toUpperCase()),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF777777),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onDuplicate,
          icon: const Icon(Icons.add_circle),
          label: Text(language.t('builder.duplicate').toUpperCase()),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF57C78A),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  static const colors = [
    Color(0xFF1F2937),
    Color(0xFF2B78C2),
    Color(0xFF66B64A),
    Color(0xFFFFC928),
    Color(0xFFE15B64),
    Color(0xFF7C3AED),
  ];

  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorPickerButton({required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Color>(
      tooltip: AppLanguage.of(context).t('builder.textColor'),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in colors)
          PopupMenuItem(
            value: option,
            child: Container(width: 44, height: 24, color: option),
          ),
      ],
      child: Container(
        width: 72,
        height: 42,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: const Color(0xFF777777)),
          ),
        ),
      ),
    );
  }
}

class _AddNewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        height: 124,
        decoration: BoxDecoration(
          color: const Color(0xFF66B64A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3E8D41), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 38),
            const SizedBox(height: 8),
            Text(
              AppLanguage.of(context).t('builder.addNew').toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTab extends StatelessWidget {
  final ScratchGameSettings settings;
  final ValueChanged<ScratchGameSettings> onChanged;

  const _GameTab({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _SettingRow(
            label: language.t('builder.background'),
            value: settings.background,
          ),
          _NumberSetting(
            label: language.t('builder.worldWidth'),
            value: settings.worldWidth,
            onChanged: (value) =>
                onChanged(settings.copyWith(worldWidth: value)),
          ),
          _NumberSetting(
            label: language.t('builder.worldHeight'),
            value: settings.worldHeight,
            onChanged: (value) =>
                onChanged(settings.copyWith(worldHeight: value)),
          ),
          _NumberSetting(
            label: language.t('builder.gravity'),
            value: settings.gravity,
            onChanged: (value) => onChanged(settings.copyWith(gravity: value)),
          ),
          _SettingRow(
            label: language.t('builder.physicsMode'),
            value: settings.physicsMode,
          ),
          _SettingRow(
            label: language.t('builder.cameraTarget'),
            value: settings.cameraTargetId,
          ),
          _SettingRow(
            label: language.t('builder.tilemap'),
            value: 'ground, platform, obstacle',
          ),
          _SettingRow(
            label: language.t('builder.soundSettingsLabel'),
            value: 'enabled',
          ),
        ],
      ),
    );
  }
}

class _MiniAssetCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniAssetCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 128,
        height: 124,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2B78C2), size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteAvatar extends StatelessWidget {
  final ScratchStageSprite? sprite;
  final double size;

  const _SpriteAvatar({required this.sprite, required this.size});

  @override
  Widget build(BuildContext context) {
    final kind = sprite?.kind;
    final assetId = sprite?.assetId ?? '';
    final playerAssetPath = builderCharacterById(
      assetId.isEmpty ? defaultBuilderCharacterId : assetId,
    ).idlePreviewAssetPath;
    final collectableAssetPath = builderCollectableById(
      assetId.isEmpty ? defaultBuilderCollectableId : assetId,
    ).flutterAssetPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child:
          kind == ScratchSpriteKind.player ||
              kind == ScratchSpriteKind.collectible
          ? Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(
                kind == ScratchSpriteKind.player
                    ? playerAssetPath
                    : collectableAssetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            )
          : Icon(
              Icons.category,
              color: Color(sprite?.colorValue ?? 0xFF66B64A),
              size: size * 0.62,
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? Colors.white : const Color(0xFFD3D9DD),
        borderRadius: active
            ? BorderRadius.zero
            : const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
        child: InkWell(
          onTap: onTap,
          borderRadius: active
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                )
              : BorderRadius.zero,
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                  color: active ? Colors.black : const Color(0xFF6C747A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton.filled(
        tooltip: AppLanguage.of(context).t('builder.stageTool'),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: active ? const Color(0xFF66B64A) : Colors.white,
          foregroundColor: active ? Colors.white : const Color(0xFF3A241D),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B78C2),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        decoration: _fieldDecoration(label),
        onFieldSubmitted: (raw) => onChanged(double.tryParse(raw) ?? value),
      ),
    );
  }
}

class ScratchSpriteAssetChoice {
  final String id;
  final String label;
  final String assetPath;
  final ScratchSpriteKind kind;

  const ScratchSpriteAssetChoice({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.kind,
  });
}

Future<ScratchSpriteAssetChoice?> showScratchSpriteChoiceDialog(
  BuildContext context,
) async {
  final language = AppLanguage.of(context);
  final choices = <ScratchSpriteAssetChoice>[
    for (final character in builderCharacters)
      ScratchSpriteAssetChoice(
        id: character.id,
        label: localizedBuilderCharacterLabel(language, character.id),
        assetPath: character.idlePreviewAssetPath,
        kind: ScratchSpriteKind.player,
      ),
    for (final collectable in builderCollectables)
      ScratchSpriteAssetChoice(
        id: collectable.id,
        label: localizedBuilderCollectableLabel(language, collectable.id),
        assetPath: collectable.flutterAssetPath,
        kind: ScratchSpriteKind.collectible,
      ),
  ];
  var selected = choices.first;

  return showDialog<ScratchSpriteAssetChoice>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSprite'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 520,
            height: 430,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: choices.length,
              itemBuilder: (context, index) {
                final choice = choices[index];
                return _ImageChoiceTile(
                  label: choice.label,
                  assetPath: choice.assetPath,
                  selected:
                      selected.id == choice.id && selected.kind == choice.kind,
                  onTap: () => setState(() => selected = choice),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Future<ScratchWidgetKind?> showScratchWidgetChoiceDialog(
  BuildContext context,
) async {
  var selected = ScratchWidgetKind.counter;
  return showDialog<ScratchWidgetKind>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseWidget'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final type in ScratchWidgetKind.values)
                  _IconChoiceTile(
                    label: scratchWidgetLabel(AppLanguage.of(context), type),
                    icon: scratchWidgetIcon(type),
                    selected: selected == type,
                    onTap: () => setState(() => selected = type),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> showScratchSoundChoiceDialog(BuildContext context) async {
  const sounds = <String>[
    'collectSparkle',
    'jumpPop',
    'buttonClick',
    'successChime',
    'timerTick',
    'warningBeep',
  ];
  var selected = sounds.first;
  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSound'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final sound in sounds)
                  _IconChoiceTile(
                    label: AppLanguage.of(
                      context,
                    ).tr('builder.sound.$sound', sound),
                    icon: Icons.music_note,
                    selected: selected == sound,
                    onTap: () => setState(() => selected = sound),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ImageChoiceTile extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _ImageChoiceTile({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Icon(icon, color: const Color(0xFF2B78C2), size: 38),
    );
  }
}

class _ChoiceShell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _ChoiceShell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF66B64A)
                          : const Color(0xFFD9DEE2),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: child,
                ),
                if (selected)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF2F9F46),
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget action;

  const _CourseDialog({
    required this.title,
    required this.child,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF3A241D),
        ),
      ),
      content: SizedBox(width: 520, child: child),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLanguage.of(context).t('builder.cancel')),
        ),
        action,
      ],
    );
  }
}

IconData scratchWidgetIcon(ScratchWidgetKind type) {
  return switch (type) {
    ScratchWidgetKind.counter => Icons.exposure_plus_1,
    ScratchWidgetKind.text => Icons.text_fields,
    ScratchWidgetKind.timer => Icons.timer,
    ScratchWidgetKind.clock => Icons.schedule,
    ScratchWidgetKind.button => Icons.smart_button,
    ScratchWidgetKind.dialog => Icons.chat_bubble_outline,
  };
}

String scratchWidgetLabel(AppLanguage language, ScratchWidgetKind type) {
  return switch (type) {
    ScratchWidgetKind.counter => language.tr(
      'builder.widget.counter',
      'Counter',
    ),
    ScratchWidgetKind.text => language.t('builder.text'),
    ScratchWidgetKind.timer => language.tr('builder.widget.timer', 'Timer'),
    ScratchWidgetKind.clock => language.tr('builder.widget.clock', 'Clock'),
    ScratchWidgetKind.button => language.tr('builder.widget.button', 'Button'),
    ScratchWidgetKind.dialog => language.tr('builder.widget.dialog', 'Dialog'),
  };
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD9DEE2)),
    ),
  );
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
