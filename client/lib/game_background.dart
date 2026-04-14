import 'dart:math';
import 'package:flutter/material.dart';

class GameBackground extends StatefulWidget {
  const GameBackground({super.key});

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_cloudController, _sunController]),
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(
            cloudOffset: _cloudController.value,
            sunBob: _sunController.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double cloudOffset;
  final double sunBob;

  _BackgroundPainter({required this.cloudOffset, required this.sunBob});

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawFarMountains(canvas, size);
    _drawNearMountains(canvas, size);
    _drawClouds(canvas, size);
    _drawSun(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFAEDFF7),
          const Color(0xFFD6F0FB),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawFarMountains(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8FB8A0).withOpacity(0.5);
    final path = Path();
    final groundY = size.height * 0.62;

    path.moveTo(0, groundY);
    final peaks = [
      Offset(size.width * 0.05, groundY - size.height * 0.18),
      Offset(size.width * 0.18, groundY - size.height * 0.28),
      Offset(size.width * 0.30, groundY - size.height * 0.15),
      Offset(size.width * 0.42, groundY - size.height * 0.32),
      Offset(size.width * 0.55, groundY - size.height * 0.20),
      Offset(size.width * 0.68, groundY - size.height * 0.30),
      Offset(size.width * 0.80, groundY - size.height * 0.18),
      Offset(size.width * 0.92, groundY - size.height * 0.25),
      Offset(size.width, groundY - size.height * 0.12),
    ];

    path.lineTo(peaks[0].dx, peaks[0].dy);
    for (int i = 1; i < peaks.length; i++) {
      final prev = peaks[i - 1];
      final curr = peaks[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + curr.dy) / 2);
    }
    path.lineTo(size.width, groundY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawNearMountains(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF5A8A6A).withOpacity(0.7);
    final path = Path();
    final groundY = size.height * 0.62;

    path.moveTo(0, groundY);
    final peaks = [
      Offset(size.width * 0.08, groundY - size.height * 0.22),
      Offset(size.width * 0.22, groundY - size.height * 0.14),
      Offset(size.width * 0.38, groundY - size.height * 0.26),
      Offset(size.width * 0.52, groundY - size.height * 0.12),
      Offset(size.width * 0.65, groundY - size.height * 0.24),
      Offset(size.width * 0.78, groundY - size.height * 0.14),
      Offset(size.width * 0.90, groundY - size.height * 0.20),
      Offset(size.width, groundY - size.height * 0.10),
    ];

    path.lineTo(peaks[0].dx, peaks[0].dy);
    for (int i = 1; i < peaks.length; i++) {
      final prev = peaks[i - 1];
      final curr = peaks[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + curr.dy) / 2);
    }
    path.lineTo(size.width, groundY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.9);

    // Three clouds at different positions, moving at different speeds
    final clouds = [
      _CloudData(baseX: 0.15, baseY: 0.08, scale: 1.0, speed: 1.0),
      _CloudData(baseX: 0.50, baseY: 0.05, scale: 0.7, speed: 0.6),
      _CloudData(baseX: 0.78, baseY: 0.10, scale: 0.85, speed: 0.8),
    ];

    for (final cloud in clouds) {
      // Offset moves cloud left, wraps around
      double x = (cloud.baseX - cloudOffset * cloud.speed) % 1.2 - 0.1;
      final cx = x * size.width;
      final cy = cloud.baseY * size.height;
      final s = cloud.scale * size.width * 0.06;
      _drawCloud(canvas, paint, cx, cy, s);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, double cx, double cy, double s) {
    canvas.drawCircle(Offset(cx, cy), s * 0.8, paint);
    canvas.drawCircle(Offset(cx - s, cy + s * 0.3), s * 0.6, paint);
    canvas.drawCircle(Offset(cx + s, cy + s * 0.3), s * 0.6, paint);
    canvas.drawCircle(Offset(cx - s * 0.4, cy + s * 0.5), s * 0.55, paint);
    canvas.drawCircle(Offset(cx + s * 0.4, cy + s * 0.5), s * 0.55, paint);
  }

  void _drawSun(Canvas canvas, Size size) {
    final cx = size.width * 0.88;
    // Gentle bobbing
    final cy = size.height * 0.10 + sunBob * 8;
    final r = size.width * 0.055;

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final innerR = r + 6;
      final outerR = r + 18;
      canvas.drawLine(
        Offset(cx + cos(angle) * innerR, cy + sin(angle) * innerR),
        Offset(cx + cos(angle) * outerR, cy + sin(angle) * outerR),
        rayPaint,
      );
    }

    // Sun body
    final sunPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(cx, cy), r, sunPaint);

    // Sun face — eyes
    final eyePaint = Paint()..color = const Color(0xFF7A5000);
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.1), r * 0.1, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.28, cy - r * 0.1), r * 0.1, eyePaint);

    // Sun face — smile
    final smilePaint = Paint()
      ..color = const Color(0xFF7A5000)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.28, cy + r * 0.18);
    smilePath.quadraticBezierTo(cx, cy + r * 0.42, cx + r * 0.28, cy + r * 0.18);
    canvas.drawPath(smilePath, smilePaint);

    // Sun cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF9800).withOpacity(0.4);
    canvas.drawCircle(Offset(cx - r * 0.42, cy + r * 0.15), r * 0.15, cheekPaint);
    canvas.drawCircle(Offset(cx + r * 0.42, cy + r * 0.15), r * 0.15, cheekPaint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.cloudOffset != cloudOffset || old.sunBob != sunBob;
}

class _CloudData {
  final double baseX;
  final double baseY;
  final double scale;
  final double speed;
  const _CloudData({
    required this.baseX,
    required this.baseY,
    required this.scale,
    required this.speed,
  });
}