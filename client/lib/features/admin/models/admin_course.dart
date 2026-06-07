class AdminCourse {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final bool isPublic;
  final int totalLevels;
  final int enrolledStudents;
  final String category;
  final String? courseImageBase64;
  final double coverFrameScale;
  final double coverFrameOffsetX;
  final double coverFrameOffsetY;
  final String creatorId;
  final String creatorName;
  final String creatorRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminCourse({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.totalLevels,
    required this.enrolledStudents,
    required this.category,
    this.courseImageBase64,
    this.coverFrameScale = 1,
    this.coverFrameOffsetX = 0,
    this.coverFrameOffsetY = 0,
    this.creatorId = '',
    this.creatorName = '',
    this.creatorRole = '',
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    final createdBy = _readMap(json['createdBy']);

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
      courseImageBase64: _readNullableString(json['courseImageBase64']),
      coverFrameScale: _readDouble(json['coverFrameScale'], fallback: 1),
      coverFrameOffsetX: _readDouble(json['coverFrameOffsetX']),
      coverFrameOffsetY: _readDouble(json['coverFrameOffsetY']),
      creatorId: _readString(createdBy, '_id', fallbackKey: 'id').isNotEmpty
          ? _readString(createdBy, '_id', fallbackKey: 'id')
          : _readString(json, 'createdBy'),
      creatorName: _readString(createdBy, 'name', fallbackKey: 'email'),
      creatorRole: _readString(createdBy, 'role'),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  bool get isAdminCreated => creatorRole.toLowerCase() == 'admin';
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

double _readDouble(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _readNullableString(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}

DateTime? _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value?.toString() ?? '');
}
