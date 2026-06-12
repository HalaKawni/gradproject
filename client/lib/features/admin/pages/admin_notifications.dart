import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
import 'package:client/features/admin/shared/admin_view_theme.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:client/features/builder/shared/widgets/course_level_nav_banner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminCourse> _courses = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final language = AppLanguage.instance;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getAdminCourseNotifications(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final rawList = result['data'] is List
          ? result['data'] as List
          : const [];
      setState(() {
        _courses = rawList
            .whereType<Map>()
            .map(
              (item) => AdminCourse.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage =
          result['message']?.toString() ?? language.t('failedToLoadNotifications');
      _isLoading = false;
    });
  }

  Future<void> _approve(AdminCourse course) async {
    final language = AppLanguage.of(context);
    final result = await ApiService.approveAdminCourseVerification(
      authToken: widget.session.token,
      courseId: course.id,
    );
    _handleActionResult(result, language.t('courseVerified'));
  }

  Future<void> _reject(AdminCourse course) async {
    final language = AppLanguage.of(context);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            language.t('rejectCourseTitle', params: {'title': course.title}),
          ),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: language.t('reasonOptional'),
              border: const OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              child: Text(language.t('reject')),
            ),
          ],
        );
      },
    );
    reasonController.dispose();

    if (reason == null) {
      return;
    }

    final result = await ApiService.rejectAdminCourseVerification(
      authToken: widget.session.token,
      courseId: course.id,
      reason: reason.trim(),
    );
    _handleActionResult(result, language.t('verificationRejected'));
  }

  Future<void> _dismissUpdate(AdminCourse course) async {
    final language = AppLanguage.of(context);
    final result = await ApiService.dismissAdminCourseUpdateNotification(
      authToken: widget.session.token,
      courseId: course.id,
    );
    _handleActionResult(result, language.t('updateNotificationDismissed'));
  }

  Future<void> _reviewCourse(AdminCourse course) async {
    final language = AppLanguage.of(context);
    final courseId = course.courseId.isNotEmpty ? course.courseId : course.id;
    final result = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: courseId,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                language.t('failedToLoadCourseLevels'),
          ),
        ),
      );
      return;
    }

    final rawLevels = result['data'] is List
        ? result['data'] as List
        : const [];
    final levels = rawLevels
        .whereType<Map>()
        .map(
          (item) =>
              SavedBuilderProject.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((level) => level.id.isNotEmpty)
        .toList();
    levels.sort((a, b) {
      final orderComparison = a.orderInCourse.compareTo(b.orderInCourse);
      if (orderComparison != 0) {
        return orderComparison;
      }
      return a.title.compareTo(b.title);
    });

    if (levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language.t('noPlayableCourseLevels'))),
      );
      return;
    }

    openCourseBuilderLevel(
      context: context,
      session: widget.session,
      courseId: courseId,
      level: levels.first,
    );
  }

  Future<void> _handleActionResult(
    Map<String, dynamic> result,
    String successMessage,
  ) async {
    if (!mounted) {
      return;
    }
    final language = AppLanguage.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? successMessage
              : result['message']?.toString() ?? language.t('actionFailed'),
        ),
      ),
    );

    if (result['success'] == true) {
      await _loadNotifications();
    }
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
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(language.t('retry')),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(child: Text(language.t('noCourseNotifications')));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AdminViewTheme.softCardDecoration(
              AdminViewTheme.accent,
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
                    Icons.notifications_active_outlined,
                    color: AdminViewTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.t('notifications'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language.t('notificationsSummary'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._courses.map((course) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseNotificationCard(
                course: course,
                onReview: () => _reviewCourse(course),
                onApprove: course.isVerificationPending
                    ? () => _approve(course)
                    : null,
                onReject: course.isVerificationPending
                    ? () => _reject(course)
                    : null,
                onDismissUpdate: course.hasUnreadUpdateNotification
                    ? () => _dismissUpdate(course)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CourseNotificationCard extends StatelessWidget {
  const _CourseNotificationCard({
    required this.course,
    required this.onReview,
    required this.onApprove,
    required this.onReject,
    required this.onDismissUpdate,
  });

  final AdminCourse course;
  final VoidCallback onReview;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDismissUpdate;

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    final creator = course.creatorName.isEmpty
        ? language.t('unknownUser')
        : course.creatorName;
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AdminViewTheme.primarySoft.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    course.title,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(language.t('byCreator', params: {'creator': creator})),
              ],
            ),
            const SizedBox(height: 10),
            if (course.isVerificationPending)
              Text(language.t('verificationRequestWaiting')),
            if (course.hasUnreadUpdateNotification)
              Text(
                course.lastUpdateNotificationMessage.isEmpty
                    ? language.t('verifiedCourseUpdated')
                    : course.lastUpdateNotificationMessage,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(language.t('reviewLevels')),
                ),
                const SizedBox(width: 8),
                if (onApprove != null)
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(language.t('approve')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminViewTheme.success,
                    ),
                  ),
                if (onApprove != null) const SizedBox(width: 8),
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(language.t('reject')),
                  ),
                const Spacer(),
                if (onDismissUpdate != null)
                  TextButton.icon(
                    onPressed: onDismissUpdate,
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(language.t('dismissUpdate')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
