import 'dart:convert';
import 'dart:typed_data';
import 'package:client/core/models/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'lesson_editor_page.dart';
import 'custom_course_viewer_page.dart';

class CreateCoursePage extends StatefulWidget {
  final String? courseId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialCoverImageBase64;
  final List<Map<String, dynamic>>? initialLessons;
  final AuthSession? session;

  const CreateCoursePage({
    super.key,
    this.courseId,
    this.initialTitle,
    this.initialDescription,
    this.initialCoverImageBase64,
    this.initialLessons,
    this.session,
  });

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<_LessonDraft> _lessons = [];
  bool _saved = false;
  Uint8List? _coverImageBytes;
  bool get _isEditMode => widget.courseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.initialTitle ?? '';
      _descController.text = widget.initialDescription ?? '';
      if (widget.initialCoverImageBase64 != null) {
        try {
          _coverImageBytes = base64Decode(widget.initialCoverImageBase64!);
        } catch (_) {}
      }
      if (widget.initialLessons != null) {
        for (final l in widget.initialLessons!) {
          Uint8List? imgBytes;
          final imgB64 = l['imageBase64'] as String?;
          if (imgB64 != null) {
            try {
              imgBytes = base64Decode(imgB64);
            } catch (_) {}
          }
          _lessons.add(
            _LessonDraft(
              number: (l['number'] as num?)?.toInt() ?? (_lessons.length + 1),
              title: l['title'] as String? ?? '',
              imageBytes: imgBytes,
              slides: List<Map<String, dynamic>>.from(
                (l['slides'] as List? ?? []).map(
                  (s) => Map<String, dynamic>.from(s as Map),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Show dialog to name a lesson before adding it ──
  void _showAddLessonDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Name Your Lesson',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Introduction to the Topic',
            hintStyle: GoogleFonts.nunito(color: const Color(0xFFAAAAAA)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.nunito(fontSize: 15),
          onSubmitted: (_) => _confirmAddLesson(nameController.text, ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmAddLesson(nameController.text, ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DD0C4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAddLesson(String name, BuildContext dialogCtx) {
    Navigator.of(dialogCtx).pop();
    final trimmed = name.trim();
    setState(() {
      _lessons.add(
        _LessonDraft(
          number: _lessons.length + 1,
          title: trimmed.isEmpty ? 'Lesson ${_lessons.length + 1}' : trimmed,
        ),
      );
    });
  }

  Future<void> _pickImageForLesson(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.first.bytes != null) {
      final lesson = _lessons[index];
      setState(() {
        _lessons[index] = _LessonDraft(
          number: lesson.number,
          title: lesson.title,
          imageBytes: result.files.first.bytes,
          slides: lesson.slides,
        );
      });
    }
  }

  Future<void> _editLesson(int index) async {
    final lesson = _lessons[index];
    final result = await Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute(
        builder: (_) => LessonEditorPage(
          lessonNumber: lesson.number,
          lessonTitle: lesson.title,
          initialSlides: lesson.slides,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _lessons[index] = _LessonDraft(
        number: lesson.number,
        title: lesson.title,
        imageBytes: lesson.imageBytes,
        slides: result,
      );
    });
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || result == null || result.files.first.bytes == null) return;
    setState(() => _coverImageBytes = result.files.first.bytes);
  }

  Future<void> _saveCourst() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a course title first.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final lessonsData = _lessons
        .map(
          (l) => <String, dynamic>{
            'number': l.number,
            'title': l.title,
            if (l.imageBytes != null)
              'imageBase64': base64Encode(l.imageBytes!),
            'slides': l.slides,
          },
        )
        .toList();

    bool success;
    if (_isEditMode) {
      success = await ApiService.updateCourse(widget.courseId!, {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'lessons': lessonsData,
        'courseImageBase64': _coverImageBytes != null
            ? base64Encode(_coverImageBytes!)
            : null,
      }, authToken: widget.session?.token);
    } else {
      final saved = await ApiService.saveCourse(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        lessons: lessonsData,
        coverImageBase64: _coverImageBytes != null
            ? base64Encode(_coverImageBytes!)
            : null,
        authToken: widget.session?.token,
      );
      success = saved != null;
    }

    if (!mounted) return;
    if (success) {
      if (_isEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Are you logged in?'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 24, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _saved ? _buildSavedLeftPanel() : _buildEditingLeftPanel(),
                  const SizedBox(width: 58),
                  Expanded(child: _buildLessonsArea()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP NAV ──
  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(
                _isEditMode
                    ? 'Edit Course'
                    : (_saved ? _titleController.text : 'Create New Course'),
                style: GoogleFonts.montserrat(
                  color: const Color.fromARGB(255, 202, 97, 128),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.menu, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  // ── LEFT PANEL — EDITING MODE ──
  Widget _buildEditingLeftPanel() {
    return Container(
      width: 400,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lessons count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 230, 154),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_lessons.length} Lesson${_lessons.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Chennai',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cover image picker
            Text(
              'Cover Image',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _coverImageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_coverImageBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _coverImageBytes = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: Color(0xFFAAAAAA),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to add cover image',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Course Title',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontFamily: 'Chennai',
                fontSize: 22,
                color: Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Enter course name...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFFAAAAAA),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Description',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF555555),
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Describe your course...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 13,
                  color: const Color(0xFFAAAAAA),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 36),

            Center(
              child: Text(
                'PROGRESS',
                style: const TextStyle(
                  fontFamily: 'xolonium',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 240,
                height: 150,
                child: CustomPaint(painter: _ArcProgressPainter(progress: 0)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '0 / ${_lessons.length} lessons completed',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCourst,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 230, 154),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.save_rounded, size: 22),
                label: Text(
                  _isEditMode ? 'Update Course' : 'Save Course',
                  style: const TextStyle(
                    fontFamily: 'Chennai',
                    fontSize: 15,
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

  // ── LEFT PANEL — SAVED / DISPLAY MODE (like Digital Literacy) ──
  Widget _buildSavedLeftPanel() {
    final progress = 0.0; // no lessons completed yet
    final total = _lessons.length;

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
          // Lessons badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
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
              // Edit button
              GestureDetector(
                onTap: () => setState(() => _saved = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF555555),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cover image
          if (_coverImageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _coverImageBytes!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Course title
          Text(
            _titleController.text,
            style: const TextStyle(
              fontFamily: 'Chennai',
              fontSize: 28,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 18),

          // Description
          if (_descController.text.isNotEmpty) ...[
            Text(
              _descController.text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 46),
          ] else
            const SizedBox(height: 46),

          // Progress arc
          Center(
            child: Text(
              'TRACK YOUR PROGRESS',
              style: const TextStyle(
                fontFamily: 'xolonium',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 240,
              height: 150,
              child: CustomPaint(
                painter: _ArcProgressPainter(progress: progress),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 36),

          // Start Course button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: total > 0
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomCourseViewerPage(
                            courseTitle: _titleController.text,
                            lessons: _lessons
                                .map(
                                  (l) => <String, dynamic>{
                                    'number': l.number,
                                    'title': l.title,
                                    'slides': l.slides,
                                  },
                                )
                                .toList(),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0C4),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.play_circle_outline, size: 24),
              label: Text(
                total > 0 ? 'Start Course' : 'No Lessons Yet',
                style: const TextStyle(
                  fontFamily: 'Chennai',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LESSONS AREA ──
  Widget _buildLessonsArea() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 40,
        runSpacing: 40,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          ..._lessons.asMap().entries.map(
            (e) => _LessonDraftCard(
              lesson: e.value,
              onDelete: _saved
                  ? null
                  : () => setState(() {
                      _lessons.removeAt(e.key);
                      for (int i = 0; i < _lessons.length; i++) {
                        _lessons[i] = _LessonDraft(
                          number: i + 1,
                          title: _lessons[i].title,
                          imageBytes: _lessons[i].imageBytes,
                          slides: _lessons[i].slides,
                        );
                      }
                    }),
              onImagePick: _saved ? null : () => _pickImageForLesson(e.key),
              onEditSlide: () => _editLesson(e.key),
            ),
          ),
          if (!_saved) _AddLessonCard(onTap: _showAddLessonDialog),
        ],
      ),
    );
  }
}

// ── ADD LESSON CARD ──
class _AddLessonCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AddLessonCard({required this.onTap});

  @override
  State<_AddLessonCard> createState() => _AddLessonCardState();
}

class _AddLessonCardState extends State<_AddLessonCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: _hovered
                  ? const Color(0xFF4DD0C4)
                  : const Color(0xFF4DD0C4).withOpacity(0.5),
              borderRadius: 12,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4DD0C4).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? const Color(0xFF4DD0C4)
                          : const Color(0xFF4DD0C4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: _hovered ? Colors.white : const Color(0xFF4DD0C4),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add a Lesson',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Click to add a new lesson',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── LESSON DRAFT CARD ──
class _LessonDraftCard extends StatefulWidget {
  final _LessonDraft lesson;
  final VoidCallback? onDelete;
  final VoidCallback? onImagePick;
  final VoidCallback? onEditSlide;
  const _LessonDraftCard({
    required this.lesson,
    this.onDelete,
    this.onImagePick,
    this.onEditSlide,
  });

  @override
  State<_LessonDraftCard> createState() => _LessonDraftCardState();
}

class _LessonDraftCardState extends State<_LessonDraftCard>
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
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
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
                    if (widget.onDelete != null)
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE0E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Image area — tap to pick
              GestureDetector(
                onTap: widget.onImagePick,
                child: Stack(
                  children: [
                    widget.lesson.imageBytes != null
                        ? Image.memory(
                            widget.lesson.imageBytes!,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 160,
                            color: const Color(0xFFE0F7FA),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Color(0xFF4DD0C4),
                            ),
                          ),
                    if (widget.onImagePick != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.lesson.imageBytes != null
                                    ? 'Change'
                                    : 'Add Photo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Lesson title
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
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

              // Slide status + edit button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.lesson.slides.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 13,
                              color: Color(0xFF4DD0C4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.lesson.slides.length} slide${widget.lesson.slides.length == 1 ? '' : 's'} created',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4DD0C4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: widget.onEditSlide,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: widget.lesson.slides.isNotEmpty
                              ? const Color(0xFFE8F4FD)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.lesson.slides.isNotEmpty
                                ? const Color(0xFF4A90D9)
                                : const Color(0xFFFFB74D),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.lesson.slides.isNotEmpty
                                  ? Icons.edit_rounded
                                  : Icons.add_box_outlined,
                              size: 15,
                              color: widget.lesson.slides.isNotEmpty
                                  ? const Color(0xFF4A90D9)
                                  : const Color(0xFFFF8F00),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.lesson.slides.isNotEmpty
                                  ? 'Edit Slides'
                                  : 'Create Slides',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.lesson.slides.isNotEmpty
                                    ? const Color(0xFF4A90D9)
                                    : const Color(0xFFFF8F00),
                              ),
                            ),
                          ],
                        ),
                      ),
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

// ── DATA ──
class _LessonDraft {
  final int number;
  final String title;
  final Uint8List? imageBytes;
  final List<Map<String, dynamic>> slides;
  const _LessonDraft({
    required this.number,
    this.title = '',
    this.imageBytes,
    this.slides = const [],
  });
}

// ── DASHED BORDER PAINTER ──
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
          Radius.circular(borderRadius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
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
  bool shouldRepaint(_ArcProgressPainter old) => old.progress != progress;
}
