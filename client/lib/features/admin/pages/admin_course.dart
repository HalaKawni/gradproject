import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
import 'package:client/features/admin/models/admin_level.dart';
import 'package:flutter/material.dart';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
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

  Future<void> _showCreateCourseDialog() async {
    final nameController = TextEditingController();
    final courseIdController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = true;
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
      title: 'Create New Course',
      actionLabel: 'Create',
      nameController: nameController,
      courseIdController: courseIdController,
      categoryController: categoryController,
      descriptionController: descriptionController,
      initialIsPublic: isPublic,
      onPublicChanged: (value) => isPublic = value,
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
  }) {
    bool isPublic = initialIsPublic;

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
                        decoration: const InputDecoration(
                          labelText: 'Course Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: courseIdController,
                        decoration: const InputDecoration(
                          labelText: 'Course ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Public'),
                        subtitle: Text(
                          isPublic ? 'Visible to users' : 'Hidden from users',
                        ),
                        value: isPublic,
                        onChanged: (value) {
                          onPublicChanged(value);
                          setDialogState(() {
                            isPublic = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final courseName = nameController.text.trim();
                    final courseId = courseIdController.text.trim();

                    if (courseName.isEmpty || courseId.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, {
                      'courseName': courseName,
                      'courseId': courseId,
                      'category': categoryController.text.trim(),
                      'description': descriptionController.text.trim(),
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
    final courseIdController = TextEditingController(text: course.courseId);
    final categoryController = TextEditingController(text: course.category);
    final descriptionController = TextEditingController(
      text: course.description,
    );
    bool isPublic = course.isPublic;

    final payload = await _showCourseDialog(
      title: 'Edit Course',
      actionLabel: 'Save',
      nameController: nameController,
      courseIdController: courseIdController,
      categoryController: categoryController,
      descriptionController: descriptionController,
      initialIsPublic: isPublic,
      onPublicChanged: (value) => isPublic = value,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text('Are you sure you want to delete "${course.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
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

  Future<void> _openManageLevels(AdminCourse course) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseLevelsPage(
          authToken: widget.session.token,
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

  @override
  Widget build(BuildContext context) {
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
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Courses Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh courses',
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showCreateCourseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Course'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _courses.isEmpty
              ? const Center(child: Text('No courses yet.'))
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView.separated(
                    itemCount: _courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final levelsCount = _levelsForCourse(course).length;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.menu_book_outlined),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      course.description.isEmpty
                                          ? 'No description'
                                          : course.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _CourseChip(
                                          label: 'ID: ${course.courseId}',
                                        ),
                                        _CourseChip(
                                          label: 'Levels: $levelsCount',
                                        ),
                                        if (course.category.isNotEmpty)
                                          _CourseChip(label: course.category),
                                        _CourseChip(
                                          label: course.isPublic
                                              ? 'Public'
                                              : 'Private',
                                          isPositive: course.isPublic,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openManageLevels(course),
                                    icon: const Icon(Icons.reorder),
                                    label: const Text('Manage Levels'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showEditCourseDialog(course),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _deleteCourse(course),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CourseChip extends StatelessWidget {
  const _CourseChip({required this.label, this.isPositive});

  final String label;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive == null
        ? Theme.of(context).colorScheme.primary
        : isPositive!
        ? Colors.green
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label),
    );
  }
}

class CourseLevelsPage extends StatefulWidget {
  const CourseLevelsPage({
    super.key,
    required this.authToken,
    required this.course,
    required this.courseLevels,
    required this.allLevels,
  });

  final String authToken;
  final AdminCourse course;
  final List<AdminLevel> courseLevels;
  final List<AdminLevel> allLevels;

  @override
  State<CourseLevelsPage> createState() => _CourseLevelsPageState();
}

class _CourseLevelsPageState extends State<CourseLevelsPage> {
  late List<AdminLevel> levels;
  bool _isSaving = false;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    levels = List<AdminLevel>.from(widget.courseLevels);
  }

  String get _courseKey {
    return widget.course.courseId.isNotEmpty
        ? widget.course.courseId
        : widget.course.id;
  }

  List<AdminLevel> get _availableLevels {
    final selectedIds = levels.map((level) => level.id).toSet();
    final available = widget.allLevels
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
      authToken: widget.authToken,
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
      authToken: widget.authToken,
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
        authToken: widget.authToken,
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
                decoration: const InputDecoration(
                  labelText: 'Add Level',
                  border: OutlineInputBorder(),
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
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                ? const Center(child: Text('This course has no levels yet.'))
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
                                tooltip: 'Remove from course',
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
