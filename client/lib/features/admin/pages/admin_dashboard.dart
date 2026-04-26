import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _AdminErrorState(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final cards = [
      _DashboardCardData(
        'Total Courses',
        '${_readInt('totalCourses')}',
        Icons.menu_book,
      ),
      _DashboardCardData(
        'Total Levels',
        '${_readInt('totalLevels')}',
        Icons.extension,
      ),
      _DashboardCardData('Users', '${_readInt('totalUsers')}', Icons.people),
      _DashboardCardData(
        'Published Levels',
        '${_readInt('publishedLevels')}',
        Icons.public,
      ),
      _DashboardCardData(
        'Draft Levels',
        '${_readInt('draftLevels')}',
        Icons.edit_note,
      ),
      _DashboardCardData(
        'User Created',
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
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public_outlined),
                    title: const Text('Published levels'),
                    trailing: Text('${_readInt('publishedLevels')}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Draft levels'),
                    trailing: Text('${_readInt('draftLevels')}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('User created levels'),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(data.icon, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
