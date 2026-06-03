import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../digitalgame/digital_play_page.dart';
import '../digitalgame/digital_quiz_page.dart';
import '../digitalgame/lesson_slide_texts.dart';
import 'lesson_editor_page.dart';

// ── Flat entry: one canvas slide with its lesson context ──────────────────
class _SlideEntry {
  final int lessonIdx;
  final String lessonTitle;
  final int slideIdxInLesson;
  final int totalInLesson;
  final Map<String, dynamic> slideData;
  final bool isLastInLesson;
  const _SlideEntry({
    required this.lessonIdx,
    required this.lessonTitle,
    required this.slideIdxInLesson,
    required this.totalInLesson,
    required this.slideData,
    required this.isLastInLesson,
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

  // Lessons whose activities have been completed
  final Set<int> _activitiesDone = {};
  bool _finalReviewDone = false;

  // Stable reference to this page's route for popUntil
  Route? _myRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myRoute ??= ModalRoute.of(context);
  }

  @override
  void initState() {
    super.initState();
    _all = [];
    for (int li = 0; li < widget.lessons.length; li++) {
      final lesson = widget.lessons[li];
      final title = lesson['title'] as String? ?? '';
      final slides = (lesson['slides'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (slides.isEmpty) {
        _all.add(_SlideEntry(
          lessonIdx: li, lessonTitle: title,
          slideIdxInLesson: 0, totalInLesson: 0,
          slideData: {}, isLastInLesson: true,
        ));
      } else {
        for (int si = 0; si < slides.length; si++) {
          _all.add(_SlideEntry(
            lessonIdx: li, lessonTitle: title,
            slideIdxInLesson: si, totalInLesson: slides.length,
            slideData: slides[si],
            isLastInLesson: si == slides.length - 1,
          ));
        }
      }
    }
    if (_all.isEmpty) {
      _all.add(_SlideEntry(
        lessonIdx: 0, lessonTitle: '', slideIdxInLesson: 0,
        totalInLesson: 0, slideData: {}, isLastInLesson: true,
      ));
    }
  }

  // ── Extract text content from all slides in a lesson ─────────────────────
  List<String> _textsForLesson(int lessonIdx) {
    final lesson = widget.lessons[lessonIdx];
    final slides = (lesson['slides'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final texts = <String>[];
    for (final slide in slides) {
      for (final e in (slide['elements'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()) {
        if (e['type'] == 'text') {
          final t = (e['text'] as String? ?? '').trim();
          if (t.isNotEmpty) texts.add(t);
        }
      }
    }
    return texts;
  }

  List<String> _textsForAllLessons() {
    final texts = <String>[];
    for (int i = 0; i < widget.lessons.length; i++) {
      texts.addAll(_textsForLesson(i));
    }
    return texts;
  }

  // ── Launch word-match → fill-blanks → word-search → quiz chain ───────────
  void _launchLessonActivities(int lessonIdx) {
    final lesson = widget.lessons[lessonIdx];
    final title = lesson['title'] as String? ?? 'Lesson ${lessonIdx + 1}';
    final texts = _textsForLesson(lessonIdx);
    final customNum = 9000 + lessonIdx;

    if (texts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No text content found in slides to generate activities.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    LessonSlideTexts.setCustom(customNum, texts);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DigitalPlayPage(
        lesson: {'number': customNum, 'title': title},
        onChainFinished: () {
          LessonSlideTexts.clearCustom(customNum);
          final route = _myRoute;
          if (route != null) {
            Navigator.of(context).popUntil((r) => r == route);
          }
          if (mounted) setState(() => _activitiesDone.add(lessonIdx));
        },
      ),
    ));
  }

  // ── Launch final quiz only (covers all lessons) ───────────────────────────
  void _launchFinalReview() {
    final texts = _textsForAllLessons();
    const customNum = 9999;

    if (texts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No text content found to generate a review.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    LessonSlideTexts.setCustom(customNum, texts);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DigitalQuizPage(
        lesson: {'number': customNum, 'title': 'Final Review: ${widget.courseTitle}'},
        onChainFinished: () {
          LessonSlideTexts.clearCustom(customNum);
          final route = _myRoute;
          if (route != null) {
            Navigator.of(context).popUntil((r) => r == route);
          }
          if (mounted) setState(() => _finalReviewDone = true);
        },
      ),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entry = _all[_current];
    final total = _all.length;
    final isLast = _current == total - 1;
    final lessonActivitiesDone = _activitiesDone.contains(entry.lessonIdx);
    final isLastSlideOfLesson = entry.isLastInLesson;
    final needsActivities = isLastSlideOfLesson && !lessonActivitiesDone;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildTopBar(entry, total),
          Expanded(child: _buildSlideView(entry)),
          _buildBottomBar(
            total: total,
            isLast: isLast,
            needsActivities: needsActivities,
            lessonIdx: entry.lessonIdx,
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(_SlideEntry entry, int total) {
    final slideLabel = entry.totalInLesson > 1
        ? 'Slide ${entry.slideIdxInLesson + 1}/${entry.totalInLesson}'
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
                  'Lesson ${entry.lessonIdx + 1}: ${entry.lessonTitle}',
                  style: GoogleFonts.montserrat(
                    color: const Color.fromARGB(255, 202, 97, 128),
                    fontSize: 13, fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (slideLabel.isNotEmpty)
                  Text(slideLabel,
                      style: GoogleFonts.nunito(
                          fontSize: 10, color: Colors.white70,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (total <= 12)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(total, _buildDot),
            )
          else
            Text('${_current + 1}/$total',
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w700,
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
              : current ? Colors.white : Colors.white.withValues(alpha: 0.35),
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
                      fontSize: 10, fontWeight: FontWeight.bold,
                      color: current ? const Color(0xFF4DD0C4) : Colors.white70)),
        ),
      ),
    );
  }

  // ── SLIDE VIEW ────────────────────────────────────────────────────────────
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
                    fontSize: 16, color: const Color(0xFFAAAAAA),
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
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 800,
                height: 450,
                child: LessonSlideRenderer(slideData: entry.slideData),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM BAR ────────────────────────────────────────────────────────────
  Widget _buildBottomBar({
    required int total,
    required bool isLast,
    required bool needsActivities,
    required int lessonIdx,
  }) {
    final isFirst = _current == 0;
    final allLessonsDone = _activitiesDone.length >= widget.lessons.length;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Previous
          AnimatedOpacity(
            opacity: isFirst ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              onPressed: isFirst ? null : () => setState(() => _current--),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: const Color(0xFF444444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text('Previous',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),

          const Spacer(),
          Text('${_current + 1} / $total',
              style: GoogleFonts.montserrat(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF888888))),
          const Spacer(),

          // Right action(s)
          if (isLast && allLessonsDone && !_finalReviewDone)
            // All lessons + activities done → offer Final Review
            Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEEEEE),
                  foregroundColor: const Color(0xFF444444),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: Text('Finish',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _launchFinalReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5DC2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: Text('Final Review',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ])
          else if (isLast && _finalReviewDone)
            // All done including final review
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0C4),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.emoji_events_rounded, size: 18),
              label: Text('Course Complete!',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            )
          else if (needsActivities)
            // Last slide of lesson, activities not done yet
            ElevatedButton.icon(
              onPressed: () => _launchLessonActivities(lessonIdx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC83D),
                foregroundColor: const Color(0xFF1A1A2E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.sports_esports_rounded, size: 18),
              label: Text('Play Activities',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            )
          else
            // Normal next
            ElevatedButton.icon(
              onPressed: isLast
                  ? () => Navigator.of(context).pop()
                  : () => setState(() => _current++),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast
                    ? const Color(0xFF4DD0C4)
                    : const Color(0xFFADE8F4),
                foregroundColor: isLast ? Colors.white : const Color(0xFF1A5276),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                  isLast
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward_rounded,
                  size: 18),
              label: Text(isLast ? 'Finish' : 'Next',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
