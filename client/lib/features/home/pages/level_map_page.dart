import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'monkey_game_page.dart';

class LevelMapPage extends StatelessWidget {
  final String topic;
  final int unlockedLevel; // levels 1..unlockedLevel are playable

  const LevelMapPage({
    super.key,
    required this.topic,
    required this.unlockedLevel,
  });

  // Path positions for 11 visible levels (zigzag road)
  static const List<Offset> _levelPositions = [
    Offset(0.12, 0.72), // 1
    Offset(0.18, 0.58), // 2  ← monkey here
    Offset(0.30, 0.72), // 3
    Offset(0.38, 0.50), // 4
    Offset(0.48, 0.32), // 5
    Offset(0.58, 0.48), // 6
    Offset(0.64, 0.66), // 7
    Offset(0.72, 0.74), // 8
    Offset(0.76, 0.55), // 9 (off screen right — scroll later)
    Offset(0.82, 0.42), // 10
    Offset(0.88, 0.32), // 11
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B00),
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF44ACFF), width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        // ── BACKGROUND ──
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF87CEEB),
                                  Color(0xFFB0E0FF)
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── HILLS ──
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LevelMapHillsPainter(),
                          ),
                        ),

                        // ── ROAD PATH ──
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RoadPainter(
                              positions: _levelPositions,
                              width: w,
                              height: h,
                            ),
                          ),
                        ),

                        // ── DECORATIONS ──
                        ..._buildDecorations(w, h),

                        // ── LEVEL NODES ──
                        ..._buildLevelNodes(context, w, h),

                        // ── TOPIC BANNER ──
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFFE65100),
                                    blurRadius: 0,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                topic,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── MUTE ──
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7B68EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.volume_off,
                                color: Colors.white, size: 20),
                          ),
                        ),

                        // ── HOME BUTTON ──
                        Positioned(
                          left: 12,
                          top: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE91E8C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.home,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLevelNodes(
      BuildContext context, double w, double h) {
    final nodes = <Widget>[];

    for (int i = 0; i < _levelPositions.length; i++) {
      final levelNum = i + 1;
      final pos = _levelPositions[i];
      final isUnlocked = levelNum <= unlockedLevel;
      final isCurrent = levelNum == unlockedLevel;
      final x = pos.dx * w;
      final y = pos.dy * h;

      nodes.add(
        Positioned(
          left: x - 30,
          top: y - 30,
          child: GestureDetector(
            onTap: isUnlocked
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MonkeyGamePage(),
                      ),
                    )
                : null,
            child: _LevelNode(
              number: levelNum,
              isUnlocked: isUnlocked,
              isCurrent: isCurrent,
            ),
          ),
        ),
      );
    }

    return nodes;
  }

  List<Widget> _buildDecorations(double w, double h) {
    return [
      // Frog on lily pad
      Positioned(
        left: w * 0.42,
        top: h * 0.55,
        child: CustomPaint(
          size: const Size(60, 50),
          painter: _FrogPainter(),
        ),
      ),
      // Flower 1
      Positioned(
        left: w * 0.22,
        top: h * 0.3,
        child: CustomPaint(
          size: const Size(40, 50),
          painter: _FlowerPainter(color: const Color(0xFF9C27B0)),
        ),
      ),
      // Flower 2
      Positioned(
        left: w * 0.88,
        top: h * 0.18,
        child: CustomPaint(
          size: const Size(36, 44),
          painter: _FlowerPainter(color: const Color(0xFFE91E63)),
        ),
      ),
      // Rocket bird
      Positioned(
        left: w * 0.62,
        top: h * 0.2,
        child: CustomPaint(
          size: const Size(50, 40),
          painter: _RocketBirdPainter(),
        ),
      ),
      // Blue bird
      Positioned(
        left: w * 0.86,
        top: h * 0.22,
        child: CustomPaint(
          size: const Size(30, 30),
          painter: _BlueBirdPainter(),
        ),
      ),
    ];
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFF3D2200),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6DB84A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'CODEMONKEY JR. – $topic'.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.play_arrow,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF90A4AE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.menu, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

// ── LEVEL NODE WIDGET ─────────────────────────────────────────
class _LevelNode extends StatelessWidget {
  final int number;
  final bool isUnlocked;
  final bool isCurrent;

  const _LevelNode({
    required this.number,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      // Monkey avatar on current level
      return SizedBox(
        width: 60,
        height: 72,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFFFFF),
                border: Border.all(
                    color: const Color(0xFFFFB300), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: _SmallMonkeyPainter(),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Text(
                '$number',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isUnlocked) {
      // Completed level — show stars
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFFB300), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$number',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF555555),
              ),
            ),
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star,
                      color: const Color(0xFFFFB300), size: 10),
                  Icon(Icons.star,
                      color: const Color(0xFFFFB300), size: 10),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Locked level
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF333333),
          border: Border.all(color: const Color(0xFF555555), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.lock,
                  color: Colors.white, size: 18),
            ),
            Positioned(
              bottom: 6,
              child: Text(
                '$number',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ── ROAD PAINTER ──────────────────────────────────────────────
class _RoadPainter extends CustomPainter {
  final List<Offset> positions;
  final double width;
  final double height;

  _RoadPainter(
      {required this.positions,
      required this.width,
      required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final points = positions
        .map((p) => Offset(p.dx * width, p.dy * height))
        .toList();

    // Brown road
    final roadPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, roadPaint);

    // Center dashes
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(_RoadPainter old) => false;
}

// ── HILLS FOR LEVEL MAP ───────────────────────────────────────
class _LevelMapHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    p.color = const Color(0xFF2E7D32);
    final hill1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.15,
          size.width * 0.35, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.7,
          size.width * 0.75, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.15,
          size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill1, p);

    p.color = const Color(0xFF388E3C);
    final hill2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.5,
          size.width * 0.4, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.78,
          size.width * 0.8, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.5,
          size.width, size.height * 0.6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill2, p);

    p.color = const Color(0xFF43A047);
    final hill3 = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.72,
          size.width * 0.5, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.95,
          size.width, size.height * 0.8)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill3, p);

    // Pond
    p.color = const Color(0xFF29B6F6).withOpacity(0.7);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.68),
            width: 90,
            height: 50),
        p);
  }

  @override
  bool shouldRepaint(_LevelMapHillsPainter old) => false;
}

// ── FROG PAINTER ──────────────────────────────────────────────
class _FrogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF43A047);
    // Lily pad
    p.color = const Color(0xFF2E7D32);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.85),
            width: size.width,
            height: size.height * 0.3),
        p);
    // Body
    p.color = const Color(0xFF66BB6A);
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.55), size.width * 0.3, p);
    // Eyes
    p.color = Colors.white;
    canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.3), 7, p);
    canvas.drawCircle(
        Offset(size.width * 0.65, size.height * 0.3), 7, p);
    p.color = Colors.black87;
    canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.3), 4, p);
    canvas.drawCircle(
        Offset(size.width * 0.65, size.height * 0.3), 4, p);
  }

  @override
  bool shouldRepaint(_FrogPainter old) => false;
}

// ── FLOWER PAINTER ────────────────────────────────────────────
class _FlowerPainter extends CustomPainter {
  final Color color;
  _FlowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    // Stem
    p.color = const Color(0xFF388E3C);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    canvas.drawLine(Offset(size.width / 2, size.height),
        Offset(size.width / 2, size.height * 0.4), p);
    p.style = PaintingStyle.fill;
    // Petals
    p.color = color;
    for (int i = 0; i < 6; i++) {
      final angle = i * 3.14159 / 3;
      canvas.drawCircle(
          Offset(size.width / 2 + 10 * _cos(angle),
              size.height * 0.35 + 10 * _sin(angle)),
          7,
          p);
    }
    // Center
    p.color = Colors.yellow;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.35), 6, p);
  }

  double _cos(double a) => _trig(a, true);
  double _sin(double a) => _trig(a, false);
  double _trig(double x, bool isCos) {
    if (isCos) x = 3.14159 / 2 - x;
    double r = x, t = x;
    for (int i = 1; i <= 5; i++) {
      t *= -x * x / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(_FlowerPainter old) => false;
}

// ── ROCKET BIRD PAINTER ───────────────────────────────────────
class _RocketBirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    // Body (red triangle pointing right)
    p.color = Colors.red;
    final body = Path()
      ..moveTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(body, p);
    // Eye
    p.color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.45), 5, p);
    p.color = Colors.black;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.45), 3, p);
  }

  @override
  bool shouldRepaint(_RocketBirdPainter old) => false;
}

// ── BLUE BIRD PAINTER ─────────────────────────────────────────
class _BlueBirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.4, p);
    p.color = Colors.white;
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.35), 5, p);
    p.color = Colors.black;
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.35), 3, p);
    // Hat
    p.color = const Color(0xFF1565C0);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, 8), p);
  }

  @override
  bool shouldRepaint(_BlueBirdPainter old) => false;
}

// ── SMALL MONKEY FOR CURRENT NODE ────────────────────────────
class _SmallMonkeyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final cx = size.width / 2;

    p.color = const Color(0xFFFFB300);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.6, size.width, size.height), p);

    p.color = const Color(0xFFD4A017);
    canvas.drawCircle(Offset(cx, size.height * 0.4), size.width * 0.28, p);

    p.color = const Color(0xFFFFD580);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.42),
            width: size.width * 0.36,
            height: size.height * 0.24),
        p);

    p.color = Colors.white;
    canvas.drawCircle(Offset(cx - 6, size.height * 0.36), 5, p);
    canvas.drawCircle(Offset(cx + 6, size.height * 0.36), 5, p);
    p.color = Colors.black87;
    canvas.drawCircle(Offset(cx - 5, size.height * 0.36), 3, p);
    canvas.drawCircle(Offset(cx + 7, size.height * 0.36), 3, p);
  }

  @override
  bool shouldRepaint(_SmallMonkeyPainter old) => false;
}