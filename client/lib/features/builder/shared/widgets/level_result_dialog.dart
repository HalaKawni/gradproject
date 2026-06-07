import 'package:flutter/material.dart';

Future<void> showLevelResultDialog({
  required BuildContext context,
  required bool success,
  required int score,
  required int totalScore,
  required int stars,
  required VoidCallback onPlayAgain,
  VoidCallback? onNextLevel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final accent = success
          ? const Color(0xFF39B54A)
          : const Color(0xFFFF8A3D);
      final title = success ? 'Great job!' : 'Try again!';
      final subtitle = success
          ? 'You finished the level.'
          : 'You can replay it and collect more points.';
      final canGoNext = success && onNextLevel != null;
      final showDone = success && onNextLevel == null;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF3),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success
                          ? Icons.celebration_rounded
                          : Icons.refresh_rounded,
                      color: accent,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF213547),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(3, (index) {
                      final filled = index < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled
                              ? const Color(0xFFFFC400)
                              : Colors.blueGrey.shade200,
                          size: 44,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFFE08A)),
                    ),
                    child: Text(
                      'Score: $score / $totalScore',
                      style: const TextStyle(
                        color: Color(0xFF213547),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onPlayAgain();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(150, 48),
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(
                            color: Color(0xFF8EC5FF),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text(
                          'Play again',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: canGoNext
                            ? () {
                                Navigator.of(dialogContext).pop();
                                onNextLevel();
                              }
                            : showDone
                            ? () => Navigator.of(dialogContext).pop()
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(150, 48),
                          backgroundColor: const Color(0xFF39B54A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: Colors.blueGrey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: Icon(
                          showDone
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          showDone ? 'Done' : 'Next',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
