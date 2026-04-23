import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/features/admin/pages/admin_shell.dart';
import 'package:client/features/auth/pages/login_page_demo.dart';
import 'package:client/features/auth/pages/register_page_demo.dart';
import 'package:client/features/builder/pages/builder_play_page.dart';
import 'package:client/features/builder/pages/builder_page.dart';
import 'package:client/features/builder/pages/my_games_page.dart';
import 'package:client/features/builder/pages/top_view_builder_page.dart';
import 'package:client/features/home/pages/discover.dart';
import 'package:client/features/home/pages/user_home_page_demo.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Navigator.defaultRouteName:
      case AppRoutes.login:
        return _pageRoute(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      case AppRoutes.register:
        return _pageRoute(
          settings: settings,
          builder: (_) => const RegisterPage(),
        );
      case AppRoutes.home:
        final data = settings.arguments;
        if (data is HomeRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => UserHomePage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The home page needs an active user session.',
        );
      case AppRoutes.builder:
        final data = settings.arguments;
        if (data is BuilderRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => BuilderPage(
              session: data.session,
              initialProjectId: data.initialProjectId,
            ),
          );
        }
        return _errorRoute(
          settings,
          'The builder page needs an active user session.',
        );
      case AppRoutes.builderPlay:
        final data = settings.arguments;
        if (data is BuilderPlayRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => BuilderPlayPage(
              session: data.session,
              projectId: data.projectId,
              initialTitle: data.initialTitle,
            ),
          );
        }
        return _errorRoute(
          settings,
          'The play page needs an active user session and project.',
        );
      case AppRoutes.topViewBuilder:
        final data = settings.arguments;
        if (data is TopViewBuilderRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => TopViewBuilderPage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The top view builder page needs an active user session.',
        );
      case AppRoutes.myGames:
        final data = settings.arguments;
        if (data is MyGamesRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => MyGamesPage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The My Games page needs an active user session.',
        );
      case AppRoutes.myPublishedGames:
        final data = settings.arguments;
        if (data is MyPublishedGamesRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => MyGamesPage(
              session: data.session,
              title: 'My Published Games',
              statusFilter: 'published',
              openProjectOnTap: false,
              playProjectOnTap: true,
              emptyMessage: 'No published games yet.',
            ),
          );
        }
        return _errorRoute(
          settings,
          'The My Published Games page needs an active user session.',
        );
      case AppRoutes.discover:
        final data = settings.arguments;
        if (data is DiscoverRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => DiscoverPage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The Discover page needs an active user session.',
        );

      case AppRoutes.admin:
        final data = settings.arguments;
        if (data is AdminRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => AdminShellPage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The admin page needs an active user session.',
        );
      default:
        return onUnknownRoute(settings);
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _errorRoute(
      settings,
      'No page is registered for ${settings.name ?? 'this route'}.',
    );
  }

  static MaterialPageRoute<void> _pageRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  static MaterialPageRoute<void> _errorRoute(
    RouteSettings settings,
    String message,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
