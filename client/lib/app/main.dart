import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:client/app/navigation/app_router.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/features/auth/pages/login_page.dart';
import 'package:client/features/auth/pages/signup_page.dart';
import 'package:client/features/auth/pages/codejr.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppLanguage.instance.load();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: AppLanguage.instance.locale,
      useOnlyLangCode: true,
      child: const LanguageScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeMonkey',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const WelcomePage(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}

// ── Design tokens ──────────────────────────────────────────────────────────────
const _skyBlue = Color(0xFFBDD8EB);
const _navyText = Color(0xFF2D3560);
const _yellowBtn = Color(0xFFE8B400);
const _darkTeal = Color(0xFF2C5A78);
const _yellowBg = Color(0xFFEFBC45);

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
            // ── original hero (unchanged) ──
            _buildHero(),
            _buildCatchSection(),
            _buildFeatureCards(),
            _buildStatsBar(),
            // ── new sections below ──
            _buildAboutSection(),
            _buildWave(toBlue: true),
            _buildParentsSection(),
            _buildWave(toBlue: false),
            const _TypewriterSection(),
            _buildCurriculumSection(),
            _buildAwardsSection(),
            _buildFeaturesSection(),
            _buildAppsSection(),
            _buildNumbersSection(),
            _buildWave(toBlue: true),
            _buildAllInOneSection(),
            _buildWave(toBlue: false),
            _buildCTASection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Cloud wave divider ──────────────────────────────────────────────────────
  Widget _buildWave({required bool toBlue}) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: CustomPaint(painter: _CloudWavePainter(toBlue: toBlue)),
    );
  }

  // ── NAVBAR (original, unchanged) ────────────────────────────────────────────
  Widget _buildNavbar(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/sprites/logocodey.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              const _CourseDropdown(),
              const SizedBox(width: 28),
              Text(
                'nav.plans'.tr(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 28),
              Text(
                'nav.resources'.tr(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _HoverButton(label: 'nav.kids_signup'.tr(), onPressed: () {}),
              _HoverButton(
                label: 'nav.signup'.tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
                filled: true,
              ),
              _HoverButton(
                label: 'nav.login'.tr(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
              const _NavLanguageDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  // ── HERO (original, unchanged) ──────────────────────────────────────────────
  Widget _buildHero() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: SizedBox(
        width: double.infinity,
        height: 600,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background1.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(
                  255,
                  186,
                  236,
                  245,
                ).withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              top: 40,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  Text(
                    'home.title'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amaticSc(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 90,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          offset: Offset(3, 3),
                          color: Color.fromARGB(255, 50, 136, 189),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'home.subtitle'.tr(),
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
                      color: const Color.fromARGB(255, 195, 158, 222),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            220,
                            202,
                            233,
                          ),
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
                          'home.start_for_free'.tr(),
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
            Positioned(
              bottom: 0,
              left: 70,
              right: 0,
              child: Center(
                child: Image.asset('assets/images/elephant2.png', height: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ABOUT SECTION ────────────────────────────────────────────────────────────
  Widget _buildCatchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 52),
      child: Column(
        children: [
          Text(
            'home.catch_bananas'.tr(),
            style: GoogleFonts.pacifico(
              color: const Color(0xFFD4A017),
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      ('🎮', 'home.feature1_title'.tr(), 'home.feature1_desc'.tr()),
      ('🏆', 'home.feature2_title'.tr(), 'home.feature2_desc'.tr()),
      ('👩‍🏫', 'home.feature3_title'.tr(), 'home.feature3_desc'.tr()),
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

  Widget _buildStatsBar() {
    final stats = [
      ('70M+', 'stats.games_played'.tr()),
      ('5M+', 'stats.students'.tr()),
      ('150+', 'stats.countries'.tr()),
      ('500K+', 'stats.teachers'.tr()),
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

  Widget _buildCTASection() {
    return Container(
      color: const Color(0xFF6DB33F),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 32),
      child: Column(
        children: [
          Text(
            'home.cta_title'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.pacifico(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            'home.cta_subtitle'.tr(),
            style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
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
                  'home.kids_signup_btn'.tr(),
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
                  'home.teacher_signup_btn'.tr(),
                  style: GoogleFonts.pacifico(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 100),
      child: Column(
        children: [
          Center(
            child: Text(
              'Write Code.',
              style: GoogleFonts.pacifico(color: _darkTeal, fontSize: 30),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Codey is an AWARD-WINNING online platform that teaches kids real coding languages like Python and JavaScript. Children and teenagers learn block-based and text-based coding through an engaging game-like environment.',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF444444),
                        fontSize: 17,
                        height: 1.85,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Millions of Codey's students are now excited about coding! Codey does not require prior coding experience and is designed for home and family use.",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF444444),
                        fontSize: 17,
                        height: 1.85,
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF444444),
                          fontSize: 17,
                          height: 1.85,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Do you want to start coding now? ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF222222),
                            ),
                          ),
                          TextSpan(
                            text:
                                'Kids from 5–14 years old can learn block-coding, text-coding, and Python all while playing! Kids as young as 5 can start programming and build their own games. Try it today!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              SizedBox(
                width: 200,
                child: Image.asset(
                  'assets/images/Teaching_to_code.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PARENTS SECTION ──────────────────────────────────────────────────────────
  Widget _buildParentsSection() {
    return Container(
      color: _skyBlue,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 80),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset('assets/images/clouds.png', fit: BoxFit.cover),
            ),
          ),
          Center(
            child: SizedBox(
              width: 500,
              child: Column(
                children: [
                  Image.asset('assets/images/Parent-Image2.png', height: 220),
                  const SizedBox(height: 24),
                  Text(
                    'PARENTS',
                    style: GoogleFonts.amaticSc(
                      color: _navyText,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "With Codey's all-inclusive home plan, your child will learn to code in no time! Codey's courses teach text-based coding so kids learn to program like a real developer. This is coding made fun. No previous experience is needed!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: _navyText.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...[
                    '🐾  Track Child\'s Progress',
                    '🐾  Self-Paced',
                    '🐾  Educational Screen Time',
                  ].map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        f,
                        style: GoogleFonts.montserrat(
                          color: _navyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellowBtn,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'LEARN MORE',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CURRICULUM SECTION ───────────────────────────────────────────────────────
  Widget _buildCurriculumSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/course1.jpg',
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A fun coding course for kids',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    9,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 6 ? _navyText : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRICULUM',
                  style: GoogleFonts.amaticSc(
                    color: _navyText,
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Codey offers educational resources for students of different grades and experience levels. From Codey Jr. to advanced courses, students learn coding basics such as block-based and text-based coding. Kids also learn how to code in real programming languages like Python and JavaScript. Through Codey, kids will develop the necessary skills for the future while having fun!',
                  style: GoogleFonts.nunito(
                    color: _darkTeal,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellowBtn,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'SIGN UP NOW',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'free trial',
                    style: GoogleFonts.nunito(color: _darkTeal, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AWARDS SECTION ───────────────────────────────────────────────────────────
  Widget _buildAwardsSection() {
    return Container(
      color: _darkTeal,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Column(
        children: [
          Text(
            'Get your students coding in no time!',
            textAlign: TextAlign.center,
            style: GoogleFonts.amaticSc(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Codey is a fun and educational game-based environment where kids learn to code without any prior experience. After completing Codey\'s award-winning coding courses, kids will be able to navigate through the programming world with a sense of confidence and accomplishment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 48),
          // Best of STEM badge centered
          Image.asset('assets/images/BOS.png', height: 160),
        ],
      ),
    );
  }

  // ── FEATURES SECTION ─────────────────────────────────────────────────────────
  Widget _buildFeaturesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Column(
        children: [
          Text(
            'Kids will love learning to code\nwith Codey',
            textAlign: TextAlign.center,
            style: GoogleFonts.amaticSc(
              color: _navyText,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _featureCol(
                'assets/images/Full-courses-ready-to-go.png',
                'READY TO GO COURSES',
                "With Codey's support team, anyone can learn the basics of computer science and start coding today.",
              ),
              _featureCol(
                'assets/images/Real-coding-langauges.png',
                'REAL CODING LANGUAGES',
                "Codey's courses teach text-based coding so students learn to program like a real developer.",
              ),
              _featureCol(
                'assets/images/game-based.png',
                'GAME-BASED LEARNING',
                'Kids learn coding in an engaging and rewarding environment that utilizes gaming elements.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCol(String imagePath, String title, String desc) {
    return SizedBox(
      width: 230,
      child: Column(
        children: [
          Image.asset(imagePath, height: 110, width: 110),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: _navyText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── APPS SECTION ─────────────────────────────────────────────────────────────
  Widget _buildAppsSection() {
    return Container(
      color: _yellowBg,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Column(
        children: [
          Text(
            'APPS AND WEB-BASED COURSES',
            style: GoogleFonts.amaticSc(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Image.asset(
              'assets/images/codemonkey-devices-mobile.png',
              width: 700,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  // ── NUMBERS SECTION ───────────────────────────────────────────────────────────
  Widget _buildNumbersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Column(
        children: [
          Image.asset('assets/images/sprites/logocodey.png', height: 56),
          const SizedBox(height: 20),
          Text(
            "What sets Codey apart is its unique approach to teaching children programming right from day one, in an engaging, gamified manner. We believe that learning should be fun, and that's exactly what we've been doing.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: _navyText,
              fontSize: 15,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBlob(
                'LEVELS\nSOLVED',
                '570M+',
                const Color(0xFFF5E88A),
                const Color(0xFF7B6B10),
              ),
              _statBlob('KIDS', '45M+', const Color(0xFFADD8E6), _darkTeal),
              _statBlob(
                'PARENTS',
                '350K+',
                const Color(0xFFBFD9A0),
                const Color(0xFF3A6B20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlob(String label, String value, Color bg, Color fg) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 140,
          height: 120,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(64),
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.pacifico(color: fg, fontSize: 28),
            ),
          ),
        ),
      ],
    );
  }

  // ── ALL IN ONE SECTION ────────────────────────────────────────────────────────
  Widget _buildAllInOneSection() {
    return Container(
      color: _skyBlue,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset('assets/images/clouds.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              Text(
                'All you need in one place',
                style: GoogleFonts.amaticSc(
                  color: _navyText,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 48),
              // Progress Tracking row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRESS TRACKING',
                          style: GoogleFonts.montserrat(
                            color: _navyText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Equipped with student solutions, automatic grading, and progress management, Codey's dashboard allows you to effortlessly monitor your child's coding journey.",
                          style: GoogleFonts.nunito(
                            color: _navyText.withValues(alpha: 0.82),
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Image.asset(
                    'assets/images/classroom-management-2.png',
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Standards Alignment row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/standards-checklist1.png',
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 32),
                  Image.asset(
                    'assets/images/teacher_-page-2.png',
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STANDARDS ALIGNMENT',
                          style: GoogleFonts.montserrat(
                            color: _navyText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Codey places a high emphasis on content that aligns to today\'s standards. With online challenges and activities, students not only develop coding skills, but also computational thinking, collaboration, reasoning, and logic.',
                          style: GoogleFonts.nunito(
                            color: _navyText.withValues(alpha: 0.82),
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF1A2A3A),
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/sprites/logocodey.png', height: 34),
          Row(
            children:
                [
                      'footer.privacy_policy'.tr(),
                      'footer.terms_of_use'.tr(),
                      'footer.contact_us'.tr(),
                    ]
                    .map(
                      (l) => Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          l,
                          style: GoogleFonts.nunito(
                            color: Colors.white54,
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

// ── Typewriter Section ─────────────────────────────────────────────────────────
class _TypewriterSection extends StatefulWidget {
  const _TypewriterSection();
  @override
  State<_TypewriterSection> createState() => _TypewriterSectionState();
}

class _TypewriterSectionState extends State<_TypewriterSection> {
  static const _words = [
    'GAMIFIED',
    'FUN',
    'INTERACTIVE',
    'ENGAGING',
    'EXCITING',
  ];
  int _wordIdx = 0;
  int _charCount = 0;
  bool _deleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    int delay;
    if (!_deleting && _charCount == _words[_wordIdx].length) {
      delay = 1400;
    } else if (_deleting) {
      delay = 75;
    } else {
      delay = 110;
    }
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        if (!_deleting) {
          if (_charCount < _words[_wordIdx].length) {
            _charCount++;
          } else {
            _deleting = true;
          }
        } else {
          _charCount--;
          if (_charCount == 0) {
            _wordIdx = (_wordIdx + 1) % _words.length;
            _deleting = false;
          }
        }
      });
      _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _words[_wordIdx].substring(0, _charCount);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TEACH KIDS COURSES THAT ARE ',
            style: GoogleFonts.amaticSc(
              color: const Color(0xFF2D3560),
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            display,
            style: GoogleFonts.amaticSc(
              color: const Color(0xFF5BA033),
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(width: 2.5, height: 36, color: const Color(0xFF2D3560)),
        ],
      ),
    );
  }
}

// ── Cloud Wave Painter ─────────────────────────────────────────────────────────
class _CloudWavePainter extends CustomPainter {
  final bool toBlue;
  const _CloudWavePainter({required this.toBlue});

  static const _skyBlue = Color(0xFFBDD8EB);

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = toBlue ? Colors.white : _skyBlue;
    final fgColor = toBlue ? _skyBlue : Colors.white;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    const bumpCount = 14;
    final bumpW = size.width / bumpCount;
    const bumpH = 32.0;
    final baseY = size.height * 0.48;

    final path = Path();
    path.addRect(
      Rect.fromLTWH(
        0,
        baseY + bumpH * 0.5,
        size.width,
        size.height - baseY - bumpH * 0.5,
      ),
    );
    for (int i = 0; i < bumpCount; i++) {
      path.addOval(
        Rect.fromCenter(
          center: Offset((i + 0.5) * bumpW, baseY + bumpH * 0.5),
          width: bumpW + 2,
          height: bumpH * 2,
        ),
      );
    }
    canvas.drawPath(path, Paint()..color = fgColor);
  }

  @override
  bool shouldRepaint(_CloudWavePainter old) => old.toBlue != toBlue;
}

// ── Course Dropdown ────────────────────────────────────────────────────────────
class _CourseDropdown extends StatefulWidget {
  const _CourseDropdown();
  @override
  State<_CourseDropdown> createState() => _CourseDropdownState();
}

class _CourseDropdownState extends State<_CourseDropdown> {
  bool _hovered = false;
  List<String> get _courses => [
    'courses.all'.tr(),
    'courses.code_jr'.tr(),
    'courses.beaver'.tr(),
    'courses.dodo'.tr(),
    'courses.adventure'.tr(),
    'courses.game_builder'.tr(),
    'courses.banana'.tr(),
    'courses.chatbots'.tr(),
    'courses.digital'.tr(),
    'courses.data'.tr(),
    'courses.ai'.tr(),
    'courses.highschool'.tr(),
    'courses.monthly'.tr(),
  ];

  OverlayEntry? _overlayEntry;

  void _showDropdown(BuildContext context) {
    final courses = _courses;
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: offset.dy + size.height,
            left: offset.dx,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color.fromARGB(255, 195, 158, 222),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: courses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final course = entry.value;
                    final isHighSchool = idx == 11;
                    return InkWell(
                      onTap: () {
                        _hideDropdown();
                        if (idx == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CodemonkeyJrPage(),
                            ),
                          );
                        }
                      },
                      hoverColor: const Color(0xFFF0F4FF),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFEEEEEE),
                              width: idx == courses.length - 1 ? 0 : 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A3A6B),
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (isHighSchool)
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Color(0xFF1A3A6B),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _hovered = true);
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _hideDropdown() {
    _removeDropdownOverlay();
    if (!mounted) {
      return;
    }
    setState(() => _hovered = false);
  }

  @override
  void dispose() {
    _removeDropdownOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          _overlayEntry == null ? _showDropdown(context) : _hideDropdown(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _hovered
                  ? const Color.fromARGB(255, 195, 158, 222)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'nav.courses'.tr(),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: _hovered
                    ? const Color.fromARGB(255, 195, 158, 222)
                    : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: _hovered
                  ? const Color.fromARGB(255, 195, 158, 222)
                  : Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hover Button ───────────────────────────────────────────────────────────────
class _HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
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

// ── Language Dropdown ──────────────────────────────────────────────────────────
class _NavLanguageDropdown extends StatefulWidget {
  const _NavLanguageDropdown();
  @override
  State<_NavLanguageDropdown> createState() => _NavLanguageDropdownState();
}

class _NavLanguageDropdownState extends State<_NavLanguageDropdown> {
  String _selected = '🇺🇸 EN';
  bool _hovered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected = context.locale.languageCode == 'ar' ? '🇸🇦 AR' : '🇺🇸 EN';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        color: const Color(0xFF2A1505),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        offset: const Offset(0, 52),
        onSelected: (value) async {
          setState(() => _selected = value);
          if (value == '🇸🇦 AR') {
            await AppLanguage.instance.setLanguage('ar');
            if (context.mounted) {
              await context.setLocale(const Locale('ar'));
            }
          } else {
            await AppLanguage.instance.setLanguage('en');
            if (context.mounted) {
              await context.setLocale(const Locale('en'));
            }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: '🇺🇸 EN',
            child: Text(
              '🇺🇸 English',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFE8D8B0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          PopupMenuItem(
            value: '🇸🇦 AR',
            child: Text(
              '🇸🇦 العربية',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFE8D8B0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color.fromARGB(255, 220, 202, 233)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selected,
                style: GoogleFonts.montserrat(
                  color: _hovered
                      ? const Color(0xFF3A2A00)
                      : const Color(0xFFE8D8B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: _hovered
                    ? const Color(0xFF3A2A00)
                    : const Color(0xFFE8D8B0),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Curve Clipper (used by hero) ────────────────────────────────────────
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 60,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BottomCurveClipper oldClipper) => false;
}
