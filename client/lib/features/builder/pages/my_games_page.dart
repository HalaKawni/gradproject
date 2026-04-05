import 'package:flutter/material.dart';

import '../../../models/auth_session.dart';
import '../../../services/api_service.dart';
import '../models/saved_builder_project.dart';
import 'builder_page.dart';

class MyGamesPage extends StatefulWidget {
  final AuthSession session;

  const MyGamesPage({
    super.key,
    required this.session,
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

        setState(() {
          projects = items
              .whereType<Map>()
              .map(
                (item) => SavedBuilderProject.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((project) => project.id.isNotEmpty)
              .toList();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuilderPage(
          session: widget.session,
          initialProjectId: project.id,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProjects();
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
        title: const Text('My Games'),
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
                children: const [
                  Text(
                    'No saved games yet.',
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openProject(project),
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
