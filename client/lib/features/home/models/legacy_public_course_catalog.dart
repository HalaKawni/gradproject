import 'package:flutter/material.dart';

class LegacyPublicCourseMetadata {
  const LegacyPublicCourseMetadata({
    required this.courseId,
    required this.topic,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    required this.description,
    required this.legacyPageKey,
  });

  final String courseId;
  final String topic;
  final String level;
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;
  final String description;
  final String legacyPageKey;
}

const Map<String, LegacyPublicCourseMetadata> legacyPublicCourseCatalog = {
  'legacy-data-is-everywhere': LegacyPublicCourseMetadata(
    courseId: 'legacy-data-is-everywhere',
    topic: 'CS Topics',
    level: 'Beginner',
    title: 'Data is Everywhere',
    subtitle: 'Functions & Variables',
    color: Color(0xFF4A90C4),
    imagePath: 'assets/images/datacourse.png',
    description:
        'Get a glimpse into the world of data. Learn what data is and how to collect it. You will also learn how to organize your data using different graphing visualizations.',
    legacyPageKey: 'data_is_everywhere',
  ),
  'legacy-banana-tales': LegacyPublicCourseMetadata(
    courseId: 'legacy-banana-tales',
    topic: 'Text Coding',
    level: 'Beginner',
    title: 'Banana Tales',
    subtitle: 'Loops & Conditions',
    color: Color(0xFFE8A838),
    imagePath: 'assets/images/elephant.png',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'banana_tales',
  ),
  'legacy-digital-literacy': LegacyPublicCourseMetadata(
    courseId: 'legacy-digital-literacy',
    topic: 'Digital Literacy',
    level: 'Beginner',
    title: 'Digital Literacy',
    subtitle: 'Internet Safety',
    color: Color(0xFF9B7BCB),
    imagePath: 'assets/images/digitalcourse.png',
    description:
        'A short introduction to some important topics in the digital world: How to use computers, what are software and hardware, possible threats online and protecting your privacy.',
    legacyPageKey: 'digital_literacy',
  ),
  'legacy-game-builder': LegacyPublicCourseMetadata(
    courseId: 'legacy-game-builder',
    topic: 'Text Coding',
    level: 'Intermediate',
    title: 'Game Builder',
    subtitle: 'Game Design',
    color: Color(0xFFE57373),
    imagePath: 'assets/images/monkey_yes.png',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'game_builder',
  ),
  'legacy-coding-chatbots': LegacyPublicCourseMetadata(
    courseId: 'legacy-coding-chatbots',
    topic: 'Coding',
    level: 'Intermediate',
    title: 'AI is a Hoot',
    subtitle: 'AI & Logic',
    color: Color(0xFF4DB6AC),
    imagePath: 'assets/images/aicourse.png',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'coding_chatbots',
  ),
  'legacy-data-science': LegacyPublicCourseMetadata(
    courseId: 'legacy-data-science',
    topic: 'Text Coding',
    level: 'Advanced',
    title: 'Data Science',
    subtitle: 'Python & Data',
    color: Color(0xFF7986CB),
    imagePath: 'assets/images/elephant.png',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'data_science',
  ),
};

LegacyPublicCourseMetadata? legacyPublicCourseMetadataForCourseId(
  String courseId,
) {
  return legacyPublicCourseCatalog[courseId.trim()];
}
