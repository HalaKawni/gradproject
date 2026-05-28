import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lesson_editor_page.dart';

// Flat entry: one canvas slide with its lesson context
class _SlideEntry {
  final int lessonNumber;
  final String lessonTitle;
  final int slideIndex;
  final int totalInLesson;
  final Map<String, dynamic> slideData;
  const _SlideEntry({
    required this.lessonNumber,
    required this.lessonTitle,
    required this.slideIndex,
    required this.totalInLesson,
    required this.slideData,
  });
}

class CustomCourseViewerPage extends StatefulWidget {
  final String courseTitle;
  final List<Map<String, dynamic>> lessons;

  const CustomCourseViewerPage({
    super.key,
    required this.courseTitle,
    required this.lessons,
  });

  @override
  State<CustomCourseViewerPage> createState() => _CustomCourseViewerPageState();
}

class _CustomCourseViewerPageState extends State<CustomCourseViewerPage> {
  late final List<_SlideEntry> _all;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _all = [];
    for (final lesson in widget.lessons) {
      final num = lesson['number'] as int? ?? 0;
      final title = lesson['title'] as String? ?? '';
      final slides = (lesson['slides'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (slides.isEmpty) {
        // Lesson exists but no slides yet — show placeholder entry
        _all.add(_SlideEntry(
          lessonNumber: num,
          lessonTitle: title,
          slideIndex: 0,
          totalInLesson: 0,
          slideData: {},
        ));
      } else {
        for (int i = 0; i < slides.length; i++) {
          _all.add(_SlideEntry(
            lessonNumber: num,
            lessonTitle: title,
            slideIndex: i,
            totalInLesson: slides.length,
            slideData: slides[i],
          ));
        }
      }
    }
    if (_all.isEmpty) {
      _all.add(_SlideEntry(
        lessonNumber: 1, lessonTitle: '', slideIndex: 0,
        totalInLesson: 0, slideData: {},
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _all[_current];
    final total = _all.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildTopBar(entry, total),
          Expanded(child: _buildSlideView(entry)),
          _buildBottomBar(total),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────
  Widget _buildTopBar(_SlideEntry entry, int total) {
    final slideLabel = entry.totalInLesson > 1
        ? 'Slide ${entry.slideIndex + 1}/${entry.totalInLesson}'
        : '';
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson ${entry.lessonNumber}: ${entry.lessonTitle}',
                  style: GoogleFonts.montserrat(
                    color: const Color.fromARGB(255, 202, 97, 128),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (slideLabel.isNotEmpty)
                  Text(slideLabel,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Progress dots — capped at 12 to avoid overflow
          if (total <= 12)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, _buildDot),
            )
          else
            Text('$_current/$total',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDot(int i) {
    final done = i < _current;
    final current = i == _current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: current ? 26 : 20,
        height: current ? 26 : 20,
        decoration: BoxDecoration(
          color: done
              ? const Color(0xFF4DD0C4)
              : current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: current ? const Color(0xFF4DD0C4) : Colors.white54,
            width: current ? 2.5 : 1.5,
          ),
        ),
        child: Center(
          child: done
              ? const Icon(Icons.star_rounded, size: 12, color: Colors.white)
              : Text('${i + 1}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: current ? const Color(0xFF4DD0C4) : Colors.white70)),
        ),
      ),
    );
  }

  // ── SLIDE VIEW ───────────────────────────────────────────────
  Widget _buildSlideView(_SlideEntry entry) {
    if (entry.slideData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_outlined, size: 64, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            Text('No slides created for this lesson yet.',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: const Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LessonSlideRenderer(slideData: entry.slideData),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────
  Widget _buildBottomBar(int total) {
    final isFirst = _current == 0;
    final isLast = _current == total - 1;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: isFirst ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: isFirst ? null : () => setState(() => _current--),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: const Color(0xFF444444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Previous',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const Spacer(),
          Text('${_current + 1} / $total',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF888888))),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: isLast
                ? () => Navigator.of(context).pop()
                : () => setState(() => _current++),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLast ? const Color(0xFF4DD0C4) : const Color(0xFFADE8F4),
              foregroundColor: isLast ? Colors.white : const Color(0xFF1A5276),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(
                isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
                size: 18),
            label: Text(isLast ? 'Finish' : 'Next',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
