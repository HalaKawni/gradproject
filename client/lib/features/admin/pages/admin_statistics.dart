import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/shared/admin_view_theme.dart';
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

  List<_CoursePlayRow> _readCoursePlayRows() {
    final rawRows = _statistics['coursePlayCounts'];
    final rows = rawRows is List ? rawRows : const [];
    final langCode = AppLanguage.instance.locale.languageCode;

    return rows.whereType<Map>().map((row) {
      final data = Map<String, dynamic>.from(row);
      final rawName = data['courseName'];
      final String name;
      if (rawName is Map) {
        name = rawName[langCode]?.toString() ??
            rawName['en']?.toString() ??
            'Unnamed Course';
      } else {
        name = rawName?.toString().trim() ?? '';
      }
      return _CoursePlayRow(
        name: name.isEmpty ? 'Unnamed Course' : name,
        plays: _readInt(data['plays']),
      );
    }).toList();
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

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
              label: Text(language.t('retry')),
            ),
          ],
        ),
      );
    }

    final usersByRole = _readCountRows('usersByRole');
    final levelsByStatus = _readCountRows('levelsByStatus');
    final totalCourses = _readInt(_statistics['totalCourses']);
    final coursePlayRows = _readCoursePlayRows();

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AdminViewTheme.softCardDecoration(
                AdminViewTheme.primarySoft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.t('statistics'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          language.t('statisticsSummary'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: language.t('refreshStatistics'),
                    onPressed: _loadStatistics,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Original breakdown cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 260,
                  child: _StatisticCard(
                    title: language.t('totalCourses'),
                    rows: [
                      _CountRow(
                        label: language.t('courses'),
                        count: totalCourses,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _StatisticCard(
                    title: language.t('usersByRole'),
                    rows: usersByRole,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _StatisticCard(
                    title: language.t('levelsByStatus'),
                    rows: levelsByStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Courses ranked by plays
            _CourseRankingSection(rows: coursePlayRows),
          ],
        ),
      ),
    );
  }
}

// ── Course ranking section ────────────────────────────────────────────────────

class _CoursePlayRow {
  const _CoursePlayRow({required this.name, required this.plays});
  final String name;
  final int plays;
}

class _CourseRankingSection extends StatelessWidget {
  const _CourseRankingSection({required this.rows});

  final List<_CoursePlayRow> rows;

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AdminViewTheme.border.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminViewTheme.primarySoft.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AdminViewTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Courses by Plays',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              Text(language.t('noDataYet'))
            else
              _CourseRankingList(rows: rows),
          ],
        ),
      ),
    );
  }
}

class _CourseRankingList extends StatelessWidget {
  const _CourseRankingList({required this.rows});

  final List<_CoursePlayRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxPlays = rows.first.plays.clamp(1, double.maxFinite).toInt();

    return Column(
      children: rows.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final row = entry.value;
        final fraction = (row.plays / maxPlays).clamp(0.0, 1.0);

        final rankColor = switch (rank) {
          1 => const Color(0xFFF59E0B),
          2 => const Color(0xFF9CA3AF),
          3 => const Color(0xFFB87333),
          _ => AdminViewTheme.mutedText,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Name + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor:
                            AdminViewTheme.border.withValues(alpha: 0.5),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(rankColor.withValues(alpha: 0.75)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Play count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminViewTheme.accent.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${row.plays}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Original statistic card (unchanged) ──────────────────────────────────────

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
    final language = AppLanguage.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AdminViewTheme.border.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text(language.t('noDataYet'))
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatLabel(row.label),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AdminViewTheme.accent.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${row.count}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
      return AppLanguage.instance.t('unknown');
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}
