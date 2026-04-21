import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CodemonkeyJrPage extends StatelessWidget {
  const CodemonkeyJrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavbar(context),
            _buildHero(context),
            _buildTeachSection(),
            _buildFoundationsSection(),
            _buildFeaturesSection(),
            _buildHowItWorksSection(),
            _buildCTASection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── NAVBAR (reuse your existing style) ──
  Widget _buildNavbar(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'nameofweb',
              style: TextStyle(
                color: Color.fromARGB(255, 220, 202, 233),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _NavBtn(label: 'COURSES', onTap: () {}),
              const SizedBox(width: 28),
              _NavBtn(label: 'PLANS', onTap: () {}),
              const SizedBox(width: 28),
              _NavBtn(label: 'RESOURCES', onTap: () {}),
            ],
          ),
          Row(
            children: [
              _HoverNavButton(label: 'LOG IN', onPressed: () {}),
              _HoverNavButton(
                  label: 'SIGN UP', onPressed: () {}, filled: true),
            ],
          ),
        ],
      ),
    );
  }

  // ── HERO ──
  Widget _buildHero(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFD6EAF8),
        child: Stack(
          children: [
            // Sky background
            Container(
              height: 420,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD6EAF8),
                    Color(0xFFEBF5FB),
                  ],
                ),
              ),
            ),
            // Green ground
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D9C2A),
                ),
              ),
            ),
            // Darker green strip at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                color: const Color(0xFF4A7D1E),
              ),
            ),

            // ── LEFT TEXT ──
            Positioned(
              top: 60,
              left: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CODE JR.',
                    style: GoogleFonts.amaticSc(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2471A3),
                      height: 1.1,
                       shadows: const [
                      Shadow(
                        offset: Offset(3, 3),
                        color: Color.fromARGB(255, 255, 255, 255),
                        blurRadius: 0,
                      )
                    ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A BLOCK-BASED CODING GAME\nFOR PRE-K & K',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF34495E),
                      letterSpacing: 0.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // SIGN UP button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255,214, 185, 43),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255,252, 214, 60),
                          foregroundColor: const Color(0xFF3A2A00),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'SIGN UP NOW',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

           Positioned(
  top: 10,
  right: 200,
  child: Image.asset(
    'assets/images/Jr1.png',
    height: 340,
    fit: BoxFit.contain,
  ),
),
                  
          ],
        ),
      ),
    );
  }

  // ── TEACH SECTION ──
 // Replace _buildTeachSection with this:
Widget _buildTeachSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
    child: Column(
      children: [
        Text(
          'TEACH THE BASICS OF CODING',
          textAlign: TextAlign.center,
          style: GoogleFonts.amaticSc(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(180, 16),
          painter: _SquigglePainter(),
        ),
        const SizedBox(height: 28),
        Text(
          'In a world filled with captivating creatures and bright colors, your youngest students '
          'will join a monkey on a mission to collect bananas and unlock a treasure chest. '
          'All the while, they will explore and learn the basics of code as they use blocks '
          "to program a monkey's journey through the world.",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: const Color(0xFF555555),
            height: 1.8,
          ),
        ),
      ],
    ),
  );
}

// Add this new section:
Widget _buildFoundationsSection() {
  return ClipPath(
    clipper: _WaveBothClipper(),
    child: Container(
      width: double.infinity,
      color: const Color(0xFF4A90C4),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 80),
      child: Column(
        children: [
          // ── TITLE with circle around CODE ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'THE FOUNDATIONS OF ',
                style: GoogleFonts.amaticSc(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'CODE',
                  style: GoogleFonts.amaticSc(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),

          // ── CONTENT ROW ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLOCK-BASED CODING',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Block-based coding simplifies the process of computer programming. '
                      'Rather than writing out the code, students can drag and drop coding '
                      'blocks that represent code. Block-based coding uses interlocking, '
                      'graphical blocks so students don\'t need to write. The benefit of '
                      'using block-based coding is that it helps younger students learn the '
                      'basics of programming without having to worry about the messy syntax '
                      'that often accompanies code.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60),

              // Right: placeholder for kid photo
              Expanded(
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.child_care,
                          size: 60,
                          color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Photo coming soon',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // ── FEATURES ──
  Widget _buildFeaturesSection() {
    final features = [
      ('🧩', 'Block-Based Coding', 'Drag and drop colorful blocks to program — no typing required. Perfect for tiny hands and big imaginations.'),
      ('🎨', 'Vibrant World', 'A rich, colorful environment full of cute characters that keeps kids engaged and excited to learn.'),
      ('🏆', 'Collect & Unlock', 'Kids earn bananas and unlock treasure chests as they complete coding challenges and progress through levels.'),
      ('👶', 'Pre-K & Kindergarten', 'Designed specifically for ages 4–6. Simple, intuitive, and developmentally appropriate for young learners.'),
    ];

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 52),
      child: Column(
        children: [
          Text(
            'WHY KIDS LOVE IT',
            style: GoogleFonts.amaticSc(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: features.map((f) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE8F4E8)),
                  ),
                  child: Column(
                    children: [
                      Text(f.$1, style: const TextStyle(fontSize: 42)),
                      const SizedBox(height: 14),
                      Text(
                        f.$2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        f.$3,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF777777),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── HOW IT WORKS ──
  Widget _buildHowItWorksSection() {
    final steps = [
      ('1', const Color(0xFF3498DB), '🐒', 'Meet the Monkey', 'Your child joins a friendly monkey on an adventure through a colorful world.'),
      ('2', const Color(0xFF5D9C2A), '🧩', 'Place the Blocks', 'Drag colorful coding blocks to tell the monkey where to go and what to do.'),
      ('3', const Color(0xFFDDAA00), '🍌', 'Collect Bananas', 'Complete the path correctly to collect bananas and earn stars.'),
      ('4', const Color(0xFFE74C3C), '🏆', 'Unlock Treasure', 'Finish levels to unlock the treasure chest and celebrate success!'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 52),
      child: Column(
        children: [
          Text(
            'HOW IT WORKS',
            style: GoogleFonts.amaticSc(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          CustomPaint(
            size: const Size(140, 16),
            painter: _SquigglePainter(),
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.asMap().entries.map((entry) {
              final s = entry.value;
              final isLast = entry.key == steps.length - 1;
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: s.$2,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.$3,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.$4,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.$5,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: const Color(0xFF777777),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Icon(Icons.arrow_forward,
                            color: const Color(0xFFCCCCCC), size: 24),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── CTA ──
  Widget _buildCTASection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF5D9C2A),
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
      child: Column(
        children: [
          Text(
            'Ready to Start the Adventure? 🐒',
            textAlign: TextAlign.center,
            style: GoogleFonts.amaticSc(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Join thousands of kindergarteners already coding with CodeMonkey Jr.!",
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255,214, 185, 43),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255,252, 214, 60),
                  foregroundColor: const Color(0xFF3A2A00),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 52, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'SIGN UP FOR FREE',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FOOTER ──
  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF2A1505),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '🐒 nameofweb',
            style: GoogleFonts.pacifico(
              color: const Color(0xFFF5C518),
              fontSize: 16,
            ),
          ),
          Row(
            children: ['Privacy Policy', 'Terms of Use', 'Contact Us']
                .map((l) => Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        l,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFFE8D8B0),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── NAV TEXT BUTTON ──
class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── HOVER NAV BUTTON (same as login page) ──
class _HoverNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const _HoverNavButton(
      {required this.label, required this.onPressed, this.filled = false});

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
              color:
                  isYellow ? const Color(0xFF3A2A00) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── WAVE CLIPPER ──
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width * 0.25, size.height + 30,
      size.width * 0.5, size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 90,
      size.width, size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ── SQUIGGLE PAINTER ──
class _SquigglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5D9C2A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    double x = 0;
    while (x < size.width) {
      path.relativeCubicTo(10, -10, 10, 10, 20, 0);
      x += 20;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => false;
}

// ── ILLUSTRATION WIDGETS ──

class _IllustrationTree extends StatelessWidget {
  final Color trunkColor;
  const _IllustrationTree({required this.trunkColor});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.0,
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 14,
            height: 40,
            color: trunkColor,
          ),
        ],
      ),
    );
  }
}

class _IllustrationHouse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Roof (triangle via CustomPaint)
        CustomPaint(
          size: const Size(80, 40),
          painter: _TrianglePainter(color: const Color(0xFFE53935)),
        ),
        Container(
          width: 80,
          height: 60,
          color: const Color(0xFF90A4AE),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Eyes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Eye(),
                  _Eye(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Eye extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF37474F),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

class _IllustrationRainbowBird extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE53935),
            Color(0xFFFF9800),
            Color(0xFFFFEB3B),
            Color(0xFF4CAF50),
            Color(0xFF2196F3),
            Color(0xFF9C27B0),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: Text('🌈', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _IllustrationChest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lid
        Container(
          width: 70,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: const Color(0xFF5D2E0C), width: 2),
          ),
        ),
        // Body
        Container(
          width: 70,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFA0522D),
            border: Border.all(color: const Color(0xFF5D2E0C), width: 2),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFDDAA00),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B6914), width: 2),
              ),
            ),
          ),
        ),
        // Gold coins spilling
        const Text('✨', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _IllustrationMonkey extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('🐒', style: TextStyle(fontSize: 72));
  }
}

class _IllustrationUnicorn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('🦄', style: TextStyle(fontSize: 52));
  }
}

class _IllustrationFlower extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('🌸', style: TextStyle(fontSize: 28));
  }
}
class _WaveBothClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Wave top
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 30);
    path.quadraticBezierTo(size.width * 0.75, 60, size.width, 30);
    path.lineTo(size.width, size.height - 30);
    // Wave bottom
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(size.width * 0.25, size.height - 60, 0, size.height - 30);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveBothClipper old) => false;
}