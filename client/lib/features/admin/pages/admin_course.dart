import 'dart:convert';
import 'dart:typed_data';

import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
import 'package:client/features/admin/models/admin_level.dart';
import 'package:client/mycourses/create_course_page.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _AdminCourseCreationOption { slides, levels }

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  static const double _dashboardCourseCoverWidth = 220;
  static const double _dashboardCourseCoverHeight = 140;
  static const double _dashboardCourseCardWidth = 220;
  static const double _dashboardCourseCoverAspectRatio =
      _dashboardCourseCoverWidth / _dashboardCourseCoverHeight;

  bool _isLoading = true;
  String? _errorMessage;
  List<AdminCourse> _courses = [];
  List<AdminLevel> _levels = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final coursesResult = await ApiService.getAdminCourses(
      authToken: widget.session.token,
    );
    final levelsResult = await ApiService.getAdminLevels(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (coursesResult['success'] != true) {
      setState(() {
        _errorMessage =
            coursesResult['message']?.toString() ?? 'Failed to load courses';
        _isLoading = false;
      });
      return;
    }

    if (levelsResult['success'] != true) {
      setState(() {
        _errorMessage =
            levelsResult['message']?.toString() ?? 'Failed to load levels';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _courses = _parseList(
        coursesResult['data'],
      ).map(AdminCourse.fromJson).toList();
      _levels = _parseList(
        levelsResult['data'],
      ).map(AdminLevel.fromJson).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<AdminLevel> _levelsForCourse(AdminCourse course) {
    final levels = _levels.where((level) {
      return level.courseId == course.id || level.courseId == course.courseId;
    }).toList();

    levels.sort((a, b) {
      final orderComparison = a.orderInCourse.compareTo(b.orderInCourse);

      if (orderComparison != 0) {
        return orderComparison;
      }

      return a.title.compareTo(b.title);
    });
    return levels;
  }

  List<AdminCourse> _sortedCourses(Iterable<AdminCourse> courses) {
    final sorted = courses.toList();
    sorted.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateComparison = bDate.compareTo(aDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final titleComparison = a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      );

      if (titleComparison != 0) {
        return titleComparison;
      }

      return a.courseId.compareTo(b.courseId);
    });
    return sorted;
  }

  List<AdminCourse> get _adminCreatedCourses {
    return _sortedCourses(_courses.where((course) => course.isAdminCreated));
  }

  List<AdminCourse> get _userCreatedCourses {
    return _sortedCourses(_courses.where((course) => !course.isAdminCreated));
  }

  List<AdminCourse> get _draftCourses {
    return _sortedCourses(
      _adminCreatedCourses.where((course) => !course.isPublic),
    );
  }

  List<AdminCourse> get _publishedCourses {
    return _sortedCourses(
      _adminCreatedCourses.where((course) => course.isPublic),
    );
  }

  String _buildCourseId(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.isNotEmpty) {
      return slug;
    }

    return 'course-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _resolveCourseId(String courseName, String rawCourseId) {
    final courseId = rawCourseId.trim();
    if (courseId.isNotEmpty) {
      return courseId;
    }

    return _buildCourseId(courseName);
  }

  Future<void> _showCreateCourseDialog() async {
    final selection = await showDialog<_AdminCourseCreationOption>(
      context: context,
      builder: (context) {
        return const _AdminCourseCreationPickerDialog();
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    if (selection == _AdminCourseCreationOption.slides) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateCoursePage(session: widget.session),
        ),
      );

      if (mounted) {
        await _loadCourses();
      }
      return;
    }

    final nameController = TextEditingController();
    final courseIdController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = true;
    String? courseImageBase64;
    double coverFrameScale = 1;
    double coverFrameOffsetX = 0;
    double coverFrameOffsetY = 0;
    bool courseIdWasEdited = false;
    bool isAutoUpdatingCourseId = false;

    courseIdController.addListener(() {
      if (!isAutoUpdatingCourseId) {
        courseIdWasEdited = true;
      }
    });
    nameController.addListener(() {
      if (!courseIdWasEdited) {
        isAutoUpdatingCourseId = true;
        courseIdController.text = _buildCourseId(nameController.text.trim());
        isAutoUpdatingCourseId = false;
      }
    });

    final payload = await _showCourseDialog(
      title: AppLanguage.of(context).t('createCourse'),
      actionLabel: AppLanguage.of(context).t('create'),
      nameController: nameController,
      courseIdController: courseIdController,
      categoryController: categoryController,
      descriptionController: descriptionController,
      initialIsPublic: isPublic,
      onPublicChanged: (value) => isPublic = value,
      initialCourseImageBase64: courseImageBase64,
      initialCoverFrameScale: coverFrameScale,
      initialCoverFrameOffsetX: coverFrameOffsetX,
      initialCoverFrameOffsetY: coverFrameOffsetY,
    );

    nameController.dispose();
    courseIdController.dispose();
    categoryController.dispose();
    descriptionController.dispose();

    if (payload == null) {
      return;
    }

    final result = await ApiService.createAdminCourse(
      authToken: widget.session.token,
      courseJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadCourses();
      _showMessage('Course created successfully');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to create course');
    }
  }

  Future<Map<String, dynamic>?> _showCourseDialog({
    required String title,
    required String actionLabel,
    required TextEditingController nameController,
    required TextEditingController courseIdController,
    required TextEditingController categoryController,
    required TextEditingController descriptionController,
    required bool initialIsPublic,
    required ValueChanged<bool> onPublicChanged,
    String? initialCourseImageBase64,
    double initialCoverFrameScale = 1,
    double initialCoverFrameOffsetX = 0,
    double initialCoverFrameOffsetY = 0,
  }) {
    bool isPublic = initialIsPublic;
    final language = AppLanguage.of(context);
    String? courseImageBase64 = initialCourseImageBase64;
    double coverFrameScale = initialCoverFrameScale;
    double coverFrameOffsetX = initialCoverFrameOffsetX;
    double coverFrameOffsetY = initialCoverFrameOffsetY;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: language.t('courseName'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: courseIdController,
                        decoration: InputDecoration(
                          labelText: language.t('courseId'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: language.t('category'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: language.t('description'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(language.t('public')),
                        subtitle: Text(
                          isPublic
                              ? language.t('visibleToUsers')
                              : language.t('hiddenFromUsers'),
                        ),
                        value: isPublic,
                        onChanged: (value) {
                          onPublicChanged(value);
                          setDialogState(() {
                            isPublic = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showFramedImageUploadDialog(
                            context: context,
                            title: 'Upload course cover',
                            initialImageBase64: courseImageBase64,
                            initialScale: coverFrameScale,
                            initialOffsetX: coverFrameOffsetX,
                            initialOffsetY: coverFrameOffsetY,
                            aspectRatio: _dashboardCourseCoverAspectRatio,
                          );
                          if (result == null) {
                            return;
                          }
                          setDialogState(() {
                            courseImageBase64 = result.imageBase64;
                            coverFrameScale = result.scale;
                            coverFrameOffsetX = result.offsetX;
                            coverFrameOffsetY = result.offsetY;
                          });
                        },
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Upload cover'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(language.t('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final courseName = nameController.text.trim();
                    final courseId = _resolveCourseId(
                      courseName,
                      courseIdController.text,
                    );

                    if (courseName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a course name.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, {
                      'courseName': courseName,
                      'courseId': courseId,
                      'category': categoryController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'courseImageBase64': courseImageBase64,
                      'coverFrameScale': coverFrameScale,
                      'coverFrameOffsetX': coverFrameOffsetX,
                      'coverFrameOffsetY': coverFrameOffsetY,
                      'isPublic': isPublic,
                    });
                  },
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCourseDialog(AdminCourse course) async {
    final nameController = TextEditingController(text: course.title);
    final courseIdController = TextEditingController(
      text: course.courseId.isEmpty
          ? _buildCourseId(course.title)
          : course.courseId,
    );
    final categoryController = TextEditingController(text: course.category);
    final descriptionController = TextEditingController(
      text: course.description,
    );
    bool isPublic = course.isPublic;

    final payload = await _showCourseDialog(
      title: AppLanguage.of(context).t('editCourse'),
      actionLabel: AppLanguage.of(context).t('save'),
      nameController: nameController,
      courseIdController: courseIdController,
      categoryController: categoryController,
      descriptionController: descriptionController,
      initialIsPublic: isPublic,
      onPublicChanged: (value) => isPublic = value,
      initialCourseImageBase64: course.courseImageBase64,
      initialCoverFrameScale: course.coverFrameScale,
      initialCoverFrameOffsetX: course.coverFrameOffsetX,
      initialCoverFrameOffsetY: course.coverFrameOffsetY,
    );

    nameController.dispose();
    courseIdController.dispose();
    categoryController.dispose();
    descriptionController.dispose();

    if (payload == null) {
      return;
    }

    final result = await ApiService.updateAdminCourse(
      authToken: widget.session.token,
      courseId: course.id,
      courseJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadCourses();
      _showMessage('Course updated successfully');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to update course');
    }
  }

  Future<void> _deleteCourse(AdminCourse course) async {
    final language = AppLanguage.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('deleteCourse')),
          content: Text('Are you sure you want to delete "${course.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(language.t('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.deleteAdminCourse(
      authToken: widget.session.token,
      courseId: course.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadCourses();
      _showMessage('"${course.title}" deleted');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to delete course');
    }
  }

  Future<void> _revokeVerification(AdminCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revoke verification?'),
          content: Text(
            'Remove verification from "${course.title}"? It will leave the main Courses section.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.revokeAdminCourseVerification(
      authToken: widget.session.token,
      courseId: course.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadCourses();
      _showMessage('Verification revoked');
    } else {
      _showMessage(
        result['message']?.toString() ?? 'Failed to revoke verification',
      );
    }
  }

  Future<void> _openManageLevels(AdminCourse course) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseLevelsPage(
          session: widget.session,
          course: course,
          courseLevels: _levelsForCourse(course),
          allLevels: _levels,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCourses();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Uint8List? _safeDecodeBase64(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Color _courseColor(AdminCourse course) {
    switch (course.category.toLowerCase().trim()) {
      case 'digital literacy':
        return const Color(0xFF9B7BCB);
      case 'cs topics':
        return const Color(0xFF4A90C4);
      case 'text coding':
        return const Color(0xFFE8A838);
      case 'coding':
        return const Color(0xFF7BC67E);
      default:
        return const Color(0xFF4A90C4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh),
              label: Text(language.t('retry')),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                language.t('coursesManagement'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: language.t('refreshCourses'),
                onPressed: _loadCourses,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateCourseDialog,
                icon: const Icon(Icons.add),
                label: Text(language.t('createCourse')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            tabs: [
              Tab(text: language.t('published')),
              Tab(text: language.t('drafts')),
              Tab(text: language.t('userCreated')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _CoursesGrid(
                  courses: _publishedCourses,
                  emptyMessage: _courses.isEmpty
                      ? language.t('noCoursesYet')
                      : 'No published courses yet.',
                  levelsForCourse: _levelsForCourse,
                  courseColor: _courseColor,
                  decodeCover: _safeDecodeBase64,
                  onManageLevels: _openManageLevels,
                  onEdit: _showEditCourseDialog,
                  onDelete: _deleteCourse,
                  onRevokeVerification: _revokeVerification,
                  onRefresh: _loadCourses,
                ),
                _CoursesGrid(
                  courses: _draftCourses,
                  emptyMessage: _courses.isEmpty
                      ? language.t('noCoursesYet')
                      : 'No draft courses yet.',
                  levelsForCourse: _levelsForCourse,
                  courseColor: _courseColor,
                  decodeCover: _safeDecodeBase64,
                  onManageLevels: _openManageLevels,
                  onEdit: _showEditCourseDialog,
                  onDelete: _deleteCourse,
                  onRevokeVerification: _revokeVerification,
                  onRefresh: _loadCourses,
                ),
                _CoursesGrid(
                  courses: _userCreatedCourses,
                  emptyMessage: _courses.isEmpty
                      ? language.t('noCoursesYet')
                      : 'No user-created courses yet.',
                  levelsForCourse: _levelsForCourse,
                  courseColor: _courseColor,
                  decodeCover: _safeDecodeBase64,
                  onManageLevels: _openManageLevels,
                  onEdit: _showEditCourseDialog,
                  onDelete: _deleteCourse,
                  onRevokeVerification: _revokeVerification,
                  onRefresh: _loadCourses,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  const _CoursesGrid({
    required this.courses,
    required this.emptyMessage,
    required this.levelsForCourse,
    required this.courseColor,
    required this.decodeCover,
    required this.onManageLevels,
    required this.onEdit,
    required this.onDelete,
    required this.onRevokeVerification,
    required this.onRefresh,
  });

  final List<AdminCourse> courses;
  final String emptyMessage;
  final List<AdminLevel> Function(AdminCourse course) levelsForCourse;
  final Color Function(AdminCourse course) courseColor;
  final Uint8List? Function(String? value) decodeCover;
  final void Function(AdminCourse course) onManageLevels;
  final void Function(AdminCourse course) onEdit;
  final void Function(AdminCourse course) onDelete;
  final void Function(AdminCourse course) onRevokeVerification;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: courses.map((course) {
            final levelsCount = levelsForCourse(course).length;
            return _AdminDashboardCourseCard(
              course: course,
              levelsCount: levelsCount,
              color: courseColor(course),
              coverBytes: decodeCover(course.courseImageBase64),
              onManageLevels: () => onManageLevels(course),
              onEdit: () => onEdit(course),
              onDelete: () => onDelete(course),
              onRevokeVerification: () => onRevokeVerification(course),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminDashboardCourseCard extends StatefulWidget {
  const _AdminDashboardCourseCard({
    required this.course,
    required this.levelsCount,
    required this.color,
    required this.coverBytes,
    required this.onManageLevels,
    required this.onEdit,
    required this.onDelete,
    required this.onRevokeVerification,
  });

  final AdminCourse course;
  final int levelsCount;
  final Color color;
  final Uint8List? coverBytes;
  final VoidCallback onManageLevels;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRevokeVerification;

  @override
  State<_AdminDashboardCourseCard> createState() =>
      _AdminDashboardCourseCardState();
}

class _AdminCourseCreationPickerDialog extends StatelessWidget {
  const _AdminCourseCreationPickerDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE59E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 28,
                        color: Color(0xFF6B4F1D),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Course',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C2A4A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose how you want to create this course.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useColumn = constraints.maxWidth < 620;

                    final slidesOption = _AdminCourseCreationChoiceCard(
                      title: 'Create Slides',
                      subtitle:
                          'Open the same slide course creator used in My Creations.',
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFFFFB84D),
                      accentColor: const Color(0xFFFFF2C7),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_AdminCourseCreationOption.slides),
                    );
                    final levelsOption = _AdminCourseCreationChoiceCard(
                      title: 'Create Course',
                      subtitle:
                          'Create a course with levels you can add and reorder here.',
                      icon: Icons.view_list_rounded,
                      color: const Color(0xFF57A5FF),
                      accentColor: const Color(0xFFE7F2FF),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_AdminCourseCreationOption.levels),
                    );

                    if (useColumn) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          slidesOption,
                          const SizedBox(height: 16),
                          levelsOption,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: slidesOption),
                        const SizedBox(width: 18),
                        Expanded(child: levelsOption),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCourseCreationChoiceCard extends StatefulWidget {
  const _AdminCourseCreationChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_AdminCourseCreationChoiceCard> createState() =>
      _AdminCourseCreationChoiceCardState();
}

class _AdminCourseCreationChoiceCardState
    extends State<_AdminCourseCreationChoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? widget.color : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _hovered ? 0.26 : 0.14),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2A4A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F6473),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Open Creator',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: widget.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardCourseCardState extends State<_AdminDashboardCourseCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  String get _topic {
    final category = widget.course.category.trim();
    return category.isEmpty ? 'Coding' : category;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _AdminCoursesPageState._dashboardCourseCardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.widgets,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.course.isPublic
                            ? language.t('public')
                            : language.t('private'),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _AdminCoursesPageState._dashboardCourseCoverWidth,
              height: _AdminCoursesPageState._dashboardCourseCoverHeight,
              child: widget.coverBytes == null
                  ? Image.asset('assets/images/course1.jpg', fit: BoxFit.cover)
                  : FramedImagePreview(
                      bytes: widget.coverBytes,
                      scale: widget.course.coverFrameScale,
                      offsetX: widget.course.coverFrameOffsetX,
                      offsetY: widget.course.coverFrameOffsetY,
                      placeholderIcon: Icons.menu_book_rounded,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.course.description.isEmpty
                        ? language.t('noDescription')
                        : widget.course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${language.t('levels')}: ${widget.levelsCount}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: language.t('manageLevels'),
                        child: IconButton(
                          onPressed: widget.onManageLevels,
                          icon: const Icon(Icons.reorder),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          color: widget.color,
                        ),
                      ),
                      Tooltip(
                        message: language.t('edit'),
                        child: IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          color: widget.color,
                        ),
                      ),
                      if (!widget.course.isAdminCreated &&
                          widget.course.isVerified)
                        Tooltip(
                          message: 'Revoke verification',
                          child: IconButton(
                            onPressed: widget.onRevokeVerification,
                            icon: const Icon(Icons.verified_user_outlined),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 30,
                            ),
                            color: const Color(0xFFFFA726),
                          ),
                        ),
                      Tooltip(
                        message: language.t('delete'),
                        child: IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseLevelsPage extends StatefulWidget {
  const CourseLevelsPage({
    super.key,
    required this.session,
    required this.course,
    required this.courseLevels,
    required this.allLevels,
  });

  final AuthSession session;
  final AdminCourse course;
  final List<AdminLevel> courseLevels;
  final List<AdminLevel> allLevels;

  @override
  State<CourseLevelsPage> createState() => _CourseLevelsPageState();
}

class _CourseLevelsPageState extends State<CourseLevelsPage> {
  late List<AdminLevel> levels;
  late List<AdminLevel> allLevels;
  bool _isSaving = false;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    levels = List<AdminLevel>.from(widget.courseLevels);
    allLevels = List<AdminLevel>.from(widget.allLevels);
  }

  String get _courseKey {
    return widget.course.courseId.isNotEmpty
        ? widget.course.courseId
        : widget.course.id;
  }

  List<AdminLevel> get _availableLevels {
    final selectedIds = levels.map((level) => level.id).toSet();
    final available = allLevels
        .where((level) => !selectedIds.contains(level.id))
        .toList();

    available.sort((a, b) {
      final courseComparison = a.courseId.compareTo(b.courseId);

      if (courseComparison != 0) {
        return courseComparison;
      }

      return a.title.compareTo(b.title);
    });

    return available;
  }

  void _onReorder(int oldIndex, int newIndex) {
    _handleReorder(oldIndex, newIndex);
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (_isSaving) {
      return;
    }

    final previousLevels = List<AdminLevel>.from(levels);

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = levels.removeAt(oldIndex);
      levels.insert(newIndex, item);
      _isSaving = true;
    });

    final saved = await _persistCurrentOrder();

    if (!mounted) {
      return;
    }

    setState(() {
      if (!saved) {
        levels = previousLevels;
      }
      _isSaving = false;
    });

    if (saved) {
      _showMessage('Level order saved');
    }
  }

  Future<void> _addSelectedLevel() async {
    if (_isSaving) {
      return;
    }

    final levelId = _selectedLevelId;

    if (levelId == null) {
      return;
    }

    AdminLevel? selectedLevel;

    for (final level in _availableLevels) {
      if (level.id == levelId) {
        selectedLevel = level;
        break;
      }
    }

    if (selectedLevel == null) {
      return;
    }

    final previousLevels = List<AdminLevel>.from(levels);
    final previousSelectedLevelId = _selectedLevelId;

    setState(() {
      levels.add(selectedLevel!);
      _selectedLevelId = null;
      _isSaving = true;
    });

    final result = await ApiService.updateAdminLevel(
      authToken: widget.session.token,
      levelId: selectedLevel.id,
      levelJson: {'courseId': _courseKey},
    );

    if (!mounted) {
      return;
    }

    final saved = result['success'] == true;

    setState(() {
      if (!saved) {
        levels = previousLevels;
        _selectedLevelId = previousSelectedLevelId;
      }
      _isSaving = false;
    });

    if (saved) {
      _showMessage('Level added to the end');
    } else {
      _showSaveFailure(result);
    }
  }

  Future<void> _removeLevel(AdminLevel level) async {
    if (_isSaving) {
      return;
    }

    final previousLevels = List<AdminLevel>.from(levels);

    setState(() {
      levels.removeWhere((item) => item.id == level.id);
      _selectedLevelId = null;
      _isSaving = true;
    });

    final removeResult = await ApiService.updateAdminLevel(
      authToken: widget.session.token,
      levelId: level.id,
      levelJson: {'courseId': '', 'orderInCourse': 0},
    );

    if (!mounted) {
      return;
    }

    if (removeResult['success'] != true) {
      setState(() {
        levels = previousLevels;
        _isSaving = false;
      });
      _showSaveFailure(removeResult);
      return;
    }

    final orderSaved = await _persistCurrentOrder();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (orderSaved) {
      _showMessage('Level removed from course');
    }
  }

  Future<bool> _persistCurrentOrder() async {
    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      final result = await ApiService.updateAdminLevel(
        authToken: widget.session.token,
        levelId: level.id,
        levelJson: {'courseId': _courseKey, 'orderInCourse': index + 1},
      );

      if (!mounted) {
        return false;
      }

      if (result['success'] != true) {
        _showSaveFailure(result);
        return false;
      }
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSaveFailure(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to save course levels',
        ),
      ),
    );
  }

  String _assignmentLabel(AdminLevel level) {
    if (level.courseId.isEmpty) {
      return 'No course';
    }

    if (level.courseId == widget.course.id || level.courseId == _courseKey) {
      return 'This course';
    }

    return 'From ${level.courseId}';
  }

  Widget _buildAddLevelPanel() {
    final language = AppLanguage.of(context);
    final availableLevels = _availableLevels;
    final selectedLevelId =
        availableLevels.any((level) => level.id == _selectedLevelId)
        ? _selectedLevelId
        : null;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedLevelId,
                decoration: InputDecoration(
                  labelText: language.t('addLevel'),
                  border: const OutlineInputBorder(),
                ),
                items: availableLevels.map((level) {
                  return DropdownMenuItem(
                    value: level.id,
                    child: Text(
                      '${level.title} - ${_assignmentLabel(level)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: availableLevels.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedLevelId = value;
                        });
                      },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _isSaving || selectedLevelId == null
                  ? null
                  : _addSelectedLevel,
              icon: const Icon(Icons.playlist_add),
              label: Text(language.t('add')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.title} - Levels'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildAddLevelPanel(),
          Expanded(
            child: levels.isEmpty
                ? Center(child: Text(language.t('thisCourseHasNoLevels')))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    buildDefaultDragHandles: false,
                    itemCount: levels.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final level = levels[index];

                      return Card(
                        key: ValueKey(level.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(level.title),
                          subtitle: Text(
                            'Difficulty: ${level.difficulty} - Creator: ${level.creatorName}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: language.t('removeFromCourse'),
                                onPressed: _isSaving
                                    ? null
                                    : () => _removeLevel(level),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.drag_handle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
