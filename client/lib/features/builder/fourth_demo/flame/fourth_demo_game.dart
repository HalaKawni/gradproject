import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../controllers/fourth_demo_controller.dart';
import '../models/fourth_demo_project.dart';

class FourthDemoGame extends FlameGame {
  final FourthDemoController controller;

  FourthDemoGame({required this.controller});

  @override
  Color backgroundColor() => const Color(0xFFB7DFF2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    controller.addListener(_wake);
  }

  @override
  void onRemove() {
    controller.removeListener(_wake);
    super.onRemove();
  }

  void _wake() {}

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
    final settings = controller.project.settings;
    if (size.x <= 0 || size.y <= 0) {
      return 1;
    }
    return math.min(size.x / settings.worldWidth, size.y / settings.worldHeight);
  }

  Offset get _worldOffset {
    final settings = controller.project.settings;
    final scale = _scale;
    return Offset(
      (size.x - settings.worldWidth * scale) / 2,
      (size.y - settings.worldHeight * scale) / 2,
    );
  }

  void _drawStage(Canvas canvas, FourthDemoProject project) {
    final world = Rect.fromLTWH(
      0,
      0,
      project.settings.worldWidth,
      project.settings.worldHeight,
    );
    canvas.clipRect(world);
    _drawBackground(canvas, world);
    _drawTiles(canvas, project);
    for (final sprite in project.sprites) {
      if (!sprite.visible) {
        continue;
      }
      _drawSprite(canvas, sprite);
    }
    _drawScreenWidgets(canvas, project.widgets);
    _drawSelection(canvas, project);
    if (controller.exerciseComplete) {
      _drawSuccessBanner(canvas, world);
    }
  }

  void _drawBackground(Canvas canvas, Rect world) {
    canvas.drawRect(world, Paint()..color = const Color(0xFFB7DFF2));
    canvas.drawCircle(
      Offset(world.width * 0.83, world.height * 0.2),
      32,
      Paint()..color = const Color(0xFFFFE082),
    );
    final far = Paint()..color = const Color(0xFF7BB86F).withValues(alpha: 0.55);
    final near = Paint()..color = const Color(0xFF3E8D41).withValues(alpha: 0.72);
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

  void _drawHill(Canvas canvas, Rect world, Paint paint, double yFactor, double height) {
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
        _drawPlayer(canvas, rect);
      case FourthDemoSpriteKind.collectible:
        _drawBanana(canvas, rect);
      case FourthDemoSpriteKind.prop:
        _drawProp(canvas, rect, Color(sprite.colorValue));
    }
    canvas.restore();
  }

  void _drawPlayer(Canvas canvas, Rect rect) {
    final body = Paint()..color = const Color(0xFF9A5B26);
    final face = Paint()..color = const Color(0xFFFFC48C);
    canvas.drawCircle(Offset(rect.left + rect.width * 0.28, rect.top + 13), 12, body);
    canvas.drawCircle(Offset(rect.right - rect.width * 0.28, rect.top + 13), 12, body);
    canvas.drawOval(rect.deflate(4), body);
    canvas.drawOval(rect.deflate(13).translate(0, 6), face);
    canvas.drawCircle(Offset(rect.left + rect.width * 0.42, rect.top + 25), 3, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(rect.left + rect.width * 0.60, rect.top + 25), 3, Paint()..color = Colors.black87);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(rect.center.dx, rect.top + 34), width: 18, height: 10),
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawBanana(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.left + 8, rect.center.dy)
      ..quadraticBezierTo(rect.center.dx, rect.bottom + 10, rect.right - 8, rect.top + 10);
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
    canvas.drawCircle(rect.center, rect.width * 0.18, Paint()..color = Colors.white.withValues(alpha: 0.5));
  }

  void _drawScreenWidgets(Canvas canvas, List<FourthDemoScreenWidget> widgets) {
    for (final widget in widgets) {
      if (!widget.visible) {
        continue;
      }
      final text = widget.type == FourthDemoWidgetKind.counter
          ? '${widget.text}: ${widget.value.toInt()}'
          : widget.text;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Color(widget.textColorValue).withValues(alpha: widget.opacity),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bg = Rect.fromLTWH(widget.x - 8, widget.y - 5, painter.width + 16, painter.height + 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bg, const Radius.circular(8)),
        Paint()..color = Colors.white.withValues(alpha: 0.82),
      );
      painter.paint(canvas, Offset(widget.x, widget.y));
    }
  }

  void _drawSelection(Canvas canvas, FourthDemoProject project) {
    final sprite = project.selectedSprite;
    if (sprite == null || !sprite.visible) {
      return;
    }
    final rect = Rect.fromLTWH(sprite.x, sprite.y, sprite.width, sprite.height).inflate(6);
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
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(canvas, Offset(rect.left + 22, rect.top + 11));
  }
}
