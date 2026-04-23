class SavedBuilderProject {
  final String id;
  final String title;
  final String description;
  final String status;
  final String publisherName;
  final DateTime? updatedAt;

  const SavedBuilderProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.publisherName,
    required this.updatedAt,
  });

  factory SavedBuilderProject.fromJson(Map<String, dynamic> json) {
    return SavedBuilderProject(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      publisherName: _readPublisherName(json),
      updatedAt: _tryParseDateTime(json['updatedAt']?.toString()),
    );
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
