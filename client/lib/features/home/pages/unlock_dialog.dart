import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnlockDialog extends StatefulWidget {
  const UnlockDialog({super.key});

  @override
  State<UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<UnlockDialog> {
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: SizedBox(
        width: 780,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── FULL BACKGROUND IMAGE ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/dashboard.jpg',
                width: double.infinity,
               fit: BoxFit.fitWidth,
              ),
            ),

            // ── TITLE + SUBTITLE on top of image 
            // ── CLOSE BUTTON ──
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.black54),
                ),
              ),
            ),

            // ── BOTTOM FORM BOX ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child:Container(
  margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
decoration: BoxDecoration(
  color: const Color(0xFF4A6741).withOpacity(0.75),
  borderRadius: BorderRadius.circular(4),
),
padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask your parent for access',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromARGB(255, 240, 206, 56),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── EMAIL + REQUEST ──
                    if (!_submitted) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: const Color(0xFF333333),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter parent's email",
                                hintStyle: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: const Color(0xFF999999),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_emailController.text.isNotEmpty) {
                                    setState(() => _submitted = true);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB300),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'REQUEST',
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
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7ED957).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF7ED957), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF7ED957), size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Request sent to ${_emailController.text}!',
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF7ED957),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── FEATURES LIST ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FeatureItem('Block-based Coding Courses'),
                              const SizedBox(height: 8),
                              _FeatureItem('Text-based Coding Courses'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FeatureItem('Game Creation Courses'),
                              const SizedBox(height: 8),
                              _FeatureItem('Python Courses'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB300),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}