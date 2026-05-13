import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/builder_controller.dart';
import '../models/builder_playback_state.dart';
import '../models/entity_data.dart';
import '../models/logic_command.dart';
import '../models/tile_data.dart';
import '../shared/builder_character.dart';
import '../shared/builder_collectable.dart';

class BuilderGame extends FlameGame {
  static const Color boardBackgroundColor = Color(0xFFDDEAF7);

  final BuilderController controller;
  late final BuilderBoard board;

  BuilderGame({required this.controller});

  @override
  Color backgroundColor() {
    return boardBackgroundColor;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    board = BuilderBoard(controller: controller);
    add(board);
  }
}

class BuilderBoard extends PositionComponent
    with HasGameReference<BuilderGame> {
  static const int _idleFrameDurationMs = 95;
  static const int _actionFrameDurationMs = 62;
  static const int _moveAnimationDurationMs = 420;
  static const double _defaultPlayerSpriteMaxWidthScale = 1.35;
  static const double _defaultPlayerSpriteMaxHeightScale = 1.7;
  static const double _defaultPlayerSpriteFacingLeftOffsetXScale = 0.20;
  static const double _defaultPlayerSpriteFacingRightOffsetXScale = -0.1;
  static const double _defaultPlayerSpriteOffsetYScale = 0.17;
  static const int _goalChestFrameDurationMs = 150;
  static const List<String> _goalChestFramePaths = <String>[
    'game_builder/goal/chest_closed.png',
    'game_builder/goal/chest_opening.png',
    'game_builder/goal/chest_open_gold.png',
  ];
  static const String _groundTerrainPath = 'game_builder/terrain/grass.png';
  static const String _obstacleTerrainPath = 'game_builder/terrain/wood.png';
  static const String _backgroundImagePath =
      'game_builder/background/backgroundColorForest.png';

  static const Color _backgroundColor = BuilderGame.boardBackgroundColor;
  static const Color _groundTileColor = Color(0xFF5FBF72);
  static const Color _obstacleTileColor = Color(0xFF7C8796);
  static const Color _unknownTileColor = Color(0xFF9AA5B5);
  static const Color _playerColor = Color(0xFF3B82F6);
  static const Color _collectableColor = Color(0xFFF59E0B);
  static const Color _goalColor = Color(0xFFEF4444);
  static const Color _unknownEntityColor = Color(0xFF8B5CF6);

  final BuilderController controller;
  final Map<String, _CharacterFrameSet> _characterFrames =
      <String, _CharacterFrameSet>{};
  final Map<String, ui.Image> _collectableImages = <String, ui.Image>{};
  List<ui.Image> _goalChestFrames = const <ui.Image>[];
  ui.Image? _backgroundImage;
  ui.Image? _groundTerrainImage;
  ui.Image? _obstacleTerrainImage;
  double _animationElapsedMs = 0;
  double _visualPlaybackElapsedMs = 0;
  double _goalChestAnimationElapsedMs = 0;
  int? _trackedPlaybackRunId;
  int? _trackedGoalChestPlaybackRunId;
  BuilderPlaybackVisualSegment? _activeVisualSegment;

  BuilderBoard({required this.controller});

  double get tileSize => controller.project.settings.tileSize;
  int get rows => controller.project.settings.rows;
  int get columns => controller.project.settings.columns;
  double get boardWidth => columns * tileSize;
  double get boardHeight => rows * tileSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadBackgroundImage();
    await _loadPlayerFrames();
    await _loadCollectableImages();
    await _loadGoalChestFrames();
    await _loadTerrainImages();
    _syncBoardSize();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final deltaMs = dt * Duration.millisecondsPerSecond;
    _animationElapsedMs += deltaMs;
    _updateVisualPlayback(deltaMs);
    _updateGoalChestAnimation(deltaMs);
  }

  Future<void> _loadPlayerFrames() async {
    for (final character in builderCharacters) {
      try {
        _characterFrames[character.id] = await _loadCharacterFrames(character);
      } catch (error) {
        debugPrint(
          'Failed to load ${character.label} animation frames: $error',
        );
      }
    }
  }

  Future<void> _loadCollectableImages() async {
    for (final collectable in builderCollectables) {
      try {
        _collectableImages[collectable.id] = await _loadUiImage(
          collectable.assetPath,
        );
      } catch (error) {
        debugPrint(
          'Failed to load ${collectable.label} collectable image: $error',
        );
      }
    }
  }

  Future<void> _loadGoalChestFrames() async {
    try {
      _goalChestFrames = await Future.wait(
        _goalChestFramePaths.map(_loadUiImage),
      );
    } catch (error) {
      debugPrint('Failed to load goal chest frames: $error');
    }
  }

  Future<void> _loadBackgroundImage() async {
    try {
      _backgroundImage = await _loadUiImage(_backgroundImagePath);
    } catch (error) {
      debugPrint('Failed to load builder background image: $error');
    }
  }

  Future<void> _loadTerrainImages() async {
    try {
      _groundTerrainImage = await _loadUiImage(_groundTerrainPath);
    } catch (error) {
      debugPrint('Failed to load ground terrain image: $error');
    }

    try {
      _obstacleTerrainImage = await _loadUiImage(_obstacleTerrainPath);
    } catch (error) {
      debugPrint('Failed to load obstacle terrain image: $error');
    }
  }

  Future<_CharacterFrameSet> _loadCharacterFrames(
    BuilderCharacter character,
  ) async {
    return _CharacterFrameSet(
      idle: await Future.wait(_idleFramePaths(character).map(_loadUiImage)),
      walk: await Future.wait(_walkFramePaths(character).map(_loadUiImage)),
      jumpUp: await Future.wait(_jumpUpFramePaths(character).map(_loadUiImage)),
      jumpFall: await Future.wait(
        _jumpFallFramePaths(character).map(_loadUiImage),
      ),
    );
  }

  List<String> _idleFramePaths(BuilderCharacter character) {
    return List.generate(
      12,
      (index) =>
          '${character.basePath}/01-Idle/01-Idle/${character.filePrefix}_Idle_${index.toString().padLeft(3, '0')}.png',
    );
  }

  List<String> _walkFramePaths(BuilderCharacter character) {
    return List.generate(
      12,
      (index) =>
          '${character.basePath}/${character.walkFolder}/${character.filePrefix}_Walk_${index.toString().padLeft(3, '0')}.png',
    );
  }

  List<String> _jumpUpFramePaths(BuilderCharacter character) {
    return List.generate(
      5,
      (index) =>
          '${character.basePath}/06-Jump/01-Jump_Up/${character.filePrefix}_Jump_UP_${index.toString().padLeft(3, '0')}.png',
    );
  }

  List<String> _jumpFallFramePaths(BuilderCharacter character) {
    return List.generate(
      5,
      (index) =>
          '${character.basePath}/06-Jump/02-Jump_Fall/${character.filePrefix}_Jump_Fall_${index.toString().padLeft(3, '0')}.png',
    );
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await _loadAssetBytes(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    return decodeImageFromList(bytes);
  }

  Future<ByteData> _loadAssetBytes(String assetPath) async {
    try {
      return await rootBundle.load(assetPath);
    } catch (_) {
      return rootBundle.load(['assets', assetPath].join('/'));
    }
  }

  void _syncBoardSize() {
    final nextWidth = boardWidth;
    final nextHeight = boardHeight;

    if (size.x != nextWidth || size.y != nextHeight) {
      size = Vector2(nextWidth, nextHeight);
    }
  }

  void _updateVisualPlayback(double deltaMs) {
    final playbackState = controller.playbackState;
    final segments = controller.playbackVisualSegments;

    if (playbackState == null) {
      _trackedPlaybackRunId = null;
      _visualPlaybackElapsedMs = 0;
      _activeVisualSegment = null;
      return;
    }

    if (segments.isEmpty) {
      _activeVisualSegment = null;
      return;
    }

    if (_trackedPlaybackRunId != controller.playbackRunId) {
      _trackedPlaybackRunId = controller.playbackRunId;
      _visualPlaybackElapsedMs = 0;
      _activeVisualSegment = segments.first;
      return;
    }

    final totalDurationMs = segments.length * _moveAnimationDurationMs;
    if (_visualPlaybackElapsedMs < totalDurationMs) {
      _visualPlaybackElapsedMs = math.min(
        totalDurationMs.toDouble(),
        _visualPlaybackElapsedMs + deltaMs,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    _syncBoardSize();

    _drawBackground(canvas);
    _drawTiles(canvas);
    _drawEntities(canvas);
    _drawSelection(canvas);
    super.render(canvas);
  }

  void _drawTiles(Canvas canvas) {
    for (final TileData tile in controller.project.tiles) {
      final rect = Rect.fromLTWH(
        tile.x * tileSize,
        tile.y * tileSize,
        tileSize,
        tileSize,
      );
      if (_isGroundTile(tile.type)) {
        _drawTileImage(
          canvas,
          rect,
          image: _groundTerrainImage,
          fallbackColor: _groundTileColor,
        );
      } else if (tile.type == 'obstacle') {
        _drawTileImage(
          canvas,
          rect,
          image: _obstacleTerrainImage,
          fallbackColor: _obstacleTileColor,
        );
      } else {
        _drawBox(canvas, rect, _tileColorForType(tile.type));
      }
    }
  }

  void _drawEntities(Canvas canvas) {
    final playbackState = controller.playbackState;

    for (final EntityData entity in controller.project.entities) {
      if (_shouldHideEntity(entity, playbackState)) {
        continue;
      }

      final rect = Rect.fromLTWH(
        entity.x * tileSize,
        entity.y * tileSize,
        tileSize,
        tileSize,
      );
      if (entity.type == 'playerStart') {
        _drawPlayer(
          canvas,
          rect,
          characterId: _characterIdForEntity(entity),
          facingDirection: _facingDirectionForEntity(entity),
        );
      } else if (entity.type == 'collectable') {
        _drawCollectable(canvas, rect, entity);
      } else if (entity.type == 'goal') {
        _drawGoal(canvas, rect);
      } else {
        _drawBox(
          canvas,
          rect.deflate(tileSize * 0.18),
          _entityColorForType(entity.type),
        );
      }
    }

    if (playbackState != null) {
      final previewRect = _buildAnimatedPlayerRect(playbackState);
      _drawPlayer(
        canvas,
        previewRect,
        playbackState: playbackState,
        characterId: controller.playerCharacterId,
        facingDirection:
            _activeVisualSegment?.facingDirection ??
            playbackState.facingDirection,
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    if (controller.selectedX == null || controller.selectedY == null) {
      return;
    }

    final rect = Rect.fromLTWH(
      controller.selectedX! * tileSize,
      controller.selectedY! * tileSize,
      tileSize,
      tileSize,
    );

    final fillPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  void _drawBackground(Canvas canvas) {
    final boardRect = Rect.fromLTWH(0, 0, boardWidth, boardHeight);
    final image = _backgroundImage;
    if (image == null) {
      canvas.drawRect(boardRect, Paint()..color = _backgroundColor);
      return;
    }

    canvas.drawImageRect(
      image,
      _coverSourceRectForImage(image: image, destinationRect: boardRect),
      boardRect,
      Paint(),
    );
  }

  void _drawBox(Canvas canvas, Rect rect, Color color) {
    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = const Color(0x26000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tileSize * 0.04 < 1 ? 1.0 : tileSize * 0.04;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  void _drawTileImage(
    Canvas canvas,
    Rect tileRect, {
    required ui.Image? image,
    required Color fallbackColor,
  }) {
    if (image == null) {
      _drawBox(canvas, tileRect, fallbackColor);
      return;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      tileRect,
      Paint(),
    );
  }

  void _drawPlayer(
    Canvas canvas,
    Rect tileRect, {
    BuilderPlaybackState? playbackState,
    required String characterId,
    required String facingDirection,
  }) {
    final character = builderCharacterById(characterId);
    final frame = _currentCharacterFrame(playbackState, characterId);
    if (frame == null) {
      _drawBox(canvas, tileRect.deflate(tileSize * 0.18), _playerColor);
      return;
    }
    final isFacingRight =
        facingDirection == BuilderController.playerFacingRight;
    final sourceRect = _sourceRectForCharacter(frame, character);
    final spriteRectConfig = character.spriteRect;

    final spriteRect =
        _spriteRectForTile(
          sourceRect: sourceRect,
          tileRect: tileRect,
          maxWidth:
              tileSize *
              (spriteRectConfig.maxWidthScale ??
                  _defaultPlayerSpriteMaxWidthScale),
          maxHeight:
              tileSize *
              (spriteRectConfig.maxHeightScale ??
                  _defaultPlayerSpriteMaxHeightScale),
        ).translate(
          isFacingRight
              ? tileSize *
                    (spriteRectConfig.facingRightOffsetXScale ??
                        _defaultPlayerSpriteFacingRightOffsetXScale)
              : tileSize *
                    (spriteRectConfig.facingLeftOffsetXScale ??
                        _defaultPlayerSpriteFacingLeftOffsetXScale),
          tileSize *
              (spriteRectConfig.offsetYScale ??
                  _defaultPlayerSpriteOffsetYScale),
        );

    _drawImageRectFacing(
      canvas: canvas,
      image: frame,
      sourceRect: sourceRect,
      destinationRect: spriteRect,
      flipHorizontally: facingDirection == BuilderController.playerFacingRight,
    );
  }

  void _drawImageRectFacing({
    required Canvas canvas,
    required ui.Image image,
    required Rect sourceRect,
    required Rect destinationRect,
    required bool flipHorizontally,
  }) {
    if (!flipHorizontally) {
      canvas.drawImageRect(image, sourceRect, destinationRect, Paint());
      return;
    }

    canvas.save();
    canvas.translate(
      destinationRect.left + destinationRect.width,
      destinationRect.top,
    );
    canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      sourceRect,
      Rect.fromLTWH(0, 0, destinationRect.width, destinationRect.height),
      Paint(),
    );
    canvas.restore();
  }

  ui.Image? _currentCharacterFrame(
    BuilderPlaybackState? playbackState,
    String characterId,
  ) {
    final frames = _framesForPlayback(
      playbackState,
      _activeVisualSegment,
      characterId,
    );
    if (frames.isEmpty) {
      return null;
    }

    final frameIndex =
        (_animationElapsedMs / _frameDurationForPlayback(playbackState))
            .floor() %
        frames.length;
    return frames[frameIndex];
  }

  List<ui.Image> _framesForPlayback(
    BuilderPlaybackState? playbackState,
    BuilderPlaybackVisualSegment? visualSegment,
    String characterId,
  ) {
    final frameSet =
        _characterFrames[builderCharacterById(characterId).id] ??
        _characterFrames[defaultBuilderCharacterId];
    if (frameSet == null) {
      return const <ui.Image>[];
    }

    final command = visualSegment?.command ?? playbackState?.animatedCommand;
    if (playbackState == null || command == null) {
      return frameSet.idle;
    }

    final fromY = visualSegment?.fromPlayerY ?? playbackState.fromPlayerY;
    final toY = visualSegment?.toPlayerY ?? playbackState.toPlayerY;
    final verticalDelta = toY - fromY;
    if (verticalDelta > 0 && frameSet.jumpFall.isNotEmpty) {
      return frameSet.jumpFall;
    }

    if (verticalDelta < 0 && frameSet.jumpUp.isNotEmpty) {
      return frameSet.jumpUp;
    }

    switch (command) {
      case LogicCommandType.moveLeft:
      case LogicCommandType.moveRight:
        return frameSet.walk.isEmpty ? frameSet.idle : frameSet.walk;
      case LogicCommandType.jumpUp:
      case LogicCommandType.climbUpLeft:
      case LogicCommandType.climbUpRight:
        return frameSet.jumpUp.isEmpty ? frameSet.idle : frameSet.jumpUp;
    }
  }

  int _frameDurationForPlayback(BuilderPlaybackState? playbackState) {
    return playbackState?.animatedCommand == null
        ? _idleFrameDurationMs
        : _actionFrameDurationMs;
  }

  Rect _sourceRectForCharacter(ui.Image frame, BuilderCharacter character) {
    return Rect.fromLTWH(
      character.sourceInsetLeft,
      character.sourceInsetTop,
      frame.width.toDouble() -
          character.sourceInsetLeft -
          character.sourceInsetRight,
      frame.height.toDouble() -
          character.sourceInsetTop -
          character.sourceInsetBottom,
    );
  }

  void _updateGoalChestAnimation(double deltaMs) {
    final playbackState = controller.playbackState;
    if (playbackState == null ||
        !playbackState.hasSucceeded ||
        !_hasVisualPlayerReachedGoal()) {
      _goalChestAnimationElapsedMs = 0;
      _trackedGoalChestPlaybackRunId = null;
      return;
    }

    if (_trackedGoalChestPlaybackRunId != controller.playbackRunId) {
      _trackedGoalChestPlaybackRunId = controller.playbackRunId;
      _goalChestAnimationElapsedMs = 0;
      return;
    }

    _goalChestAnimationElapsedMs += deltaMs;
  }

  bool _hasVisualPlayerReachedGoal() {
    final goal = _goalEntity;
    final playbackState = controller.playbackState;
    if (goal == null || playbackState == null) {
      return false;
    }

    final segments = controller.playbackVisualSegments;
    if (segments.isEmpty) {
      return playbackState.playerX == goal.x && playbackState.playerY == goal.y;
    }

    int? arrivalTimeMs;
    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (segment.toPlayerX == goal.x && segment.toPlayerY == goal.y) {
        arrivalTimeMs = (index + 1) * _moveAnimationDurationMs;
      }
    }

    return arrivalTimeMs != null && _visualPlaybackElapsedMs >= arrivalTimeMs;
  }

  void _drawCollectable(Canvas canvas, Rect tileRect, EntityData entity) {
    final collectable = builderCollectableById(
      entity.config['item']?.toString(),
    );
    final image = _collectableImages[collectable.id];
    if (image == null) {
      _drawBox(canvas, tileRect.deflate(tileSize * 0.18), _collectableColor);
      return;
    }

    final imageRect = _imageRectForTile(
      image: image,
      tileRect: tileRect,
      maxWidth: tileSize * 0.68,
      maxHeight: tileSize * 0.68,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );
  }

  void _drawGoal(Canvas canvas, Rect tileRect) {
    if (_goalChestFrames.isEmpty) {
      _drawBox(canvas, tileRect.deflate(tileSize * 0.18), _goalColor);
      return;
    }

    final image = _goalChestFrameForCurrentState();
    final imageRect = _imageRectForTile(
      image: image,
      tileRect: tileRect,
      maxWidth: tileSize * 1.2,
      maxHeight: tileSize * 1.2,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );
  }

  ui.Image _goalChestFrameForCurrentState() {
    final playbackState = controller.playbackState;
    if (playbackState == null || !playbackState.hasSucceeded) {
      return _goalChestFrames.first;
    }

    final frameIndex =
        (_goalChestAnimationElapsedMs / _goalChestFrameDurationMs)
            .floor()
            .clamp(0, _goalChestFrames.length - 1)
            .toInt();
    return _goalChestFrames[frameIndex];
  }

  Rect _spriteRectForTile({
    required Rect sourceRect,
    required Rect tileRect,
    required double maxWidth,
    required double maxHeight,
  }) {
    final imageAspect = sourceRect.width / sourceRect.height;
    var width = maxWidth;
    var height = width / imageAspect;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * imageAspect;
    }

    return Rect.fromLTWH(
      tileRect.center.dx - width / 2,
      tileRect.bottom - height,
      width,
      height,
    );
  }

  Rect _imageRectForTile({
    required ui.Image image,
    required Rect tileRect,
    required double maxWidth,
    required double maxHeight,
  }) {
    final imageAspect = image.width / image.height;
    var width = maxWidth;
    var height = width / imageAspect;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * imageAspect;
    }

    return Rect.fromLTWH(
      tileRect.center.dx - width / 2,
      tileRect.center.dy - height / 2,
      width,
      height,
    );
  }

  Rect _coverSourceRectForImage({
    required ui.Image image,
    required Rect destinationRect,
  }) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final imageAspect = imageWidth / imageHeight;
    final destinationAspect = destinationRect.width / destinationRect.height;
    final zoom = 0.8;

    if (imageAspect > destinationAspect) {
      final sourceWidth = imageHeight * destinationAspect / zoom;
      return Rect.fromLTWH(
        (imageWidth - sourceWidth) / 2,
        0,
        sourceWidth,
        imageHeight,
      );
    }

    final sourceHeight = imageWidth / destinationAspect;
    return Rect.fromLTWH(
      0,
      (imageHeight - sourceHeight) / 2 + 40,
      imageWidth,
      sourceHeight,
    );
  }

  Color _tileColorForType(String type) {
    if (_isGroundTile(type)) {
      return _groundTileColor;
    }

    if (type == 'obstacle') {
      return _obstacleTileColor;
    }

    return _unknownTileColor;
  }

  Color _entityColorForType(String type) {
    switch (type) {
      case 'playerStart':
        return _playerColor;
      case 'collectable':
        return _collectableColor;
      case 'goal':
        return _goalColor;
      default:
        return _unknownEntityColor;
    }
  }

  bool _isGroundTile(String type) {
    return type == 'ground' || type == 'floor';
  }

  Rect _buildAnimatedPlayerRect(BuilderPlaybackState playbackState) {
    final segments = controller.playbackVisualSegments;
    if (segments.isEmpty) {
      _activeVisualSegment = null;
      return Rect.fromLTWH(
        playbackState.toPlayerX * tileSize,
        playbackState.toPlayerY * tileSize,
        tileSize,
        tileSize,
      );
    }

    final totalDurationMs = segments.length * _moveAnimationDurationMs;
    final elapsedMs = _visualPlaybackElapsedMs
        .clamp(0.0, totalDurationMs.toDouble())
        .toDouble();
    final isAtEnd = elapsedMs >= totalDurationMs;
    final segmentIndex = isAtEnd
        ? segments.length - 1
        : (elapsedMs ~/ _moveAnimationDurationMs)
              .clamp(0, segments.length - 1)
              .toInt();
    final segment = segments[segmentIndex];
    final segmentStartMs = segmentIndex * _moveAnimationDurationMs;
    final rawProgress = isAtEnd
        ? 1.0
        : (elapsedMs - segmentStartMs) / _moveAnimationDurationMs;
    final progress = rawProgress.clamp(0.0, 1.0).toDouble();
    _activeVisualSegment = isAtEnd && !playbackState.isPlaying ? null : segment;

    final left =
        ((segment.toPlayerX - segment.fromPlayerX) * progress +
            segment.fromPlayerX) *
        tileSize;
    final baseTop =
        ((segment.toPlayerY - segment.fromPlayerY) * progress +
            segment.fromPlayerY) *
        tileSize;
    var top = baseTop;

    if (_isJumpCommand(segment.command)) {
      top -= math.sin(progress * math.pi) * tileSize * 0.45;
    }

    return Rect.fromLTWH(left, top, tileSize, tileSize);
  }

  bool _isJumpCommand(LogicCommandType? command) {
    return command == LogicCommandType.jumpUp ||
        command == LogicCommandType.climbUpLeft ||
        command == LogicCommandType.climbUpRight;
  }

  String _facingDirectionForEntity(EntityData entity) {
    return entity.config['direction'] == BuilderController.playerFacingLeft
        ? BuilderController.playerFacingLeft
        : BuilderController.playerFacingRight;
  }

  String _characterIdForEntity(EntityData entity) {
    return builderCharacterById(entity.config['character']?.toString()).id;
  }

  EntityData? get _goalEntity {
    for (final entity in controller.project.entities) {
      if (entity.type == 'goal') {
        return entity;
      }
    }

    return null;
  }

  bool _shouldHideEntity(
    EntityData entity,
    BuilderPlaybackState? playbackState,
  ) {
    if (playbackState == null) {
      return false;
    }

    if (entity.type == 'playerStart') {
      return true;
    }

    return entity.type == 'collectable' &&
        playbackState.collectedCollectableIds.contains(entity.id);
  }
}

class _CharacterFrameSet {
  final List<ui.Image> idle;
  final List<ui.Image> walk;
  final List<ui.Image> jumpUp;
  final List<ui.Image> jumpFall;

  const _CharacterFrameSet({
    required this.idle,
    required this.walk,
    required this.jumpUp,
    required this.jumpFall,
  });
}
