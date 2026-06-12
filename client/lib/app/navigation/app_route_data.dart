import 'package:client/core/models/auth_session.dart';

class HomeRouteData {
  const HomeRouteData({required this.session});

  final AuthSession session;
}

class DashboardRouteData {
  const DashboardRouteData({required this.session});

  final AuthSession session;
}

class BuilderRouteData {
  const BuilderRouteData({
    required this.session,
    this.initialProjectId,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
  });

  final AuthSession session;
  final String? initialProjectId;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
}

class BuilderPlayRouteData {
  const BuilderPlayRouteData({
    required this.session,
    required this.projectId,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.courseProgressCourseId,
    this.courseProgressLevelId,
  });

  final AuthSession session;
  final String projectId;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;
}

class FourthDemoBuilderRouteData {
  const FourthDemoBuilderRouteData({
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
    this.courseProgressCourseId,
    this.courseProgressLevelId,
  });

  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;
}

class TopViewBuilderRouteData {
  const TopViewBuilderRouteData({
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
    this.courseProgressCourseId,
    this.courseProgressLevelId,
  });

  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;
}

class ScratchBuilderRouteData {
  const ScratchBuilderRouteData({
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
    this.courseProgressCourseId,
    this.courseProgressLevelId,
  });

  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;
}

class MyGamesRouteData {
  const MyGamesRouteData({required this.session});

  final AuthSession session;
}

class MyPublishedGamesRouteData {
  const MyPublishedGamesRouteData({required this.session});

  final AuthSession session;
}

class DiscoverRouteData {
  const DiscoverRouteData({required this.session});

  final AuthSession session;
}

class PublicCoursesRouteData {
  const PublicCoursesRouteData({required this.session});

  final AuthSession session;
}

class ProfileRouteData {
  const ProfileRouteData({required this.session});

  final AuthSession session;
}

class AdminRouteData {
  const AdminRouteData({required this.session});

  final AuthSession session;
}

class ParentRouteData {
  const ParentRouteData({required this.session});

  final AuthSession session;
}
