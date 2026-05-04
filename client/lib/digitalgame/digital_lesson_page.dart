import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DigitalLessonPage extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const DigitalLessonPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final int number = lesson['number'] as int;
    final String title = lesson['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFADE8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4DD0C4),
        foregroundColor: Colors.white,
        title: Text(
          'Lesson #$number: $title',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.computer, size: 80, color: const Color(0xFF4DD0C4)),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lesson content coming soon!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0C4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'COMPLETE LESSON',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}