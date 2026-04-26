class AdminCourse {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final bool isPublic;
  final int totalLevels;
  final int enrolledStudents;
  final String category;

  const AdminCourse({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.totalLevels,
    required this.enrolledStudents,
    required this.category,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    return AdminCourse(
      id: _readString(json, '_id', fallbackKey: 'id'),
      courseId: _readString(json, 'courseId'),
      title: _readString(json, 'courseName', fallbackKey: 'title'),
      description: _readString(json, 'description'),
      isPublic: json['isPublic'] == true,
      totalLevels: _readInt(json['totalLevels'] ?? json['levelsCount']),
      enrolledStudents: _readInt(
        json['enrolledStudents'] ?? json['enrollmentsCount'],
      ),
      category: _readString(json, 'category'),
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
