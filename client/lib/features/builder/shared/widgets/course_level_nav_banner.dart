import 'dart:async';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:client/features/home/services/course_resume_service.dart';
import 'package:flutter/material.dart';

class CourseLevelNavBanner extends StatefulWidget {
  final AuthSession session;
  final String? courseId;
  final String? currentLevelId;
  final bool currentLevelSolved;
  final bool topBarMode;

  const CourseLevelNavBanner({
    super.key,
    required this.session,
    required this.courseId,
    required this.currentLevelId,
    this.currentLevelSolved = false,
    this.topBarMode = false,
  });

  @override
  State<CourseLevelNavBanner> createState() => _CourseLevelNavBannerState();
}

class _CourseLevelNavBannerState extends State<CourseLevelNavBanner> {
  bool _isLoading = false;
  String? _errorMessage;
  List<SavedBuilderProject> _levels = const <SavedBuilderProject>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CourseLevelNavBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.currentLevelId != widget.currentLevelId ||
        oldWidget.session.token != widget.session.token) {
      _load();
    }
  }

  Future<void> _load() async {
    final courseId = widget.courseId;
    final currentLevelId = widget.currentLevelId;
    if (courseId == null ||
        courseId.isEmpty ||
        currentLevelId == null ||
        currentLevelId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final levelsResult = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: courseId,
    );
    if (!mounted || widget.courseId != courseId) {
      return;
    }
    if (levelsResult['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            levelsResult['message']?.toString() ?? 'Failed to load levels.';
      });
      return;
    }

    final rawLevels = levelsResult['data'];
    final levels = rawLevels is List
        ? rawLevels
              .whereType<Map>()
              .map(
                (level) => SavedBuilderProject.fromJson(
                  Map<String, dynamic>.from(level),
                ),
              )
              .where((level) => level.id.isNotEmpty)
              .toList()
        : <SavedBuilderProject>[];
    levels.sort((a, b) {
      final orderCompare = a.orderInCourse.compareTo(b.orderInCourse);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    setState(() {
      _levels = levels;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseId = widget.courseId;
    final currentLevelId = widget.currentLevelId;
    if (courseId == null ||
        courseId.isEmpty ||
        currentLevelId == null ||
        currentLevelId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoading && _levels.isEmpty) {
      if (widget.topBarMode) {
        return const SizedBox(
          width: 38,
          height: 38,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return _BannerShell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading course levels'),
          ],
        ),
      );
    }

    if (_errorMessage != null || _levels.isEmpty) {
      if (widget.topBarMode) {
        return const SizedBox.shrink();
      }
      return _BannerShell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, color: Colors.blueGrey.shade500),
            const SizedBox(width: 10),
            Text(_errorMessage ?? 'No course levels found.'),
          ],
        ),
      );
    }

    final currentIndex = _levels.indexWhere(
      (level) => level.id == currentLevelId,
    );
    if (currentIndex == -1) {
      return const SizedBox.shrink();
    }

    final previousLevel = currentIndex > 0 ? _levels[currentIndex - 1] : null;
    final nextLevel = currentIndex < _levels.length - 1
        ? _levels[currentIndex + 1]
        : null;
    final canGoNext = nextLevel != null;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD166), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB703).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundNavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Previous level',
            enabled: previousLevel != null,
            color: const Color(0xFF2F80ED),
            onPressed: previousLevel == null
                ? null
                : () => _openLevel(previousLevel),
          ),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 96),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFE8A3)),
            ),
            child: Text(
              'Level ${currentIndex + 1} / ${_levels.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF243B53),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          _RoundNavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Next level',
            enabled: canGoNext,
            color: const Color(0xFF39B54A),
            onPressed: canGoNext ? () => _openLevel(nextLevel) : null,
          ),
        ],
      ),
    );

    if (widget.topBarMode) {
      return content;
    }
    return _BannerShell(child: content);
  }

  void _openLevel(SavedBuilderProject? level) {
    if (level == null || level.id == widget.currentLevelId) {
      return;
    }
    openCourseBuilderLevel(
      context: context,
      session: widget.session,
      courseId: widget.courseId!,
      level: level,
      replace: true,
    );
  }
}

void openCourseBuilderLevel({
  required BuildContext context,
  required AuthSession session,
  required String courseId,
  required SavedBuilderProject level,
  bool replace = false,
}) {
  final routeName = level.isTopView
      ? AppRoutes.topViewBuilder
      : level.isScratch
      ? AppRoutes.scratchBuilder
      : level.isFourthDemo
      ? AppRoutes.fourthDemoBuilder
      : AppRoutes.builderPlay;
  final arguments = level.isTopView
      ? TopViewBuilderRouteData(
          session: session,
          initialProjectId: level.id,
          allowPublishedAccess: true,
          playMode: true,
          initialTitle: level.title,
          courseProgressCourseId: courseId,
          courseProgressLevelId: level.id,
        )
      : level.isScratch
      ? ScratchBuilderRouteData(
          session: session,
          initialProjectId: level.id,
          allowPublishedAccess: true,
          playMode: true,
          initialTitle: level.title,
          courseProgressCourseId: courseId,
          courseProgressLevelId: level.id,
        )
      : level.isFourthDemo
      ? FourthDemoBuilderRouteData(
          session: session,
          initialProjectId: level.id,
          allowPublishedAccess: true,
          playMode: true,
          initialTitle: level.title,
          courseProgressCourseId: courseId,
          courseProgressLevelId: level.id,
        )
      : BuilderPlayRouteData(
          session: session,
          projectId: level.id,
          initialTitle: level.title,
          courseProgressCourseId: courseId,
          courseProgressLevelId: level.id,
        );

  unawaited(
    CourseResumeService.savePublicCourse(
      userId: session.user.id,
      courseLookupId: courseId,
      levelId: level.id,
    ),
  );

  if (replace) {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    return;
  }
  Navigator.of(context).pushNamed(routeName, arguments: arguments);
}

Future<List<SavedBuilderProject>> loadCourseBuilderLevels({
  required AuthSession session,
  required String courseId,
}) async {
  if (courseId.isEmpty) {
    return const <SavedBuilderProject>[];
  }

  final levelsResult = await ApiService.getPublicCourseLevels(
    authToken: session.token,
    courseId: courseId,
  );
  if (levelsResult['success'] != true) {
    return const <SavedBuilderProject>[];
  }

  final rawLevels = levelsResult['data'];
  final levels = rawLevels is List
      ? rawLevels
            .whereType<Map>()
            .map(
              (level) => SavedBuilderProject.fromJson(
                Map<String, dynamic>.from(level),
              ),
            )
            .where((level) => level.id.isNotEmpty)
            .toList()
      : <SavedBuilderProject>[];
  levels.sort((a, b) {
    final orderCompare = a.orderInCourse.compareTo(b.orderInCourse);
    if (orderCompare != 0) {
      return orderCompare;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return levels;
}

Future<SavedBuilderProject?> loadNextCourseBuilderLevel({
  required AuthSession session,
  required String? courseId,
  required String? currentLevelId,
}) async {
  if (courseId == null ||
      courseId.isEmpty ||
      currentLevelId == null ||
      currentLevelId.isEmpty) {
    return null;
  }

  final levels = await loadCourseBuilderLevels(
    session: session,
    courseId: courseId,
  );
  final currentIndex = levels.indexWhere((level) => level.id == currentLevelId);
  if (currentIndex == -1 || currentIndex >= levels.length - 1) {
    return null;
  }
  return levels[currentIndex + 1];
}

class _BannerShell extends StatelessWidget {
  final Widget child;

  const _BannerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey.shade100, width: 1.4),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1260),
          child: child,
        ),
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  const _RoundNavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton.filled(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size(38, 38),
          fixedSize: const Size(38, 38),
          padding: EdgeInsets.zero,
          backgroundColor: enabled ? color : const Color(0xFFE5E7EB),
          foregroundColor: enabled ? Colors.white : Colors.blueGrey.shade400,
          shadowColor: enabled
              ? color.withValues(alpha: 0.28)
              : Colors.transparent,
          elevation: enabled ? 2 : 0,
        ),
      ),
    );
  }
}
