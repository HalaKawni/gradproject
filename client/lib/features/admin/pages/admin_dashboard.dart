import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _DashboardCardData('Total Courses', '12', Icons.menu_book),
      _DashboardCardData('Total Levels', '84', Icons.extension),
      _DashboardCardData('Students', '326', Icons.people),
      _DashboardCardData('Active Today', '57', Icons.show_chart),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards
                .map((card) => SizedBox(
                      width: 220,
                      child: _StatCard(data: card),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.add_circle_outline),
                  title: Text('New course added: Flutter Basics'),
                  subtitle: Text('2 hours ago'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Level 3 updated in Logic Course'),
                  subtitle: Text('5 hours ago'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.people_outline),
                  title: Text('14 new students registered'),
                  subtitle: Text('Today'),
                ),
              ],
            ),
          ),
        ],
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
  final _DashboardCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(data.icon, size: 32),
            const SizedBox(width: 12),
            Column(
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
          ],
        ),
      ),
    );
  }
}