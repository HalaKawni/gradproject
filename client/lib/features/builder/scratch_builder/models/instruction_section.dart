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
  switch (type) {
    case InstructionSectionType.overview:
      return 'Overview';
    case InstructionSectionType.instructions:
      return 'Instructions';
    case InstructionSectionType.checklist:
      return 'Checklist';
    case InstructionSectionType.hints:
      return 'Hints';
    case InstructionSectionType.codeExample:
      return 'Code Example';
    case InstructionSectionType.expectedOutput:
      return 'Expected Output';
    case InstructionSectionType.resources:
      return 'Resources';
    case InstructionSectionType.custom:
      return 'Custom Section';
  }
}
