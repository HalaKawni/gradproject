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

class MyGamesRouteData {
  const MyGamesRouteData({required this.session});

  final AuthSession session;
}
