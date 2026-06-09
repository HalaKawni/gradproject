import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/onboarding_service.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _WizardStep {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final String title;
  final String description;

  const _WizardStep({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.description,
  });
}

const _kSteps = [
  _WizardStep(
    icon: Icons.school_rounded,
    iconColor: Color(0xFF328CBD),
    gradient: [Color(0xFF328CBD), Color(0xFF2D3560)],
    title: 'Welcome to Your\nLearning Hub!',
    description:
        "You're about to start an amazing coding journey. Let's take a quick tour so you know exactly where everything is!",
  ),
  _WizardStep(
    icon: Icons.auto_stories_rounded,
    iconColor: Color(0xFF43A047),
    gradient: [Color(0xFF56C96D), Color(0xFF1B7A3A)],
    title: 'New Here? Start\nwith Beginner Courses',
    description:
        "Head to the Courses tab and filter by 'Beginner' level. These are designed for students who have never coded before — perfect starting point!",
  ),
  _WizardStep(
    icon: Icons.tune_rounded,
    iconColor: Color(0xFFE8B400),
    gradient: [Color(0xFFFFCC02), Color(0xFFE07B00)],
    title: 'Filter to Find\nExactly What You Need',
    description:
        "Use the filter options to search by level, topic, or category. Whether you want easy challenges or specific subjects — filters make it fast!",
  ),
  _WizardStep(
    icon: Icons.sports_esports_rounded,
    iconColor: Color(0xFF7C4DFF),
    gradient: [Color(0xFF9C6FFF), Color(0xFF4A1FA8)],
    title: 'Build Your Own\nGame!',
    description:
        "Go to My Creations to design and build your own games. Choose from slides, front view, top view, or scratch style. Be a game creator!",
  ),
  _WizardStep(
    icon: Icons.people_alt_rounded,
    iconColor: Color(0xFF00ACC1),
    gradient: [Color(0xFF26C6DA), Color(0xFF00607A)],
    title: 'Join Your\nClassroom',
    description:
        "Got a code from your teacher? Open the Classroom section, enter the code, and instantly access your assigned lessons and activities.",
  ),
];

// ── Public API ─────────────────────────────────────────────────────────────────

class WelcomeWizard extends StatefulWidget {
  const WelcomeWizard({super.key});

  /// Shows the wizard the first time only, then never again.
  static Future<void> showIfNeeded(BuildContext context) async {
    final shown = await OnboardingService.hasShownWelcome();
    if (shown || !context.mounted) return;
    await OnboardingService.markWelcomeShown();
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const WelcomeWizard(),
    );
  }

  /// Force-shows the wizard regardless of visit history (e.g. "Replay Tour" button).
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const WelcomeWizard(),
    );
  }

  @override
  State<WelcomeWizard> createState() => _WelcomeWizardState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _WelcomeWizardState extends State<WelcomeWizard>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  bool _forward = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page < _kSteps.length - 1) {
      setState(() {
        _forward = true;
        _page++;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_page > 0) {
      setState(() {
        _forward = false;
        _page--;
      });
    }
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final step = _kSteps[_page];
    final isLast = _page == _kSteps.length - 1;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(step: step, page: _page),
                _Content(step: step, page: _page, forward: _forward),
                _Footer(
                  page: _page,
                  total: _kSteps.length,
                  isLast: isLast,
                  onNext: _goNext,
                  onPrev: _goPrev,
                  onSkip: _skip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _WizardStep step;
  final int page;
  const _Header({required this.step, required this.page});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 168,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: step.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative background circles
          Positioned(
            top: -30,
            right: -30,
            child: _Circle(size: 130, opacity: 0.12),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: _Circle(size: 110, opacity: 0.08),
          ),
          Positioned(
            top: 12,
            left: 30,
            child: _Circle(size: 50, opacity: 0.10),
          ),
          Positioned(
            top: 8,
            right: 60,
            child: _Circle(size: 28, opacity: 0.15),
          ),
          // Centered icon
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Container(
                key: ValueKey(page),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(step.icon, color: step.iconColor, size: 42),
              ),
            ),
          ),
          // Step label top-left
          Positioned(
            top: 14,
            left: 18,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Step ${page + 1} of ${_kSteps.length}',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  final _WizardStep step;
  final int page;
  final bool forward;
  const _Content(
      {required this.step, required this.page, required this.forward});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(forward ? 0.08 : -0.08, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: SizedBox(
        key: ValueKey(page),
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.pacifico(
                  fontSize: 21,
                  color: const Color(0xFF2D3560),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  color: const Color(0xFF6B7280),
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;

  const _Footer({
    required this.page,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF328CBD)
                      : const Color(0xFFDDE3EA),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Navigation row
          Row(
            children: [
              // Back button (hidden on first step)
              if (page > 0)
                _OutlineBtn(label: 'Back', onTap: onPrev)
              else
                const SizedBox(width: 72),
              const SizedBox(width: 12),
              // Next / Get Started button
              Expanded(
                child: _GradientBtn(
                  label: isLast ? '🎉  Get Started!' : 'Next',
                  onTap: onNext,
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'Skip Tour',
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  color: const Color(0xFFB0BAC9),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFB0BAC9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFCC02), Color(0xFFFF8C00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8B400).withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDE3EA), width: 1.8),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
