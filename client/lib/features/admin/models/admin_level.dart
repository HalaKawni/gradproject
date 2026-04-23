class AdminLevel {
  final String id;
  final String title;
  final String creatorName;
  final bool isCreatedByAdmin;
  final String difficulty;
  final String status; // published, draft, userCreated
  final String? previewImageUrl;

  const AdminLevel({
    required this.id,
    required this.title,
    required this.creatorName,
    required this.isCreatedByAdmin,
    required this.difficulty,
    required this.status,
    this.previewImageUrl,
  });
}