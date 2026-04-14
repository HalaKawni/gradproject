import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student.dart';
import 'parent.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
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
    _cloudAnimation = Tween<double>(begin: 0, end: 1).animate(_cloudController);
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
                // ── BACKGROUND IMAGE ──
                Positioned.fill(
                  child: Container(
                    color: const Color.fromRGBO(216, 233, 241, 1),
                  ),
                ),

                // ── CLOUD 1 — top-left, slow ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x = -200 + (_cloudAnimation.value * (sw + 400));
                    return Positioned(left: x, top: 30, child: child!);
                  },
                  child: _buildCloud(180, 65),
                ),

                // ── CLOUD 2 — top, offset 0.5 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -160 +
                        (((_cloudAnimation.value + 0.5) % 1.0) * (sw + 320));
                    return Positioned(left: x, top: 80, child: child!);
                  },
                  child: _buildCloud(140, 48),
                ),

                // ── CLOUD 3 — upper area, offset 0.25 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -180 +
                        (((_cloudAnimation.value + 0.25) % 1.0) * (sw + 360));
                    return Positioned(left: x, top: 10, child: child!);
                  },
                  child: _buildCloud(120, 42),
                ),

                // ── CLOUD 4 — mid page, offset 0.1, slower ──
                AnimatedBuilder(
                  animation: CurvedAnimation(
                    parent: _cloudController,
                    curve: Curves.linear,
                  ),
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -200 +
                        (((_cloudAnimation.value + 0.1) % 1.0) * (sw + 400));
                    return Positioned(left: x, top: 200, child: child!);
                  },
                  child: _buildCloud(160, 55),
                ),

                // ── CLOUD 5 — mid page right side, offset 0.7 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -150 +
                        (((_cloudAnimation.value + 0.7) % 1.0) * (sw + 300));
                    return Positioned(left: x, top: 260, child: child!);
                  },
                  child: _buildCloud(100, 35),
                ),

                // ── CLOUD 6 — lower area, offset 0.4 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -200 +
                        (((_cloudAnimation.value + 0.4) % 1.0) * (sw + 400));
                    return Positioned(left: x, top: 380, child: child!);
                  },
                  child: _buildCloud(150, 52),
                ),

                // ── CLOUD 7 — bottom area, offset 0.85 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -180 +
                        (((_cloudAnimation.value + 0.85) % 1.0) * (sw + 360));
                    return Positioned(left: x, top: 460, child: child!);
                  },
                  child: _buildCloud(130, 44),
                ),

                // ── CLOUD 8 — very bottom, offset 0.6 ──
                AnimatedBuilder(
                  animation: _cloudAnimation,
                  builder: (context, child) {
                    final sw = MediaQuery.of(context).size.width;
                    final x =
                        -160 +
                        (((_cloudAnimation.value + 0.6) % 1.0) * (sw + 320));
                    return Positioned(left: x, top: 540, child: child!);
                  },
                  child: _buildCloud(110, 38),
                ),

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
                                const Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  size: 20,
                                ),
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

                      const SizedBox(height: 10),

                      // ── SIGN UP label ──
                      Text(
                        'SIGN UP',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── WHO ARE YOU? ──
                      Text(
                        'WHO ARE YOU?',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 52,
                          shadows: const [
                            Shadow(
                              offset: Offset(3, 3),
                              color: Color(0x33000000),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Subtitle ──
                      Text(
                        'Start your free trial today!',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── CARDS ROW ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoleCard(
                            title: 'STUDENT',
                            subtitle:
                                'Join your classmates in fun coding games',
                            imagePath: 'assets/images/student.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentSignupPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 24),
                          _RoleCard(
                            title: 'PARENT',
                            subtitle:
                                'Introduce your child to Computer Science and track their progress',
                            imagePath: 'assets/images/parent.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const parentAccountPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Already a member ──
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF333333),
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

  Widget _buildCloud(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CloudPainter()),
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
              _HoverNavButton(label: 'SIGN UP', onPressed: () {}, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ROLE CARD WITH HOVER ──
class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
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
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF888888)
                  : const Color(0xFFDDDDDD),
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3A3A3A),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFF777777),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  widget.imagePath,
                  width: 260,
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
            borderRadius: BorderRadius.zero,
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

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // ── BOTTOM BUMPS ──
    canvas.drawCircle(Offset(w * 0.18, h * 0.85), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.92), w * 0.17, paint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.83, h * 0.85), w * 0.14, paint);

    // ── WIDE MIDDLE BODY ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.90,
        height: h * 0.55,
      ),
      paint,
    );

    // ── TOP BUMPS ──
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.30), w * 0.22, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.18, h * 0.58), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.58), w * 0.14, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}
