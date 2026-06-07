import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/fourth_demo_controller.dart';
import '../models/fourth_demo_project.dart';
import '../../front_view/shared/builder_collectable.dart';
import '../../front_view/shared/builder_character.dart';

class FourthDemoGame extends FlameGame {
  static const int _idleFrameDurationMs = 95;
  static const int _walkFrameDurationMs = 62;
  static const double _defaultPlayerSpriteMaxWidthScale = 1.35;
  static const double _defaultPlayerSpriteMaxHeightScale = 1.7;
  static const double _defaultPlayerSpriteFacingLeftOffsetXScale = 0.20;
  static const double _defaultPlayerSpriteFacingRightOffsetXScale = -0.1;
  static const double _defaultPlayerSpriteOffsetYScale = 0.17;
  static const double _cameraFollowSpeed = 10;

  final FourthDemoController controller;
  final Map<String, ui.Image> _assetImages = <String, ui.Image>{};
  final Map<String, _CharacterFrameSet> _characterFrames =
      <String, _CharacterFrameSet>{};
  final Map<String, ui.Image> _backgroundImages = <String, ui.Image>{};
  final Map<String, _SpriteAnimationState> _spriteAnimations =
      <String, _SpriteAnimationState>{};
  double _animationElapsedMs = 0;
  Offset _cameraOffset = Offset.zero;
  bool _cameraInitialized = false;

  FourthDemoGame({required this.controller});

  @override
  Color backgroundColor() => const Color(0xFFB7DFF2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadSpriteImages());
    unawaited(_loadBackgroundImage());
    unawaited(_loadPlayerFrames());
    controller.addListener(_wake);
  }

  @override
  void onRemove() {
    controller.removeListener(_wake);
    super.onRemove();
  }

  void _wake() {}

  @override
  void update(double dt) {
    super.update(dt);
    _animationElapsedMs += dt * Duration.millisecondsPerSecond;
    _advanceSpriteAnimations(dt);
    controller.handleUpdate(dt);
    _updateCamera(dt);
  }

  Offset worldPositionFromCanvas(Offset canvasPosition) {
    final scale = _scale;
    final offset = _worldOffset;
    return Offset(
      (canvasPosition.dx - offset.dx) / scale,
      (canvasPosition.dy - offset.dy) / scale,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final project = controller.project;
    final scale = _scale;
    final offset = _worldOffset;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    _drawStage(canvas, project);
    canvas.restore();
  }

  double get _scale {
    return 1;
  }

  Offset get _worldOffset {
    if (!_cameraInitialized) {
      return _desiredWorldOffset;
    }
    return _cameraOffset;
  }

  Offset get _desiredWorldOffset {
    final project = controller.project;
    final viewportWidth = size.x;
    final viewportHeight = size.y;
    final worldWidth = project.settings.worldWidth;
    final worldHeight = project.settings.worldHeight;
    if (viewportWidth <= 0 || viewportHeight <= 0) {
      return Offset.zero;
    }

    final target = _cameraTargetSprite(project);
    if (target == null) {
      return Offset(
        worldWidth < viewportWidth ? (viewportWidth - worldWidth) / 2 : 0,
        worldHeight < viewportHeight ? (viewportHeight - worldHeight) / 2 : 0,
      );
    }

    final visualPosition = controller.visualPositionFor(target);
    final targetCenter = Offset(
      visualPosition.dx + target.width / 2,
      visualPosition.dy + target.height / 2,
    );
    return Offset(
      _cameraFollowOffsetAfterMidpoint(
        targetCenter: targetCenter.dx,
        viewportExtent: viewportWidth,
        worldExtent: worldWidth,
      ),
      _cameraFollowOffsetAfterMidpoint(
        targetCenter: targetCenter.dy,
        viewportExtent: viewportHeight,
        worldExtent: worldHeight,
      ),
    );
  }

  double _cameraFollowOffsetAfterMidpoint({
    required double targetCenter,
    required double viewportExtent,
    required double worldExtent,
  }) {
    if (worldExtent <= viewportExtent) {
      return (viewportExtent - worldExtent) / 2;
    }
    final rawOffset = viewportExtent / 2 - targetCenter;
    return rawOffset.clamp(viewportExtent - worldExtent, 0).toDouble();
  }

  void _updateCamera(double dt) {
    final desired = _desiredWorldOffset;
    if (!_cameraInitialized || !controller.isPlaying) {
      _cameraOffset = desired;
      _cameraInitialized = true;
      return;
    }
    final t = (1 - math.exp(-dt * _cameraFollowSpeed))
        .clamp(0.0, 1.0)
        .toDouble();
    final next = Offset.lerp(_cameraOffset, desired, t) ?? desired;
    if ((next - desired).distance < 0.2) {
      _cameraOffset = desired;
      return;
    }
    _cameraOffset = next;
  }

  FourthDemoSprite? _cameraTargetSprite(FourthDemoProject project) {
    final targetId = project.settings.cameraTargetId.trim();
    if (targetId.isNotEmpty) {
      final normalized = targetId.toLowerCase();
      final target = project.sprites
          .where(
            (sprite) =>
                sprite.id.toLowerCase() == normalized ||
                sprite.name.toLowerCase() == normalized,
          )
          .firstOrNull;
      if (target != null) {
        return target;
      }
    }
    return project.selectedSprite ??
        project.sprites
            .where((sprite) => sprite.kind == FourthDemoSpriteKind.player)
            .firstOrNull ??
        project.sprites.firstOrNull;
  }

  void _drawStage(Canvas canvas, FourthDemoProject project) {
    final world = Rect.fromLTWH(
      0,
      0,
      project.settings.worldWidth,
      project.settings.worldHeight,
    );
    canvas.clipRect(world);
    _drawBackground(canvas, world, project.settings.background);
    _drawTiles(canvas, project);
    for (final sprite in project.sprites) {
      if (!sprite.visible || sprite.destroyed) {
        continue;
      }
      final visualPosition = controller.visualPositionFor(sprite);
      _drawSprite(
        canvas,
        sprite.copyWith(x: visualPosition.dx, y: visualPosition.dy),
      );
    }
    _drawSpeechBubbles(canvas, project, world);
    _drawScreenWidgets(canvas, project.widgets);
    _drawSelection(canvas, project);
    if (controller.exerciseComplete) {
      _drawSuccessBanner(canvas, world);
    }
  }

  void _drawBackground(Canvas canvas, Rect world, String backgroundName) {
    final background = backgroundName.trim().toLowerCase();
    final image = _backgroundImages[background];
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: world,
        image: image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
      );
      return;
    }

    switch (background) {
      case 'desert':
        _drawDesertBackground(canvas, world);
        return;
      case 'green':
        _drawGreenBackground(canvas, world);
        return;
      case 'sky':
        _drawSkyBackground(canvas, world);
        return;
      case 'forest':
      default:
        _drawForestFallback(canvas, world);
        return;
    }
  }

  void _drawForestFallback(Canvas canvas, Rect world) {
    canvas.drawRect(world, Paint()..color = const Color(0xFFB7DFF2));
    canvas.drawCircle(
      Offset(world.width * 0.83, world.height * 0.2),
      32,
      Paint()..color = const Color(0xFFFFE082),
    );
    final far = Paint()
      ..color = const Color(0xFF7BB86F).withValues(alpha: 0.55);
    final near = Paint()
      ..color = const Color(0xFF3E8D41).withValues(alpha: 0.72);
    _drawHill(canvas, world, far, 0.58, 80);
    _drawHill(canvas, world, near, 0.68, 54);
    for (var i = 0; i < 7; i += 1) {
      final x = i * 92.0 - 20;
      canvas.drawOval(
        Rect.fromLTWH(x, world.height * 0.52 - (i.isEven ? 18 : 0), 60, 120),
        Paint()..color = const Color(0xFF2F6B22).withValues(alpha: 0.22),
      );
    }
  }

  void _drawSkyBackground(Canvas canvas, Rect world) {
    canvas.drawRect(world, Paint()..color = const Color(0xFFAEDDF8));
    canvas.drawCircle(
      Offset(world.width * 0.78, world.height * 0.22),
      34,
      Paint()..color = const Color(0xFFFFDD67),
    );
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.84);
    for (final center in <Offset>[
      Offset(world.width * 0.22, world.height * 0.25),
      Offset(world.width * 0.52, world.height * 0.18),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 86, height: 32),
        cloud,
      );
      canvas.drawCircle(center.translate(-26, -4), 18, cloud);
      canvas.drawCircle(center.translate(18, -9), 22, cloud);
    }
  }

  void _drawDesertBackground(Canvas canvas, Rect world) {
    canvas.drawRect(world, Paint()..color = const Color(0xFFFFD98A));
    canvas.drawCircle(
      Offset(world.width * 0.82, world.height * 0.18),
      34,
      Paint()..color = const Color(0xFFFFF0A3),
    );
    _drawHill(
      canvas,
      world,
      Paint()..color = const Color(0xFFE3A95D),
      0.72,
      34,
    );
    _drawHill(
      canvas,
      world,
      Paint()..color = const Color(0xFFC98945),
      0.82,
      28,
    );
  }

  void _drawGreenBackground(Canvas canvas, Rect world) {
    canvas.drawRect(world, Paint()..color = const Color(0xFFCDEFD2));
    _drawHill(
      canvas,
      world,
      Paint()..color = const Color(0xFF7BC46F),
      0.62,
      62,
    );
    _drawHill(
      canvas,
      world,
      Paint()..color = const Color(0xFF3FA65D),
      0.78,
      44,
    );
  }

  void _drawHill(
    Canvas canvas,
    Rect world,
    Paint paint,
    double yFactor,
    double height,
  ) {
    final path = Path()..moveTo(0, world.height);
    for (var x = 0.0; x <= world.width; x += 80) {
      path.quadraticBezierTo(
        x + 38,
        world.height * yFactor - height,
        x + 80,
        world.height * yFactor,
      );
    }
    path.lineTo(world.width, world.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawTiles(Canvas canvas, FourthDemoProject project) {
    final tileWidth = project.settings.worldWidth / project.tilemap.columns;
    final tileHeight = project.settings.worldHeight / project.tilemap.rows;
    for (final tile in project.tilemap.tiles) {
      final rect = Rect.fromLTWH(
        tile.x * tileWidth,
        tile.y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final color = switch (tile.type) {
        'platform' => const Color(0xFF7BBF51),
        'obstacle' => const Color(0xFF8B5E3C),
        _ => const Color(0xFF2F6B22),
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.23),
        Paint()..color = const Color(0xFF73CA55),
      );
    }
  }

  void _drawSprite(Canvas canvas, FourthDemoSprite sprite) {
    final rect = Rect.fromLTWH(sprite.x, sprite.y, sprite.width, sprite.height);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(sprite.rotation * math.pi / 180);
    canvas.scale(sprite.scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    switch (sprite.kind) {
      case FourthDemoSpriteKind.player:
        _drawPlayer(canvas, rect, sprite);
      case FourthDemoSpriteKind.collectible:
        _drawCollectible(canvas, rect, sprite.assetId);
      case FourthDemoSpriteKind.prop:
        _drawProp(canvas, rect, Color(sprite.colorValue));
    }
    canvas.restore();
  }

  void _drawPlayer(Canvas canvas, Rect rect, FourthDemoSprite sprite) {
    final character = builderCharacterById(
      sprite.assetId.isEmpty ? defaultBuilderCharacterId : sprite.assetId,
    );
    final image =
        _scriptedPlayerFrame(sprite, character.id) ??
        _currentPlayerFrame(
          character.id,
          isWalking: controller.isSpriteWalking(sprite),
        ) ??
        _assetImages[character.idlePreviewAssetPath];
    if (image != null) {
      final flip = sprite.facing == FourthDemoSpriteFacing.right;
      final sourceRect = _sourceRectForCharacter(image, character);
      final destinationRect = _playerDestinationRect(
        image: image,
        spriteRect: rect,
        character: character,
        facing: sprite.facing,
      );
      _drawImageRectFacing(
        canvas: canvas,
        image: image,
        sourceRect: sourceRect,
        destinationRect: destinationRect,
        flipHorizontally: flip,
      );
      return;
    }

    final body = Paint()..color = const Color(0xFF9A5B26);
    final face = Paint()..color = const Color(0xFFFFC48C);
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.28, rect.top + 13),
      12,
      body,
    );
    canvas.drawCircle(
      Offset(rect.right - rect.width * 0.28, rect.top + 13),
      12,
      body,
    );
    canvas.drawOval(rect.deflate(4), body);
    canvas.drawOval(rect.deflate(13).translate(0, 6), face);
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.42, rect.top + 25),
      3,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.60, rect.top + 25),
      3,
      Paint()..color = Colors.black87,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top + 34),
        width: 18,
        height: 10,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Rect _playerDestinationRect({
    required ui.Image image,
    required Rect spriteRect,
    required BuilderCharacter character,
    required FourthDemoSpriteFacing facing,
  }) {
    final config = character.spriteRect;
    final baseRect = _imageRectForSprite(
      image: image,
      spriteRect: spriteRect,
      maxWidth:
          spriteRect.width *
          (config.maxWidthScale ?? _defaultPlayerSpriteMaxWidthScale),
      maxHeight:
          spriteRect.height *
          (config.maxHeightScale ?? _defaultPlayerSpriteMaxHeightScale),
    );

    return baseRect.translate(
      facing == FourthDemoSpriteFacing.right
          ? spriteRect.width *
                (config.facingRightOffsetXScale ??
                    _defaultPlayerSpriteFacingRightOffsetXScale)
          : spriteRect.width *
                (config.facingLeftOffsetXScale ??
                    _defaultPlayerSpriteFacingLeftOffsetXScale),
      spriteRect.height *
          (config.offsetYScale ?? _defaultPlayerSpriteOffsetYScale),
    );
  }

  Rect _imageRectForSprite({
    required ui.Image image,
    required Rect spriteRect,
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
      spriteRect.center.dx - width / 2,
      spriteRect.bottom - height,
      width,
      height,
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

  void _drawCollectible(Canvas canvas, Rect rect, String assetId) {
    final image = _assetImages[_collectableAssetPath(assetId)];
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
      return;
    }

    final path = Path()
      ..moveTo(rect.left + 8, rect.center.dy)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.bottom + 10,
        rect.right - 8,
        rect.top + 10,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFC928)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF1A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawProp(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(8)),
      Paint()..color = color,
    );
    canvas.drawCircle(
      rect.center,
      rect.width * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawScreenWidgets(Canvas canvas, List<FourthDemoScreenWidget> widgets) {
    for (final widget in widgets) {
      if (!widget.visible || widget.type == FourthDemoWidgetKind.dialog) {
        continue;
      }
      _drawScreenWidget(canvas, widget);
    }
    for (final widget in widgets) {
      if (widget.visible && widget.type == FourthDemoWidgetKind.dialog) {
        _drawDialogWidget(canvas, widget);
      }
    }
  }

  void _drawScreenWidget(Canvas canvas, FourthDemoScreenWidget widget) {
    final alpha = widget.opacity.clamp(0.0, 1.0);
    final text = switch (widget.type) {
      FourthDemoWidgetKind.counter =>
        '${_widgetText(widget, fallback: widget.name)}: ${widget.value.toInt()}',
      FourthDemoWidgetKind.timer => _widgetLabelValue(
        widget,
        _formatSeconds(widget.value),
      ),
      FourthDemoWidgetKind.clock => _widgetLabelValue(
        widget,
        _formatSeconds(widget.value),
      ),
      FourthDemoWidgetKind.button => _widgetText(widget, fallback: widget.name),
      _ => _widgetText(widget, fallback: widget.name),
    };
    final textColor = Color(
      widget.textColorValue,
    ).withValues(alpha: widget.enabled ? alpha : alpha * 0.45);
    final painter =
        TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: widget.type == FourthDemoWidgetKind.button ? 15 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          maxLines: widget.type == FourthDemoWidgetKind.text ? 3 : 1,
          ellipsis: '...',
          textAlign: _textAlign(widget.textAlign),
          textDirection: TextDirection.ltr,
        )..layout(
          minWidth: widget.type == FourthDemoWidgetKind.text ? 190 : 0,
          maxWidth: widget.type == FourthDemoWidgetKind.text ? 190 : 160,
        );

    final rect = widget.type == FourthDemoWidgetKind.button
        ? Rect.fromLTWH(
            widget.x,
            widget.y,
            math.max(116, painter.width + 28),
            38,
          )
        : Rect.fromLTWH(
            widget.x - 8,
            widget.y - 5,
            math.max(64, painter.width + 16),
            painter.height + 10,
          );
    final backgroundColor = switch (widget.type) {
      FourthDemoWidgetKind.button =>
        widget.enabled ? const Color(0xFF66B64A) : const Color(0xFF94A3B8),
      FourthDemoWidgetKind.timer => const Color(0xFFFFF3D4),
      FourthDemoWidgetKind.clock => const Color(0xFFE9F4FF),
      FourthDemoWidgetKind.counter => const Color(0xFFEAF8EA),
      _ => Colors.white,
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = backgroundColor.withValues(alpha: alpha * 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF263238).withValues(alpha: alpha * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final textOffset = widget.type == FourthDemoWidgetKind.button
        ? Offset(
            rect.left + (rect.width - painter.width) / 2,
            rect.top + (rect.height - painter.height) / 2,
          )
        : Offset(widget.x, widget.y);
    painter.paint(canvas, textOffset);
  }

  void _drawDialogWidget(Canvas canvas, FourthDemoScreenWidget widget) {
    final alpha = widget.opacity.clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(widget.x, widget.y, 260, 118);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.96),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFF263238).withValues(alpha: alpha * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final title = widget.title.trim();
    if (title.isNotEmpty) {
      final titlePainter = TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
            color: const Color(0xFF263238).withValues(alpha: alpha),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        maxLines: 1,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 28);
      titlePainter.paint(canvas, Offset(rect.left + 14, rect.top + 12));
    }

    final buttonRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - 22),
      width: 64,
      height: 24,
    );
    final bodyPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          color: Color(widget.textColorValue).withValues(alpha: alpha),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 3,
      ellipsis: '...',
      textAlign: _textAlign(widget.textAlign),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: rect.width - 28, maxWidth: rect.width - 28);
    final bodyTop = title.isEmpty ? rect.top + 14 : rect.top + 36;
    final bodyBottom = buttonRect.top - 10;
    final bodyY =
        bodyTop + math.max(0.0, bodyBottom - bodyTop - bodyPainter.height) / 2;
    bodyPainter.paint(canvas, Offset(rect.left + 14, bodyY));
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF66B64A).withValues(alpha: alpha),
    );
    final buttonPainter = TextPainter(
      text: TextSpan(
        text: widget.buttonText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: buttonRect.width - 8);
    buttonPainter.paint(
      canvas,
      Offset(
        buttonRect.left + (buttonRect.width - buttonPainter.width) / 2,
        buttonRect.top + (buttonRect.height - buttonPainter.height) / 2,
      ),
    );
  }

  String _widgetText(
    FourthDemoScreenWidget widget, {
    required String fallback,
  }) {
    final text = widget.text.trim();
    return text.isEmpty ? fallback : text;
  }

  String _widgetLabelValue(FourthDemoScreenWidget widget, String value) {
    final label = widget.text.trim();
    return label.isEmpty ? value : '$label: $value';
  }

  String _formatSeconds(double value) {
    final total = math.max(0, value).floor();
    final minutes = total ~/ 60;
    final seconds = total % 60;
    if (minutes <= 0) {
      return seconds.toString();
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  TextAlign _textAlign(FourthDemoWidgetTextAlign value) {
    return switch (value) {
      FourthDemoWidgetTextAlign.left => TextAlign.left,
      FourthDemoWidgetTextAlign.center => TextAlign.center,
      FourthDemoWidgetTextAlign.right => TextAlign.right,
    };
  }

  void _drawSpeechBubbles(
    Canvas canvas,
    FourthDemoProject project,
    Rect world,
  ) {
    for (final sprite in project.sprites) {
      if (!sprite.visible || sprite.destroyed) {
        continue;
      }
      final text = controller.speechTextFor(sprite.id);
      if (text == null || text.trim().isEmpty) {
        continue;
      }
      final visualPosition = controller.visualPositionFor(sprite);
      final rect = Rect.fromLTWH(
        visualPosition.dx,
        visualPosition.dy,
        sprite.width,
        sprite.height,
      );
      _drawSpeechBubble(canvas, rect, text, world);
    }
  }

  void _drawSpeechBubble(
    Canvas canvas,
    Rect spriteRect,
    String text,
    Rect world,
  ) {
    const maxBubbleWidth = 180.0;
    const horizontalPadding = 12.0;
    const verticalPadding = 8.0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF263238),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 3,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxBubbleWidth - horizontalPadding * 2);

    final bubbleWidth = painter.width + horizontalPadding * 2;
    final bubbleHeight = painter.height + verticalPadding * 2;
    var left = spriteRect.center.dx - bubbleWidth / 2;
    left = left.clamp(world.left + 6, world.right - bubbleWidth - 6).toDouble();
    final top = math.max(world.top + 6, spriteRect.top - bubbleHeight - 12);
    final bubbleRect = Rect.fromLTWH(left, top, bubbleWidth, bubbleHeight);

    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.94);
    final borderPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(bubbleRect, const Radius.circular(8));
    canvas.drawRRect(rrect, bubblePaint);
    canvas.drawRRect(rrect, borderPaint);

    final tailCenter = spriteRect.center.dx.clamp(
      bubbleRect.left + 14,
      bubbleRect.right - 14,
    );
    final tail = Path()
      ..moveTo(tailCenter - 7, bubbleRect.bottom - 1)
      ..lineTo(tailCenter + 7, bubbleRect.bottom - 1)
      ..lineTo(spriteRect.center.dx, bubbleRect.bottom + 9)
      ..close();
    canvas.drawPath(tail, bubblePaint);
    canvas.drawPath(tail, borderPaint);

    painter.paint(
      canvas,
      Offset(
        bubbleRect.left + horizontalPadding,
        bubbleRect.top + verticalPadding,
      ),
    );
  }

  void _drawSelection(Canvas canvas, FourthDemoProject project) {
    final sprite = project.selectedSprite;
    if (sprite == null || !sprite.visible) {
      return;
    }
    final rect = Rect.fromLTWH(
      sprite.x,
      sprite.y,
      sprite.width,
      sprite.height,
    ).inflate(6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF66B64A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawSuccessBanner(Canvas canvas, Rect world) {
    final rect = Rect.fromCenter(
      center: Offset(world.center.dx, 56),
      width: 270,
      height: 46,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF4CC486),
    );
    final painter = TextPainter(
      text: const TextSpan(
        text: 'Success! Banana collected',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(canvas, Offset(rect.left + 22, rect.top + 11));
  }

  ui.Image? _currentPlayerFrame(String characterId, {required bool isWalking}) {
    final frameSet =
        _characterFrames[builderCharacterById(characterId).id] ??
        _characterFrames[defaultBuilderCharacterId];
    if (frameSet == null) {
      return null;
    }

    final frames = isWalking && frameSet.walk.isNotEmpty
        ? frameSet.walk
        : frameSet.idle;
    if (frames.isEmpty) {
      return null;
    }

    final duration = isWalking ? _walkFrameDurationMs : _idleFrameDurationMs;
    final frameIndex = (_animationElapsedMs / duration).floor() % frames.length;
    return frames[frameIndex];
  }

  ui.Image? _scriptedPlayerFrame(FourthDemoSprite sprite, String characterId) {
    if (sprite.currentAnimation.isEmpty) {
      return null;
    }
    final animation = sprite.animations
        .where((item) => item.name == sprite.currentAnimation)
        .firstOrNull;
    if (animation == null || animation.frames.isEmpty || animation.fps <= 0) {
      return null;
    }
    final frameSet =
        _characterFrames[builderCharacterById(characterId).id] ??
        _characterFrames[defaultBuilderCharacterId];
    if (frameSet == null) {
      return null;
    }
    final sourceFrames = frameSet.walk.isNotEmpty
        ? frameSet.walk
        : frameSet.idle;
    if (sourceFrames.isEmpty) {
      return null;
    }

    final state = _spriteAnimations[sprite.id];
    final elapsed = state?.elapsedSeconds ?? 0;
    final rawFrame = (elapsed * animation.fps).floor();
    final sequenceIndex = animation.loop
        ? rawFrame % animation.frames.length
        : rawFrame.clamp(0, animation.frames.length - 1).toInt();
    final frameIndex = animation.frames[sequenceIndex]
        .clamp(0, sourceFrames.length - 1)
        .toInt();
    return sourceFrames[frameIndex];
  }

  void _advanceSpriteAnimations(double dt) {
    if (!controller.isPlaying) {
      return;
    }
    final activeSpriteIds = <String>{};
    for (final sprite in controller.project.sprites.toList()) {
      if (sprite.currentAnimation.isEmpty) {
        _spriteAnimations.remove(sprite.id);
        continue;
      }
      activeSpriteIds.add(sprite.id);
      final animation = sprite.animations
          .where((item) => item.name == sprite.currentAnimation)
          .firstOrNull;
      if (animation == null || animation.frames.isEmpty || animation.fps <= 0) {
        _spriteAnimations.remove(sprite.id);
        continue;
      }
      final state = _animationStateFor(sprite.id, animation.name)
        ..elapsedSeconds += dt;
      final durationSeconds = animation.frames.length / animation.fps;
      if (durationSeconds <= 0) {
        continue;
      }
      if (animation.loop) {
        final completedLoops = (state.elapsedSeconds / durationSeconds).floor();
        if (completedLoops > state.completedLoops) {
          state.completedLoops = completedLoops;
          controller.handleAnimationLoop(sprite.id, animation.name);
        }
      } else if (!state.ended && state.elapsedSeconds >= durationSeconds) {
        state.ended = true;
        controller.handleAnimationEnd(sprite.id, animation.name);
      }
    }
    _spriteAnimations.removeWhere((id, _) => !activeSpriteIds.contains(id));
  }

  _SpriteAnimationState _animationStateFor(String spriteId, String name) {
    final current = _spriteAnimations[spriteId];
    if (current != null && current.name == name) {
      return current;
    }
    final next = _SpriteAnimationState(name);
    _spriteAnimations[spriteId] = next;
    return next;
  }

  Future<void> _loadPlayerFrames() async {
    for (final character in builderCharacters) {
      final frames = await _loadCharacterFrames(character);
      if (frames.idle.isNotEmpty || frames.walk.isNotEmpty) {
        _characterFrames[character.id] = frames;
      }
    }
  }

  Future<_CharacterFrameSet> _loadCharacterFrames(
    BuilderCharacter character,
  ) async {
    return _CharacterFrameSet(
      idle: await _loadFrameList(_idleFramePaths(character)),
      walk: await _loadFrameList(_walkFramePaths(character)),
    );
  }

  Future<List<ui.Image>> _loadFrameList(List<String> paths) async {
    final frames = <ui.Image>[];
    for (final path in paths) {
      final image = await _loadImage(path);
      if (image != null) {
        frames.add(image);
      }
    }
    return frames;
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

  Future<void> _loadSpriteImages() async {
    final paths = <String>{
      for (final character in builderCharacters) character.idlePreviewAssetPath,
      for (final collectable in builderCollectables)
        collectable.flutterAssetPath,
    };
    for (final path in paths) {
      final image = await _loadImage(path);
      if (image != null) {
        _assetImages[path] = image;
      }
    }
  }

  Future<void> _loadBackgroundImage() async {
    final forest = await _loadImage(
      'game_builder/background/backgroundColorForest.png',
    );
    if (forest != null) {
      _backgroundImages['forest'] = forest;
    }
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    final candidates = <String>[assetPath, 'assets/$assetPath'];

    for (final candidate in candidates) {
      try {
        final data = await rootBundle.load(candidate);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _collectableAssetPath(String assetId) {
    return builderCollectableById(
      assetId.isEmpty ? defaultBuilderCollectableId : assetId,
    ).flutterAssetPath;
  }
}

class _CharacterFrameSet {
  final List<ui.Image> idle;
  final List<ui.Image> walk;

  const _CharacterFrameSet({required this.idle, required this.walk});
}

class _SpriteAnimationState {
  final String name;
  double elapsedSeconds = 0;
  int completedLoops = 0;
  bool ended = false;

  _SpriteAnimationState(this.name);
}
