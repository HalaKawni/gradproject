import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (data['completedLevels'] != null) {
        final List<dynamic> completedLevels = data['completedLevels'];
        setState(() {
          for (int i = 0; i < _lessons.length; i++) {
            if (completedLevels.contains(_lessons[i].number) ||
                completedLevels.contains(_lessons[i].number.toString())) {
              _lessons[i] = _lessons[i].copyWith(completed: true);
            }
          }
          _completedLessons = _lessons.where((l) => l.completed).length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4DD0C4),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 24, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── LEFT PANEL ──
                        _buildLeftPanel(),
                        const SizedBox(width: 58),
                        // ── LESSON CARDS ──
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _lessons
                                .map((lesson) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 40),
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

  // ── TOP NAVBAR — same as DashboardPage (no back button) ──
  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DIGITAL LITERACY: MINI COURSE',
            style: GoogleFonts.montserrat(
              color: const Color.fromARGB(255, 202, 97, 128),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7DBF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.menu, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  // ── LEFT PANEL ──
  Widget _buildLeftPanel() {
    final double progress = _completedLessons / _lessons.length;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFCDF0F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 3 LESSONS badge ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 230, 154),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_lessons.length} LESSONS',
              style: const TextStyle(
                fontFamily: 'Chennai',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 0, 0, 0),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Text(
            'DIGITAL LITERACY',
            style: const TextStyle(
              fontFamily: 'Chennai',
              fontSize: 28,
              color: Color(0xFF1A1A2E),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 18),

          // ── Description ──
          Text(
            'This course provides an overview of Digital Use and Digital Citizenship.',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 46),

          // ── Track your progress ──
          Center(
            child: Text(
              'TRACK YOUR PROGRESS',
              style: const TextStyle(
                fontFamily: 'xolonium',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Big arc ──
          Center(
            child: SizedBox(
              width: 240,
              height: 150,
              child: CustomPaint(
                painter: _ArcProgressPainter(progress: progress),
              ),
            ),
          ),
          const SizedBox(height: 46),

          Center(
            child: Text(
              'YOU COMPLETED $_completedLessons/${_lessons.length} LESSONS',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF666666),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 52),

          // ── Start button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final nextIdx = _completedLessons < _lessons.length
                    ? _completedLessons
                    : _lessons.length - 1;
                _openLesson(_lessons[nextIdx]);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 255, 230, 154),
                foregroundColor:
                    const Color.fromARGB(255, 0, 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: const Color.fromARGB(255, 255, 230, 154)
                    .withOpacity(0.4),
              ),
              label: Text(
                'START LESSON #${(_completedLessons < _lessons.length ? _completedLessons + 1 : _lessons.length)}',
                style: const TextStyle(
                  fontFamily: 'Chennai',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              icon: const Icon(Icons.play_arrow, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(_LessonData lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DigitalLessonPage(lesson: lesson.toMap()),
      ),
    ).then((_) async {
      try {
        await ApiService.saveLevelResult(
          gameId: _gameId,
          level: lesson.number,
          completed: true,
          score: 100,
        );
      } catch (e) {
        // silent fail
      }
      setState(() {
        final idx =
            _lessons.indexWhere((l) => l.number == lesson.number);
        if (idx != -1 && !_lessons[idx].completed) {
          _lessons[idx] = _lessons[idx].copyWith(completed: true);
          _completedLessons =
              _lessons.where((l) => l.completed).length;
          if (idx + 1 < _lessons.length) {
            _lessons[idx + 1] =
                _lessons[idx + 1].copyWith(isUnlocked: true);
          }
        }
      });
    });
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

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepMax,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepMax * progress,
        false,
        Paint()
          ..color = const Color(0xFF4DD0C4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.progress != progress;
}

// ── LESSON DATA ──
class _LessonData {
  final int number;
  final String title;
  final String imagePath;
  final bool isUnlocked;
  final bool completed;

  const _LessonData({
    required this.number,
    required this.title,
    required this.imagePath,
    this.isUnlocked = false,
    this.completed = false,
  });

  _LessonData copyWith({bool? isUnlocked, bool? completed}) {
    return _LessonData(
      number: number,
      title: title,
      imagePath: imagePath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'title': title,
        'imagePath': imagePath,
      };
}

// ── LESSON CARD ──
class _LessonCard extends StatefulWidget {
  final _LessonData lesson;
  final VoidCallback? onTap;
  const _LessonCard({required this.lesson, this.onTap});

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                ),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── NUMBER + STAR ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${widget.lesson.number}',
                        style: const TextStyle(
                          fontFamily: 'Chennai',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Icon(
                        widget.lesson.completed
                            ? Icons.star
                            : Icons.star_border,
                        color: widget.lesson.completed
                            ? const Color.fromARGB(255, 255, 230, 154)
                            : const Color(0xFFBBBBBB),
                        size: 22,
                      ),
                    ],
                  ),
                ),

                // ── IMAGE ──
                Image.asset(
                  widget.lesson.imagePath,
                  width: 400,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 470,
                    height: 260,
                    color: const Color(0xFFE0F7FA),
                    child: const Icon(Icons.computer,
                        size: 60, color: Color(0xFF4DD0C4)),
                  ),
                ),

                // ── TITLE ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: Center(
                    child: Text(
                      widget.lesson.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Chennai',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}