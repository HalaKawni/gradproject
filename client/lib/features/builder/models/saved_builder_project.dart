class SavedBuilderProject {
  final String id;
  final String title;
  final String description;
  final String status;
  final String builderType;
  final String ownerId;
  final String publisherName;
  final String ownerRole;
  final String difficulty;
  final String courseId;
  final int orderInCourse;
  final String? coverImageBase64;
  final double coverFrameScale;
  final double coverFrameOffsetX;
  final double coverFrameOffsetY;
  final int playCount;
  final double ratingAverage;
  final int ratingCount;
  final int commentCount;
  final int? currentUserRating;
  final List<BuilderProjectComment> comments;
  final DateTime? updatedAt;

  const SavedBuilderProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.builderType,
    required this.ownerId,
    required this.publisherName,
    required this.ownerRole,
    required this.difficulty,
    required this.courseId,
    required this.orderInCourse,
    this.coverImageBase64,
    this.coverFrameScale = 1,
    this.coverFrameOffsetX = 0,
    this.coverFrameOffsetY = 0,
    this.playCount = 0,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.commentCount = 0,
    this.currentUserRating,
    this.comments = const <BuilderProjectComment>[],
    required this.updatedAt,
  });

  factory SavedBuilderProject.fromJson(Map<String, dynamic> json) {
    return SavedBuilderProject(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      builderType: _readBuilderType(json),
      ownerId: _readOwnerId(json),
      publisherName: _readPublisherName(json),
      ownerRole: _readOwnerRole(json),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      courseId: json['courseId']?.toString() ?? '',
      orderInCourse: _readInt(json['orderInCourse']),
      coverImageBase64: _readNullableString(json['coverImageBase64']),
      coverFrameScale: _readDouble(json['coverFrameScale'], fallback: 1),
      coverFrameOffsetX: _readDouble(json['coverFrameOffsetX']),
      coverFrameOffsetY: _readDouble(json['coverFrameOffsetY']),
      playCount: _readInt(json['playCount']),
      ratingAverage: _readDouble(json['ratingAverage']),
      ratingCount: _readInt(json['ratingCount']),
      commentCount: _readInt(json['commentCount']),
      currentUserRating: _readNullableInt(json['currentUserRating']),
      comments: _readComments(json['comments']),
      updatedAt: _tryParseDateTime(json['updatedAt']?.toString()),
    );
  }

  bool get isTopView => builderType == 'topView';

  bool get isScratch => builderType == 'scratch';

  bool get isFourthDemo => builderType == 'fourthDemo';

  bool get isPublished => status.trim().toLowerCase() == 'published';

  bool get isUserCreated => ownerRole.trim().toLowerCase() != 'admin';

  SavedBuilderProject copyWith({String? courseId, int? orderInCourse}) {
    return SavedBuilderProject(
      id: id,
      title: title,
      description: description,
      status: status,
      builderType: builderType,
      ownerId: ownerId,
      publisherName: publisherName,
      ownerRole: ownerRole,
      difficulty: difficulty,
      courseId: courseId ?? this.courseId,
      orderInCourse: orderInCourse ?? this.orderInCourse,
      coverImageBase64: coverImageBase64,
      coverFrameScale: coverFrameScale,
      coverFrameOffsetX: coverFrameOffsetX,
      coverFrameOffsetY: coverFrameOffsetY,
      playCount: playCount,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      commentCount: commentCount,
      currentUserRating: currentUserRating,
      comments: comments,
      updatedAt: updatedAt,
    );
  }

  SavedBuilderProject copyWithEngagement({
    int? playCount,
    double? ratingAverage,
    int? ratingCount,
    int? commentCount,
    int? currentUserRating,
    List<BuilderProjectComment>? comments,
  }) {
    return SavedBuilderProject(
      id: id,
      title: title,
      description: description,
      status: status,
      builderType: builderType,
      ownerId: ownerId,
      publisherName: publisherName,
      ownerRole: ownerRole,
      difficulty: difficulty,
      courseId: courseId,
      orderInCourse: orderInCourse,
      coverImageBase64: coverImageBase64,
      coverFrameScale: coverFrameScale,
      coverFrameOffsetX: coverFrameOffsetX,
      coverFrameOffsetY: coverFrameOffsetY,
      playCount: playCount ?? this.playCount,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      commentCount: commentCount ?? this.commentCount,
      currentUserRating: currentUserRating ?? this.currentUserRating,
      comments: comments ?? this.comments,
      updatedAt: updatedAt,
    );
  }

  static String _readBuilderType(Map<String, dynamic> json) {
    final directType = json['builderType']?.toString().trim();
    if (directType == 'topView' ||
        directType == 'frontView' ||
        directType == 'scratch' ||
        directType == 'fourthDemo') {
      return directType!;
    }

    final draftData = json['draftData'];
    if (draftData is Map) {
      final draftDataMap = Map<String, dynamic>.from(draftData);
      final draftType = draftDataMap['builderType']?.toString().trim();
      if (draftType == 'topView' ||
          draftType == 'frontView' ||
          draftType == 'scratch' ||
          draftType == 'fourthDemo') {
        return draftType!;
      }
    }

    return 'frontView';
  }

  static String _readPublisherName(Map<String, dynamic> json) {
    final ownerName = json['ownerName']?.toString().trim() ?? '';
    if (ownerName.isNotEmpty) {
      return ownerName;
    }

    final draftData = json['draftData'];
    if (draftData is Map) {
      final draftDataMap = Map<String, dynamic>.from(draftData);
      final owner = draftDataMap['owner'];
      if (owner is Map) {
        final ownerMap = Map<String, dynamic>.from(owner);
        final draftOwnerName = ownerMap['name']?.toString().trim() ?? '';
        if (draftOwnerName.isNotEmpty) {
          return draftOwnerName;
        }
      }
    }

    return 'Unknown publisher';
  }

  static String _readOwnerId(Map<String, dynamic> json) {
    final ownerId = json['ownerId']?.toString().trim() ?? '';
    if (ownerId.isNotEmpty) {
      return ownerId;
    }

    final owner = json['owner'];
    if (owner is Map) {
      final ownerMap = Map<String, dynamic>.from(owner);
      final directOwnerId =
          (ownerMap['_id'] ?? ownerMap['id'])?.toString().trim() ?? '';
      if (directOwnerId.isNotEmpty) {
        return directOwnerId;
      }
    }

    final draftData = json['draftData'];
    if (draftData is Map) {
      final draftDataMap = Map<String, dynamic>.from(draftData);
      final draftOwner = draftDataMap['owner'];
      if (draftOwner is Map) {
        final draftOwnerMap = Map<String, dynamic>.from(draftOwner);
        final draftOwnerId =
            (draftOwnerMap['_id'] ?? draftOwnerMap['id'])?.toString().trim() ??
            '';
        if (draftOwnerId.isNotEmpty) {
          return draftOwnerId;
        }
      }
    }

    return '';
  }

  static String _readOwnerRole(Map<String, dynamic> json) {
    final ownerRole = json['ownerRole']?.toString().trim();
    if (ownerRole != null && ownerRole.isNotEmpty) {
      return ownerRole;
    }

    final draftData = json['draftData'];
    if (draftData is Map) {
      final draftDataMap = Map<String, dynamic>.from(draftData);
      final owner = draftDataMap['owner'];
      if (owner is Map) {
        final ownerMap = Map<String, dynamic>.from(owner);
        final draftOwnerRole = ownerMap['role']?.toString().trim() ?? '';
        if (draftOwnerRole.isNotEmpty) {
          return draftOwnerRole;
        }
      }
    }

    return '';
  }

  static DateTime? _tryParseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static List<BuilderProjectComment> _readComments(Object? value) {
    if (value is! List) {
      return const <BuilderProjectComment>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              BuilderProjectComment.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}

class BuilderProjectComment {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime? createdAt;

  const BuilderProjectComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  factory BuilderProjectComment.fromJson(Map<String, dynamic> json) {
    return BuilderProjectComment(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'User',
      message: json['message']?.toString() ?? '',
      createdAt: SavedBuilderProject._tryParseDateTime(
        json['createdAt']?.toString(),
      ),
    );
  }
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
