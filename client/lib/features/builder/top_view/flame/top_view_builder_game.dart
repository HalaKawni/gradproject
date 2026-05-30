import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:client/features/builder/top_view/models/top_view_character.dart';
import 'package:client/features/builder/top_view/models/top_view_board_style.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopViewRenderCell {
  final int column;
  final int row;

  const TopViewRenderCell({required this.column, required this.row});
}

class TopViewRenderItem {
  final String type;
  final TopViewRenderCell cell;
  final String? obstacleStyleId;
  final String? customAssetId;
  final double customAssetFrameScale;
  final double customAssetFrameOffsetX;
  final double customAssetFrameOffsetY;

  const TopViewRenderItem({
    required this.type,
    required this.cell,
    this.obstacleStyleId,
    this.customAssetId,
    this.customAssetFrameScale = 1,
    this.customAssetFrameOffsetX = 0,
    this.customAssetFrameOffsetY = 0,
  });
}

class TopViewBuilderGame extends FlameGame {
  final int columns;
  final int rows;
  final double playerSpriteTileScale;
  final double obstacleSpriteTileScale;
  final double runTilesPerSecond;
  final double walkFrameDurationSeconds;

  List<TopViewRenderItem> _items = const <TopViewRenderItem>[];
  TopViewRenderCell? _playerCell;
  String _playerCharacterId = defaultTopViewCharacterId;
  String _backgroundId = defaultTopViewBackgroundId;
  String _obstacleStyleId = defaultTopViewObstacleStyleId;
  double _playerHeadingDegrees = 90;
  Offset? _playerPosition;
  Offset? _targetPosition;
  Completer<void>? _moveCompleter;
  final Map<String, ui.Image> _characterImages = <String, ui.Image>{};
  final Map<String, ui.Image> _characterWalkSheets = <String, ui.Image>{};
  final Map<String, ui.Image> _backgroundImages = <String, ui.Image>{};
  final Map<String, ui.Image> _obstacleImages = <String, ui.Image>{};
  final Map<String, ui.Image> _customAssetImages = <String, ui.Image>{};
  final Set<String> _customAssetImagesLoading = <String>{};
  String? _customBackgroundAssetId;
  double _customBackgroundFrameScale = 1;
  double _customBackgroundFrameOffsetX = 0;
  double _customBackgroundFrameOffsetY = 0;
  double _walkAnimationElapsedSeconds = 0;

  TopViewBuilderGame({
    required this.columns,
    required this.rows,
    this.playerSpriteTileScale = 2.3,
    this.obstacleSpriteTileScale = 2.3,
    this.runTilesPerSecond = 3,
    this.walkFrameDurationSeconds = 0.28,
  });

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final character in topViewCharacters) {
      try {
        _characterImages[character.id] = await _loadUiImage(
          character.stillAssetPath,
        );
        _characterWalkSheets[character.id] = await _loadUiImage(
          character.walkSheetAssetPath,
        );
      } catch (_) {
        // Keep a painted fallback if an asset is temporarily unavailable.
      }
    }
    for (final background in topViewBackgrounds) {
      try {
        _backgroundImages[background.id] = await _loadUiImage(
          background.assetPath,
        );
      } catch (_) {
        // Keep the painted fallback if the background asset is unavailable.
      }
    }
    for (final obstacle in topViewObstacleStyles) {
      try {
        _obstacleImages[obstacle.id] = await _loadUiImage(obstacle.assetPath);
      } catch (_) {
        // Keep the painted fallback if the obstacle asset is unavailable.
      }
    }
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

  void syncBoard({
    required List<TopViewRenderItem> items,
    required TopViewRenderCell? playerCell,
    required String playerCharacterId,
    required String backgroundId,
    required String obstacleStyleId,
    required double playerHeadingDegrees,
    String? customBackgroundAssetId,
    double customBackgroundFrameScale = 1,
    double customBackgroundFrameOffsetX = 0,
    double customBackgroundFrameOffsetY = 0,
    Map<String, Uint8List> customAssetImages = const <String, Uint8List>{},
  }) {
    _items = List<TopViewRenderItem>.unmodifiable(items);
    _playerCell = playerCell;
    _playerCharacterId = topViewCharacterById(playerCharacterId).id;
    _backgroundId = topViewBackgroundById(backgroundId).id;
    _obstacleStyleId = topViewObstacleStyleById(obstacleStyleId).id;
    _playerHeadingDegrees = playerHeadingDegrees;
    _customBackgroundAssetId = customBackgroundAssetId;
    _customBackgroundFrameScale = customBackgroundFrameScale;
    _customBackgroundFrameOffsetX = customBackgroundFrameOffsetX;
    _customBackgroundFrameOffsetY = customBackgroundFrameOffsetY;
    _ensureCustomAssetImages(customAssetImages);
    _playerPosition ??= _playerCenterFromCell(playerCell);
  }

  void _ensureCustomAssetImages(Map<String, Uint8List> images) {
    for (final entry in images.entries) {
      if (_customAssetImages.containsKey(entry.key) ||
          _customAssetImagesLoading.contains(entry.key)) {
        continue;
      }

      _customAssetImagesLoading.add(entry.key);
      decodeImageFromList(entry.value)
          .then((image) {
            _customAssetImages[entry.key] = image;
          })
          .whenComplete(() {
            _customAssetImagesLoading.remove(entry.key);
          });
    }
  }

  void resetPlayerToCell(TopViewRenderCell? cell, double headingDegrees) {
    _moveCompleter?.complete();
    _moveCompleter = null;
    _targetPosition = null;
    _playerCell = cell;
    _playerPosition = _playerCenterFromCell(cell);
    _playerHeadingDegrees = headingDegrees;
  }

  void face(double headingDegrees) {
    _playerHeadingDegrees = headingDegrees;
  }

  Future<void> movePlayerTo(Offset targetPosition) {
    _targetPosition = targetPosition;
    final completer = Completer<void>();
    _moveCompleter = completer;
    return completer.future;
  }

  Offset cellCenter(int column, int row) {
    return Offset(column + 0.5, row + 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _targetPosition;
    final current = _playerPosition;
    if (target == null || current == null) {
      _walkAnimationElapsedSeconds = 0;
      return;
    }

    _walkAnimationElapsedSeconds += dt;

    final delta = target - current;
    final distance = delta.distance;
    if (distance < 0.001) {
      _finishMoveAt(target);
      return;
    }

    final step = runTilesPerSecond * dt;
    if (step >= distance) {
      _finishMoveAt(target);
      return;
    }

    _playerPosition = current + delta / distance * step;
  }

  void _finishMoveAt(Offset target) {
    _playerPosition = target;
    _targetPosition = null;
    _walkAnimationElapsedSeconds = 0;
    final completer = _moveCompleter;
    _moveCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cellWidth = size.x / columns;
    final cellHeight = size.y / rows;
    _renderBackground(canvas);
    _renderItems(canvas, cellWidth, cellHeight);
    _renderPlayer(canvas, cellWidth, cellHeight);
  }

  void _renderBackground(Canvas canvas) {
    final boardRect = Offset.zero & Size(size.x, size.y);
    final customBackgroundImage = _customAssetImages[_customBackgroundAssetId];
    if (customBackgroundImage != null) {
      _drawImageFrameCover(
        canvas,
        customBackgroundImage,
        boardRect,
        scale: _customBackgroundFrameScale,
        offsetX: _customBackgroundFrameOffsetX,
        offsetY: _customBackgroundFrameOffsetY,
        clipToFrame: true,
      );
      return;
    }

    final image = _backgroundImages[_backgroundId];

    if (image == null) {
      canvas.drawRect(boardRect, Paint()..color = const Color(0xFFCFE1F3));
      return;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      boardRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void _renderItems(Canvas canvas, double cellWidth, double cellHeight) {
    for (final item in _items) {
      if (item.type == 'player') {
        continue;
      }

      final center = Offset(
        (item.cell.column + 0.5) * cellWidth,
        (item.cell.row + 0.5) * cellHeight,
      );
      final shortestSide = math.min(cellWidth, cellHeight);
      final paint = Paint()..color = _itemColor(item.type);
      final customImage = _customAssetImages[item.customAssetId];
      if (customImage != null) {
        final scale = item.type == 'obstacle'
            ? obstacleSpriteTileScale
            : item.type == 'player'
            ? playerSpriteTileScale
            : 1.0;
        final rect = Rect.fromCenter(
          center: center,
          width: shortestSide * scale,
          height: shortestSide * scale,
        );
        _drawImageFrameCover(
          canvas,
          customImage,
          rect,
          scale: item.customAssetFrameScale,
          offsetX: item.customAssetFrameOffsetX,
          offsetY: item.customAssetFrameOffsetY,
          clipToFrame: false,
        );
        continue;
      }

      if (item.type == 'obstacle') {
        final obstacleStyleId = topViewObstacleStyleById(
          item.obstacleStyleId ?? _obstacleStyleId,
        ).id;
        final image = _obstacleImages[obstacleStyleId];
        final rect = Rect.fromCenter(
          center: center,
          width: shortestSide * obstacleSpriteTileScale,
          height: shortestSide * obstacleSpriteTileScale,
        );
        if (image != null) {
          _drawImageContain(canvas, image, rect);
          continue;
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(shortestSide * 0.12)),
          paint,
        );
        continue;
      }

      canvas.drawCircle(center, shortestSide * 0.3, paint);
    }
  }

  void _drawImageContain(Canvas canvas, ui.Image image, Rect bounds) {
    final imageAspectRatio = image.width / image.height;
    final boundsAspectRatio = bounds.width / bounds.height;
    final destination = imageAspectRatio > boundsAspectRatio
        ? Rect.fromCenter(
            center: bounds.center,
            width: bounds.width,
            height: bounds.width / imageAspectRatio,
          )
        : Rect.fromCenter(
            center: bounds.center,
            width: bounds.height * imageAspectRatio,
            height: bounds.height,
          );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void _drawImageFrameCover(
    Canvas canvas,
    ui.Image image,
    Rect bounds, {
    required double scale,
    required double offsetX,
    required double offsetY,
    bool clipToFrame = false,
  }) {
    final imageAspectRatio = image.width / image.height;
    final boundsAspectRatio = bounds.width / bounds.height;
    final fittedRect = imageAspectRatio > boundsAspectRatio
        ? Rect.fromCenter(
            center: bounds.center,
            width: bounds.width,
            height: bounds.width / imageAspectRatio,
          )
        : Rect.fromCenter(
            center: bounds.center,
            width: bounds.height * imageAspectRatio,
            height: bounds.height,
          );
    final scaledRect = Rect.fromCenter(
      center: bounds.center.translate(
        offsetX * bounds.width * 0.5,
        offsetY * bounds.height * 0.5,
      ),
      width: fittedRect.width * scale,
      height: fittedRect.height * scale,
    );

    canvas.save();
    if (clipToFrame) {
      canvas.clipRect(bounds);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      scaledRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _renderPlayer(Canvas canvas, double cellWidth, double cellHeight) {
    final playerPosition =
        _playerPosition ?? _playerCenterFromCell(_playerCell);
    if (playerPosition == null) {
      return;
    }

    final isMoving = _targetPosition != null;
    TopViewRenderItem? customPlayerItem;
    for (final item in _items) {
      if (item.type == 'player' && item.customAssetId != null) {
        customPlayerItem = item;
        break;
      }
    }
    final customPlayerImage =
        _customAssetImages[customPlayerItem?.customAssetId];
    final image = isMoving
        ? _characterWalkSheets[_playerCharacterId] ??
              _characterImages[_playerCharacterId]
        : _characterImages[_playerCharacterId];
    final shortestSide = math.min(cellWidth, cellHeight);
    final spriteSize = shortestSide * playerSpriteTileScale;
    final center = Offset(
      playerPosition.dx * cellWidth,
      playerPosition.dy * cellHeight,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_degreesToRadians(90 - _playerHeadingDegrees));
    if (customPlayerImage != null) {
      final destination = Rect.fromCenter(
        center: Offset.zero,
        width: spriteSize,
        height: spriteSize,
      );
      _drawImageFrameCover(
        canvas,
        customPlayerImage,
        destination,
        scale: customPlayerItem?.customAssetFrameScale ?? 1,
        offsetX: customPlayerItem?.customAssetFrameOffsetX ?? 0,
        offsetY: customPlayerItem?.customAssetFrameOffsetY ?? 0,
        clipToFrame: false,
      );
    } else if (image == null) {
      final destination = Rect.fromCenter(
        center: Offset.zero,
        width: spriteSize,
        height: spriteSize,
      );
      final fallbackPaint = Paint()..color = const Color(0xFF2563EB);
      canvas.drawRRect(
        RRect.fromRectAndRadius(destination, const Radius.circular(8)),
        fallbackPaint,
      );
    } else {
      final sourceRect = _playerSourceRect(image, isMoving: isMoving);
      final aspectRatio = sourceRect.width / sourceRect.height;
      final destination = Rect.fromCenter(
        center: Offset.zero,
        width: spriteSize * aspectRatio,
        height: spriteSize,
      );
      canvas.drawImageRect(
        image,
        sourceRect,
        destination,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    canvas.restore();
  }

  Rect _playerSourceRect(ui.Image image, {required bool isMoving}) {
    if (!isMoving) {
      return Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
    }

    const frameCount = 5;
    final frameWidth = image.width / frameCount;
    final frameIndex =
        (_walkAnimationElapsedSeconds / walkFrameDurationSeconds).floor() %
        frameCount;

    return Rect.fromLTWH(
      frameIndex * frameWidth,
      0,
      frameWidth,
      image.height.toDouble(),
    );
  }

  Offset? _playerCenterFromCell(TopViewRenderCell? cell) {
    if (cell == null) {
      return null;
    }
    return Offset(cell.column + 0.5, cell.row + 0.5);
  }

  Color _itemColor(String type) {
    switch (type) {
      case 'obstacle':
        return const Color(0xFF64748B);
      case 'collectable':
        return const Color(0xFFF59E0B);
      case 'goal':
        return const Color(0xFF22C55E);
      default:
        return Colors.black;
    }
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
