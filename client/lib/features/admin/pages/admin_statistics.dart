import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getAdminStatistics(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _statistics = data is Map ? Map<String, dynamic>.from(data) : {};
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result['message']?.toString() ?? 'Failed to load statistics';
        _isLoading = false;
      });
    }
  }

  List<_CountRow> _readCountRows(String key) {
    final rawRows = _statistics[key];
    final rows = rawRows is List ? rawRows : const [];

    return rows.whereType<Map>().map((row) {
      final data = Map<String, dynamic>.from(row);
      return _CountRow(
        label: data['_id']?.toString() ?? 'Unknown',
        count: _readInt(data['count']),
      );
    }).toList();
  }

  int _readInt(Object? value) {
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final usersByRole = _readCountRows('usersByRole');
    final levelsByStatus = _readCountRows('levelsByStatus');
    final totalCourses = _readInt(_statistics['totalCourses']);

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh statistics',
                  onPressed: _loadStatistics,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 260,
                  child: _StatisticCard(
                    title: 'Total Courses',
                    rows: [_CountRow(label: 'Courses', count: totalCourses)],
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _StatisticCard(
                    title: 'Users by Role',
                    rows: usersByRole,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _StatisticCard(
                    title: 'Levels by Status',
                    rows: levelsByStatus,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRow {
  const _CountRow({required this.label, required this.count});

  final String label;
  final int count;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.title, required this.rows});

  final String title;
  final List<_CountRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text('No data yet.')
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(_formatLabel(row.label))),
                      Text(
                        '${row.count}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String value) {
    if (value.isEmpty) {
      return 'Unknown';
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}
