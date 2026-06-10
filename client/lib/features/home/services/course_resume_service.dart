import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CourseResumeEntry {
  const CourseResumeEntry({
    required this.courseLookupId,
    this.levelId,
    this.legacyPageKey,
    this.updatedAt,
  });

  final String courseLookupId;
  final String? levelId;
  final String? legacyPageKey;
  final DateTime? updatedAt;

  bool get isLegacyCourse => (legacyPageKey ?? '').isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'courseLookupId': courseLookupId,
      'levelId': levelId,
      'legacyPageKey': legacyPageKey,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CourseResumeEntry.fromJson(Map<String, dynamic> json) {
    return CourseResumeEntry(
      courseLookupId: json['courseLookupId']?.toString() ?? '',
      levelId: json['levelId']?.toString(),
      legacyPageKey: json['legacyPageKey']?.toString(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}

class CourseResumeService {
  static String _storageKey(String userId) => 'dashboard.resumeCourse.$userId';

  static Future<CourseResumeEntry?> load(String userId) async {
    if (userId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final entry = CourseResumeEntry.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return entry.courseLookupId.isEmpty ? null : entry;
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePublicCourse({
    required String userId,
    required String courseLookupId,
    required String levelId,
  }) async {
    if (userId.isEmpty || courseLookupId.isEmpty || levelId.isEmpty) {
      return;
    }

    await _save(
      userId,
      CourseResumeEntry(
        courseLookupId: courseLookupId,
        levelId: levelId,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  static Future<void> saveLegacyCourse({
    required String userId,
    required String courseLookupId,
    required String legacyPageKey,
  }) async {
    if (userId.isEmpty || courseLookupId.isEmpty || legacyPageKey.isEmpty) {
      return;
    }

    await _save(
      userId,
      CourseResumeEntry(
        courseLookupId: courseLookupId,
        legacyPageKey: legacyPageKey,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  static Future<void> _save(String userId, CourseResumeEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(userId), jsonEncode(entry.toJson()));
  }
}
