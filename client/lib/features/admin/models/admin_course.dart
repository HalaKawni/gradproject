class AdminCourse {
  final String id;
  final String title;
  final String description;
  final bool isPublic;
  final int totalLevels;
  final int enrolledStudents;
  final String category;

  const AdminCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.totalLevels,
    required this.enrolledStudents,
    required this.category,
  });
}