import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/features/admin/pages/admin_shell.dart';
import 'package:client/devDemo/login_page_demo.dart';
import 'package:client/devDemo/register_page_demo.dart';
import 'package:client/features/auth/pages/email_verification_page.dart';
import 'package:client/features/builder/front_view/pages/builder_play_page.dart';
import 'package:client/features/builder/front_view/pages/builder_page.dart';
import 'package:client/features/builder/pages/my_games_page.dart';
import 'package:client/features/builder/scratch_builder/pages/scratch_builder_page.dart';
import 'package:client/features/builder/top_view/pages/top_view_builder_page.dart';
import 'package:client/features/home/pages/discover.dart';
import 'package:client/features/home/pages/dashboard_page.dart';
import 'package:client/features/home/pages/public_courses_page.dart';
import 'package:client/devDemo/user_home_page_demo.dart';
import 'package:client/features/profile/pages/user_profile_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    final routeName = uri?.path ?? settings.name;

    switch (routeName) {
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
      case AppRoutes.verifyEmail:
        final token = uri?.queryParameters['token'];
        return _pageRoute(
          settings: settings,
          builder: (_) => EmailVerificationPage(token: token),
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
      case AppRoutes.dashboard:
        final data = settings.arguments;
        if (data is DashboardRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => DashboardPage(username: data.session.user.name),
          );
        }
        return _errorRoute(
          settings,
          'The dashboard page needs an active user session.',
        );
      case AppRoutes.builder:
        final data = settings.arguments;
        if (data is BuilderRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => BuilderPage(
              session: data.session,
              initialProjectId: data.initialProjectId,
              useAdminLevelApi: data.useAdminLevelApi,
              initialCourseId: data.initialCourseId,
              initialOrderInCourse: data.initialOrderInCourse,
              initialDifficulty: data.initialDifficulty,
              initialStatus: data.initialStatus,
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
            builder: (_) => TopViewBuilderPage(
              session: data.session,
              initialProjectId: data.initialProjectId,
              allowPublishedAccess: data.allowPublishedAccess,
              playMode: data.playMode,
              initialTitle: data.initialTitle,
              useAdminLevelApi: data.useAdminLevelApi,
              initialCourseId: data.initialCourseId,
              initialOrderInCourse: data.initialOrderInCourse,
              initialDifficulty: data.initialDifficulty,
              initialStatus: data.initialStatus,
            ),
          );
        }
        return _errorRoute(
          settings,
          'The top view builder page needs an active user session.',
        );
      case AppRoutes.scratchBuilder:
        final data = settings.arguments;
        if (data is ScratchBuilderRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => ScratchBuilderPage(
              session: data.session,
              initialProjectId: data.initialProjectId,
              allowPublishedAccess: data.allowPublishedAccess,
              playMode: data.playMode,
              initialTitle: data.initialTitle,
              useAdminLevelApi: data.useAdminLevelApi,
              initialCourseId: data.initialCourseId,
              initialOrderInCourse: data.initialOrderInCourse,
              initialDifficulty: data.initialDifficulty,
              initialStatus: data.initialStatus,
            ),
          );
        }
        return _errorRoute(
          settings,
          'The scratch builder page needs an active user session.',
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
      case AppRoutes.publicCourses:
        final data = settings.arguments;
        if (data is PublicCoursesRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => PublicCoursesPage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The Courses page needs an active user session.',
        );
      case AppRoutes.profile:
        final data = settings.arguments;
        if (data is ProfileRouteData) {
          return _pageRoute(
            settings: settings,
            builder: (_) => UserProfilePage(session: data.session),
          );
        }
        return _errorRoute(
          settings,
          'The profile page needs an active user session.',
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
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        final language = AppLanguage.of(context);
        return Directionality(
          textDirection: language.textDirection,
          child: builder(context),
        );
      },
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
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
