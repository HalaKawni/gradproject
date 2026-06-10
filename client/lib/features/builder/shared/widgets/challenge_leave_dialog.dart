import 'package:flutter/material.dart';

typedef ChallengeRatingSubmitter = Future<String?> Function(int rating);

Future<bool> showChallengeLeaveDialog({
  required BuildContext context,
  required String title,
  required ChallengeRatingSubmitter onSubmitRating,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _ChallengeLeaveDialog(
        title: title,
        onSubmitRating: onSubmitRating,
      );
    },
  );

  return result == true;
}

class _ChallengeLeaveDialog extends StatefulWidget {
  const _ChallengeLeaveDialog({
    required this.title,
    required this.onSubmitRating,
  });

  final String title;
  final ChallengeRatingSubmitter onSubmitRating;

  @override
  State<_ChallengeLeaveDialog> createState() => _ChallengeLeaveDialogState();
}

class _ChallengeLeaveDialogState extends State<_ChallengeLeaveDialog> {
  int _selectedRating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRatingAndLeave() async {
    if (_selectedRating == 0 || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final errorMessage = await widget.onSubmitRating(_selectedRating);
    if (!mounted) {
      return;
    }

    if (errorMessage != null) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Leave Challenge?',
        style: TextStyle(
          color: Color(0xFF243A1B),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before you go, rate "${widget.title}" to help other players find great challenges.',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: List<Widget>.generate(5, (index) {
                final value = index + 1;
                final isSelected = value <= _selectedRating;
                return IconButton.filledTonal(
                  tooltip: '$value star${value == 1 ? '' : 's'}',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _selectedRating = value;
                          });
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: isSelected
                        ? const Color(0xFFFFE082)
                        : const Color(0xFFF1F5F9),
                    foregroundColor: isSelected
                        ? const Color(0xFFF57F17)
                        : const Color(0xFF94A3B8),
                  ),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 28,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Keep Playing'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
        FilledButton(
          onPressed: _selectedRating == 0 || _isSubmitting
              ? null
              : _submitRatingAndLeave,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF66B64A),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Rate & Leave'),
        ),
      ],
    );
  }
}
