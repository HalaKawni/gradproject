import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/builder_controller.dart';
import '../models/builder_playback_state.dart';
import '../models/entity_data.dart';
import '../models/logic_command.dart';
import '../models/tile_data.dart';

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

class BuilderBoard extends PositionComponent {
  static const Color _backgroundColor = BuilderGame.boardBackgroundColor;
  static const Color _groundTileColor = Color(0xFF5FBF72);
  static const Color _obstacleTileColor = Color(0xFF7C8796);
  static const Color _unknownTileColor = Color(0xFF9AA5B5);
  static const Color _playerColor = Color(0xFF3B82F6);
  static const Color _collectableColor = Color(0xFFF59E0B);
  static const Color _goalColor = Color(0xFFEF4444);
  static const Color _unknownEntityColor = Color(0xFF8B5CF6);

  final BuilderController controller;

  BuilderBoard({required this.controller});

  double get tileSize => controller.project.settings.tileSize;
  int get rows => controller.project.settings.rows;
  int get columns => controller.project.settings.columns;
  double get boardWidth => columns * tileSize;
  double get boardHeight => rows * tileSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncBoardSize();
  }

  void _syncBoardSize() {
    final nextWidth = boardWidth;
    final nextHeight = boardHeight;

    if (size.x != nextWidth || size.y != nextHeight) {
      size = Vector2(nextWidth, nextHeight);
    }
  }

  @override
  void render(Canvas canvas) {
    _syncBoardSize();

    _drawBackground(canvas);
    _drawTiles(canvas);
    _drawGrid(canvas);
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
      _drawBox(canvas, rect, _tileColorForType(tile.type));
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF7AA9C9).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int r = 0; r <= rows; r++) {
      final y = r * tileSize;
      canvas.drawLine(Offset(0, y), Offset(columns * tileSize, y), paint);
    }

    for (int c = 0; c <= columns; c++) {
      final x = c * tileSize;
      canvas.drawLine(Offset(x, 0), Offset(x, rows * tileSize), paint);
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
      _drawBox(
        canvas,
        rect.deflate(tileSize * 0.18),
        _entityColorForType(entity.type),
      );
    }

    if (playbackState != null) {
      final previewRect = _buildAnimatedPlayerRect(playbackState);
      _drawBox(canvas, previewRect.deflate(tileSize * 0.18), _playerColor);
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
    canvas.drawRect(boardRect, Paint()..color = _backgroundColor);
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
    final elapsedMs =
        DateTime.now().millisecondsSinceEpoch - playbackState.movementStartedAtMs;
    final rawProgress = elapsedMs / 450.0;
    final progress = math.min(1.0, math.max(0.0, rawProgress));
    final left =
        ((playbackState.toPlayerX - playbackState.fromPlayerX) * progress +
            playbackState.fromPlayerX) *
        tileSize;
    var top =
        ((playbackState.toPlayerY - playbackState.fromPlayerY) * progress +
            playbackState.fromPlayerY) *
        tileSize;

    if (_isJumpCommand(playbackState.animatedCommand)) {
      top -= math.sin(progress * math.pi) * tileSize * 0.45;
    }

    return Rect.fromLTWH(left, top, tileSize, tileSize);
  }

  bool _isJumpCommand(LogicCommandType? command) {
    return command == LogicCommandType.jumpUp ||
        command == LogicCommandType.climbUpLeft ||
        command == LogicCommandType.climbUpRight;
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
