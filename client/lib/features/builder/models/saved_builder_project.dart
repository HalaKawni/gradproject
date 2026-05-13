class SavedBuilderProject {
  final String id;
  final String title;
  final String description;
  final String status;
  final String builderType;
  final String publisherName;
  final String difficulty;
  final String courseId;
  final int orderInCourse;
  final DateTime? updatedAt;

  const SavedBuilderProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.builderType,
    required this.publisherName,
    required this.difficulty,
    required this.courseId,
    required this.orderInCourse,
    required this.updatedAt,
  });

  factory SavedBuilderProject.fromJson(Map<String, dynamic> json) {
    return SavedBuilderProject(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      builderType: _readBuilderType(json),
      publisherName: _readPublisherName(json),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      courseId: json['courseId']?.toString() ?? '',
      orderInCourse: _readInt(json['orderInCourse']),
      updatedAt: _tryParseDateTime(json['updatedAt']?.toString()),
    );
  }

  bool get isTopView => builderType == 'topView';

  bool get isScratch => builderType == 'scratch';

  static String _readBuilderType(Map<String, dynamic> json) {
    final directType = json['builderType']?.toString().trim();
    if (directType == 'topView' ||
        directType == 'frontView' ||
        directType == 'scratch') {
      return directType!;
    }

    final draftData = json['draftData'];
    if (draftData is Map) {
      final draftDataMap = Map<String, dynamic>.from(draftData);
      final draftType = draftDataMap['builderType']?.toString().trim();
      if (draftType == 'topView' ||
          draftType == 'frontView' ||
          draftType == 'scratch') {
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

  static DateTime? _tryParseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
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
