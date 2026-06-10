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
  final String verificationStatus;
  final DateTime? verificationRequestedAt;
  final DateTime? verificationReviewedAt;
  final String verificationRejectedReason;
  final DateTime? verifiedAt;
  final String verifiedByName;
  final bool hasUnreadUpdateNotification;
  final DateTime? lastUpdateNotificationAt;
  final String lastUpdateNotificationMessage;
  final double ratingAverage;
  final int ratingCount;
  final int commentCount;
  final int? currentUserRating;
  final List<AdminCourseComment> comments;
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
    this.verificationStatus = 'none',
    this.verificationRequestedAt,
    this.verificationReviewedAt,
    this.verificationRejectedReason = '',
    this.verifiedAt,
    this.verifiedByName = '',
    this.hasUnreadUpdateNotification = false,
    this.lastUpdateNotificationAt,
    this.lastUpdateNotificationMessage = '',
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.commentCount = 0,
    this.currentUserRating,
    this.comments = const <AdminCourseComment>[],
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    final createdBy = _readMap(json['createdBy']);
    final verifiedBy = _readMap(json['verifiedBy']);

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
      verificationStatus: _readString(
        json,
        'verificationStatus',
        fallback: 'none',
      ),
      verificationRequestedAt: _readDate(json['verificationRequestedAt']),
      verificationReviewedAt: _readDate(json['verificationReviewedAt']),
      verificationRejectedReason: _readString(
        json,
        'verificationRejectedReason',
      ),
      verifiedAt: _readDate(json['verifiedAt']),
      verifiedByName: _readString(verifiedBy, 'name', fallbackKey: 'email'),
      hasUnreadUpdateNotification: json['hasUnreadUpdateNotification'] == true,
      lastUpdateNotificationAt: _readDate(json['lastUpdateNotificationAt']),
      lastUpdateNotificationMessage: _readString(
        json,
        'lastUpdateNotificationMessage',
      ),
      ratingAverage: _readDouble(json['ratingAverage']),
      ratingCount: _readInt(json['ratingCount']),
      commentCount: _readInt(json['commentCount']),
      currentUserRating: _readNullableInt(json['currentUserRating']),
      comments: _readComments(json['comments']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  bool get isAdminCreated => creatorRole.toLowerCase() == 'admin';

  bool get isVerified => verificationStatus == 'approved';

  bool get isVerificationPending => verificationStatus == 'pending';

  bool get canRequestVerification =>
      !isAdminCreated &&
      isPublic &&
      verificationStatus != 'pending' &&
      !isVerified;
}

class AdminCourseComment {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime? createdAt;

  const AdminCourseComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  factory AdminCourseComment.fromJson(Map<String, dynamic> json) {
    return AdminCourseComment(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'User',
      message: json['message']?.toString() ?? '',
      createdAt: _readDate(json['createdAt']),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
  String fallback = '',
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  return value?.toString() ?? fallback;
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

int? _readNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
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

List<AdminCourseComment> _readComments(Object? value) {
  if (value is! List) {
    return const <AdminCourseComment>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => AdminCourseComment.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}
