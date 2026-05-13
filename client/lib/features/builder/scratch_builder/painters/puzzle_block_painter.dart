import 'package:flutter/material.dart';

class PuzzleBlockPainter extends CustomPainter {
  final Color color;
  final bool isContainer;

  PuzzleBlockPainter({required this.color, required this.isContainer});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = _buildPath(size);

    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  Path _buildPath(Size size) {
    final r = isContainer ? 13.0 : 12.0;
    const notchH = 8.0;

    final path = Path();

    path.moveTo(r, 0);
    path.lineTo(48, 0);
    path.cubicTo(52, 0, 54, notchH, 60, notchH);
    path.lineTo(80, notchH);
    path.cubicTo(86, notchH, 88, 0, 92, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height - r - notchH);
    path.quadraticBezierTo(
      size.width,
      size.height - notchH,
      size.width - r,
      size.height - notchH,
    );
    path.lineTo(92, size.height - notchH);
    path.cubicTo(88, size.height - notchH, 86, size.height, 80, size.height);
    path.lineTo(60, size.height);
    path.cubicTo(
      54,
      size.height,
      52,
      size.height - notchH,
      48,
      size.height - notchH,
    );
    path.lineTo(r, size.height - notchH);
    path.quadraticBezierTo(
      0,
      size.height - notchH,
      0,
      size.height - notchH - r,
    );
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant PuzzleBlockPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isContainer != isContainer;
  }
}
