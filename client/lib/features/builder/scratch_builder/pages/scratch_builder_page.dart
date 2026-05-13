import 'package:flutter/material.dart';

import 'package:client/core/models/auth_session.dart';

import '../models/block_template.dart';
import '../models/block_type.dart';
import '../models/instruction_section.dart';
import '../models/workspace_block.dart';
import '../widgets/instruction_editor_panel.dart';
import '../widgets/stage_panel.dart';
import '../widgets/top_bar.dart';
import '../widgets/workspace_panel.dart';

class ScratchBuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;

  const ScratchBuilderPage({
    super.key,
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
  });

  @override
  State<ScratchBuilderPage> createState() => _ScratchBuilderPageState();
}

class _ScratchBuilderPageState extends State<ScratchBuilderPage> {
  static const double blockHeight = 40;
  static const double containerBlockHeight = 86;
  static const double snapDistance = 24;

  late final TextEditingController _titleController;
  final List<InstructionSection> instructionSections = [];
  final List<WorkspaceBlock> workspaceBlocks = [];

  BlockType? selectedCategory;
  bool isDraggingWorkspaceBlock = false;
  bool isSaving = false;

  Offset spritePosition = const Offset(80, 80);
  double spriteRotation = 0;
  String spriteText = '';

  int _nextId = 1;
  int _nextInstructionId = 1;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? 'Scratch Builder',
    );
    instructionSections.addAll([
      InstructionSection(
        id: 'section_${_nextInstructionId++}',
        type: InstructionSectionType.overview,
        title: 'Overview',
        content: 'Describe what the learner will build.',
      ),
      InstructionSection(
        id: 'section_${_nextInstructionId++}',
        type: InstructionSectionType.instructions,
        title: 'Instructions',
        items: const ['Drag blocks into the workspace.', 'Run your program.'],
      ),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _toggleCategory(BlockType type) {
    setState(() {
      selectedCategory = selectedCategory == type ? null : type;
    });
  }

  void _setWorkspaceDragState(bool isDragging) {
    setState(() {
      isDraggingWorkspaceBlock = isDragging;
    });
  }

  void _addInstructionSection(InstructionSectionType type) {
    setState(() {
      instructionSections.add(
        InstructionSection(
          id: 'section_${_nextInstructionId++}',
          type: type,
          title: instructionSectionLabel(type),
          content: _defaultContentForInstructionType(type),
          items: _defaultItemsForInstructionType(type),
        ),
      );
    });
  }

  void _removeInstructionSection(String id) {
    setState(() {
      instructionSections.removeWhere((section) => section.id == id);
    });
  }

  void _moveInstructionSection(String id, int direction) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      final newIndex = index + direction;
      if (newIndex < 0 || newIndex >= instructionSections.length) return;

      final section = instructionSections.removeAt(index);
      instructionSections.insert(newIndex, section);
    });
  }

  void _updateInstructionTitle(String id, String title) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      instructionSections[index] = instructionSections[index].copyWith(
        title: title,
      );
    });
  }

  void _updateInstructionContent(String id, String content) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      instructionSections[index] = instructionSections[index].copyWith(
        content: content,
      );
    });
  }

  void _addInstructionItem(String id) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      final section = instructionSections[index];

      instructionSections[index] = section.copyWith(
        items: [...section.items, ''],
      );
    });
  }

  void _updateInstructionItem(String id, int itemIndex, String value) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) return;

      final items = [...section.items];
      items[itemIndex] = value;

      instructionSections[index] = section.copyWith(items: items);
    });
  }

  void _removeInstructionItem(String id, int itemIndex) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) return;

      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) return;

      final items = [...section.items]..removeAt(itemIndex);

      instructionSections[index] = section.copyWith(items: items);
    });
  }

  String _defaultContentForInstructionType(InstructionSectionType type) {
    switch (type) {
      case InstructionSectionType.overview:
        return 'Describe what the learner will build.';
      case InstructionSectionType.codeExample:
        return 'Move 10 Steps\nRepeat 5 Times';
      case InstructionSectionType.expectedOutput:
        return 'Describe what should happen when the learner runs the project.';
      case InstructionSectionType.custom:
        return '';
      case InstructionSectionType.instructions:
      case InstructionSectionType.checklist:
      case InstructionSectionType.hints:
      case InstructionSectionType.resources:
        return '';
    }
  }

  List<String> _defaultItemsForInstructionType(InstructionSectionType type) {
    switch (type) {
      case InstructionSectionType.instructions:
        return const [''];
      case InstructionSectionType.checklist:
        return const [''];
      case InstructionSectionType.hints:
        return const [''];
      case InstructionSectionType.resources:
        return const [''];
      case InstructionSectionType.overview:
      case InstructionSectionType.codeExample:
      case InstructionSectionType.expectedOutput:
      case InstructionSectionType.custom:
        return const [];
    }
  }

  void _addBlock(BlockTemplate template, Offset localPosition) {
    final defaultInputs = {
      for (final input in template.inputs) input.key: input.defaultValue,
    };

    setState(() {
      workspaceBlocks.add(
        WorkspaceBlock(
          id: 'block_${_nextId++}',
          template: template,
          inputValues: defaultInputs,
          position: Offset(
            (localPosition.dx - 24).clamp(10, 360),
            (localPosition.dy - 20).clamp(10, 560),
          ),
        ),
      );
    });
  }

  void _updateBlockInput(String blockId, String inputKey, String value) {
    setState(() {
      final index = workspaceBlocks.indexWhere((b) => b.id == blockId);
      if (index == -1) return;

      final block = workspaceBlocks[index];

      workspaceBlocks[index] = block.copyWith(
        inputValues: {...block.inputValues, inputKey: value},
      );
    });
  }

  void _moveBlockStack(String id, Offset delta) {
    setState(() {
      final stackIds = _getStackFrom(id);

      for (final stackId in stackIds) {
        final index = workspaceBlocks.indexWhere((b) => b.id == stackId);
        if (index == -1) continue;

        final block = workspaceBlocks[index];

        workspaceBlocks[index] = block.copyWith(
          position: Offset(
            (block.position.dx + delta.dx).clamp(0, 900),
            (block.position.dy + delta.dy).clamp(0, 700),
          ),
        );
      }
    });
  }

  void _detachFromParent(String id) {
    setState(() {
      final index = workspaceBlocks.indexWhere((b) => b.id == id);
      if (index == -1) return;

      final block = workspaceBlocks[index];

      if (block.previousBlockId == null) return;

      final parentIndex = workspaceBlocks.indexWhere(
        (b) => b.id == block.previousBlockId,
      );

      if (parentIndex != -1) {
        workspaceBlocks[parentIndex] = workspaceBlocks[parentIndex].copyWith(
          clearNextBlockId: true,
        );
      }

      workspaceBlocks[index] = block.copyWith(clearPreviousBlockId: true);
    });
  }

  void _snapBlockStack(String draggedId) {
    setState(() {
      final draggedIndex = workspaceBlocks.indexWhere((b) => b.id == draggedId);
      if (draggedIndex == -1) return;

      final dragged = workspaceBlocks[draggedIndex];
      final draggedStackIds = _getStackFrom(draggedId);

      WorkspaceBlock? bestTarget;
      double bestDistance = double.infinity;

      for (final target in workspaceBlocks) {
        if (draggedStackIds.contains(target.id)) continue;
        if (target.nextBlockId != null) continue;
        if (!_canStackOnTop(target.template, dragged.template)) continue;

        final targetBottom = Offset(
          target.position.dx,
          target.position.dy + _heightFor(target),
        );

        final distance = (dragged.position - targetBottom).distance;

        if (distance < snapDistance && distance < bestDistance) {
          bestDistance = distance;
          bestTarget = target;
        }
      }

      if (bestTarget == null) return;

      final newDraggedPosition = Offset(
        bestTarget.position.dx,
        bestTarget.position.dy + _heightFor(bestTarget),
      );

      final offsetDelta = newDraggedPosition - dragged.position;

      for (final stackId in draggedStackIds) {
        final index = workspaceBlocks.indexWhere((b) => b.id == stackId);
        if (index == -1) continue;

        final block = workspaceBlocks[index];

        workspaceBlocks[index] = block.copyWith(
          position: block.position + offsetDelta,
        );
      }

      final targetIndex = workspaceBlocks.indexWhere(
        (b) => b.id == bestTarget!.id,
      );

      final draggedNewIndex = workspaceBlocks.indexWhere(
        (b) => b.id == draggedId,
      );

      if (targetIndex != -1 && draggedNewIndex != -1) {
        workspaceBlocks[targetIndex] = workspaceBlocks[targetIndex].copyWith(
          nextBlockId: draggedId,
        );

        workspaceBlocks[draggedNewIndex] = workspaceBlocks[draggedNewIndex]
            .copyWith(previousBlockId: bestTarget.id);
      }
    });
  }

  void _deleteBlockStack(String id) {
    setState(() {
      final stackIds = _getStackFrom(id);

      final draggedBlock = workspaceBlocks.firstWhereOrNull((b) => b.id == id);
      if (draggedBlock?.previousBlockId != null) {
        final parentIndex = workspaceBlocks.indexWhere(
          (b) => b.id == draggedBlock!.previousBlockId,
        );

        if (parentIndex != -1) {
          workspaceBlocks[parentIndex] = workspaceBlocks[parentIndex].copyWith(
            clearNextBlockId: true,
          );
        }
      }

      workspaceBlocks.removeWhere((block) => stackIds.contains(block.id));
      isDraggingWorkspaceBlock = false;
    });
  }

  bool _canStackOnTop(BlockTemplate top, BlockTemplate bottom) {
    if (top.shape == BlockShape.cap) return false;
    if (bottom.shape == BlockShape.reporter) return false;
    if (bottom.shape == BlockShape.boolean) return false;
    return true;
  }

  List<String> _getStackFrom(String startId) {
    final ids = <String>[];
    String? currentId = startId;

    while (currentId != null) {
      final block = workspaceBlocks.firstWhereOrNull((b) => b.id == currentId);
      if (block == null) break;

      ids.add(block.id);
      currentId = block.nextBlockId;
    }

    return ids;
  }

  double _heightFor(WorkspaceBlock block) {
    return block.template.isContainer ? containerBlockHeight : blockHeight;
  }

  Future<void> _runBlocks() async {
    final topBlocks =
        workspaceBlocks.where((block) => block.previousBlockId == null).toList()
          ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

    setState(() {
      spriteText = '';
    });

    for (final topBlock in topBlocks) {
      final stackIds = _getStackFrom(topBlock.id);

      for (final id in stackIds) {
        final block = workspaceBlocks.firstWhereOrNull((b) => b.id == id);
        if (block == null) continue;

        await Future.delayed(const Duration(milliseconds: 400));

        setState(() {
          switch (block.template.label) {
            case 'Move {steps} Steps':
              final steps = _readDoubleInput(block, 'steps');
              spritePosition = Offset(
                spritePosition.dx + steps * 1.8,
                spritePosition.dy,
              );
              break;
            case 'Turn {degrees}\u00b0':
              final degrees = _readDoubleInput(block, 'degrees');
              spriteRotation += degrees * 0.0166667;
              break;
            case 'Go To X: {x} Y: {y}':
              final x = _readDoubleInput(block, 'x');
              final y = _readDoubleInput(block, 'y');
              spritePosition = Offset(80 + x, 80 + y);
              break;
            case 'Say {message}':
              spriteText = _readTextInput(block, 'message');
              break;
            case 'Think {message}':
              spriteText = _readTextInput(block, 'message');
              break;
            case 'Wait {seconds} Second':
              break;
            case 'Repeat {times} Times':
              final times = _readDoubleInput(block, 'times');
              spritePosition = Offset(
                spritePosition.dx + times * 10,
                spritePosition.dy,
              );
              break;
          }
        });
      }
    }
  }

  double _readDoubleInput(WorkspaceBlock block, String key) {
    final text =
        block.inputValues[key] ??
        block.template.inputs
            .firstWhereOrNull((input) => input.key == key)
            ?.defaultValue;

    return double.tryParse(text ?? '') ?? 0;
  }

  String _readTextInput(WorkspaceBlock block, String key) {
    return block.inputValues[key] ??
        block.template.inputs
            .firstWhereOrNull((input) => input.key == key)
            ?.defaultValue ??
        '';
  }

  void _reset() {
    setState(() {
      workspaceBlocks.clear();
      spritePosition = const Offset(80, 80);
      spriteRotation = 0;
      spriteText = '';
      selectedCategory = null;
      isDraggingWorkspaceBlock = false;
    });
  }

  Future<void> _saveProject({required bool publish}) async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(publish ? 'Project published' : 'Draft saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              titleController: _titleController,
              onRun: _runBlocks,
              onReset: _reset,
              onSaveDraft: () => _saveProject(publish: false),
              onPublish: () => _saveProject(publish: true),
              isSaving: isSaving,
              playMode: widget.playMode,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InstructionEditorPanel(
                      sections: instructionSections,
                      onAddSection: _addInstructionSection,
                      onRemoveSection: _removeInstructionSection,
                      onMoveSection: _moveInstructionSection,
                      onTitleChanged: _updateInstructionTitle,
                      onContentChanged: _updateInstructionContent,
                      onAddItem: _addInstructionItem,
                      onItemChanged: _updateInstructionItem,
                      onRemoveItem: _removeInstructionItem,
                    ),
                  ),
                  Expanded(
                    child: WorkspacePanel(
                      blocks: workspaceBlocks,
                      selectedCategory: selectedCategory,
                      isDraggingWorkspaceBlock: isDraggingWorkspaceBlock,
                      onCategoryPressed: _toggleCategory,
                      onAcceptTemplate: _addBlock,
                      onDetachBlock: _detachFromParent,
                      onMoveBlockStack: _moveBlockStack,
                      onSnapBlockStack: _snapBlockStack,
                      onDeleteBlockStack: _deleteBlockStack,
                      onUpdateBlockInput: _updateBlockInput,
                      onWorkspaceDragStateChanged: _setWorkspaceDragState,
                    ),
                  ),
                  Expanded(
                    child: StagePanel(
                      spritePosition: spritePosition,
                      spriteRotation: spriteRotation,
                      spriteText: spriteText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }

    return null;
  }
}
