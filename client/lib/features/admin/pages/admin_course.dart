import 'package:flutter/material.dart';

class AdminCourse {
  final String id;
  String title;
  bool isPublic;

  AdminCourse({
    required this.id,
    required this.title,
    required this.isPublic,
  });
}

class AdminLevel {
  final String id;
  final String title;
  final String creatorName;
  final bool isCreatedByAdmin;
  final String difficulty;
  final String status; // published, draft, userCreated
  final String? previewImageUrl;

  const AdminLevel({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.isCreatedByAdmin,
    required this.difficulty,
    required this.status,
    this.previewImageUrl,
  });
}

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final List<AdminCourse> courses = [
    AdminCourse(id: '1', title: 'Flutter Basics', isPublic: true),
    AdminCourse(id: '2', title: 'Game Logic', isPublic: false),
    AdminCourse(id: '3', title: 'Puzzle Thinking', isPublic: true),
  ];

  final Map<String, List<AdminLevel>> courseLevels = {
    '1': [
      const AdminLevel(
        id: 'l1',
        title: 'Introduction',
        creatorName: 'Admin Nasser',
        isCreatedByAdmin: true,
        difficulty: 'Easy',
        status: 'published',
      ),
      const AdminLevel(
        id: 'l2',
        title: 'Variables',
        creatorName: 'Admin Sarah',
        isCreatedByAdmin: true,
        difficulty: 'Easy',
        status: 'draft',
      ),
      const AdminLevel(
        id: 'l3',
        title: 'Widgets',
        creatorName: 'Admin Nasser',
        isCreatedByAdmin: true,
        difficulty: 'Medium',
        status: 'published',
      ),
    ],
    '2': [
      const AdminLevel(
        id: 'l4',
        title: 'Game Loop',
        creatorName: 'Admin Sarah',
        isCreatedByAdmin: true,
        difficulty: 'Medium',
        status: 'published',
      ),
      const AdminLevel(
        id: 'l5',
        title: 'Collision',
        creatorName: 'Admin Nasser',
        isCreatedByAdmin: true,
        difficulty: 'Hard',
        status: 'draft',
      ),
    ],
    '3': [
      const AdminLevel(
        id: 'l6',
        title: 'Patterns',
        creatorName: 'Admin Nasser',
        isCreatedByAdmin: true,
        difficulty: 'Easy',
        status: 'published',
      ),
      const AdminLevel(
        id: 'l7',
        title: 'Sequences',
        creatorName: 'Admin Sarah',
        isCreatedByAdmin: true,
        difficulty: 'Medium',
        status: 'published',
      ),
    ],
  };

  Future<void> _showCreateCourseDialog() async {
    final controller = TextEditingController();
    bool isPublic = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Course'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public'),
                    subtitle: Text(
                      isPublic ? 'Visible to users' : 'Hidden from users',
                    ),
                    value: isPublic,
                    onChanged: (value) {
                      setDialogState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    final newCourse = AdminCourse(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: controller.text.trim(),
                      isPublic: isPublic,
                    );

                    setState(() {
                      courses.add(newCourse);
                      courseLevels[newCourse.id] = [];
                    });

                    Navigator.pop(context, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully')),
      );
    }
  }

  Future<void> _showEditCourseDialog(AdminCourse course) async {
    final controller = TextEditingController(text: course.title);
    bool isPublic = course.isPublic;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Course'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public'),
                    subtitle: Text(
                      isPublic ? 'Visible to users' : 'Hidden from users',
                    ),
                    value: isPublic,
                    onChanged: (value) {
                      setDialogState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      course.title = controller.text.trim();
                      course.isPublic = isPublic;
                    });

                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course updated successfully')),
      );
    }
  }

  Future<void> _deleteCourse(AdminCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete "${course.title}"?',
          ),
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

    if (confirmed == true) {
      setState(() {
        courses.removeWhere((c) => c.id == course.id);
        courseLevels.remove(course.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${course.title}" deleted')),
        );
      }
    }
  }

  void _openManageLevels(AdminCourse course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseLevelsPage(
          course: course,
          levels: List<AdminLevel>.from(courseLevels[course.id] ?? []),
          onSave: (updatedLevels) {
            setState(() {
              courseLevels[course.id] = updatedLevels;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            ElevatedButton.icon(
              onPressed: _showCreateCourseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Course'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: courses.isEmpty
              ? const Center(child: Text('No courses yet.'))
              : ListView.separated(
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final levelsCount = courseLevels[course.id]?.length ?? 0;

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
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Levels: $levelsCount'),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: course.isPublic
                                          ? Colors.green.withOpacity(0.12)
                                          : Colors.grey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      course.isPublic ? 'Public' : 'Private',
                                    ),
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
                                  onPressed: () => _showEditCourseDialog(course),
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
      ],
    );
  }
}

class CourseLevelsPage extends StatefulWidget {
  const CourseLevelsPage({
    super.key,
    required this.course,
    required this.levels,
    required this.onSave,
  });

  final AdminCourse course;
  final List<AdminLevel> levels;
  final void Function(List<AdminLevel> updatedLevels) onSave;

  @override
  State<CourseLevelsPage> createState() => _CourseLevelsPageState();
}

class _CourseLevelsPageState extends State<CourseLevelsPage> {
  late List<AdminLevel> levels;

  @override
  void initState() {
    super.initState();
    levels = List<AdminLevel>.from(widget.levels);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = levels.removeAt(oldIndex);
      levels.insert(newIndex, item);
    });
  }

  void _saveChanges() {
    widget.onSave(levels);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Level order saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.title} - Levels'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saveChanges,
              child: const Text('Save Order'),
            ),
          ),
        ],
      ),
      body: levels.isEmpty
          ? const Center(
              child: Text('This course has no levels yet.'),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: levels.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final level = levels[index];

                return Card(
                  key: ValueKey(level.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(level.title),
                    subtitle: Text(
                      'Difficulty: ${level.difficulty} • Creator: ${level.creatorName}',
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
    );
  }
}