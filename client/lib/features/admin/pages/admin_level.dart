import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
import 'package:client/features/admin/models/admin_level.dart';
import 'package:flutter/material.dart';

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminLevel> _levels = [];
  List<AdminCourse> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final levelsResult = await ApiService.getAdminLevels(
      authToken: widget.session.token,
    );
    final coursesResult = await ApiService.getAdminCourses(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (levelsResult['success'] == true && coursesResult['success'] == true) {
      setState(() {
        _levels = _parseList(
          levelsResult['data'],
        ).map(AdminLevel.fromJson).toList();
        _courses = _parseList(
          coursesResult['data'],
        ).map(AdminCourse.fromJson).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            levelsResult['message']?.toString() ??
            coursesResult['message']?.toString() ??
            'Failed to load levels';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<AdminLevel> _levelsByStatus(String status) {
    return _levels.where((level) => level.status == status).toList();
  }

  Future<void> _createLevel() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(session: widget.session),
    );

    if (mounted) {
      _loadLevels();
    }
  }

  Future<void> _openLevelBuilder(AdminLevel level) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(
        session: widget.session,
        initialProjectId: level.id,
        useAdminLevelApi: true,
      ),
    );

    if (mounted) {
      _loadLevels();
    }
  }

  String _courseKey(AdminCourse course) {
    return course.courseId.isNotEmpty ? course.courseId : course.id;
  }

  String? _courseDropdownValue(String courseId) {
    if (courseId.isEmpty) {
      return '';
    }

    for (final course in _courses) {
      if (course.id == courseId || course.courseId == courseId) {
        return _courseKey(course);
      }
    }

    return courseId;
  }

  Future<void> _editLevel(AdminLevel level) async {
    if (!level.isCreatedByAdmin) {
      _showMessage('You cannot edit levels created by users.');
      return;
    }

    final titleController = TextEditingController(text: level.title);
    String difficulty = level.difficulty.toLowerCase();
    String status = level.status;
    String selectedCourseId = _courseDropdownValue(level.courseId) ?? '';

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Level'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Level Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            difficulty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Published'),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            status = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourseId,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('No course'),
                          ),
                          ..._courses.map((course) {
                            return DropdownMenuItem(
                              value: _courseKey(course),
                              child: Text(course.title),
                            );
                          }),
                          if (selectedCourseId.isNotEmpty &&
                              !_courses.any(
                                (course) =>
                                    _courseKey(course) == selectedCourseId,
                              ))
                            DropdownMenuItem(
                              value: selectedCourseId,
                              child: Text('Current: $selectedCourseId'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            selectedCourseId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {'action': 'openBuilder'});
                  },
                  icon: const Icon(Icons.extension_outlined),
                  label: const Text('Edit Layout'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, {
                      'title': title,
                      'difficulty': difficulty,
                      'status': status,
                      'courseId': selectedCourseId,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();

    if (payload == null) {
      return;
    }

    if (payload['action'] == 'openBuilder') {
      await _openLevelBuilder(level);
      return;
    }

    final result = await ApiService.updateAdminLevel(
      authToken: widget.session.token,
      levelId: level.id,
      levelJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadLevels();
      _showMessage('Level updated successfully');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to update level');
    }
  }

  Future<void> _deleteLevel(AdminLevel level) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Level'),
          content: Text(
            'Are you sure you want to delete "${level.title}"?\n\nThis action cannot be undone.',
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

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.deleteAdminLevel(
      authToken: widget.session.token,
      levelId: level.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadLevels();
      _showMessage('"${level.title}" deleted');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to delete level');
    }
  }

  Future<void> _reviewLevel(AdminLevel level) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Publish User Level'),
          content: Text('Publish "${level.title}" so users can play it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.updateAdminLevel(
      authToken: widget.session.token,
      levelId: level.id,
      levelJson: {
        'status': 'published',
        'reviewStatus': 'approved',
        'approvedBy': widget.session.user.id,
      },
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadLevels();
      _showMessage('"${level.title}" published');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to publish level');
    }
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
              onPressed: _loadLevels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
                'Levels Management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh levels',
                onPressed: _loadLevels,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _createLevel,
                icon: const Icon(Icons.add),
                label: const Text('Create Level'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TabBar(
            tabs: [
              Tab(text: 'Published'),
              Tab(text: 'Drafts'),
              Tab(text: 'User Created'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _LevelsGrid(
                  levels: _levelsByStatus('published'),
                  onEdit: _editLevel,
                  onDelete: _deleteLevel,
                  onReview: _reviewLevel,
                  onRefresh: _loadLevels,
                ),
                _LevelsGrid(
                  levels: _levelsByStatus('draft'),
                  onEdit: _editLevel,
                  onDelete: _deleteLevel,
                  onReview: _reviewLevel,
                  onRefresh: _loadLevels,
                ),
                _LevelsGrid(
                  levels: _levelsByStatus('userCreated'),
                  onEdit: _editLevel,
                  onDelete: _deleteLevel,
                  onReview: _reviewLevel,
                  onRefresh: _loadLevels,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelsGrid extends StatelessWidget {
  const _LevelsGrid({
    required this.levels,
    required this.onEdit,
    required this.onDelete,
    required this.onReview,
    required this.onRefresh,
  });

  final List<AdminLevel> levels;
  final void Function(AdminLevel level) onEdit;
  final void Function(AdminLevel level) onDelete;
  final void Function(AdminLevel level) onReview;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return const Center(child: Text('No levels found in this section.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;

        if (constraints.maxWidth >= 1600) {
          crossAxisCount = 5;
        } else if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            itemCount: levels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final level = levels[index];
              return _LevelCard(
                level: level,
                onEdit: () => onEdit(level),
                onDelete: () => onDelete(level),
                onReview: () => onReview(level),
              );
            },
          ),
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.onEdit,
    required this.onDelete,
    required this.onReview,
  });

  final AdminLevel level;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  Color _difficultyColor(BuildContext context) {
    switch (level.difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel() {
    switch (level.status) {
      case 'published':
        return 'Published';
      case 'draft':
        return 'Draft';
      case 'userCreated':
        return 'User Created';
      default:
        return level.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUserCreated = !level.isCreatedByAdmin;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: level.previewImageUrl == null
                ? const Center(child: Icon(Icons.image_outlined, size: 32))
                : Image.network(
                    level.previewImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const Center(
                        child: Icon(Icons.image_outlined, size: 32),
                      );
                    },
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Creator: ${level.creatorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _difficultyColor(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          level.difficulty,
                          style: TextStyle(
                            color: _difficultyColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: isUserCreated
                            ? OutlinedButton.icon(
                                onPressed: onReview,
                                icon: const Icon(
                                  Icons.verified_outlined,
                                  size: 18,
                                ),
                                label: const Text('Review'),
                              )
                            : OutlinedButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
