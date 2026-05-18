import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'digital_lesson_page.dart';
import '../services/api_service.dart';

class DigitalLiteracyPage extends StatefulWidget {
  const DigitalLiteracyPage({super.key});

  @override
  State<DigitalLiteracyPage> createState() => _DigitalLiteracyPageState();
}

class _DigitalLiteracyPageState extends State<DigitalLiteracyPage> {
  int _completedLessons = 0;
  bool _isLoading = true;

  static const String _gameId = 'digital-literacy';

  final List<_LessonData> _lessons = [
    _LessonData(
      number: 1,
      title: 'Digital Use In A Nutshell',
      imagePath: 'assets/images/digital1.jpg',
      isUnlocked: true,
    ),
    _LessonData(
      number: 2,
      title: 'Digital Citizenship In A Nutshell',
      imagePath: 'assets/images/digital2.jpg',
      isUnlocked: true,
    ),
    _LessonData(
      number: 3,
      title: 'Digital Collaboration',
      imagePath: 'assets/images/digital3.jpg',
      isUnlocked: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final data = await ApiService.getProgress(_gameId);
      if (!mounted) return;
      final List<dynamic> results = data['levelResults'] ?? [];

      setState(() {
        for (int i = 0; i < _lessons.length; i++) {
          final lessonNum = _lessons[i].number;

          Map<String, dynamic>? lessonResult;
          Map<String, dynamic>? quizResult;
          for (final r in results) {
            final rMap = r as Map<String, dynamic>;
            final lvl = rMap['level'];
            if (lvl == lessonNum || lvl.toString() == lessonNum.toString()) {
              lessonResult = rMap;
            }
            if (lvl == (100 + lessonNum) || lvl.toString() == (100 + lessonNum).toString()) {
              quizResult = rMap;
            }
          }

          final baseStars = (lessonResult?['stars'] as num? ?? 0).toInt();
          final quizStars = (quizResult?['stars'] as num? ?? 0).toInt();
          final effectiveStars = quizStars >= 3 ? 3 : baseStars;

          _lessons[i] = _LessonData(
            number: _lessons[i].number,
            title: _lessons[i].title,
            imagePath: _lessons[i].imagePath,
            isUnlocked: true,
            completed: effectiveStars >= 3,
            inProgress: effectiveStars >= 1 && effectiveStars < 3,
          );
        }
        _completedLessons =
            _lessons.where((l) => l.completed == true).length;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Returns the lesson the user should continue or start next
  _LessonData get _nextLesson {
    final inProgressIdx = _lessons.indexWhere((l) => l.inProgress == true);
    if (inProgressIdx >= 0) return _lessons[inProgressIdx];
    final incompleteIdx = _lessons.indexWhere((l) => l.completed != true);
    if (incompleteIdx >= 0) return _lessons[incompleteIdx];
    return _lessons.last;
  }

  String get _actionButtonText {
    final l = _nextLesson;
    if (l.inProgress == true) return 'digital.btn_continue'.tr(namedArgs: {'num': '${l.number}'});
    if (_completedLessons == _lessons.length) return 'digital.btn_review'.tr(namedArgs: {'num': '${l.number}'});
    return 'digital.btn_start'.tr(namedArgs: {'num': '${l.number}'});
  }

  void _openLesson(_LessonData lesson) async {
    ApiService.saveLevelResult(
      gameId: _gameId,
      level: lesson.number,
      completed: false,
      score: 0,
    );

    final prefs = await SharedPreferences.getInstance();
    final savedSlide = prefs.getInt('lesson_slide_${lesson.number}');
    if (!mounted) return;

    Widget destination;
    if (savedSlide != null && savedSlide >= 0) {
      // Resume mid-slides at the exact slide they left off on
      destination = DigitalLessonPage(lesson: lesson.toMap(), initialSlide: savedSlide);
    } else if (savedSlide == -1 || lesson.inProgress == true) {
      // Slides done — push lesson page with skipToPlay so the play page
      // is pushed on top immediately, keeping lesson in the stack for PREVIOUS
      destination = DigitalLessonPage(lesson: lesson.toMap(), skipToPlay: true);
    } else {
      destination = DigitalLessonPage(lesson: lesson.toMap());
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    ).then((_) async {
      await _loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFADE8F4),
      body: Column(
        children: [
          _buildTopNavbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4DD0C4)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 24, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftPanel(),
                        const SizedBox(width: 58),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _lessons
                                .map((lesson) => Padding(
                                      padding: const EdgeInsets.only(right: 40),
                                      child: _LessonCard(
                                        lesson: lesson,
                                        onTap: () => _openLesson(lesson),
                                      ),
                                    ))
                                .toList(),
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

  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('digital.course_title'.tr(),
              style: GoogleFonts.montserrat(
                  color: const Color.fromARGB(255, 202, 97, 128),
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFF4A7DBF), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2)),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.menu, color: Colors.white, size: 24),
          ]),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final double progress = _completedLessons / _lessons.length;
    return Container(
      width: 400,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFCDF0F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 230, 154),
                borderRadius: BorderRadius.circular(20)),
            child: Text('data.lessons_count'.tr(namedArgs: {'count': '${_lessons.length}'}),
                style: const TextStyle(
                    fontFamily: 'Chennai', fontSize: 12,
                    fontWeight: FontWeight.w800, color: Color.fromARGB(255, 0, 0, 0))),
          ),
          const SizedBox(height: 20),
          Text('digital.course_name'.tr(),
              style: const TextStyle(fontFamily: 'Chennai', fontSize: 28, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 18),
          Text('digital.course_desc'.tr(),
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555), height: 1.5)),
          const SizedBox(height: 46),
          Center(child: Text('data.track_progress'.tr(),
              style: const TextStyle(fontFamily: 'xolonium', fontSize: 18,
                  fontWeight: FontWeight.w500, color: Color(0xFF333333)))),
          const SizedBox(height: 8),
          Center(child: SizedBox(width: 240, height: 150,
              child: CustomPaint(painter: _ArcProgressPainter(progress: progress)))),
          const SizedBox(height: 46),
          Center(child: Text('data.completed_lessons'.tr(namedArgs: {'done': '$_completedLessons', 'total': '${_lessons.length}'}),
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF666666)))),
          const SizedBox(height: 52),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openLesson(_nextLesson),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 230, 154),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              label: Text(
                _actionButtonText,
                style: const TextStyle(fontFamily: 'Chennai', fontSize: 15,
                    fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              icon: const Icon(Icons.play_arrow, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ARC PROGRESS PAINTER ──
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  const _ArcProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 14;
    const startAngle = 3.14159265;
    const sweepMax = 3.14159265;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepMax, false,
        Paint()..color = Colors.white.withOpacity(0.55)
               ..style = PaintingStyle.stroke ..strokeWidth = 26 ..strokeCap = StrokeCap.round);

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepMax * progress, false,
          Paint()..color = const Color(0xFF4DD0C4)
                 ..style = PaintingStyle.stroke ..strokeWidth = 26 ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) => old.progress != progress;
}

// ── LESSON DATA ──
class _LessonData {
  final int number;
  final String title;
  final String imagePath;
  final bool isUnlocked;
  final bool completed;
  final bool inProgress;

  const _LessonData({
    required this.number, required this.title, required this.imagePath,
    this.isUnlocked = false, this.completed = false, this.inProgress = false,
  });

  _LessonData copyWith({bool? isUnlocked, bool? completed, bool? inProgress}) => _LessonData(
    number: number, title: title, imagePath: imagePath,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    completed: completed ?? this.completed,
    inProgress: inProgress ?? this.inProgress,
  );

  Map<String, dynamic> toMap() => {'number': number, 'title': title, 'imagePath': imagePath};
}

// ── LESSON CARD ──
class _LessonCard extends StatefulWidget {
  final _LessonData lesson;
  final VoidCallback? onTap;
  const _LessonCard({required this.lesson, this.onTap});
  @override State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) {
              final isHovered = _scaleAnim.value > 1.01;
              return Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: lesson.inProgress == true
                      ? Border.all(color: const Color(0xFFFFC83D), width: 2)
                      : null,
                  boxShadow: isHovered
                      ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${lesson.number}',
                          style: const TextStyle(fontFamily: 'Chennai', fontSize: 18,
                              fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lesson.inProgress == true)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC83D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('data.in_progress'.tr(),
                                  style: const TextStyle(
                                      fontSize: 8, fontWeight: FontWeight.w800,
                                      color: Colors.white, letterSpacing: 0.5)),
                            ),
                          Icon(
                            lesson.completed == true
                                ? Icons.star
                                : lesson.inProgress == true
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: lesson.completed == true
                                ? const Color.fromARGB(255, 255, 230, 154)
                                : lesson.inProgress == true
                                    ? const Color(0xFFFFC83D)
                                    : const Color(0xFFBBBBBB),
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(lesson.imagePath, width: 400, height: 220, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 470, height: 260,
                        color: const Color(0xFFE0F7FA),
                        child: const Icon(Icons.computer, size: 60, color: Color(0xFF4DD0C4)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: Center(child: Text(lesson.title, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Chennai', fontSize: 18,
                          fontWeight: FontWeight.w500, color: Color(0xFF222222)))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
