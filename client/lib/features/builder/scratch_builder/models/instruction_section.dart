import 'package:client/core/localization/app_language.dart';

enum InstructionSectionType {
  overview,
  instructions,
  checklist,
  hints,
  codeExample,
  expectedOutput,
  resources,
  custom,
}

class InstructionSection {
  final String id;
  final InstructionSectionType type;
  final String title;
  final String content;
  final List<String> items;
  final bool collapsed;

  const InstructionSection({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    this.items = const [],
    this.collapsed = false,
  });

  InstructionSection copyWith({
    String? id,
    InstructionSectionType? type,
    String? title,
    String? content,
    List<String>? items,
    bool? collapsed,
  }) {
    return InstructionSection(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      items: items ?? this.items,
      collapsed: collapsed ?? this.collapsed,
    );
  }
}

String instructionSectionLabel(InstructionSectionType type) {
  return localizedInstructionSectionLabel(AppLanguage.instance, type);
}

String localizedInstructionSectionLabel(
  AppLanguage language,
  InstructionSectionType type,
) {
  switch (type) {
    case InstructionSectionType.overview:
      return language.t('builder.overview');
    case InstructionSectionType.instructions:
      return language.t('builder.instructions');
    case InstructionSectionType.checklist:
      return language.tr('builder.checklist', 'Checklist');
    case InstructionSectionType.hints:
      return language.tr('builder.hints', 'Hints');
    case InstructionSectionType.codeExample:
      return language.t('builder.codeExample');
    case InstructionSectionType.expectedOutput:
      return language.tr('builder.expectedOutput', 'Expected Output');
    case InstructionSectionType.resources:
      return language.tr('builder.resources', 'Resources');
    case InstructionSectionType.custom:
      return language.tr('builder.customSection', 'Custom Section');
  }
}
