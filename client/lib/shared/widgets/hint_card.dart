import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/onboarding_service.dart';

enum ArrowDirection { up, down, left, right }

/// A coach-mark callout bubble.
///
/// Renders as [SizedBox.shrink] in the layout — the visible speech bubble
/// is injected into the [Overlay] and positioned right next to [targetKey].
/// Arrow direction tells which way the bubble's pointer points (toward the target).
///
/// If [targetKey] is null the bubble appears bottom-center above the FAB.
class HintCard extends StatefulWidget {
  final String hintKey;
  final String? userScope;
  final GlobalKey? targetKey;
  final ArrowDirection arrowDirection;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final VoidCallback? onDismissed;

  const HintCard({
    super.key,
    required this.hintKey,
    this.userScope,
    this.targetKey,
    this.arrowDirection = ArrowDirection.down,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.onDismissed,
  });

  @override
  State<HintCard> createState() => _HintCardState();
}

class _HintCardState extends State<HintCard>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted) return;
    final dismissed =
        await OnboardingService.isHintDismissed(
          widget.hintKey,
          widget.userScope,
        );
    if (!mounted || dismissed) return;
    _show();
  }

  void _show() {
    _entry = OverlayEntry(builder: (_) => _overlay());
    Overlay.of(context).insert(_entry!);
    _ctrl.forward();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    _entry?.remove();
    _entry = null;
    await OnboardingService.dismissHint(widget.hintKey, widget.userScope);
    widget.onDismissed?.call();
  }

  // ── Compute target rect ─────────────────────────────────────────────────────

  Rect _targetRect(Size screen) {
    final key = widget.targetKey;
    if (key != null) {
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          return box.localToGlobal(Offset.zero) & box.size;
        }
      }
    }
    // Fallback: position above FAB (bottom-center)
    return Rect.fromLTWH(
      screen.width / 2 - 20,
      screen.height - 160,
      40,
      40,
    );
  }

  // ── Build overlay ───────────────────────────────────────────────────────────

  Widget _overlay() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final screen = MediaQuery.of(ctx).size;
        final target = _targetRect(screen);
        const bw = 260.0; // bubble width
        const bh = 148.0; // estimated bubble height
        const arrow = 12.0; // arrow height
        const gap = 6.0;

        double left, top;
        Offset slideBegin;

        switch (widget.arrowDirection) {
          case ArrowDirection.down:
            top = target.top - bh - arrow - gap;
            left = (target.center.dx - bw / 2)
                .clamp(10.0, screen.width - bw - 10);
            slideBegin = const Offset(0, 0.15);
            break;
          case ArrowDirection.up:
            top = target.bottom + arrow + gap;
            left = (target.center.dx - bw / 2)
                .clamp(10.0, screen.width - bw - 10);
            slideBegin = const Offset(0, -0.15);
            break;
          case ArrowDirection.left:
            left = target.right + arrow + gap;
            top = (target.center.dy - bh / 2)
                .clamp(10.0, screen.height - bh - 10);
            slideBegin = const Offset(-0.15, 0);
            break;
          case ArrowDirection.right:
            left = target.left - bw - arrow - gap;
            top = (target.center.dy - bh / 2)
                .clamp(10.0, screen.height - bh - 10);
            slideBegin = const Offset(0.15, 0);
            break;
        }

        top = top.clamp(10.0, screen.height - bh - 10);

        // Arrow offset along the bubble edge, clamped to stay inside bubble
        double arrowOffset;
        switch (widget.arrowDirection) {
          case ArrowDirection.down:
          case ArrowDirection.up:
            arrowOffset = (target.center.dx - left - 8)
                .clamp(16.0, bw - 32);
            break;
          case ArrowDirection.left:
          case ArrowDirection.right:
            arrowOffset = (target.center.dy - top - 8)
                .clamp(16.0, bh - 32);
            break;
        }

        final fade =
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
        final slide = Tween<Offset>(begin: slideBegin, end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

        return Positioned(
          left: left,
          top: top,
          width: bw,
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: _Bubble(
                  icon: widget.icon,
                  color: widget.color,
                  title: widget.title,
                  message: widget.message,
                  arrowDir: widget.arrowDirection,
                  arrowOffset: arrowOffset,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Bubble widget ─────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final ArrowDirection arrowDir;
  final double arrowOffset;
  final VoidCallback onDismiss;

  const _Bubble({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.arrowDir,
    required this.arrowOffset,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Arrow ──────────────────────────────────────────────────────────
        _ArrowWidget(
          direction: arrowDir,
          offset: arrowOffset,
          color: color,
        ),
        // ── Main card ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored accent bar at top
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.45)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2D3560),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              message,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ✕ button
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // "Got it" button
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withValues(alpha: 0.22), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Got it  ✓',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Arrow widget ──────────────────────────────────────────────────────────────

class _ArrowWidget extends StatelessWidget {
  final ArrowDirection direction;
  final double offset;
  final Color color;

  const _ArrowWidget({
    required this.direction,
    required this.offset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const aw = 16.0; // arrow base width
    const ah = 11.0; // arrow height

    double? l, t, r, b;
    double paintW, paintH;

    switch (direction) {
      case ArrowDirection.down:
        l = offset;
        b = -ah;
        paintW = aw;
        paintH = ah;
        break;
      case ArrowDirection.up:
        l = offset;
        t = -ah;
        paintW = aw;
        paintH = ah;
        break;
      case ArrowDirection.left:
        l = -ah;
        t = offset;
        paintW = ah;
        paintH = aw;
        break;
      case ArrowDirection.right:
        r = -ah;
        t = offset;
        paintW = ah;
        paintH = aw;
        break;
    }

    return Positioned(
      left: l,
      top: t,
      right: r,
      bottom: b,
      child: CustomPaint(
        size: Size(paintW, paintH),
        painter: _ArrowPainter(direction: direction, color: color),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final ArrowDirection direction;
  final Color color;
  const _ArrowPainter({required this.direction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path();
    final borderPath = Path();

    switch (direction) {
      case ArrowDirection.down:
        path
          ..moveTo(1, 0)
          ..lineTo(size.width - 1, 0)
          ..lineTo(size.width / 2, size.height);
        borderPath
          ..moveTo(0, -1)
          ..lineTo(size.width, -1)
          ..lineTo(size.width / 2, size.height + 1);
        break;
      case ArrowDirection.up:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width - 1, size.height)
          ..lineTo(1, size.height);
        borderPath
          ..moveTo(size.width / 2, -1)
          ..lineTo(size.width + 1, size.height)
          ..lineTo(-1, size.height);
        break;
      case ArrowDirection.left:
        path
          ..moveTo(size.width, 1)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height - 1);
        borderPath
          ..moveTo(size.width + 1, 0)
          ..lineTo(-1, size.height / 2)
          ..lineTo(size.width + 1, size.height);
        break;
      case ArrowDirection.right:
        path
          ..moveTo(0, 1)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height - 1);
        borderPath
          ..moveTo(-1, 0)
          ..lineTo(size.width + 1, size.height / 2)
          ..lineTo(-1, size.height);
        break;
    }

    path.close();
    borderPath.close();
    canvas.drawPath(borderPath, borderPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.direction != direction || old.color != color;
}
