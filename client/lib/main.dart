import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'signup_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeMonkey',
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavbar(context),
            _buildHero(),
            _buildCatchSection(),
            _buildFeatureCards(),
            _buildStatsBar(),
            _buildCTASection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── NAVBAR ──
 // ── NAVBAR ──
Widget _buildNavbar(BuildContext context) {
  return Container(
    //color: const Color(0xFF3B2008),
    color: const Color.fromARGB(255,50, 136, 189),
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Text(
          'nameofweb',
          style: const TextStyle(
            fontFamily: 'Arial',
            color: Color.fromARGB(255,220, 202, 233),
            //color: Color.fromARGB(255,219, 161, 157),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Nav links
        Row(
          children: [
            const _CourseDropdown(),
            const SizedBox(width: 28),
           Text('PLANS',
           style: GoogleFonts.montserrat(
           color: const Color.fromARGB(255, 255, 255, 255),
           fontSize: 14,
          fontWeight: FontWeight.w500,
  ),
),
            const SizedBox(width: 28),
            Text(
              'RESOURCES',
              style: GoogleFonts.montserrat(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Buttons
        Row(
          children: [
    _HoverButton(label: 'KIDS SIGN UP', onPressed: () {}),
   _HoverButton(
  label: 'SIGN UP',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  },
  filled: true,
),
    _HoverButton(
  label: 'LOG IN',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  },
),
    _NavLanguageDropdown(),
  ],
  
                
              ),

          ],
        ),
  );
}


Widget _buildHero() {
  return ClipPath(
    clipper: _BottomCurveClipper(),
    child: SizedBox(
      width: double.infinity,
      height: 600,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── BACKGROUND IMAGE ──
     
          Positioned.fill(
           
            child: Image.asset(
              'assets/images/background1.jpg',
              fit: BoxFit.cover,

            ),
            
          ),
       Positioned.fill(
      child: Container(
        //color: const Color(0xFF6DB33F).withOpacity(0.55)
        color: const Color.fromARGB(255, 186, 236, 245).withOpacity(0.22),
      ),
    ),
          // ── TEXT + BUTTON ──
          Positioned(
            top: 40,
            left: 32,
            right: 32,
            child: Column(
              children: [
                Text(
                  'CODING FOR KIDS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amaticSc(
                    //color: const Color.fromARGB(255, 153, 206, 138),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 90,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(
                        offset: Offset(3, 3),
                        color: Color.fromARGB(255,50, 136, 189),
                        blurRadius: 0,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'INTRODUCING PROGRAMMING GAMES FOR THE NEXT GENERATION',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),
                 
                 DecoratedBox(
  decoration: BoxDecoration(
    //color: const Color.fromARGB(255,219, 161, 157),
        color: const Color.fromARGB(255,195, 158, 222),

    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255,220, 202, 233),
               // backgroundColor: const Color.fromARGB(255, 237, 209, 205),

        foregroundColor: const Color(0xFF3A2A00),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 60,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(
        'START FOR FREE',
        style: GoogleFonts.montserrat(
          fontSize: 16,
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

          // ── MONKEY AT BOTTOM ──
          Positioned(
            bottom: 0,
            left: 70,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/elephant.png',
                height: 150,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  // ── CATCH SECTION ──
  Widget _buildCatchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 52),
      child: Column(
        children: [
          Text(
            'Catch Bananas.',
            style: GoogleFonts.pacifico(
              color: const Color(0xFFD4A017),
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          // Text(
          //   'CodeMonkey is an award-winning online platform that teaches kids real '
          //   'coding languages. Children and teenagers learn to code through fun, '
          //   'engaging games and challenges — no experience needed!',
          //   textAlign: TextAlign.center,
          //   style: GoogleFonts.nunito(
          //     color: const Color(0xFF555555),
          //     fontSize: 15,
          //     height: 1.7,
          //   ),
          // ),
        ],
      ),
    );
  }

  // ── FEATURE CARDS ──
  Widget _buildFeatureCards() {
    final features = [
      (
        '🎮',
        'Game-Based Learning',
        'Kids learn to code by solving fun challenges and building their own games.'
      ),
      (
        '🏆',
        'Real Coding Languages',
        'Learn Python, CoffeeScript and more — real languages used by professionals.'
      ),
      (
        '👩‍🏫',
        'Teacher & Parent Tools',
        'Track progress, assign challenges, and manage classrooms with ease.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
      child: Row(
        children: features
            .map(
              (f) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0DDD5)),
                  ),
                  child: Column(
                    children: [
                      Text(f.$1, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        f.$2,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pacifico(
                          color: const Color(0xFF3B2008),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.$3,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF777777),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── STATS BAR ──
  Widget _buildStatsBar() {
    final stats = [
      ('70M+', 'Games Played'),
      ('5M+', 'Students'),
      ('150+', 'Countries'),
      ('500K+', 'Teachers'),
    ];

    return Container(
      color: const Color(0xFF3B2008),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats
            .map(
              (s) => Column(
                children: [
                  Text(
                    s.$1,
                    style: GoogleFonts.pacifico(
                      color: const Color.fromARGB(255, 164, 219, 168),
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.$2,
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFE8D8B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  // ── CTA SECTION ──
  Widget _buildCTASection() {
    return Container(
      color: const Color(0xFF6DB33F),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
      child: Column(
        children: [
          Text(
            'Ready to Start Coding? 🚀',
            textAlign: TextAlign.center,
            style: GoogleFonts.pacifico(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Join millions of kids worldwide — it's completely free!",
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5C518),
                  foregroundColor: const Color(0xFF3A2A00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Kids Sign Up',
                  style: GoogleFonts.pacifico(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Teacher Sign Up',
                  style: GoogleFonts.pacifico(fontSize: 14),
                ),
              ),
            ],
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
            '🐒 CodeMonkey',
            style: GoogleFonts.pacifico(
              color: const Color(0xFFF5C518),
              fontSize: 16,
            ),
          ),
          Row(
            children: ['Privacy Policy', 'Terms of Use', 'Contact Us']
                .map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      l,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFFE8D8B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── COURSES DROPDOWN WIDGET ──
class _CourseDropdown extends StatelessWidget {
  const _CourseDropdown();

  static const courses = [
    '🎮 Coding for Kids',
    '🐍 Python Course',
    '🌐 Web Development',
    '🕹️ Game Design',
    '📱 Mobile Apps',
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF2A1505),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      offset: const Offset(0, 40),
      onSelected: (value) {},
      itemBuilder: (_) => courses
          .map(
            (c) => PopupMenuItem(
              value: c,
              child: Text(
                c,
                style: GoogleFonts.pacifico(
                  color: const Color(0xFFE8D8B0),
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
      child: Row(
        children: [
          Text(
            'COURSES',
            style: GoogleFonts.montserrat(fontSize: 14, color: const Color.fromARGB(255, 255, 255, 255),fontWeight: FontWeight.w500),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFE8D8B0),
            size: 16,
          ),
        ],
      ),
    );
  }
}
////////////////////////////
class _LanguageDropdown extends StatefulWidget {
  const _LanguageDropdown();

  @override
  State<_LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<_LanguageDropdown> {
  String _selected = '🇺🇸 EN';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF2A1505),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 40),
      onSelected: (value) => setState(() => _selected = value),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: '🇺🇸 EN',
          child: Text('🇺🇸 English',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFE8D8B0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ),
        PopupMenuItem(
          value: '🇸🇦 AR',
          child: Text('🇸🇦 العربية',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFE8D8B0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
        ),
      ],
      child: Row(
        children: [
          Text(
            _selected,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFE8D8B0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFFE8D8B0), size: 16),
        ],
      ),
    );
  }
}


////////////
class _HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled; // for SIGN UP yellow background by default

  const _HoverButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
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
            color: isYellow ? const Color.fromARGB(255, 220, 202, 233) : Colors.transparent,
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
        ) ,
      ),
    );
  }
}

class _NavLanguageDropdown extends StatefulWidget {
  const _NavLanguageDropdown();

  @override
  State<_NavLanguageDropdown> createState() => _NavLanguageDropdownState();
}

class _NavLanguageDropdownState extends State<_NavLanguageDropdown> {
  String _selected = '🇺🇸 EN';
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        color: const Color(0xFF2A1505),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        offset: const Offset(0, 52),
        onSelected: (value) => setState(() => _selected = value),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: '🇺🇸 EN',
            child: Text('🇺🇸 English',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFE8D8B0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ),
          PopupMenuItem(
            value: '🇸🇦 AR',
            child: Text('🇸🇦 العربية',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFE8D8B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _hovered ? const Color.fromARGB(255, 220, 202, 233) : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selected,
                style: GoogleFonts.montserrat(
                  color: _hovered ? const Color(0xFF3A2A00) : const Color(0xFFE8D8B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: _hovered ? const Color(0xFF3A2A00) : const Color(0xFFE8D8B0),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
////////////////////
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2, size.height + 60, // control point (bulge down)
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BottomCurveClipper oldClipper) => false;
}