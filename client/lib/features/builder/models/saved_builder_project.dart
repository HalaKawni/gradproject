class SavedBuilderProject {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime? updatedAt;

  const SavedBuilderProject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.updatedAt,
  });

  factory SavedBuilderProject.fromJson(Map<String, dynamic> json) {
    return SavedBuilderProject(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      updatedAt: _tryParseDateTime(json['updatedAt']?.toString()),
    );
  }

  static DateTime? _tryParseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
