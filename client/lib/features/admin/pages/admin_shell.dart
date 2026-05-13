import 'package:client/core/models/auth_session.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/features/admin/pages/admin_course.dart';
import 'package:client/features/admin/pages/admin_dashboard.dart';
import 'package:client/features/admin/pages/admin_level.dart';
import 'package:client/features/admin/pages/admin_statistics.dart';
import 'package:client/features/admin/pages/admin_users_detail.dart';
import 'package:client/features/profile/pages/user_profile_page.dart';
import 'package:flutter/material.dart';

enum AdminSection { dashboard, courses, levels, users, statistics, profile }

class AdminShellPage extends StatefulWidget {
  final AuthSession session;
  final String title;

  const AdminShellPage({
    super.key,
    required this.session,
    this.title = 'Admin',
  });

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  AdminSection selectedSection = AdminSection.dashboard;

  void _selectSection(AdminSection section) {
    setState(() {
      selectedSection = section;
    });
  }

  Widget _buildPage() {
    switch (selectedSection) {
      case AdminSection.dashboard:
        return AdminDashboardPage(session: widget.session);
      case AdminSection.courses:
        return AdminCoursesPage(session: widget.session);
      case AdminSection.levels:
        return AdminLevelsPage(session: widget.session);
      case AdminSection.users:
        return AdminUserDetailsPage(session: widget.session);
      case AdminSection.statistics:
        return AdminStatisticsPage(session: widget.session);
      case AdminSection.profile:
        return UserProfilePage(session: widget.session, showAppBar: false);
    }
  }

  String _buildTitle() {
    final language = AppLanguage.of(context);
    switch (selectedSection) {
      case AdminSection.dashboard:
        return language.t('admin');
      case AdminSection.courses:
        return language.t('courses');
      case AdminSection.levels:
        return language.t('levels');
      case AdminSection.users:
        return language.t('users');
      case AdminSection.statistics:
        return language.t('statistics');
      case AdminSection.profile:
        return language.t('profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: AdminSection.values.indexOf(selectedSection),
            onDestinationSelected: (index) {
              _selectSection(AdminSection.values[index]);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard),
                label: Text(language.t('dashboard')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: Text(language.t('courses')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.extension_outlined),
                selectedIcon: const Icon(Icons.extension),
                label: Text(language.t('levels')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text(language.t('users')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: Text(language.t('statistics')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.person),
                selectedIcon: const Icon(Icons.person),
                label: Text(language.t('profile')),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _buildTitle(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
