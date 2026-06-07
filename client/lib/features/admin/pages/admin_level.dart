import 'dart:convert';
import 'dart:typed_data';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
import 'package:client/features/admin/models/admin_level.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _AdminBuilderType { scratch, frontView, topView, fourthDemo }

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  static const double _adminLevelCoverAspectRatio = 16 / 9;

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
    await _createLevelWithMetadata();

    if (mounted) {
      _loadLevels();
    }
  }

  Future<void> _createLevelWithMetadata({String? courseId}) async {
    final builderType = await _chooseBuilderType(
      title: AppLanguage.of(context).t('createLevel'),
    );
    if (!mounted || builderType == null) {
      return;
    }

    switch (builderType) {
      case _AdminBuilderType.scratch:
        await Navigator.of(context).pushNamed(
          AppRoutes.scratchBuilder,
          arguments: ScratchBuilderRouteData(
            session: widget.session,
            useAdminLevelApi: true,
            initialCourseId: courseId,
          ),
        );
      case _AdminBuilderType.frontView:
        await Navigator.of(context).pushNamed(
          AppRoutes.builder,
          arguments: BuilderRouteData(
            session: widget.session,
            useAdminLevelApi: true,
            initialCourseId: courseId,
          ),
        );
      case _AdminBuilderType.topView:
        await Navigator.of(context).pushNamed(
          AppRoutes.topViewBuilder,
          arguments: TopViewBuilderRouteData(
            session: widget.session,
            useAdminLevelApi: true,
            initialCourseId: courseId,
          ),
        );
      case _AdminBuilderType.fourthDemo:
        await Navigator.of(context).pushNamed(
          AppRoutes.fourthDemoBuilder,
          arguments: FourthDemoBuilderRouteData(
            session: widget.session,
            initialCourseId: courseId,
          ),
        );
    }
  }

  Future<_AdminBuilderType?> _chooseBuilderType({required String title}) {
    final language = AppLanguage.of(context);
    return showDialog<_AdminBuilderType>(
      context: context,
      builder: (context) {
        return _AdminBuilderPickerDialog(
          title: title,
          subtitle: 'Choose the builder style for this admin level.',
          options: [
            _AdminBuilderCardData(
              type: _AdminBuilderType.frontView,
              title: language.t('frontViewBlockPuzzle'),
              subtitle: language.t('frontViewDescription'),
              icon: Icons.view_in_ar_rounded,
              color: const Color(0xFF58C4DD),
              accentColor: const Color(0xFFE4F9FD),
            ),
            _AdminBuilderCardData(
              type: _AdminBuilderType.topView,
              title: language.t('topViewCodingLevel'),
              subtitle: language.t('topViewDescription'),
              icon: Icons.grid_view_rounded,
              color: const Color(0xFF72C665),
              accentColor: const Color(0xFFEAF9E5),
            ),
            _AdminBuilderCardData(
              type: _AdminBuilderType.scratch,
              title: language.t('scratchBuilder'),
              subtitle: language.t('scratchBuilderDescription'),
              icon: Icons.extension_rounded,
              color: const Color(0xFFB98AF3),
              accentColor: const Color(0xFFF4ECFF),
            ),
            const _AdminBuilderCardData(
              type: _AdminBuilderType.fourthDemo,
              title: 'Game Builder',
              subtitle: 'Create a custom playable game world.',
              icon: Icons.sports_esports_rounded,
              color: Color(0xFFFF7C9B),
              accentColor: Color(0xFFFFEDF2),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openLevelBuilder(AdminLevel level) async {
    if (level.builderType == 'scratch') {
      await Navigator.of(context).pushNamed(
        AppRoutes.scratchBuilder,
        arguments: ScratchBuilderRouteData(
          session: widget.session,
          initialProjectId: level.id,
          useAdminLevelApi: true,
          initialTitle: level.title,
        ),
      );
    } else if (level.builderType == 'topView') {
      await Navigator.of(context).pushNamed(
        AppRoutes.topViewBuilder,
        arguments: TopViewBuilderRouteData(
          session: widget.session,
          initialProjectId: level.id,
          useAdminLevelApi: true,
          initialTitle: level.title,
        ),
      );
    } else if (level.builderType == 'fourthDemo') {
      await Navigator.of(context).pushNamed(
        AppRoutes.fourthDemoBuilder,
        arguments: FourthDemoBuilderRouteData(
          session: widget.session,
          initialProjectId: level.id,
          useAdminLevelApi: true,
          initialTitle: level.title,
        ),
      );
    } else {
      await Navigator.of(context).pushNamed(
        AppRoutes.builder,
        arguments: BuilderRouteData(
          session: widget.session,
          initialProjectId: level.id,
          useAdminLevelApi: true,
        ),
      );
    }

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
    final language = AppLanguage.of(context);
    if (!level.isCreatedByAdmin) {
      _showMessage('You cannot edit levels created by users.');
      return;
    }

    final titleController = TextEditingController(text: level.title);
    String difficulty = level.difficulty.toLowerCase();
    String status = level.status;
    String selectedCourseId = _courseDropdownValue(level.courseId) ?? '';
    String? coverImageBase64 = level.coverImageBase64;
    double coverFrameScale = level.coverFrameScale;
    double coverFrameOffsetX = level.coverFrameOffsetX;
    double coverFrameOffsetY = level.coverFrameOffsetY;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(language.t('editLevel')),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: language.t('levelTitle'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: difficulty,
                        decoration: InputDecoration(
                          labelText: language.t('difficulty'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'easy',
                            child: Text(language.t('easy')),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text(language.t('medium')),
                          ),
                          DropdownMenuItem(
                            value: 'hard',
                            child: Text(language.t('hard')),
                          ),
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
                        decoration: InputDecoration(
                          labelText: language.t('status'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'published',
                            child: Text(language.t('published')),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text(language.t('draft')),
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
                        decoration: InputDecoration(
                          labelText: language.t('courses'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(language.t('noCourse')),
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showFramedImageUploadDialog(
                            context: context,
                            title: 'Upload cover',
                            initialImageBase64: coverImageBase64,
                            initialScale: coverFrameScale,
                            initialOffsetX: coverFrameOffsetX,
                            initialOffsetY: coverFrameOffsetY,
                            aspectRatio: _adminLevelCoverAspectRatio,
                          );
                          if (result == null) {
                            return;
                          }
                          setDialogState(() {
                            coverImageBase64 = result.imageBase64;
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
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {'action': 'openBuilder'});
                  },
                  icon: const Icon(Icons.extension_outlined),
                  label: Text(language.t('editLayout')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(language.t('cancel')),
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
                      'coverImageBase64': coverImageBase64,
                      'coverFrameScale': coverFrameScale,
                      'coverFrameOffsetX': coverFrameOffsetX,
                      'coverFrameOffsetY': coverFrameOffsetY,
                    });
                  },
                  child: Text(language.t('save')),
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
    final language = AppLanguage.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('deleteLevel')),
          content: Text(
            'Are you sure you want to delete "${level.title}"?\n\nThis action cannot be undone.',
          ),
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
    final language = AppLanguage.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('publishUserLevel')),
          content: Text('Publish "${level.title}" so users can play it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(language.t('publish')),
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
              onPressed: _loadLevels,
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
                language.t('levelsManagement'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: language.t('refreshLevels'),
                onPressed: _loadLevels,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _createLevel,
                icon: const Icon(Icons.add),
                label: Text(language.t('createLevel')),
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

class _AdminBuilderCardData {
  final _AdminBuilderType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accentColor;

  const _AdminBuilderCardData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accentColor,
  });
}

class _AdminBuilderPickerDialog extends StatelessWidget {
  const _AdminBuilderPickerDialog({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String title;
  final String subtitle;
  final List<_AdminBuilderCardData> options;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 760;

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
                        Icons.add_circle_outline_rounded,
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
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2C2A4A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
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
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: options.map((option) {
                    return _AdminBuilderChoiceCard(
                      data: option,
                      width: isCompact ? double.infinity : 248,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBuilderChoiceCard extends StatefulWidget {
  const _AdminBuilderChoiceCard({required this.data, required this.width});

  final _AdminBuilderCardData data;
  final double width;

  @override
  State<_AdminBuilderChoiceCard> createState() =>
      _AdminBuilderChoiceCardState();
}

class _AdminBuilderChoiceCardState extends State<_AdminBuilderChoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pop(context, data.type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: data.accentColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? data.color : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: _hovered ? 0.26 : 0.14),
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
                  color: data.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2A4A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.subtitle,
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
                    'Open Builder',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: data.color,
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
    final language = AppLanguage.of(context);

    if (levels.isEmpty) {
      return Center(child: Text(language.t('noLevelsFound')));
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

  Uint8List? _safeDecodeCover(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

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

  String _statusLabel(BuildContext context) {
    final language = AppLanguage.of(context);
    switch (level.status) {
      case 'published':
        return language.t('published');
      case 'draft':
        return language.t('draft');
      case 'userCreated':
        return language.t('userCreated');
      default:
        return level.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
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
            child: level.coverImageBase64 != null
                ? FramedImagePreview(
                    bytes: _safeDecodeCover(level.coverImageBase64),
                    scale: level.coverFrameScale,
                    offsetX: level.coverFrameOffsetX,
                    offsetY: level.coverFrameOffsetY,
                    placeholderIcon: Icons.image_outlined,
                  )
                : level.previewImageUrl == null
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
                    '${language.t('creator')}: ${level.creatorName}',
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
                          _statusLabel(context),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          level.builderType == 'topView'
                              ? language.t('topView')
                              : level.builderType == 'scratch'
                              ? language.t('scratch')
                              : level.builderType == 'fourthDemo'
                              ? 'Fourth Demo'
                              : language.t('frontView'),
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
                                label: Text(language.t('review')),
                              )
                            : OutlinedButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(language.t('edit')),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(language.t('delete')),
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
