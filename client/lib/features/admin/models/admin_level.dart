class AdminLevel {
  final String id;
  final String title;
  final String creatorName;
  final bool isCreatedByAdmin;
  final String difficulty;
  final String status; // published, draft, userCreated
  final String courseId;
  final int orderInCourse;
  final String? previewImageUrl;

  const AdminLevel({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.isCreatedByAdmin,
    required this.difficulty,
    required this.status,
    this.courseId = '',
    this.orderInCourse = 0,
    this.previewImageUrl,
  });

  factory AdminLevel.fromJson(Map<String, dynamic> json) {
    final ownerRole = json['ownerRole']?.toString();
    final isCreatedByAdmin =
        json['isCreatedByAdmin'] == true ||
        ownerRole == 'admin' ||
        json['createdByRole'] == 'admin';
    final rawStatus = json['status']?.toString() ?? 'draft';
    final draftData = json['draftData'];
    final draftDataMap = draftData is Map
        ? Map<String, dynamic>.from(draftData)
        : <String, dynamic>{};

    return AdminLevel(
      id: _readString(json, '_id', fallbackKey: 'id'),
      title: _readString(json, 'title', fallbackKey: 'name'),
      creatorName: _readCreatorName(json),
      isCreatedByAdmin: isCreatedByAdmin,
      difficulty: _capitalize(
        _readString(json, 'difficulty', fallback: 'medium'),
      ),
      status: isCreatedByAdmin ? rawStatus : 'userCreated',
      courseId: _readString(json, 'courseId'),
      orderInCourse: _readInt(json['orderInCourse']),
      previewImageUrl:
          json['previewImageUrl']?.toString() ??
          draftDataMap['previewImageUrl']?.toString(),
    );
  }
}

String _readCreatorName(Map<String, dynamic> json) {
  final creator = json['creator'];

  if (creator is Map) {
    final creatorMap = Map<String, dynamic>.from(creator);
    final name = creatorMap['name']?.toString();

    if (name != null && name.isNotEmpty) {
      return name;
    }
  }

  return json['creatorName']?.toString() ??
      json['ownerName']?.toString() ??
      'Unknown';
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

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
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
