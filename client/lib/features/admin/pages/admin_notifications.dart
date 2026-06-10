import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_course.dart';
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
          result['message']?.toString() ?? 'Failed to load notifications.';
      _isLoading = false;
    });
  }

  Future<void> _approve(AdminCourse course) async {
    final result = await ApiService.approveAdminCourseVerification(
      authToken: widget.session.token,
      courseId: course.id,
    );
    _handleActionResult(result, 'Course verified.');
  }

  Future<void> _reject(AdminCourse course) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reject "${course.title}"?'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              child: const Text('Reject'),
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
    _handleActionResult(result, 'Verification rejected.');
  }

  Future<void> _dismissUpdate(AdminCourse course) async {
    final result = await ApiService.dismissAdminCourseUpdateNotification(
      authToken: widget.session.token,
      courseId: course.id,
    );
    _handleActionResult(result, 'Update notification dismissed.');
  }

  Future<void> _reviewCourse(AdminCourse course) async {
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
            result['message']?.toString() ?? 'Failed to load course levels.',
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
        const SnackBar(content: Text('This course has no playable levels.')),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? successMessage
              : result['message']?.toString() ?? 'Action failed.',
        ),
      ),
    );

    if (result['success'] == true) {
      await _loadNotifications();
    }
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
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(child: Text('No course notifications.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final course = _courses[index];
          return _CourseNotificationCard(
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
          );
        },
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
    final creator = course.creatorName.isEmpty
        ? 'Unknown user'
        : course.creatorName;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
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
                Text('By $creator'),
              ],
            ),
            const SizedBox(height: 10),
            if (course.isVerificationPending)
              const Text('Verification request is waiting for review.'),
            if (course.hasUnreadUpdateNotification)
              Text(
                course.lastUpdateNotificationMessage.isEmpty
                    ? 'Verified course was updated.'
                    : course.lastUpdateNotificationMessage,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review levels'),
                ),
                const SizedBox(width: 8),
                if (onApprove != null)
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                if (onApprove != null) const SizedBox(width: 8),
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                const Spacer(),
                if (onDismissUpdate != null)
                  TextButton.icon(
                    onPressed: onDismissUpdate,
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('Dismiss update'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
