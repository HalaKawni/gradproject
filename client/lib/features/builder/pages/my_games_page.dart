import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/saved_builder_project.dart';

enum _GameCreatorOption { frontView, topView }

class MyGamesPage extends StatefulWidget {
  final AuthSession session;
  final String title;
  final String emptyMessage;
  final String? statusFilter;
  final bool openProjectOnTap;
  final bool playProjectOnTap;
  final String pendingTapMessage;

  const MyGamesPage({
    super.key,
    required this.session,
    this.title = 'My Games',
    this.emptyMessage = 'No saved games yet.',
    this.statusFilter,
    this.openProjectOnTap = true,
    this.playProjectOnTap = false,
    this.pendingTapMessage = 'Opening published games will be connected next.',
  });

  @override
  State<MyGamesPage> createState() => _MyGamesPageState();
}

class _MyGamesPageState extends State<MyGamesPage> {
  bool isLoading = true;
  String? errorMessage;
  List<SavedBuilderProject> projects = const [];
  final Set<String> deletingProjectIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getAllBuilderProjects(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final rawData = result['data'];
        final items = rawData is List ? rawData : const [];
        final normalizedStatusFilter = widget.statusFilter
            ?.trim()
            .toLowerCase();
        final loadedProjects = items
            .whereType<Map>()
            .map(
              (item) =>
                  SavedBuilderProject.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((project) => project.id.isNotEmpty)
            .where((project) {
              if (normalizedStatusFilter == null ||
                  normalizedStatusFilter.isEmpty) {
                return true;
              }

              return project.status.trim().toLowerCase() ==
                  normalizedStatusFilter;
            })
            .toList();

        setState(() {
          projects = loadedProjects;
        });
      } else {
        setState(() {
          errorMessage =
              result['message']?.toString() ?? 'Failed to load games.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load games: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openProject(SavedBuilderProject project) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(
        session: widget.session,
        initialProjectId: project.id,
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  Future<void> _playProject(SavedBuilderProject project) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.builderPlay,
      arguments: BuilderPlayRouteData(
        session: widget.session,
        projectId: project.id,
        initialTitle: project.title,
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  Future<void> _confirmDeleteProject(SavedBuilderProject project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isPublished = project.status.trim().toLowerCase() == 'published';

        return AlertDialog(
          title: const Text('Delete game?'),
          content: Text(
            isPublished
                ? 'Are you sure you want to delete "${project.title}"? This game is published, so it will become unavailable for other users too.'
                : 'Are you sure you want to delete "${project.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _deleteProject(project);
  }

  Future<void> _deleteProject(SavedBuilderProject project) async {
    if (deletingProjectIds.contains(project.id)) {
      return;
    }

    setState(() {
      deletingProjectIds.add(project.id);
    });

    try {
      final result = await ApiService.deleteBuilderProject(
        authToken: widget.session.token,
        projectId: project.id,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        setState(() {
          projects = projects.where((item) => item.id != project.id).toList();
        });

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Game deleted successfully.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Failed to delete game.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete game: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          deletingProjectIds.remove(project.id);
        });
      }
    }
  }

  void _handleProjectPressed(SavedBuilderProject project) {
    if (widget.openProjectOnTap) {
      _openProject(project);
      return;
    }

    if (widget.playProjectOnTap) {
      _playProject(project);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.pendingTapMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _buildSubtitle(SavedBuilderProject project) {
    final parts = <String>['Status: ${project.status}'];

    if (project.updatedAt != null) {
      final localTime = project.updatedAt!.toLocal();
      parts.add(
        'Updated ${localTime.year}-${_twoDigits(localTime.month)}-${_twoDigits(localTime.day)} '
        '${_twoDigits(localTime.hour)}:${_twoDigits(localTime.minute)}',
      );
    }

    if (project.description.isNotEmpty) {
      parts.add(project.description);
    }

    return parts.join(' | ');
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  void _openFrontViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(session: widget.session),
    );
  }

  void _openTopViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.topViewBuilder,
      arguments: TopViewBuilderRouteData(session: widget.session),
    );
  }

  Future<void> _showCreateGameDialog(BuildContext context) async {
    final selection = await showDialog<_GameCreatorOption>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Game'),
          content: const Text('Choose the type of game creator to open.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.frontView);
              },
              child: const Text('Front View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.topView);
              },
              child: const Text('Top View'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || selection == null) {
      return;
    }

    switch (selection) {
      case _GameCreatorOption.frontView:
        _openFrontViewBuilder(context);
      case _GameCreatorOption.topView:
        _openTopViewBuilder(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 46),
            child: TextButton.icon(
              onPressed: () => _showCreateGameDialog(context),
              // icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create New Game',
                style: TextStyle(color: Colors.black),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // 👈 your color
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (errorMessage != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProjects,
                    child: const Text('Try Again'),
                  ),
                ],
              );
            }

            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(widget.emptyMessage, textAlign: TextAlign.center),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = projects[index];
                final isDeleting = deletingProjectIds.contains(project.id);

                return Card(
                  child: ListTile(
                    title: Text(project.title),
                    subtitle: Text(_buildSubtitle(project)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.openProjectOnTap
                              ? Icons.chevron_right
                              : widget.playProjectOnTap
                              ? Icons.play_circle_outline
                              : Icons.public_outlined,
                        ),
                        const SizedBox(width: 4),
                        if (isDeleting)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Delete game',
                            onPressed: () => _confirmDeleteProject(project),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    onTap: isDeleting
                        ? null
                        : () => _handleProjectPressed(project),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
