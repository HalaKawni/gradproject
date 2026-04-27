import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'level_map_page.dart';

class WorldMapPage extends StatelessWidget {
  const WorldMapPage({super.key});

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
                  border: Border.all(color: const Color(0xFF44ACFF), width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // ── SKY BACKGROUND ──
                    Positioned.fill(child: _SkyBackground()),

                    // ── HILLS ──
                    Positioned.fill(child: _HillsPainter()),

                    // ── TOPIC BUBBLES ──
                    // Sequencing (unlocked)
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.22,
                      top: 80,
                      child: _TopicBubble(
                        label: 'Sequencing',
                        progress: '1/15',
                        unlocked: true,
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LevelMapPage(
                              topic: 'Sequencing',
                              unlockedLevel: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Loops (locked)
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.47,
                      top: 100,
                      child: _TopicBubble(
                        label: 'Loops',
                        progress: '',
                        unlocked: false,
                        color: const Color(0xFF90CAF9),
                        onTap: () {},
                      ),
                    ),

                    // ── GET 15/15 TO UNLOCK ──
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.38,
                      top: 260,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Get 15/15 To Unlock',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── MUTE BUTTON ──
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            'CODEMONKEY JR. – SEQUENCING AND LOOPS',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Play button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                const Icon(Icons.play_arrow, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF90A4AE),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.menu, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

// ── TOPIC BUBBLE ─────────────────────────────────────────────
class _TopicBubble extends StatefulWidget {
  final String label;
  final String progress;
  final bool unlocked;
  final Color color;
  final VoidCallback onTap;

  const _TopicBubble({
    required this.label,
    required this.progress,
    required this.unlocked,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TopicBubble> createState() => _TopicBubbleState();
}

class _TopicBubbleState extends State<_TopicBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    if (widget.unlocked) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _bounce = Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    } else {
      _controller = AnimationController(vsync: this);
      _bounce = Tween<double>(begin: 0, end: 0).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            // ── BANNER LABEL ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.label,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.unlocked) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.white, size: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── CIRCLE ──
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.9),
                    border: Border.all(
                      color: widget.unlocked
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF78909C),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.unlocked
                        ? _MonkeyInBubble()
                        : _SlothInBubble(),
                  ),
                ),
                // Lock icon for locked topics
                if (!widget.unlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.lock,
                          color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),

            // ── PROGRESS ──
            if (widget.progress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.progress,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(
                        color: Colors.black45,
                        offset: Offset(1, 1),
                        blurRadius: 2),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── MONKEY DRAWING IN BUBBLE ──────────────────────────────────
class _MonkeyInBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _MonkeyBubblePainter(),
    );
  }
}

class _MonkeyBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final cx = size.width / 2;

    // Ground
    p.color = const Color(0xFFFFB300);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.65, size.width, size.height), p);

    // Body
    p.color = const Color(0xFFD4A017);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 18, size.height * 0.45, 36, 30),
            const Radius.circular(10)),
        p);

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.38), 22, p);

    // Face
    p.color = const Color(0xFFFFD580);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.4),
            width: 28,
            height: 20),
        p);

    // Eyes
    p.color = Colors.white;
    canvas.drawCircle(Offset(cx - 7, size.height * 0.34), 6, p);
    canvas.drawCircle(Offset(cx + 7, size.height * 0.34), 6, p);
    p.color = Colors.black87;
    canvas.drawCircle(Offset(cx - 6, size.height * 0.34), 4, p);
    canvas.drawCircle(Offset(cx + 8, size.height * 0.34), 4, p);
    p.color = Colors.white;
    canvas.drawCircle(Offset(cx - 5, size.height * 0.32), 1.5, p);
    canvas.drawCircle(Offset(cx + 9, size.height * 0.32), 1.5, p);

    // Smile
    p.color = Colors.brown.shade700;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    final smile = Path()
      ..moveTo(cx - 6, size.height * 0.43)
      ..quadraticBezierTo(cx, size.height * 0.48, cx + 6, size.height * 0.43);
    canvas.drawPath(smile, p);
    p.style = PaintingStyle.fill;

    // Stick
    p.color = const Color(0xFF8B4513);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4;
    p.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 20, size.height * 0.5),
        Offset(cx + 20, size.height * 0.9), p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_MonkeyBubblePainter old) => false;
}

// ── SLOTH DRAWING IN BUBBLE ───────────────────────────────────
class _SlothInBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _SlothBubblePainter(),
    );
  }
}

class _SlothBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final cx = size.width / 2;

    // Ground
    p.color = const Color(0xFFFFB300);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.65, size.width, size.height), p);

    // Body
    p.color = const Color(0xFF8D6E63);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 20, size.height * 0.45, 40, 32),
            const Radius.circular(12)),
        p);

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.36), 24, p);

    // Face
    p.color = const Color(0xFFD7CCC8);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.38),
            width: 32,
            height: 24),
        p);

    // Eyes (sleepy)
    p.color = Colors.black54;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    canvas.drawLine(Offset(cx - 9, size.height * 0.34),
        Offset(cx - 4, size.height * 0.34), p);
    canvas.drawLine(Offset(cx + 4, size.height * 0.34),
        Offset(cx + 9, size.height * 0.34), p);
    p.style = PaintingStyle.fill;

    // Nose
    p.color = Colors.brown.shade400;
    canvas.drawCircle(Offset(cx, size.height * 0.4), 3, p);
  }

  @override
  bool shouldRepaint(_SlothBubblePainter old) => false;
}

// ── SKY BACKGROUND ────────────────────────────────────────────
class _SkyBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB0E0FF)],
        ),
      ),
    );
  }
}

// ── HILLS PAINTER ─────────────────────────────────────────────
class _HillsPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HillsCustomPainter());
  }
}

class _HillsCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Back hills (darker)
    p.color = const Color(0xFF388E3C);
    final backHill = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.85, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backHill, p);

    // Front hills (lighter)
    p.color = const Color(0xFF4CAF50);
    final frontHill = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 0.45, size.width * 0.6, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.8, size.height * 0.85, size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontHill, p);

    // Clouds
    p.color = Colors.white.withOpacity(0.85);
    _drawCloud(canvas, p, size.width * 0.08, size.height * 0.08, 60, 22);
    _drawCloud(canvas, p, size.width * 0.65, size.height * 0.06, 50, 18);
    _drawCloud(canvas, p, size.width * 0.85, size.height * 0.15, 44, 16);
  }

  void _drawCloud(Canvas canvas, Paint p, double x, double y, double w, double h) {
    canvas.drawCircle(Offset(x, y + h * 0.5), w * 0.22, p);
    canvas.drawCircle(Offset(x + w * 0.3, y + h * 0.3), w * 0.28, p);
    canvas.drawCircle(Offset(x + w * 0.6, y + h * 0.5), w * 0.22, p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x + w * 0.3, y + h * 0.6), width: w * 0.8, height: h * 0.6),
        p);
  }

  @override
  bool shouldRepaint(_HillsCustomPainter old) => false;
}