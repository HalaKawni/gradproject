class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role; // student, admin
  final bool isActive;
  final int completedLevels;
  final int enrolledCourses;
  final DateTime joinedAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.completedLevels,
    required this.enrolledCourses,
    required this.joinedAt,
  });
}