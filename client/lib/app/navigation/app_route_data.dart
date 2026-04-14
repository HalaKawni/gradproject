import 'package:client/core/models/auth_session.dart';

class HomeRouteData {
  const HomeRouteData({required this.session});

  final AuthSession session;
}

class BuilderRouteData {
  const BuilderRouteData({
    required this.session,
    this.initialProjectId,
  });

  final AuthSession session;
  final String? initialProjectId;
}

class BuilderPlayRouteData {
  const BuilderPlayRouteData({
    required this.session,
    required this.projectId,
    this.initialTitle,
  });

  final AuthSession session;
  final String projectId;
  final String? initialTitle;
}

class TopViewBuilderRouteData {
  const TopViewBuilderRouteData({required this.session});

  final AuthSession session;
}

class MyGamesRouteData {
  const MyGamesRouteData({required this.session});

  final AuthSession session;
}

class MyPublishedGamesRouteData {
  const MyPublishedGamesRouteData({required this.session});

  final AuthSession session;
}
