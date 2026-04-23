import 'package:client/core/models/auth_session.dart';
import 'package:client/features/admin/pages/admin_course.dart';
import 'package:client/features/admin/pages/admin_dashboard.dart';
import 'package:client/features/admin/pages/admin_level.dart';
import 'package:client/features/admin/pages/admin_users_detail.dart';
import 'package:flutter/material.dart';

enum AdminSection {
  dashboard,
  courses,
  levels,
  users,
  statistics,
  profile,
}

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
        return const AdminDashboardPage();
      case AdminSection.courses:
        return const AdminCoursesPage();
      case AdminSection.levels:
        return const AdminLevelsPage();
      case AdminSection.users:
        return AdminUserDetailsPage(session: widget.session);
      case AdminSection.statistics:
        return const Center(child: Text('Statistics Page'));
      case AdminSection.profile:
        return const Center(child: Text('Profile Page'));
    }
  }

  String _buildTitle() {
    switch (selectedSection) {
      case AdminSection.dashboard:
        return widget.title;
      case AdminSection.courses:
        return 'Courses';
      case AdminSection.levels:
        return 'Levels';
      case AdminSection.users:
        return 'Users';
      case AdminSection.statistics:
        return 'Statistics';
      case AdminSection.profile:
        return 'Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: AdminSection.values.indexOf(selectedSection),
            onDestinationSelected: (index) {
              _selectSection(AdminSection.values[index]);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Courses'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.extension_outlined),
                selectedIcon: Icon(Icons.extension),
                label: Text('Levels'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Statistics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
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
