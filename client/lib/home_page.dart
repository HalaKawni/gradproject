import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_account_page.dart';
import 'sorry_page.dart';

class HomeAgePage extends StatefulWidget {
  const HomeAgePage({super.key});

  @override
  State<HomeAgePage> createState() => _HomeAgePageState();
}

class _HomeAgePageState extends State<HomeAgePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;
  final _ageController = TextEditingController();
  int _age = 0;
  bool _showError = false;

  // Monkey height based on age (min age 1 = small, max age 18 = tall)
double get _monkeyHeight {
  if (_age <= 0) return 100 + (10 - 1) * (300 / 17); // default = age 10 size
  final clamped = _age.clamp(1, 18);
  return 100 + (clamped - 1) * (300 / 17);
}

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
    _ageController.dispose();
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
                        'HOW OLD ARE YOU?',
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

                      // ── MONKEY + INPUT ROW ──
                      SizedBox(
                        height: 400,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // ── LEFT: vertical line + monkey ──
                            SizedBox(
                              width: 260,
                              child: Stack(
                                   clipBehavior: Clip.none,
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // vertical dashed line
                                  Positioned(
                                    left: 128,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 1.5,
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      child: CustomPaint(
                                        painter: _DashedLinePainter(),
                                      ),
                                    ),
                                  ),
                                  // monkey — animates height
                                  Positioned(
                                    bottom: 0,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeOut,
                                      height: _monkeyHeight,
                                      child: Image.asset(
                                        'assets/images/age.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 40),

                            // ── RIGHT: age input + next ──
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Age input with up/down arrows
                                Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFCCCCCC),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _ageController,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.nunito(
                                            fontSize: 16,
                                            color: const Color(0xFF333333),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Your age',
                                            hintStyle: GoogleFonts.nunito(
                                              fontSize: 14,
                                              color: const Color(0xFF999999),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 14),
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              _age = int.tryParse(val) ?? 0;
                                              _showError = false;
                                            });
                                          },
                                        ),
                                      ),
                                      // up/down buttons
                                      Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (_age < 18) {
                                                  _age++;
                                                  _ageController.text =
                                                      _age.toString();
                                                  _showError = false;
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                      color: Color(0xFFCCCCCC)),
                                                  bottom: BorderSide(
                                                      color: Color(0xFFCCCCCC)),
                                                ),
                                              ),
                                              child: const Icon(
                                                  Icons.keyboard_arrow_up,
                                                  size: 16,
                                                  color: Color(0xFF666666)),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (_age > 1) {
                                                  _age--;
                                                  _ageController.text =
                                                      _age.toString();
                                                  _showError = false;
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                      color: Color(0xFFCCCCCC)),
                                                ),
                                              ),
                                              child: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: Color(0xFF666666)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (_showError) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'This field is required',
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFFE53935),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // NEXT button
                                Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255,195, 158, 222),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_ageController.text.isEmpty || _age <= 0) {
    setState(() => _showError = true);
  } else if (_age > 12) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentAccountPage()),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SorryPage()),
    );
  }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color.fromARGB(255,220, 202, 233),
                                        foregroundColor:
                                            const Color(0xFF3A2A00),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'NEXT',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

// ── DASHED LINE PAINTER ──
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double y = 0;
    const dashHeight = 8.0;
    const gapHeight = 6.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
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