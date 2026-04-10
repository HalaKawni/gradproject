import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SorryPage extends StatefulWidget {
  const SorryPage({super.key});

  @override
  State<SorryPage> createState() => _SorryPageState();
}

class _SorryPageState extends State<SorryPage>
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
                      const SizedBox(height: 40),

                      // ── Student Signup label ──
                      Text(
                        'Student Signup',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── TITLE ──
                      Text(
                        'SORRY, FELLOW GRASSHOPPER',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amaticSc(
                          color: Colors.white,
                          fontSize: 58,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(
                              offset: Offset(3, 3),
                              color: Color(0x33000000),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── MAGNIFYING GLASS ILLUSTRATION ──
                    Image.asset(
  'assets/images/grasshopper.png',
  width: 220,
  height: 220,
  fit: BoxFit.contain,
),

                      const SizedBox(height: 40),

                      // ── Message ──
                      Text(
                        'Unfortunately you are not eligible to access this option.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── TWO BUTTONS ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _YellowButton(
                            label: 'Belong to a classroom?',
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 16),
                          _YellowButton(
                            label: 'Playing at home?',
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── Maybe these links can help ──
                      Text(
                        'Maybe these links can help?',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LinkText(label: 'Mini Courses', onTap: () {}),
                          Text(' | ',
                              style: GoogleFonts.nunito(
                                  color: Colors.white, fontSize: 14)),
                          _LinkText(label: 'Help Center', onTap: () {}),
                          Text(' | ',
                              style: GoogleFonts.nunito(
                                  color: Colors.white, fontSize: 14)),
                          _LinkText(label: 'Blog', onTap: () {}),
                        ],
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
        final x =
            -200 + (((_cloudAnimation.value + offset) % 1.0) * (sw + 400));
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

// ── YELLOW BUTTON ──
class _YellowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _YellowButton({required this.label, required this.onTap});

  @override
  State<_YellowButton> createState() => _YellowButtonState();
}

class _YellowButtonState extends State<_YellowButton> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color.fromARGB(255,195, 158, 222)
                : const Color.fromARGB(255,220, 202, 233),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3A2A00),
            ),
          ),
        ),
      ),
    );
  }
}

// ── LINK TEXT ──
class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: Colors.white,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
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