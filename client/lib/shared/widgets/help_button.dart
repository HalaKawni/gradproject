import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class HelpTip {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const HelpTip({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

// ── Public widget ─────────────────────────────────────────────────────────────

/// Floating `?` button — add as [Scaffold.floatingActionButton].
/// Tapping opens a bottom sheet with page-specific tips.
/// Optionally shows a "Replay Tour" option when [showReplayTour] is true.
class HelpButton extends StatefulWidget {
  final String pageTitle;
  final List<HelpTip> tips;
  final bool showReplayTour;
  final VoidCallback? onReplayHints;

  const HelpButton({
    super.key,
    required this.pageTitle,
    required this.tips,
    this.showReplayTour = false,
    this.onReplayHints,
  });

  @override
  State<HelpButton> createState() => _HelpButtonState();
}

class _HelpButtonState extends State<HelpButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _open() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _HelpSheet(
        pageTitle: widget.pageTitle,
        tips: widget.tips,
        showReplayTour: widget.showReplayTour,
        onReplayHints: widget.onReplayHints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: ScaleTransition(
        scale: _pulseAnim,
        child: GestureDetector(
          onTap: _open,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF44AADF), Color(0xFF2D3560)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF328CBD).withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  final String pageTitle;
  final List<HelpTip> tips;
  final bool showReplayTour;
  final VoidCallback? onReplayHints;

  const _HelpSheet({
    required this.pageTitle,
    required this.tips,
    required this.showReplayTour,
    this.onReplayHints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header card
            _SheetHeader(pageTitle: pageTitle),
            // Tips list
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Column(
                children: tips
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TipCard(tip: t),
                        ))
                    .toList(),
              ),
            ),
            // Replay tour option
            if (showReplayTour) _ReplayTourRow(onReplayHints: onReplayHints),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String pageTitle;
  const _SheetHeader({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF44AADF), Color(0xFF2D3560)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK TIPS',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pageTitle,
                  style: GoogleFonts.pacifico(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final HelpTip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tip.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tip.color.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(tip.icon, color: tip.color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3560),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayTourRow extends StatelessWidget {
  final VoidCallback? onReplayHints;
  const _ReplayTourRow({this.onReplayHints});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onReplayHints?.call();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.replay_rounded,
                  color: Color(0xFF328CBD), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replay Tips',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D3560),
                    ),
                  ),
                  Text(
                    'Show the hint bubbles again',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0BAC9), size: 22),
          ],
        ),
      ),
    );
  }
}
