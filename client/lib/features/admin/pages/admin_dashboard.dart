import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/shared/admin_view_theme.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getAdminDashboard(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _dashboard = data is Map ? Map<String, dynamic>.from(data) : {};
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message']?.toString() ?? 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  int _readInt(String key) {
    final value = _dashboard[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _AdminErrorState(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final cards = [
      _DashboardCardData(
        language.t('totalCourses'),
        '${_readInt('totalCourses')}',
        Icons.menu_book,
      ),
      _DashboardCardData(
        language.t('totalLevels'),
        '${_readInt('totalLevels')}',
        Icons.extension,
      ),
      _DashboardCardData(
        language.t('users'),
        '${_readInt('totalUsers')}',
        Icons.people,
      ),
      _DashboardCardData(
        language.t('publishedLevels'),
        '${_readInt('publishedLevels')}',
        Icons.public,
      ),
      _DashboardCardData(
        language.t('draftLevels'),
        '${_readInt('draftLevels')}',
        Icons.edit_note,
      ),
      _DashboardCardData(
        language.t('userCreated'),
        '${_readInt('userCreatedLevels')}',
        Icons.person_add_alt,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AdminViewTheme.softCardDecoration(
                AdminViewTheme.primarySoft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AdminViewTheme.highlight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.insights_outlined,
                      color: AdminViewTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.t('overview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep an eye on courses, levels, and community activity in one glance.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: cards
                  .map(
                    (card) =>
                        SizedBox(width: 220, child: _StatCard(data: card)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              language.t('overview'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: AdminViewTheme.border.withValues(alpha: 0.9),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminViewTheme.primarySoft.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.public_outlined),
                    ),
                    title: Text(language.t('publishedLevels')),
                    trailing: Text('${_readInt('publishedLevels')}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminViewTheme.accent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.edit_outlined),
                    ),
                    title: Text(language.t('draftLevels')),
                    trailing: Text('${_readInt('draftLevels')}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AdminViewTheme.highlight.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.people_outline),
                    ),
                    title: Text(language.t('userCreatedLevels')),
                    trailing: Text('${_readInt('userCreatedLevels')}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCardData {
  final String title;
  final String value;
  final IconData icon;

  _DashboardCardData(this.title, this.value, this.icon);
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _DashboardCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AdminViewTheme.border.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AdminViewTheme.primarySoft, AdminViewTheme.accent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(data.icon, size: 28, color: AdminViewTheme.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AdminViewTheme.danger.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AdminViewTheme.accent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.error_outline, size: 30),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(language.t('retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
