class UserCourseProgress {
  final String courseId;
  final String courseTitle;
  final int completedLevels;
  final int totalLevels;

  const UserCourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.completedLevels,
    required this.totalLevels,
  });

  double get progressValue {
    if (totalLevels == 0) return 0;
    return completedLevels / totalLevels;
  }

  String get progressText => '$completedLevels / $totalLevels';
}