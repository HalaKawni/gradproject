import 'package:client/features/admin/models/user_course_progress.dart';
import 'package:flutter/material.dart';

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    super.key,
    required this.course,
  });

  final UserCourseProgress course;

  @override
  Widget build(BuildContext context) {
    final progressValue = course.totalLevels == 0
        ? 0.0
        : course.completedLevels / course.totalLevels;
    final percent = (progressValue * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.courseTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Progress: ${course.completedLevels} / ${course.totalLevels} levels'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('$percent% completed'),
        ],
      ),
    );
  }
}