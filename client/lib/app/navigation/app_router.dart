import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/features/auth/pages/login_page.dart';
import 'package:client/features/auth/pages/register_page.dart';
import 'package:client/features/builder/pages/builder_page.dart';
import 'package:client/features/builder/pages/my_games_page.dart';
import 'package:client/features/home/pages/user_home_page.dart';
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
    return MaterialPageRoute<void>(
      settings: settings,
      builder: builder,
    );
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
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
