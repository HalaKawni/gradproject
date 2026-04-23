import 'package:flutter/material.dart';

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

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key});

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  final List<AdminLevel> allLevels = [
    const AdminLevel(
      id: '1',
      title: 'Forest Escape',
      creatorName: 'Admin Nasser',
      isCreatedByAdmin: true,
      difficulty: 'Easy',
      status: 'published',
    ),
    const AdminLevel(
      id: '2',
      title: 'Logic Bridge',
      creatorName: 'Admin Sarah',
      isCreatedByAdmin: true,
      difficulty: 'Medium',
      status: 'published',
    ),
    const AdminLevel(
      id: '3',
      title: 'Desert Puzzle',
      creatorName: 'Admin Nasser',
      isCreatedByAdmin: true,
      difficulty: 'Hard',
      status: 'draft',
    ),
    const AdminLevel(
      id: '4',
      title: 'My Custom Maze',
      creatorName: 'User Ahmad',
      isCreatedByAdmin: false,
      difficulty: 'Medium',
      status: 'userCreated',
    ),
    const AdminLevel(
      id: '5',
      title: 'Speed Runner',
      creatorName: 'User Lina',
      isCreatedByAdmin: false,
      difficulty: 'Hard',
      status: 'userCreated',
    ),
  ];

  List<AdminLevel> _levelsByStatus(String status) {
    return allLevels.where((level) => level.status == status).toList();
  }

  void _createLevel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Level clicked')),
    );
  }

  void _editLevel(AdminLevel level) {
    if (!level.isCreatedByAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot edit levels created by users.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit "${level.title}"')),
    );
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

    if (confirmed == true) {
      setState(() {
        allLevels.removeWhere((item) => item.id == level.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${level.title}" deleted')),
      );
    }
  }

  void _reviewLevel(AdminLevel level) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Review "${level.title}"')),
  );

  // Later:
  // open the level in play/test mode for admin
}

  @override
  Widget build(BuildContext context) {
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
                ),
                _LevelsGrid(
                  levels: _levelsByStatus('draft'),
                  onEdit: _editLevel,
                  onDelete: _deleteLevel,
                  onReview: _reviewLevel,
                ),
                _LevelsGrid(
                  levels: _levelsByStatus('userCreated'),
                  onEdit: _editLevel,
                  onDelete: _deleteLevel,
                  onReview: _reviewLevel,
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
  });

  final List<AdminLevel> levels;
  final void Function(AdminLevel level) onEdit;
  final void Function(AdminLevel level) onDelete;
  final void Function(AdminLevel level) onReview;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return const Center(
        child: Text('No levels found in this section.'),
      );
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

        return GridView.builder(
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
            child: const Center(
              child: Icon(Icons.image_outlined, size: 32),
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
                          color: _difficultyColor(context).withOpacity(0.12),
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
                          color: Colors.blue.withOpacity(0.08),
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
                                icon: const Icon(Icons.play_arrow_outlined, size: 18),
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