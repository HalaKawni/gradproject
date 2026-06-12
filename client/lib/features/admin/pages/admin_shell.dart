import 'package:client/core/models/auth_session.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/features/admin/pages/admin_course.dart';
import 'package:client/features/admin/pages/admin_dashboard.dart';
import 'package:client/features/admin/pages/admin_level.dart';
import 'package:client/features/admin/pages/admin_notifications.dart';
import 'package:client/features/admin/pages/admin_statistics.dart';
import 'package:client/features/admin/shared/admin_view_theme.dart';
import 'package:client/features/admin/pages/admin_users_detail.dart';
import 'package:client/features/profile/pages/user_profile_page.dart';
import 'package:flutter/material.dart';

enum AdminSection {
  dashboard,
  courses,
  levels,
  notifications,
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
  int _languageVersion = 0;

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _languageVersion++;
    });
  }

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
      case AdminSection.notifications:
        return AdminNotificationsPage(session: widget.session);
      case AdminSection.users:
        return AdminUserDetailsPage(session: widget.session);
      case AdminSection.statistics:
        return AdminStatisticsPage(session: widget.session);
      case AdminSection.profile:
        return UserProfilePage(session: widget.session, showAppBar: false);
    }
  }

  String _buildTitle(AppLanguage language) {
    switch (selectedSection) {
      case AdminSection.dashboard:
        return language.t('admin');
      case AdminSection.courses:
        return language.t('courses');
      case AdminSection.levels:
        return language.t('levels');
      case AdminSection.notifications:
        return language.t('notifications');
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

    return Directionality(
      textDirection: language.textDirection,
      child: Theme(
        data: AdminViewTheme.theme(context),
        child: Container(
          decoration: AdminViewTheme.pageDecoration(),
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: AdminViewTheme.shellPanelDecoration(),
                  child: Row(
                    children: [
                      Container(
                        width: 128,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: NavigationRail(
                          selectedIndex: AdminSection.values.indexOf(
                            selectedSection,
                          ),
                          onDestinationSelected: (index) {
                            _selectSection(AdminSection.values[index]);
                          },
                          useIndicator: true,
                          groupAlignment: -0.95,
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
                              icon: Icon(Icons.notifications_outlined),
                              selectedIcon: Icon(Icons.notifications),
                              label: Text(language.t('notifications')),
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
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AdminViewTheme.border.withValues(alpha: 0.8),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              constraints: const BoxConstraints(minHeight: 84),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(
                                        _buildTitle(language),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminViewTheme.primarySoft
                                          .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          color: AdminViewTheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.session.user.name.isEmpty
                                              ? 'Administrator'
                                              : widget.session.user.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: AdminViewTheme.border.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: KeyedSubtree(
                                  key: ValueKey(
                                    '${selectedSection.name}-$_languageVersion',
                                  ),
                                  child: _buildPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
