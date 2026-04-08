import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class WherePlayingPage extends StatefulWidget {
  const WherePlayingPage({super.key});

  @override
  State<WherePlayingPage> createState() => _WherePlayingPageState();
}

class _WherePlayingPageState extends State<WherePlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudAnimation =
        Tween<double>(begin: 0, end: 1).animate(_cloudController);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavbar(context),
          Expanded(
            child: Stack(
              children: [
                // ── BACKGROUND ──
                Positioned.fill(
                  child: Container(
                    color: const Color.fromRGBO(216, 233, 241, 1),
                  ),
                ),

                // ── CLOUDS ──
                _animatedCloud(0.0, 30, 180, 65),
                _animatedCloud(0.5, 80, 140, 48),
                _animatedCloud(0.25, 10, 120, 42),
                _animatedCloud(0.1, 200, 160, 55),
                _animatedCloud(0.7, 260, 100, 35),
                _animatedCloud(0.4, 380, 150, 52),
                _animatedCloud(0.85, 460, 130, 44),
                _animatedCloud(0.6, 540, 110, 38),

                // ── CONTENT ──
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── BACK ──
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_left,
                                    color: Colors.white, size: 20),
                                Text(
                                  'BACK',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── STUDENT SIGNUP label ──
                      Text(
                        'STUDENT SIGNUP',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── TITLE ──
                      Text(
                        'WHERE WILL YOU BE PLAYING?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amaticSc(
                          color: Colors.white,
                          fontSize: 58,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          shadows: const [
                            Shadow(
                              offset: Offset(3, 3),
                              color: Color(0x33000000),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── HOME / CLASSROOM CARDS ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PlayingCard(
                              answer: 'HOME',
                              subtitle: "I'm playing on my own",
                              imagePath: 'assets/images/home.png',
                              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HomeAgePage()),
  );
},
                            ),
                            const SizedBox(width: 24),
                            _PlayingCard(
                              answer: 'CLASSROOM',
                              subtitle:
                                  'I belong to a CodeMonkey classroom with a teacher',
                              imagePath: 'assets/images/classroom2.jpg',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Already a member ──
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Already a member? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Log in to your account',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: const Color(0xFF1A73E8),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCloud(
      double offset, double top, double width, double height) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        final sw = MediaQuery.of(context).size.width;
        final x = -200 +
            (((_cloudAnimation.value + offset) % 1.0) * (sw + 400));
        return Positioned(left: x, top: top, child: child!);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _CloudPainter()),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'nameofweb',
            style: TextStyle(
              color: Color.fromARGB(255, 220, 202, 233),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              _HoverNavButton(
                label: 'LOG IN',
                onPressed: () => Navigator.pop(context),
              ),
              _HoverNavButton(
                label: 'SIGN UP',
                onPressed: () {},
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── PLAYING CARD ──
class _PlayingCard extends StatefulWidget {
  final String answer;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _PlayingCard({
    required this.answer,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_PlayingCard> createState() => _PlayingCardState();
}

class _PlayingCardState extends State<_PlayingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF888888)
                  : const Color(0xFFDDDDDD),
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Text(
                widget.answer,
                style: GoogleFonts.amaticSc(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF777777),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                child: Image.asset(
                  widget.imagePath,
                  width: 240,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CLOUD PAINTER ──
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.18, h * 0.85), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.92), w * 0.17, paint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.83, h * 0.85), w * 0.14, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.90,
        height: h * 0.55,
      ),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.30), w * 0.22, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.18, h * 0.58), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.58), w * 0.14, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => false;
}

// ── HOVER NAV BUTTON ──
class _HoverNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _HoverNavButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isYellow = widget.filled || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isYellow
                ? const Color.fromARGB(255, 220, 202, 233)
                : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: isYellow ? const Color(0xFF3A2A00) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}