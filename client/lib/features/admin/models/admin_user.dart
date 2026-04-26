class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role; // student, admin
  final bool isActive;
  final bool isSuspended;
  final int completedLevels;
  final int enrolledCourses;
  final DateTime joinedAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isSuspended,
    required this.completedLevels,
    required this.enrolledCourses,
    required this.joinedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: _readString(json, '_id', fallbackKey: 'id'),
      name: _readString(json, 'name'),
      email: _readString(json, 'email'),
      role: _readString(json, 'role'),
      isActive: json['isSuspended'] == true
          ? false
          : json['isActive'] is bool
          ? json['isActive'] as bool
          : true,
      isSuspended: json['isSuspended'] == true,
      completedLevels: _readInt(json['completedLevels']),
      enrolledCourses: _readInt(json['enrolledCourses']),
      joinedAt: _readDate(json['createdAt']),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  return value?.toString() ?? '';
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

DateTime _readDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
