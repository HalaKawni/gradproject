import 'dart:async';

import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';

import '../models/block_template.dart';
import '../models/block_type.dart';
import '../models/instruction_section.dart';
import '../models/workspace_block.dart';
import '../data/block_templates.dart';
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
  static const double blockHeight = 35;
  static const double containerBlockHeight = 81;
  static const double snapDistance = 40;

  late final TextEditingController _titleController;
  final List<InstructionSection> instructionSections = [];
  final List<WorkspaceBlock> workspaceBlocks = [];

  BlockType? selectedCategory;
  bool isDraggingWorkspaceBlock = false;
  bool isSaving = false;
  bool isLoading = false;

  Offset spritePosition = const Offset(80, 80);
  double spriteRotation = 0;
  String spriteText = '';

  int _nextId = 1;
  int _nextInstructionId = 1;
  String? _savedProjectId;
  String _courseId = '';
  int _orderInCourse = 0;
  String _difficulty = 'medium';
  String _status = 'draft';
  Timer? _titleSaveDebounce;
  String? _lastAutoSavedTitle;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? 'New Level',
    );
    _titleController.addListener(_handleTitleChanged);
    _courseId = widget.initialCourseId ?? '';
    _orderInCourse = widget.initialOrderInCourse ?? 0;
    _difficulty = widget.initialDifficulty;
    _status = widget.initialStatus;
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
    if (widget.initialProjectId != null) {
      _loadProject(widget.initialProjectId!);
    }
  }

  @override
  void dispose() {
    _titleSaveDebounce?.cancel();
    _titleController.removeListener(_handleTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  void _handleTitleChanged() {
    if (widget.playMode || isLoading) {
      return;
    }

    _titleSaveDebounce?.cancel();
    _titleSaveDebounce = Timer(const Duration(milliseconds: 700), () {
      _autoSaveTitle();
    });
  }

  Future<void> _autoSaveTitle() async {
    final normalizedTitle = _normalizedTitle;
    if (_lastAutoSavedTitle == normalizedTitle || isSaving) {
      return;
    }

    _lastAutoSavedTitle = normalizedTitle;
    await _saveProject(publish: _status == 'published', showFeedback: false);
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

  void _reorderInstructionSections(int oldIndex, int newIndex) {
    setState(() {
      final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final section = instructionSections.removeAt(oldIndex);
      instructionSections.insert(adjustedNewIndex, section);
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

  Future<void> _saveProject({
    required bool publish,
    bool showFeedback = true,
  }) async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final projectJson = _buildProjectJson(
        status: publish ? 'published' : 'draft',
      );
      final response = _savedProjectId == null
          ? await ApiService.createBuilderProject(
              authToken: widget.session.token,
              projectJson: projectJson,
            )
          : widget.useAdminLevelApi
          ? await ApiService.updateAdminLevel(
              authToken: widget.session.token,
              levelId: _savedProjectId!,
              levelJson: {
                'title': projectJson['title'],
                'description': projectJson['description'],
                'status': projectJson['status'],
                'builderType': projectJson['builderType'],
                'courseId': projectJson['courseId'],
                'orderInCourse': projectJson['orderInCourse'],
                'difficulty': projectJson['difficulty'],
                'draftData': projectJson,
              },
            )
          : await ApiService.updateBuilderProject(
              authToken: widget.session.token,
              projectId: _savedProjectId!,
              projectJson: projectJson,
            );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['_id'] != null) {
          _savedProjectId = data['_id'].toString();
        }
        _status = publish ? 'published' : 'draft';
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(publish ? 'Project published' : 'Draft saved'),
            ),
          );
        }
      } else if (showFeedback) {
        final errors = response['errors'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errors is List && errors.isNotEmpty
                  ? errors.join('\n')
                  : response['message']?.toString() ??
                        'Failed to save project.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted || !showFeedback) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _loadProject(String projectId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = widget.allowPublishedAccess
          ? await ApiService.getPublishedBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            )
          : widget.useAdminLevelApi
          ? await ApiService.getAdminLevelById(
              authToken: widget.session.token,
              levelId: projectId,
            )
          : await ApiService.getBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            );

      if (!mounted) return;

      if (response['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Failed to load scratch project.',
            ),
          ),
        );
        return;
      }

      final data = Map<String, dynamic>.from(response['data'] as Map);
      final rawDraftData = data['draftData'];
      final draftData = rawDraftData is Map
          ? Map<String, dynamic>.from(rawDraftData)
          : data;
      final loadedSections = _readInstructionSections(
        draftData['instructionSections'],
      );
      final loadedBlocks = _readWorkspaceBlocks(draftData['workspaceBlocks']);

      setState(() {
        _savedProjectId = data['_id']?.toString() ?? projectId;
        _courseId =
            data['courseId']?.toString() ??
            draftData['courseId']?.toString() ??
            _courseId;
        _orderInCourse =
            _readInt(data['orderInCourse']) ??
            _readInt(draftData['orderInCourse']) ??
            _orderInCourse;
        _difficulty =
            data['difficulty']?.toString() ??
            draftData['difficulty']?.toString() ??
            _difficulty;
        _status =
            data['status']?.toString() ??
            draftData['status']?.toString() ??
            _status;
        _titleController.text =
            data['title']?.toString() ??
            draftData['title']?.toString() ??
            widget.initialTitle ??
            'New Level';
        instructionSections
          ..clear()
          ..addAll(loadedSections);
        workspaceBlocks
          ..clear()
          ..addAll(loadedBlocks);
        final sprite = draftData['sprite'] is Map
            ? Map<String, dynamic>.from(draftData['sprite'] as Map)
            : const <String, dynamic>{};
        spritePosition = Offset(
          _readDouble(sprite['x']) ??
              _readDouble(draftData['spriteX']) ??
              spritePosition.dx,
          _readDouble(sprite['y']) ??
              _readDouble(draftData['spriteY']) ??
              spritePosition.dy,
        );
        spriteRotation =
            _readDouble(sprite['rotation']) ??
            _readDouble(draftData['spriteRotation']) ??
            0;
        spriteText =
            sprite['text']?.toString() ??
            draftData['spriteText']?.toString() ??
            '';
        _nextInstructionId = _nextNumericSuffix(
          instructionSections.map((section) => section.id),
          prefix: 'section_',
        );
        _nextId = _nextNumericSuffix(
          workspaceBlocks.map((block) => block.id),
          prefix: 'block_',
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String get _normalizedTitle => _titleController.text.trim().isEmpty
      ? 'New Level'
      : _titleController.text.trim();

  Map<String, dynamic> _buildProjectJson({required String status}) {
    return {
      'builderType': 'scratch',
      'title': _normalizedTitle,
      'description': '',
      'status': status,
      'courseId': _courseId,
      'orderInCourse': _orderInCourse,
      'difficulty': _difficulty,
      'settings': {'stageWidth': 480, 'stageHeight': 360},
      'instructionSections': instructionSections
          .map(
            (section) => {
              'id': section.id,
              'type': section.type.name,
              'title': section.title,
              'content': section.content,
              'items': section.items,
              'collapsed': section.collapsed,
            },
          )
          .toList(),
      'workspaceBlocks': workspaceBlocks
          .map(
            (block) => {
              'id': block.id,
              'label': block.template.label,
              'x': block.position.dx,
              'y': block.position.dy,
              'previousBlockId': block.previousBlockId,
              'nextBlockId': block.nextBlockId,
              'inputValues': block.inputValues,
            },
          )
          .toList(),
      'sprite': {
        'x': spritePosition.dx,
        'y': spritePosition.dy,
        'rotation': spriteRotation,
        'text': spriteText,
      },
    };
  }

  List<InstructionSection> _readInstructionSections(Object? rawValue) {
    if (rawValue is! List) {
      return List<InstructionSection>.from(instructionSections);
    }

    final sections = <InstructionSection>[];
    for (final rawSection in rawValue) {
      if (rawSection is! Map) continue;
      final section = Map<String, dynamic>.from(rawSection);
      final type = _readInstructionSectionType(section['type']);
      sections.add(
        InstructionSection(
          id: section['id']?.toString() ?? 'section_${sections.length + 1}',
          type: type,
          title: section['title']?.toString() ?? instructionSectionLabel(type),
          content: section['content']?.toString() ?? '',
          items: section['items'] is List
              ? (section['items'] as List)
                    .map((item) => item.toString())
                    .toList()
              : const [],
          collapsed: section['collapsed'] == true,
        ),
      );
    }

    return sections.isEmpty
        ? List<InstructionSection>.from(instructionSections)
        : sections;
  }

  List<WorkspaceBlock> _readWorkspaceBlocks(Object? rawValue) {
    if (rawValue is! List) {
      return const [];
    }

    final blocks = <WorkspaceBlock>[];
    for (final rawBlock in rawValue) {
      if (rawBlock is! Map) continue;
      final block = Map<String, dynamic>.from(rawBlock);
      final template = _blockTemplateByLabel(block['label']?.toString());
      if (template == null) continue;
      final rawInputValues = block['inputValues'];
      final inputValues = rawInputValues is Map
          ? Map<String, String>.from(
              rawInputValues.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const <String, String>{};
      blocks.add(
        WorkspaceBlock(
          id: block['id']?.toString() ?? 'block_${blocks.length + 1}',
          template: template,
          position: Offset(
            _readDouble(block['x']) ?? 0,
            _readDouble(block['y']) ?? 0,
          ),
          previousBlockId: block['previousBlockId']?.toString(),
          nextBlockId: block['nextBlockId']?.toString(),
          inputValues: inputValues,
        ),
      );
    }

    return blocks;
  }

  InstructionSectionType _readInstructionSectionType(Object? value) {
    final name = value?.toString();
    for (final type in InstructionSectionType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return InstructionSectionType.custom;
  }

  BlockTemplate? _blockTemplateByLabel(String? label) {
    if (label == null) {
      return null;
    }
    return blockTemplates.firstWhereOrNull(
      (template) => template.label == label,
    );
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  int _nextNumericSuffix(Iterable<String> ids, {required String prefix}) {
    var next = 1;
    for (final id in ids) {
      if (!id.startsWith(prefix)) continue;
      final value = int.tryParse(id.substring(prefix.length));
      if (value != null && value >= next) {
        next = value + 1;
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fb),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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
                          flex: 34,
                          child: InstructionEditorPanel(
                            sections: instructionSections,
                            onAddSection: _addInstructionSection,
                            onRemoveSection: _removeInstructionSection,
                            onReorderSections: _reorderInstructionSections,
                            onTitleChanged: _updateInstructionTitle,
                            onContentChanged: _updateInstructionContent,
                            onAddItem: _addInstructionItem,
                            onItemChanged: _updateInstructionItem,
                            onRemoveItem: _removeInstructionItem,
                          ),
                        ),
                        Expanded(
                          flex: 43,
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
                          flex: 43,
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
