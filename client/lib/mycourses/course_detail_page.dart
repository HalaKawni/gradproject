import 'dart:convert';
import 'dart:math' as math;
import 'package:client/core/models/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'custom_course_viewer_page.dart';
import 'create_course_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onRefresh;
  final AuthSession? session;

  const CourseDetailPage({
    super.key,
    required this.course,
    required this.onRefresh,
    this.session,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  late Map<String, dynamic> _course;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _course = Map<String, dynamic>.from(widget.course);
  }

  bool get _isPublished => _course['isPublished'] as bool? ?? false;
  String get _courseId => _course['_id'] as String? ?? '';
  String get _title => _course['title'] as String? ?? 'Untitled';
  String get _description => _course['description'] as String? ?? '';
  String? get _coverImage => _course['courseImageBase64'] as String?;
  List get _lessons => _course['lessons'] as List? ?? [];

  Future<void> _togglePublish() async {
    setState(() => _publishing = true);
    final success = await ApiService.updateCourse(_courseId, {
      'isPublished': !_isPublished,
    }, authToken: widget.session?.token);
    if (!mounted) return;
    if (success) {
      setState(() {
        _course = Map<String, dynamic>.from(_course)
          ..['isPublished'] = !_isPublished;
        _publishing = false;
      });
      widget.onRefresh();
    } else {
      setState(() => _publishing = false);
    }
  }

  void _startCourse() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomCourseViewerPage(
          courseTitle: _title,
          lessons: _lessons
              .map(
                (l) => <String, dynamic>{
                  'number': l['number'],
                  'title': l['title'] ?? '',
                  'slides': l['slides'] ?? [],
                },
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _editCourse() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCoursePage(
          courseId: _courseId,
          initialTitle: _title,
          initialDescription: _description,
          initialCoverImageBase64: _coverImage,
          initialLessons: _lessons
              .map((l) => Map<String, dynamic>.from(l as Map))
              .toList(),
          session: widget.session,
        ),
      ),
    );
    widget.onRefresh();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFFADE8F4),
      body: Column(
        children: [
          _buildTopNavbar(),
          Expanded(
            child: isMobile
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftPanel(isMobile: true),
                        const SizedBox(height: 24),
                        _buildLessonsGrid(),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 24, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftPanel(),
                        const SizedBox(width: 58),
                        Expanded(child: _buildLessonsGrid()),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: GoogleFonts.montserrat(
                color: const Color.fromARGB(255, 202, 97, 128),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _isPublished
                  ? const Color(0xFF4DD0C4)
                  : const Color(0xFFFFC83D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPublished ? Icons.public : Icons.drafts_outlined,
                  size: 13,
                  color: _isPublished ? Colors.white : const Color(0xFF1A1A2E),
                ),
                const SizedBox(width: 4),
                Text(
                  _isPublished ? 'Published' : 'Draft',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isPublished
                        ? Colors.white
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel({bool isMobile = false}) {
    final total = _lessons.length;
    return Container(
      width: isMobile ? double.infinity : 400,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFCDF0F8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 230, 154),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$total Lesson${total == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Chennai',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_coverImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_coverImage!),
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              _title,
              style: const TextStyle(
                fontFamily: 'Chennai',
                fontSize: 28,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),

            if (_description.isNotEmpty) ...[
              Text(
                _description,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
            ] else
              const SizedBox(height: 32),

            Center(
              child: const Text(
                'TRACK YOUR PROGRESS',
                style: TextStyle(
                  fontFamily: 'xolonium',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: CustomPaint(painter: _ArcProgressPainter(progress: 0)),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '0 / $total lessons completed',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (total > 0) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DD0C4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: const Text(
                    'Start Course',
                    style: TextStyle(
                      fontFamily: 'Chennai',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (!_isPublished) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _editCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 230, 154),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Course',
                    style: TextStyle(
                      fontFamily: 'Chennai',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _publishing ? null : _togglePublish,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isPublished
                        ? Colors.orange
                        : const Color(0xFF4A90D9),
                    width: 1.5,
                  ),
                  foregroundColor: _isPublished
                      ? Colors.orange
                      : const Color(0xFF4A90D9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _publishing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isPublished
                            ? Icons.unpublished_outlined
                            : Icons.public,
                        size: 18,
                      ),
                label: Text(
                  _isPublished ? 'Move to Draft' : 'Publish',
                  style: const TextStyle(
                    fontFamily: 'Chennai',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsGrid() {
    if (_lessons.isEmpty) {
      return Center(
        child: Text(
          'No lessons yet.',
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: const Color(0xFF888888),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: _lessons.asMap().entries.map((entry) {
          final lesson = entry.value;
          final slides = (lesson['slides'] as List? ?? []);
          return _LessonCard(
            number: (lesson['number'] as num?)?.toInt() ?? (entry.key + 1),
            title: lesson['title'] as String? ?? 'Lesson ${entry.key + 1}',
            slideCount: slides.length,
            imageBase64: lesson['imageBase64'] as String?,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomCourseViewerPage(
                  courseTitle: _title,
                  lessons: [
                    <String, dynamic>{
                      'number': lesson['number'],
                      'title': lesson['title'] ?? '',
                      'slides': slides,
                    },
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── LESSON CARD ──
class _LessonCard extends StatefulWidget {
  final int number;
  final String title;
  final int slideCount;
  final String? imageBase64;
  final VoidCallback onTap;
  const _LessonCard({
    required this.number,
    required this.title,
    required this.slideCount,
    required this.onTap,
    this.imageBase64,
  });

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _hovered = false;

  Widget _gradientHeader() => Container(
    height: 130,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF4DD0C4), Color(0xFF4A90D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        '${widget.number}',
        style: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: widget.imageBase64 != null
                    ? Image.memory(
                        base64Decode(widget.imageBase64!),
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => _gradientHeader(),
                      )
                    : _gradientHeader(),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson ${widget.number}',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4DD0C4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_outlined,
                          size: 12,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.slideCount} slide${widget.slideCount == 1 ? '' : 's'}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFF888888),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.play_circle_outline,
                          size: 18,
                          color: _hovered
                              ? const Color(0xFF4DD0C4)
                              : const Color(0xFFCCCCCC),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ARC PROGRESS ──
class _ArcProgressPainter extends CustomPainter {
  final double progress;
  const _ArcProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFF4DD0C4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) => old.progress != progress;
}
