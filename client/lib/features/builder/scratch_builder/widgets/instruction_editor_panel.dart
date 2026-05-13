import 'package:flutter/material.dart';

import '../models/instruction_section.dart';
import 'rich_instruction_editor.dart';

class InstructionEditorPanel extends StatelessWidget {
  final List<InstructionSection> sections;
  final void Function(InstructionSectionType type) onAddSection;
  final void Function(String id) onRemoveSection;
  final void Function(String id, int direction) onMoveSection;
  final void Function(String id, String title) onTitleChanged;
  final void Function(String id, String content) onContentChanged;
  final void Function(String id) onAddItem;
  final void Function(String id, int itemIndex, String value) onItemChanged;
  final void Function(String id, int itemIndex) onRemoveItem;

  const InstructionEditorPanel({
    super.key,
    required this.sections,
    required this.onAddSection,
    required this.onRemoveSection,
    required this.onMoveSection,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.onAddItem,
    required this.onItemChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Instruction Builder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<InstructionSectionType>(
                    tooltip: 'Add section',
                    onSelected: onAddSection,
                    itemBuilder: (context) {
                      return InstructionSectionType.values.map((type) {
                        return PopupMenuItem(
                          value: type,
                          child: Text(instructionSectionLabel(type)),
                        );
                      }).toList();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sections.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Add sections for the learner to read before building.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: sections.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final section = sections[index];

                        return _InstructionSectionCard(
                          key: ValueKey(section.id),
                          section: section,
                          isFirst: index == 0,
                          isLast: index == sections.length - 1,
                          onRemove: () => onRemoveSection(section.id),
                          onMoveUp: () => onMoveSection(section.id, -1),
                          onMoveDown: () => onMoveSection(section.id, 1),
                          onTitleChanged: (value) {
                            onTitleChanged(section.id, value);
                          },
                          onContentChanged: (value) {
                            onContentChanged(section.id, value);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionSectionCard extends StatefulWidget {
  final InstructionSection section;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onContentChanged;

  const _InstructionSectionCard({
    super.key,
    required this.section,
    required this.isFirst,
    required this.isLast,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onTitleChanged,
    required this.onContentChanged,
  });

  @override
  State<_InstructionSectionCard> createState() =>
      _InstructionSectionCardState();
}

class _InstructionSectionCardState extends State<_InstructionSectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffd9e1ea)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xff64748b),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        instructionSectionLabel(widget.section.type),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Move up',
                      onPressed: widget.isFirst ? null : widget.onMoveUp,
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                    IconButton(
                      tooltip: 'Move down',
                      onPressed: widget.isLast ? null : widget.onMoveDown,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    IconButton(
                      tooltip: 'Delete section',
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _SectionBody(
                section: widget.section,
                onTitleChanged: widget.onTitleChanged,
                onContentChanged: widget.onContentChanged,
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 160),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final InstructionSection section;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onContentChanged;

  const _SectionBody({
    required this.section,
    required this.onTitleChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: ValueKey('title_${section.id}'),
          initialValue: section.title,
          decoration: const InputDecoration(
            labelText: 'Title',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 10),
        RichInstructionEditor(
          key: ValueKey('content_${section.id}'),
          initialValue: _initialEditorValue(section),
          placeholder: section.type == InstructionSectionType.codeExample
              ? 'Write or paste an example.'
              : 'Start writing...',
          maxHeight: section.type == InstructionSectionType.codeExample
              ? 300
              : 240,
          onChanged: onContentChanged,
        ),
      ],
    );
  }

  String _initialEditorValue(InstructionSection section) {
    if (section.content.trim().isNotEmpty) return section.content;
    if (section.items.isEmpty) return '';

    return section.items.where((item) => item.trim().isNotEmpty).join('\n');
  }
}
