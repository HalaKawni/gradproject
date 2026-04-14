import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/saved_builder_project.dart';

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
        final normalizedStatusFilter = widget.statusFilter?.trim().toLowerCase();
        final loadedProjects = items
            .whereType<Map>()
            .map(
              (item) => SavedBuilderProject.fromJson(
                Map<String, dynamic>.from(item),
              ),
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
    final parts = <String>[
      'Status: ${project.status}',
    ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                  Center(
                    child: CircularProgressIndicator(),
                  ),
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
                  Text(
                    widget.emptyMessage,
                    textAlign: TextAlign.center,
                  ),
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

                return Card(
                  child: ListTile(
                    title: Text(project.title),
                    subtitle: Text(_buildSubtitle(project)),
                    trailing: Icon(
                      widget.openProjectOnTap
                          ? Icons.chevron_right
                          : widget.playProjectOnTap
                          ? Icons.play_circle_outline
                          : Icons.public_outlined,
                    ),
                    onTap: () => _handleProjectPressed(project),
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
