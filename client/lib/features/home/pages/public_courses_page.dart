import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:flutter/material.dart';

class PublicCoursesPage extends StatefulWidget {
  const PublicCoursesPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<PublicCoursesPage> createState() => _PublicCoursesPageState();
}

class _PublicCoursesPageState extends State<PublicCoursesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_PublicCourse> _courses = const [];

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

    final result = await ApiService.getPublicCourses(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      setState(() {
        _courses = _parseList(result['data'])
            .map(_PublicCourse.fromJson)
            .where((course) => course.id.isNotEmpty)
            .toList();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = result['message']?.toString() ?? 'Failed to load courses';
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

  Future<void> _openCourse(_PublicCourse course) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _CourseLevelsPage(session: widget.session, course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const _ScrollableMessage(
                child: CircularProgressIndicator(),
              );
            }

            if (_errorMessage != null) {
              return _ScrollableMessage(
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

            if (_courses.isEmpty) {
              return const _ScrollableMessage(
                child: Text('No public courses are available yet.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.menu_book_outlined),
                    ),
                    title: Text(course.title),
                    subtitle: Text(
                      course.description.isEmpty
                          ? 'Open course levels'
                          : course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCourse(course),
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

class _CourseLevelsPage extends StatefulWidget {
  const _CourseLevelsPage({required this.session, required this.course});

  final AuthSession session;
  final _PublicCourse course;

  @override
  State<_CourseLevelsPage> createState() => _CourseLevelsPageState();
}

class _CourseLevelsPageState extends State<_CourseLevelsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SavedBuilderProject> _levels = const [];

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

    final result = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: widget.course.courseId.isNotEmpty
          ? widget.course.courseId
          : widget.course.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final levels =
          _parseList(result['data'])
              .map(SavedBuilderProject.fromJson)
              .where((level) => level.id.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final orderComparison = a.orderInCourse.compareTo(
                b.orderInCourse,
              );
              if (orderComparison != 0) {
                return orderComparison;
              }
              return a.title.compareTo(b.title);
            });

      setState(() {
        _levels = levels;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage =
          result['message']?.toString() ?? 'Failed to load course levels';
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

  Future<void> _openLevel(SavedBuilderProject level) async {
    final routeName = level.isTopView
        ? AppRoutes.topViewBuilder
        : level.isScratch
        ? AppRoutes.scratchBuilder
        : AppRoutes.builderPlay;
    final routeData = level.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
          )
        : level.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: level.id,
            initialTitle: level.title,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: RefreshIndicator(
        onRefresh: _loadLevels,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const _ScrollableMessage(
                child: CircularProgressIndicator(),
              );
            }

            if (_errorMessage != null) {
              return _ScrollableMessage(
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              );
            }

            if (_levels.isEmpty) {
              return const _ScrollableMessage(
                child: Text('No published levels are available yet.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _levels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final level = _levels[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(level.title),
                    subtitle: Text(
                      '${level.isTopView
                          ? 'Top View'
                          : level.isScratch
                          ? 'Scratch'
                          : 'Front View'} - ${level.difficulty}',
                    ),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () => _openLevel(level),
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

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
        Center(child: child),
      ],
    );
  }
}

class _PublicCourse {
  const _PublicCourse({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
  });

  final String id;
  final String courseId;
  final String title;
  final String description;

  factory _PublicCourse.fromJson(Map<String, dynamic> json) {
    return _PublicCourse(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      title:
          json['courseName']?.toString() ??
          json['title']?.toString() ??
          'Untitled Course',
      description: json['description']?.toString() ?? '',
    );
  }
}
