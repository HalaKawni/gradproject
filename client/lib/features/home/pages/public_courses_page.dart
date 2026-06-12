import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/aicourse/ai_hoot_conditional.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/datagame/data_course_page.dart';
import 'package:client/digitalgame/digital_literacy_page.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:client/features/home/models/legacy_public_course_catalog.dart';
import 'package:client/features/home/services/course_resume_service.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'world_map_page.dart';

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
  String? _openingCourseId;
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.locale.languageCode;
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
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
        _courses = _mergeLegacyPublicCourseFallbacks(
          _parseList(result['data'])
            .map(_PublicCourse.fromJson)
            .where((course) => course.id.isNotEmpty)
            .toList(),
        );
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
    if (_openingCourseId != null) {
      return;
    }
    setState(() {
      _openingCourseId = course.id;
    });

    try {
      await ApiService.trackPublicCourseEvent(
        authToken: widget.session.token,
        courseId: _courseLookupId(course),
        eventType: 'click',
      );
      if (course.isLegacyPublicCourse) {
        await ApiService.trackPublicCourseEvent(
          authToken: widget.session.token,
          courseId: _courseLookupId(course),
          eventType: 'level_play',
        );
        if (!mounted) {
          return;
        }
        await _openLegacyCourse(course);
        return;
      }
      final levels = await _loadCourseLevels(course);
      if (!mounted) {
        return;
      }
      if (levels.isEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                _CourseLevelsPage(session: widget.session, course: course),
          ),
        );
        return;
      }

      final progress = await _loadCourseProgress(course);
      if (!mounted) {
        return;
      }
      final nextLevel = _nextLevelForProgress(levels, progress);
      await _openLevel(nextLevel, course: course);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open course: $error')));
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _CourseLevelsPage(session: widget.session, course: course),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingCourseId = null;
        });
      }
    }
  }

  List<_PublicCourse> _mergeLegacyPublicCourseFallbacks(
    List<_PublicCourse> courses,
  ) {
    final merged = List<_PublicCourse>.from(courses);
    final seenCourseKeys = merged
        .map((course) => course.courseId.trim())
        .where((key) => key.isNotEmpty)
        .toSet();

    for (final metadata in legacyPublicCourseCatalog.values) {
      if (seenCourseKeys.contains(metadata.courseId)) {
        continue;
      }
      merged.add(_PublicCourse.fromLegacyMetadata(metadata));
    }

    return merged;
  }

  Future<void> _openLegacyCourse(_PublicCourse course) async {
    final page = _legacyCoursePage(course.legacyPageKey);
    if (!mounted || page == null) {
      return;
    }

    await CourseResumeService.saveLegacyCourse(
      userId: widget.session.user.id,
      courseLookupId: _courseLookupId(course),
      legacyPageKey: course.legacyPageKey,
    );

    final routeName = switch (course.legacyPageKey) {
      'code_monkey_jr' => 'code_monkey_jr_hub',
      'data_is_everywhere' => 'data_course_hub',
      'coding_chatbots' => 'ai_hoot_hub',
      _ => 'digital_literacy_hub',
    };

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  Widget? _legacyCoursePage(String legacyPageKey) {
    switch (legacyPageKey) {
      case 'code_monkey_jr':
        return const WorldMapPage();
      case 'digital_literacy':
        return const DigitalLiteracyPage();
      case 'data_is_everywhere':
        return const DataCoursePage();
      case 'coding_chatbots':
        return const Directionality(
          textDirection: ui.TextDirection.ltr,
          child: CodeMonkeyScratchPage(),
        );
      default:
        return null;
    }
  }

  Future<List<SavedBuilderProject>> _loadCourseLevels(
    _PublicCourse course,
  ) async {
    final result = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: _courseLookupId(course),
    );
    if (result['success'] != true) {
      throw result['message']?.toString() ?? 'Failed to load course levels';
    }
    return _parseList(result['data'])
        .map(SavedBuilderProject.fromJson)
        .where((level) => level.id.isNotEmpty)
        .toList()
      ..sort(_compareLevels);
  }

  Future<_CourseProgress> _loadCourseProgress(_PublicCourse course) async {
    final result = await ApiService.getPublicCourseProgress(
      authToken: widget.session.token,
      courseId: _courseLookupId(course),
    );
    if (result['success'] != true) {
      return const _CourseProgress();
    }
    final data = result['data'];
    return _CourseProgress.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  SavedBuilderProject _nextLevelForProgress(
    List<SavedBuilderProject> levels,
    _CourseProgress progress,
  ) {
    final lastOrder = progress.lastCompletedOrderInCourse;
    if (lastOrder <= 0 && progress.completedLevelIds.isEmpty) {
      return levels.first;
    }
    if (lastOrder <= 0) {
      return levels.firstWhere(
        (level) => !progress.completedLevelIds.contains(level.id),
        orElse: () => levels.last,
      );
    }

    return levels.firstWhere(
      (level) => level.orderInCourse > lastOrder,
      orElse: () => levels.last,
    );
  }

  Future<void> _openLevel(
    SavedBuilderProject level, {
    required _PublicCourse course,
  }) async {
    await ApiService.trackPublicCourseEvent(
      authToken: widget.session.token,
      courseId: _courseLookupId(course),
      eventType: 'level_play',
    );
    await CourseResumeService.savePublicCourse(
      userId: widget.session.user.id,
      courseLookupId: _courseLookupId(course),
      levelId: level.id,
    );
    if (!mounted) {
      return;
    }
    final routeName = level.isTopView
        ? AppRoutes.topViewBuilder
        : level.isScratch
        ? AppRoutes.scratchBuilder
        : level.isFourthDemo
        ? AppRoutes.fourthDemoBuilder
        : AppRoutes.builderPlay;
    final routeData = level.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId(course),
            courseProgressLevelId: level.id,
          )
        : level.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId(course),
            courseProgressLevelId: level.id,
          )
        : level.isFourthDemo
        ? FourthDemoBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId(course),
            courseProgressLevelId: level.id,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: level.id,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId(course),
            courseProgressLevelId: level.id,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);
  }

  int _compareLevels(SavedBuilderProject a, SavedBuilderProject b) {
    final orderComparison = a.orderInCourse.compareTo(b.orderInCourse);
    if (orderComparison != 0) {
      return orderComparison;
    }
    return a.title.compareTo(b.title);
  }

  String _courseLookupId(_PublicCourse course) {
    return course.courseId.isNotEmpty ? course.courseId : course.id;
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
                final isOpening = _openingCourseId == course.id;
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      height: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: course.imageBase64 == null
                            ? Image.asset(
                                course.imagePath,
                                fit: BoxFit.cover,
                              )
                            : FramedImagePreview(
                                bytes: _safeDecodeBase64(course.imageBase64),
                                scale: course.coverFrameScale,
                                offsetX: course.coverFrameOffsetX,
                                offsetY: course.coverFrameOffsetY,
                                placeholderIcon: Icons.menu_book_outlined,
                              ),
                      ),
                    ),
                    title: Text(course.title),
                    subtitle: Text(
                      course.description.isEmpty
                          ? 'Open course levels'
                          : course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isOpening
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    onTap: isOpening ? null : () => _openCourse(course),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
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
  String? _lastLocaleCode;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = context.locale.languageCode;
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
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
    await ApiService.trackPublicCourseEvent(
      authToken: widget.session.token,
      courseId: _courseLookupId,
      eventType: 'level_play',
    );
    await CourseResumeService.savePublicCourse(
      userId: widget.session.user.id,
      courseLookupId: _courseLookupId,
      levelId: level.id,
    );
    if (!mounted) {
      return;
    }
    final routeName = level.isTopView
        ? AppRoutes.topViewBuilder
        : level.isScratch
        ? AppRoutes.scratchBuilder
        : level.isFourthDemo
        ? AppRoutes.fourthDemoBuilder
        : AppRoutes.builderPlay;
    final routeData = level.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : level.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : level.isFourthDemo
        ? FourthDemoBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: level.id,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);
  }

  String get _courseLookupId {
    return widget.course.courseId.isNotEmpty
        ? widget.course.courseId
        : widget.course.id;
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
    required this.courseDeliveryType,
    required this.legacyPageKey,
    required this.title,
    required this.description,
    required this.imagePath,
    this.imageBase64,
    this.coverFrameScale = 1,
    this.coverFrameOffsetX = 0,
    this.coverFrameOffsetY = 0,
  });

  final String id;
  final String courseId;
  final String courseDeliveryType;
  final String legacyPageKey;
  final String title;
  final String description;
  final String imagePath;
  final String? imageBase64;
  final double coverFrameScale;
  final double coverFrameOffsetX;
  final double coverFrameOffsetY;

  bool get isLegacyPublicCourse => courseDeliveryType == 'legacy_page';

  factory _PublicCourse.fromJson(Map<String, dynamic> json) {
    final courseKey = json['courseId']?.toString() ?? '';
    final legacyMetadata = legacyPublicCourseMetadataForCourseId(courseKey);
    return _PublicCourse(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      courseId: courseKey,
      courseDeliveryType:
          json['courseDeliveryType']?.toString() ??
          (legacyMetadata != null ? 'legacy_page' : 'builder_levels'),
      legacyPageKey:
          json['legacyPageKey']?.toString() ??
          legacyMetadata?.legacyPageKey ??
          '',
      title:
          json['courseName']?.toString() ??
          json['title']?.toString() ??
          legacyMetadata?.title ??
          'Untitled Course',
      description:
          json['description']?.toString() ??
          legacyMetadata?.description ??
          '',
      imagePath: legacyMetadata?.imagePath ?? 'assets/images/course1.jpg',
      imageBase64: json['courseImageBase64']?.toString(),
      coverFrameScale: _readDouble(json['coverFrameScale'], fallback: 1),
      coverFrameOffsetX: _readDouble(json['coverFrameOffsetX']),
      coverFrameOffsetY: _readDouble(json['coverFrameOffsetY']),
    );
  }

  factory _PublicCourse.fromLegacyMetadata(
    LegacyPublicCourseMetadata metadata,
  ) {
    return _PublicCourse(
      id: metadata.courseId,
      courseId: metadata.courseId,
      courseDeliveryType: 'legacy_page',
      legacyPageKey: metadata.legacyPageKey,
      title: metadata.title,
      description: metadata.description,
      imagePath: metadata.imagePath,
    );
  }

  static double _readDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _CourseProgress {
  const _CourseProgress({
    this.completedLevelIds = const <String>{},
    this.lastCompletedOrderInCourse = 0,
  });

  final Set<String> completedLevelIds;
  final int lastCompletedOrderInCourse;

  factory _CourseProgress.fromJson(Map<String, dynamic> json) {
    final completedLevels = json['completedLevels'] is List
        ? json['completedLevels'] as List
        : const [];
    return _CourseProgress(
      completedLevelIds: completedLevels
          .whereType<Map>()
          .map((item) => item['levelId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet(),
      lastCompletedOrderInCourse: _readInt(json['lastCompletedOrderInCourse']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
