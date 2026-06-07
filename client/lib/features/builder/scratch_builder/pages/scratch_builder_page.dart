import 'dart:async';
import 'dart:math' as math;

import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/builder/shared/widgets/course_level_nav_banner.dart';
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
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;

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
    this.courseProgressCourseId,
    this.courseProgressLevelId,
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
  final List<ScratchStageSprite> stageSprites = [];
  final List<ScratchScreenWidget> stageWidgets = [];
  final List<ScratchSound> stageSounds = [];

  BlockType? selectedCategory;
  ScratchAssetTab assetTab = ScratchAssetTab.sprites;
  ScratchStageTool stageTool = ScratchStageTool.select;
  ScratchGameSettings gameSettings = const ScratchGameSettings();
  bool isDraggingWorkspaceBlock = false;
  bool isSaving = false;
  bool isLoading = false;
  bool isRuntimeRunning = false;
  bool isRuntimePaused = false;
  bool _hasSavedCourseProgress = false;
  String selectedSpriteId = 'polar';
  final Map<String, Object> runtimeVariables = {};
  final Set<String> _runtimeTriggeredTouchEvents = {};

  int _nextId = 1;
  int _nextInstructionId = 1;
  int _nextSpriteId = 1;
  int _nextWidgetId = 1;
  int _nextSoundId = 1;
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
    final language = AppLanguage.instance;
    _titleController = TextEditingController(
      text: widget.initialTitle ?? language.t('builder.newLevel'),
    );
    _titleController.addListener(_handleTitleChanged);
    _courseId = widget.initialCourseId ?? '';
    _orderInCourse = widget.initialOrderInCourse ?? 0;
    _difficulty = widget.initialDifficulty;
    _status = widget.initialStatus;
    stageSprites.addAll(ScratchStageSprite.starterSprites());
    stageSounds.add(const ScratchSound(id: 'collect', name: 'Collect sparkle'));
    instructionSections.addAll([
      InstructionSection(
        id: 'section_${_nextInstructionId++}',
        type: InstructionSectionType.overview,
        title: language.t('builder.overview'),
        content: language.t('builder.describeLearnerBuild'),
      ),
      InstructionSection(
        id: 'section_${_nextInstructionId++}',
        type: InstructionSectionType.instructions,
        title: language.t('builder.instructions'),
        items: [
          language.t('builder.dragBlocksInstruction'),
          language.t('builder.runProgramInstruction'),
        ],
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

  ScratchStageSprite? get _selectedSprite {
    return stageSprites.firstWhereOrNull(
          (sprite) => sprite.id == selectedSpriteId,
        ) ??
        stageSprites.firstWhereOrNull((sprite) => true);
  }

  void _setAssetTab(ScratchAssetTab tab) {
    setState(() {
      assetTab = tab;
    });
  }

  void _setStageTool(ScratchStageTool tool) {
    setState(() {
      stageTool = tool;
    });
  }

  void _selectSprite(String id) {
    if (!stageSprites.any((sprite) => sprite.id == id)) {
      return;
    }
    setState(() {
      selectedSpriteId = id;
    });
  }

  void _updateSprite(ScratchStageSprite sprite) {
    setState(() {
      final index = stageSprites.indexWhere((item) => item.id == sprite.id);
      if (index == -1) return;
      stageSprites[index] = sprite;
      if (!stageSprites.any((item) => item.id == selectedSpriteId)) {
        selectedSpriteId = stageSprites.first.id;
      }
    });
  }

  ScratchStageSprite _addSprite(ScratchSpriteAssetChoice choice) {
    final id = 'sprite_${_nextSpriteId++}';
    final offset = stageSprites.length * 28.0;
    final sprite = ScratchStageSprite.fromChoice(
      id: id,
      choice: choice,
      x: 80 + offset,
      y: 120 + offset,
    );
    setState(() {
      stageSprites.add(sprite);
      selectedSpriteId = id;
    });
    return sprite;
  }

  bool _deleteSprite(String id) {
    if (stageSprites.length <= 1) {
      return false;
    }
    setState(() {
      stageSprites.removeWhere((sprite) => sprite.id == id);
      if (selectedSpriteId == id) {
        selectedSpriteId = stageSprites.first.id;
      }
    });
    return true;
  }

  ScratchStageSprite? _duplicateSprite(String id) {
    final source = stageSprites.firstWhereOrNull((sprite) => sprite.id == id);
    if (source == null) {
      return null;
    }
    final copy = source.copyWith(
      id: 'sprite_${_nextSpriteId++}',
      name: '${source.name} copy',
      x: source.x + 24,
      y: source.y + 24,
      startX: source.startX + 24,
      startY: source.startY + 24,
    );
    setState(() {
      stageSprites.add(copy);
      selectedSpriteId = copy.id;
    });
    return copy;
  }

  ScratchScreenWidget _addStageWidget(ScratchWidgetKind type) {
    final widget = ScratchScreenWidget(
      id: 'widget_${_nextWidgetId++}',
      name: scratchWidgetLabel(AppLanguage.instance, type),
      type: type,
      x: 20 + stageWidgets.length * 14,
      y: 20 + stageWidgets.length * 14,
      text: type == ScratchWidgetKind.text ? 'Text' : '',
    );
    setState(() {
      stageWidgets.add(widget);
    });
    return widget;
  }

  void _updateStageWidget(ScratchScreenWidget widget) {
    setState(() {
      final index = stageWidgets.indexWhere((item) => item.id == widget.id);
      if (index == -1) return;
      stageWidgets[index] = widget;
    });
  }

  void _deleteStageWidget(String id) {
    setState(() {
      stageWidgets.removeWhere((widget) => widget.id == id);
    });
  }

  ScratchScreenWidget? _duplicateStageWidget(String id) {
    final source = stageWidgets.firstWhereOrNull((widget) => widget.id == id);
    if (source == null) {
      return null;
    }
    final copy = source.copyWith(
      id: 'widget_${_nextWidgetId++}',
      name: '${source.name} copy',
      x: source.x + 18,
      y: source.y + 18,
    );
    setState(() {
      stageWidgets.add(copy);
    });
    return copy;
  }

  ScratchSound _addSound(String name) {
    final sound = ScratchSound(id: 'sound_${_nextSoundId++}', name: name);
    setState(() {
      stageSounds.add(sound);
    });
    return sound;
  }

  void _updateSound(ScratchSound sound) {
    setState(() {
      final index = stageSounds.indexWhere((item) => item.id == sound.id);
      if (index == -1) return;
      stageSounds[index] = sound;
    });
  }

  void _deleteSound(String id) {
    setState(() {
      stageSounds.removeWhere((sound) => sound.id == id);
    });
  }

  void _updateSettings(ScratchGameSettings settings) {
    setState(() {
      gameSettings = settings;
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
    if (isRuntimeRunning) {
      return;
    }
    final runningSpriteId = selectedSpriteId;
    final topBlocks =
        workspaceBlocks
            .where(
              (block) =>
                  block.previousBlockId == null &&
                  (block.template.id == 'event_when_start' ||
                      block.template.shape != BlockShape.hat),
            )
            .toList()
          ..sort((a, b) => a.position.dy.compareTo(b.position.dy));

    setState(() {
      isRuntimeRunning = true;
      isRuntimePaused = false;
      _runtimeTriggeredTouchEvents.clear();
      _clearSpriteSpeech();
    });

    var completedRun = false;
    try {
      for (final topBlock in topBlocks) {
        if (!isRuntimeRunning) {
          break;
        }
        final startId = topBlock.template.shape == BlockShape.hat
            ? topBlock.nextBlockId
            : topBlock.id;
        if (startId == null) {
          continue;
        }
        await _executeStack(startId, runningSpriteId, depth: 0);
      }
      await _runTouchingEventStacks();
      completedRun = true;
    } finally {
      if (mounted) {
        setState(() {
          isRuntimeRunning = false;
          isRuntimePaused = false;
        });
      }
      if (completedRun && widget.playMode) {
        unawaited(_saveCourseProgress());
      }
    }
  }

  Future<void> _saveCourseProgress() async {
    if (_hasSavedCourseProgress) {
      return;
    }
    final courseId = widget.courseProgressCourseId;
    final levelId = widget.courseProgressLevelId ?? _savedProjectId;
    if (courseId == null ||
        courseId.isEmpty ||
        levelId == null ||
        levelId.isEmpty) {
      return;
    }
    _hasSavedCourseProgress = true;
    final result = await ApiService.completePublicCourseLevel(
      authToken: widget.session.token,
      courseId: courseId,
      levelId: levelId,
    );
    if (result['success'] != true) {
      _hasSavedCourseProgress = false;
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _executeStack(
    String startId,
    String spriteId, {
    required int depth,
    int maxBlocks = 1000,
  }) async {
    if (depth > 20) {
      return;
    }
    var currentId = startId;
    var executed = 0;

    while (isRuntimeRunning && executed < maxBlocks) {
      await _waitWhilePaused();
      final block = workspaceBlocks.firstWhereOrNull((b) => b.id == currentId);
      if (block == null || !block.template.enabled) {
        return;
      }
      if (!_canRunStandalone(block.template)) {
        currentId = block.nextBlockId ?? '';
        if (currentId.isEmpty) {
          return;
        }
        continue;
      }

      final stopStack = await _executeBlock(block, spriteId, depth: depth);
      if (stopStack || block.template.shape == BlockShape.cap) {
        return;
      }
      final nextId = block.nextBlockId;
      if (nextId == null) {
        return;
      }
      currentId = nextId;
      executed += 1;
    }
  }

  Future<bool> _executeBlock(
    WorkspaceBlock block,
    String spriteId, {
    required int depth,
  }) async {
    switch (block.template.id) {
      case 'motion_step':
        await _moveCurrentSpriteForward(
          spriteId,
          _readDoubleInput(block, 'steps'),
        );
      case 'motion_turn_left':
        _updateSpriteById(spriteId, (sprite) {
          final rotation = _normalizeRotation(sprite.rotation - 90);
          return sprite.copyWith(
            rotation: rotation,
            facing: _facingForRotation(rotation, sprite.facing),
          );
        });
      case 'motion_turn_right':
        _updateSpriteById(spriteId, (sprite) {
          final rotation = _normalizeRotation(sprite.rotation + 90);
          return sprite.copyWith(
            rotation: rotation,
            facing: _facingForRotation(rotation, sprite.facing),
          );
        });
      case 'motion_turn_degrees':
        _updateSpriteById(spriteId, (sprite) {
          final rotation = _normalizeRotation(
            sprite.rotation + _readDoubleInput(block, 'degrees'),
          );
          return sprite.copyWith(
            rotation: rotation,
            facing: _facingForRotation(rotation, sprite.facing),
          );
        });
      case 'motion_set_rotation':
        _updateSpriteById(spriteId, (sprite) {
          final rotation = _normalizeRotation(
            _readDoubleInput(block, 'degrees'),
          );
          return sprite.copyWith(
            rotation: rotation,
            facing: _facingForRotation(rotation, sprite.facing),
          );
        });
      case 'motion_move_right':
        await _moveCurrentSpriteBy(spriteId, Offset(_stepUnit, 0));
      case 'motion_move_left':
        await _moveCurrentSpriteBy(spriteId, Offset(-_stepUnit, 0));
      case 'motion_move_up':
        await _moveCurrentSpriteBy(spriteId, Offset(0, -_stepUnit));
      case 'motion_move_down':
        await _moveCurrentSpriteBy(spriteId, Offset(0, _stepUnit));
      case 'motion_jump_up':
        await _moveCurrentSpriteBy(spriteId, Offset(0, -_stepUnit));
      case 'motion_jump_right':
        await _moveCurrentSpriteBy(spriteId, Offset(_stepUnit, -_stepUnit));
      case 'motion_jump_left':
        await _moveCurrentSpriteBy(spriteId, Offset(-_stepUnit, -_stepUnit));
      case 'motion_go_to':
        await _moveCurrentSpriteTo(
          spriteId,
          Offset(_readDoubleInput(block, 'x'), _readDoubleInput(block, 'y')),
        );
      case 'motion_change_x':
        await _moveCurrentSpriteBy(
          spriteId,
          Offset(_readDoubleInput(block, 'value'), 0),
        );
      case 'motion_change_y':
        await _moveCurrentSpriteBy(
          spriteId,
          Offset(0, _readDoubleInput(block, 'value')),
        );
      case 'motion_set_x':
        final sprite = _spriteById(spriteId);
        if (sprite != null) {
          await _moveCurrentSpriteTo(
            spriteId,
            Offset(_readDoubleInput(block, 'x'), sprite.y),
          );
        }
      case 'motion_set_y':
        final sprite = _spriteById(spriteId);
        if (sprite != null) {
          await _moveCurrentSpriteTo(
            spriteId,
            Offset(sprite.x, _readDoubleInput(block, 'y')),
          );
        }
      case 'looks_show':
        _updateSpriteById(spriteId, (sprite) => sprite.copyWith(visible: true));
      case 'looks_hide':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(visible: false),
        );
      case 'looks_say':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(text: _readTextInput(block, 'message')),
        );
      case 'looks_say_for':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(text: _readTextInput(block, 'message')),
        );
        await _runtimeDelay(_readDoubleInput(block, 'seconds'));
        _updateSpriteById(spriteId, (sprite) => sprite.copyWith(text: ''));
      case 'looks_set_scale':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(
            scale: math.max(0.1, _readDoubleInput(block, 'value')),
          ),
        );
      case 'looks_change_scale':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(
            scale: math.max(
              0.1,
              sprite.scale + _readDoubleInput(block, 'value'),
            ),
          ),
        );
      case 'looks_destroy':
        _updateSpriteById(
          spriteId,
          (sprite) => sprite.copyWith(visible: false, draggable: false),
        );
      case 'control_wait':
        await _runtimeDelay(_readDoubleInput(block, 'seconds'));
      case 'control_repeat':
        final childId = block.nextBlockId;
        if (childId != null) {
          final times = _readDoubleInput(block, 'times').round().clamp(0, 100);
          for (var i = 0; i < times && isRuntimeRunning; i += 1) {
            await _executeStack(
              childId,
              spriteId,
              depth: depth + 1,
              maxBlocks: 200,
            );
          }
          return true;
        }
      case 'control_forever':
        final childId = block.nextBlockId;
        if (childId != null) {
          for (var i = 0; i < 120 && isRuntimeRunning; i += 1) {
            await _executeStack(
              childId,
              spriteId,
              depth: depth + 1,
              maxBlocks: 200,
            );
            await _runtimeDelay(0.016);
          }
          return true;
        }
      case 'control_if':
        final childId = block.nextBlockId;
        if (childId != null &&
            _evaluateConditionInput(block, 'condition', spriteId)) {
          await _executeStack(
            childId,
            spriteId,
            depth: depth + 1,
            maxBlocks: 200,
          );
        }
        return true;
      case 'control_repeat_until':
        final childId = block.nextBlockId;
        if (childId != null) {
          for (
            var i = 0;
            i < 200 &&
                isRuntimeRunning &&
                !_evaluateConditionInput(block, 'condition', spriteId);
            i += 1
          ) {
            await _executeStack(
              childId,
              spriteId,
              depth: depth + 1,
              maxBlocks: 200,
            );
          }
          return true;
        }
      case 'control_stop_script':
        return true;
      case 'control_stop_game':
        setState(() => isRuntimeRunning = false);
        return true;
      case 'variables_set':
        _setVariable(
          _readTextInput(block, 'variable'),
          _readValueInput(block, 'value', spriteId),
        );
      case 'variables_change':
        final name = _readTextInput(block, 'variable');
        _setVariable(
          name,
          _numberValue(runtimeVariables[name]) +
              _readDoubleInput(block, 'value'),
        );
      case 'game_set_counter':
        _setCounter(
          _readTextInput(block, 'counter'),
          _readDoubleInput(block, 'value'),
        );
      case 'game_change_counter':
        _setCounter(
          _readTextInput(block, 'counter'),
          _counterValue(_readTextInput(block, 'counter')) +
              _readDoubleInput(block, 'value'),
        );
      case 'game_reset':
        _resetRuntimeState();
      case 'game_pause':
        setState(() => isRuntimePaused = true);
      case 'game_unpause':
        setState(() => isRuntimePaused = false);
      case 'sound_play':
        // Sound assets are catalogued for future audio wiring; this block is safe no-op for now.
        break;
    }

    await _runTouchingEventStacks();
    return false;
  }

  static const double _stepUnit = 40;

  bool _canRunStandalone(BlockTemplate template) {
    return template.shape != BlockShape.reporter &&
        template.shape != BlockShape.boolean &&
        template.shape != BlockShape.hat;
  }

  Future<void> _moveCurrentSpriteForward(String spriteId, double steps) async {
    final sprite = _spriteById(spriteId);
    if (sprite == null) {
      return;
    }
    final direction = _directionForRotation(sprite.rotation);
    await _moveCurrentSpriteBy(spriteId, direction * (_stepUnit * steps));
  }

  Future<void> _moveCurrentSpriteBy(String spriteId, Offset delta) async {
    final sprite = _spriteById(spriteId);
    if (sprite == null) {
      return;
    }
    await _moveCurrentSpriteTo(
      spriteId,
      Offset(sprite.x + delta.dx, sprite.y + delta.dy),
    );
  }

  Future<void> _moveCurrentSpriteTo(String spriteId, Offset target) async {
    final sprite = _spriteById(spriteId);
    if (sprite == null) {
      return;
    }
    final destination = _clampedSpritePosition(sprite, target);
    final frames = 10;
    final start = Offset(sprite.x, sprite.y);

    for (var i = 1; i <= frames && isRuntimeRunning; i += 1) {
      await _waitWhilePaused();
      final t = Curves.easeInOut.transform(i / frames);
      final next = Offset.lerp(start, destination, t) ?? destination;
      _updateSpriteById(spriteId, (sprite) {
        final directionX = destination.dx - start.dx;
        return sprite.copyWith(
          x: next.dx,
          y: next.dy,
          facing: directionX == 0
              ? sprite.facing
              : directionX > 0
              ? ScratchSpriteFacing.right
              : ScratchSpriteFacing.left,
        );
      });
      await Future.delayed(const Duration(milliseconds: 24));
    }
  }

  Offset _clampedSpritePosition(ScratchStageSprite sprite, Offset position) {
    return Offset(
      position.dx.clamp(0, math.max(0, gameSettings.worldWidth - sprite.width)),
      position.dy.clamp(
        0,
        math.max(0, gameSettings.worldHeight - sprite.height),
      ),
    );
  }

  Offset _directionForRotation(double rotation) {
    final normalized = _normalizeRotation(rotation);
    if (normalized >= 45 && normalized < 135) {
      return const Offset(0, 1);
    }
    if (normalized >= 135 && normalized < 225) {
      return const Offset(-1, 0);
    }
    if (normalized >= 225 && normalized < 315) {
      return const Offset(0, -1);
    }
    return const Offset(1, 0);
  }

  ScratchSpriteFacing _facingForRotation(
    double rotation,
    ScratchSpriteFacing fallback,
  ) {
    final direction = _directionForRotation(rotation);
    if (direction.dx > 0) {
      return ScratchSpriteFacing.right;
    }
    if (direction.dx < 0) {
      return ScratchSpriteFacing.left;
    }
    return fallback;
  }

  double _normalizeRotation(double rotation) {
    final normalized = rotation % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  Future<void> _runtimeDelay(double seconds) async {
    final totalMs = (math.max(0, seconds) * 1000).round();
    var elapsed = 0;
    while (isRuntimeRunning && elapsed < totalMs) {
      await _waitWhilePaused();
      const slice = 50;
      await Future.delayed(const Duration(milliseconds: slice));
      elapsed += slice;
    }
  }

  Future<void> _waitWhilePaused() async {
    while (mounted && isRuntimeRunning && isRuntimePaused) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _updateSpriteById(
    String spriteId,
    ScratchStageSprite Function(ScratchStageSprite sprite) updater,
  ) {
    if (!mounted) {
      return;
    }
    setState(() {
      final index = stageSprites.indexWhere((sprite) => sprite.id == spriteId);
      if (index == -1) {
        return;
      }
      stageSprites[index] = updater(stageSprites[index]);
    });
  }

  ScratchStageSprite? _spriteById(String id) {
    return stageSprites.firstWhereOrNull((sprite) => sprite.id == id);
  }

  ScratchStageSprite? _spriteByNameOrId(String nameOrId) {
    final normalized = nameOrId.trim().toLowerCase();
    return stageSprites.firstWhereOrNull(
      (sprite) =>
          sprite.id.toLowerCase() == normalized ||
          sprite.name.toLowerCase() == normalized,
    );
  }

  bool _touchingObject(String spriteId, String objectName) {
    final sprite = _spriteById(spriteId);
    final other = _spriteByNameOrId(objectName);
    if (sprite == null || other == null || sprite.id == other.id) {
      return false;
    }
    if (!sprite.visible || !other.visible) {
      return false;
    }
    return _spriteRect(sprite).overlaps(_spriteRect(other));
  }

  double _distanceToObject(String spriteId, String objectName) {
    final sprite = _spriteById(spriteId);
    final other = _spriteByNameOrId(objectName);
    if (sprite == null || other == null) {
      return double.infinity;
    }
    return (_spriteRect(sprite).center - _spriteRect(other).center).distance;
  }

  Rect _spriteRect(ScratchStageSprite sprite) {
    return Rect.fromLTWH(
      sprite.x,
      sprite.y,
      sprite.width * sprite.scale,
      sprite.height * sprite.scale,
    );
  }

  Future<void> _runTouchingEventStacks() async {
    final events = workspaceBlocks.where(
      (block) =>
          block.previousBlockId == null &&
          block.template.id == 'event_when_touching' &&
          block.nextBlockId != null,
    );
    for (final event in events) {
      final objectName = _readTextInput(event, 'object');
      final touched = _spriteByNameOrId(objectName);
      if (touched == null || !_touchingObject(selectedSpriteId, objectName)) {
        continue;
      }
      final key = '${event.id}:${touched.id}';
      if (_runtimeTriggeredTouchEvents.contains(key)) {
        continue;
      }
      _runtimeTriggeredTouchEvents.add(key);
      await _executeStack(event.nextBlockId!, touched.id, depth: 1);
    }
  }

  bool _evaluateConditionInput(
    WorkspaceBlock block,
    String key,
    String spriteId,
  ) {
    return _evaluateCondition(_readTextInput(block, key), spriteId);
  }

  bool _evaluateCondition(String expression, String spriteId) {
    final text = expression.trim().toLowerCase();
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    if (text.startsWith('not ')) {
      return !_evaluateCondition(text.substring(4), spriteId);
    }
    if (text.startsWith('touching ')) {
      return _touchingObject(spriteId, text.substring('touching '.length));
    }
    if (text.startsWith('near ')) {
      return _distanceToObject(spriteId, text.substring('near '.length)) <=
          _stepUnit;
    }
    if (text.endsWith(' is visible')) {
      final objectName = text.replaceFirst(' is visible', '');
      return _spriteByNameOrId(objectName)?.visible == true;
    }

    for (final operator in ['>=', '<=', '!=', '=', '>', '<']) {
      final operatorIndex = text.indexOf(operator);
      if (operatorIndex <= 0) {
        continue;
      }
      final left = text.substring(0, operatorIndex).trim();
      final right = text.substring(operatorIndex + operator.length).trim();
      final leftValue = _readRuntimeValue(left, spriteId);
      final rightValue = _readRuntimeValue(right, spriteId);
      final leftNumber = _numberValue(leftValue);
      final rightNumber = _numberValue(rightValue);
      return switch (operator) {
        '=' =>
          leftValue.toString() == rightValue.toString() ||
              leftNumber == rightNumber,
        '!=' =>
          leftValue.toString() != rightValue.toString() &&
              leftNumber != rightNumber,
        '>' => leftNumber > rightNumber,
        '<' => leftNumber < rightNumber,
        '>=' => leftNumber >= rightNumber,
        '<=' => leftNumber <= rightNumber,
        _ => false,
      };
    }

    return false;
  }

  Object _readRuntimeValue(String token, String spriteId) {
    final sprite = _spriteById(spriteId);
    if (token == 'x position') {
      return sprite?.x ?? 0;
    }
    if (token == 'y position') {
      return sprite?.y ?? 0;
    }
    if (token == 'rotation') {
      return sprite?.rotation ?? 0;
    }
    if (token == 'scale') {
      return sprite?.scale ?? 1;
    }
    if (runtimeVariables.containsKey(token)) {
      return runtimeVariables[token]!;
    }
    return double.tryParse(token) ?? token;
  }

  Object _readValueInput(WorkspaceBlock block, String key, String spriteId) {
    return _readRuntimeValue(_readTextInput(block, key), spriteId);
  }

  double _numberValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _setVariable(String name, Object value) {
    setState(() {
      runtimeVariables[name] = value;
    });
    if (defaultCounters.contains(name)) {
      _setCounter(name, _numberValue(value));
    }
  }

  double _counterValue(String name) {
    final widget = stageWidgets.firstWhereOrNull(
      (item) =>
          item.type == ScratchWidgetKind.counter &&
          item.name.toLowerCase() == name.toLowerCase(),
    );
    return widget?.value ?? _numberValue(runtimeVariables[name]);
  }

  void _setCounter(String name, double value) {
    setState(() {
      runtimeVariables[name] = value;
      final index = stageWidgets.indexWhere(
        (item) =>
            item.type == ScratchWidgetKind.counter &&
            item.name.toLowerCase() == name.toLowerCase(),
      );
      if (index == -1) {
        stageWidgets.add(
          ScratchScreenWidget(
            id: 'widget_${_nextWidgetId++}',
            name: name,
            type: ScratchWidgetKind.counter,
            x: 20,
            y: 20 + stageWidgets.length * 28,
            text: '$name: ${_formatNumber(value)}',
            value: value,
          ),
        );
      } else {
        stageWidgets[index] = stageWidgets[index].copyWith(
          text: '$name: ${_formatNumber(value)}',
          value: value,
        );
      }
    });
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(2);
  }

  void _clearSpriteSpeech() {
    for (var index = 0; index < stageSprites.length; index += 1) {
      stageSprites[index] = stageSprites[index].copyWith(text: '');
    }
  }

  void _resetRuntimeState() {
    setState(() {
      stageSprites
        ..clear()
        ..addAll(ScratchStageSprite.starterSprites());
      stageWidgets.clear();
      runtimeVariables.clear();
      selectedSpriteId = stageSprites.first.id;
    });
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
      stageSprites
        ..clear()
        ..addAll(ScratchStageSprite.starterSprites());
      stageWidgets.clear();
      stageSounds
        ..clear()
        ..add(const ScratchSound(id: 'collect', name: 'Collect sparkle'));
      selectedSpriteId = stageSprites.first.id;
      assetTab = ScratchAssetTab.sprites;
      stageTool = ScratchStageTool.select;
      gameSettings = const ScratchGameSettings();
      _nextSpriteId = 1;
      _nextWidgetId = 1;
      _nextSoundId = 1;
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
              content: Text(
                publish
                    ? AppLanguage.of(context).t('builder.projectPublished')
                    : AppLanguage.of(context).t('builder.draftSaved'),
              ),
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
                        AppLanguage.of(
                          context,
                        ).t('builder.saveFailed').replaceAll(': {error}', ''),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted || !showFeedback) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.of(
              context,
            ).t('builder.saveFailed', params: {'error': e.toString()}),
          ),
        ),
      );
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
      final loadedSprites = _readStageSprites(draftData);
      final loadedWidgets = _readStageWidgets(draftData['widgets']);
      final loadedSounds = _readStageSounds(draftData['sounds']);
      final loadedSettings = ScratchGameSettings.fromJson(
        Map<String, dynamic>.from(
          draftData['settings'] as Map? ?? const <String, dynamic>{},
        ),
      );

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
            AppLanguage.instance.t('builder.newLevel');
        instructionSections
          ..clear()
          ..addAll(loadedSections);
        workspaceBlocks
          ..clear()
          ..addAll(loadedBlocks);
        stageSprites
          ..clear()
          ..addAll(loadedSprites);
        stageWidgets
          ..clear()
          ..addAll(loadedWidgets);
        stageSounds
          ..clear()
          ..addAll(loadedSounds);
        gameSettings = loadedSettings;
        selectedSpriteId =
            draftData['selectedSpriteId']?.toString() ?? stageSprites.first.id;
        if (!stageSprites.any((sprite) => sprite.id == selectedSpriteId)) {
          selectedSpriteId = stageSprites.first.id;
        }
        _nextInstructionId = _nextNumericSuffix(
          instructionSections.map((section) => section.id),
          prefix: 'section_',
        );
        _nextId = _nextNumericSuffix(
          workspaceBlocks.map((block) => block.id),
          prefix: 'block_',
        );
        _nextSpriteId = _nextNumericSuffix(
          stageSprites.map((sprite) => sprite.id),
          prefix: 'sprite_',
        );
        _nextWidgetId = _nextNumericSuffix(
          stageWidgets.map((widget) => widget.id),
          prefix: 'widget_',
        );
        _nextSoundId = _nextNumericSuffix(
          stageSounds.map((sound) => sound.id),
          prefix: 'sound_',
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.of(
              context,
            ).t('builder.loadFailed', params: {'error': e.toString()}),
          ),
        ),
      );
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
      'settings': gameSettings.toJson(),
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
              'templateId': block.template.id,
              'label': block.template.label,
              'x': block.position.dx,
              'y': block.position.dy,
              'previousBlockId': block.previousBlockId,
              'nextBlockId': block.nextBlockId,
              'inputValues': block.inputValues,
            },
          )
          .toList(),
      'selectedSpriteId': selectedSpriteId,
      'sprites': stageSprites.map((sprite) => sprite.toJson()).toList(),
      'widgets': stageWidgets.map((widget) => widget.toJson()).toList(),
      'sounds': stageSounds.map((sound) => sound.toJson()).toList(),
      'sprite': _selectedSprite?.toLegacyJson() ?? const <String, dynamic>{},
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
      final template = _blockTemplateByIdOrLabel(
        block['templateId']?.toString(),
        block['label']?.toString(),
      );
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

  List<ScratchStageSprite> _readStageSprites(Map<String, dynamic> draftData) {
    final rawSprites = draftData['sprites'];
    if (rawSprites is List) {
      final sprites = rawSprites
          .whereType<Map>()
          .map(
            (sprite) =>
                ScratchStageSprite.fromJson(Map<String, dynamic>.from(sprite)),
          )
          .toList();
      if (sprites.isNotEmpty) {
        return sprites;
      }
    }

    final legacySprite = draftData['sprite'] is Map
        ? Map<String, dynamic>.from(draftData['sprite'] as Map)
        : const <String, dynamic>{};
    final starterSprites = ScratchStageSprite.starterSprites();
    return [
      starterSprites.first.copyWith(
        x:
            _readDouble(legacySprite['x']) ??
            _readDouble(draftData['spriteX']) ??
            starterSprites.first.x,
        y:
            _readDouble(legacySprite['y']) ??
            _readDouble(draftData['spriteY']) ??
            starterSprites.first.y,
        startX:
            _readDouble(legacySprite['x']) ??
            _readDouble(draftData['spriteX']) ??
            starterSprites.first.startX,
        startY:
            _readDouble(legacySprite['y']) ??
            _readDouble(draftData['spriteY']) ??
            starterSprites.first.startY,
        rotation:
            _readDouble(legacySprite['rotation']) ??
            _readDouble(draftData['spriteRotation']) ??
            0,
        text:
            legacySprite['text']?.toString() ??
            draftData['spriteText']?.toString() ??
            '',
      ),
      starterSprites.last,
    ];
  }

  List<ScratchScreenWidget> _readStageWidgets(Object? rawValue) {
    if (rawValue is! List) {
      return const [];
    }
    return rawValue
        .whereType<Map>()
        .map(
          (widget) =>
              ScratchScreenWidget.fromJson(Map<String, dynamic>.from(widget)),
        )
        .toList();
  }

  List<ScratchSound> _readStageSounds(Object? rawValue) {
    if (rawValue is! List) {
      return const [ScratchSound(id: 'collect', name: 'Collect sparkle')];
    }
    final sounds = rawValue
        .whereType<Map>()
        .map((sound) => ScratchSound.fromJson(Map<String, dynamic>.from(sound)))
        .toList();
    return sounds.isEmpty
        ? const [ScratchSound(id: 'collect', name: 'Collect sparkle')]
        : sounds;
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

  BlockTemplate? _blockTemplateByIdOrLabel(String? id, String? label) {
    if (id != null) {
      final byId = blockTemplates.firstWhereOrNull(
        (template) => template.id == id,
      );
      if (byId != null) {
        return byId;
      }
    }
    if (label == null) {
      return null;
    }
    return blockTemplates.firstWhereOrNull((template) {
      return template.label == label ||
          (label == 'When Start Clicked' &&
              template.id == 'event_when_start') ||
          (label == 'Move {steps} Steps' && template.id == 'motion_step') ||
          (label == 'Turn {degrees}°' &&
              template.id == 'motion_turn_degrees') ||
          (label == 'Go To X: {x} Y: {y}' && template.id == 'motion_go_to') ||
          (label == 'Say {message}' && template.id == 'looks_say') ||
          (label == 'Wait {seconds} Second' && template.id == 'control_wait') ||
          (label == 'Repeat {times} Times' &&
              template.id == 'control_repeat') ||
          (label == 'Set {variable} To {value}' &&
              template.id == 'variables_set') ||
          (label == 'Change {variable} By {value}' &&
              template.id == 'variables_change');
    });
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
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
                      courseNavigator: widget.playMode
                          ? CourseLevelNavBanner(
                              session: widget.session,
                              courseId: widget.courseProgressCourseId,
                              currentLevelId:
                                  widget.courseProgressLevelId ??
                                  _savedProjectId,
                              currentLevelSolved: _hasSavedCourseProgress,
                              topBarMode: true,
                            )
                          : null,
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
                            flex: 46,
                            child: WorkspacePanel(
                              blocks: workspaceBlocks,
                              selectedCategory: selectedCategory,
                              isDraggingWorkspaceBlock:
                                  isDraggingWorkspaceBlock,
                              onCategoryPressed: _toggleCategory,
                              onAcceptTemplate: _addBlock,
                              onDetachBlock: _detachFromParent,
                              onMoveBlockStack: _moveBlockStack,
                              onSnapBlockStack: _snapBlockStack,
                              onDeleteBlockStack: _deleteBlockStack,
                              onUpdateBlockInput: _updateBlockInput,
                              onWorkspaceDragStateChanged:
                                  _setWorkspaceDragState,
                            ),
                          ),
                          Expanded(
                            flex: 44,
                            child: StagePanel(
                              sprites: stageSprites,
                              widgets: stageWidgets,
                              sounds: stageSounds,
                              settings: gameSettings,
                              selectedSpriteId: selectedSpriteId,
                              assetTab: assetTab,
                              stageTool: stageTool,
                              onSelectSprite: _selectSprite,
                              onUpdateSprite: _updateSprite,
                              onAddSprite: _addSprite,
                              onDeleteSprite: _deleteSprite,
                              onDuplicateSprite: _duplicateSprite,
                              onSetAssetTab: _setAssetTab,
                              onSetStageTool: _setStageTool,
                              onAddWidget: _addStageWidget,
                              onUpdateWidget: _updateStageWidget,
                              onDeleteWidget: _deleteStageWidget,
                              onDuplicateWidget: _duplicateStageWidget,
                              onAddSound: _addSound,
                              onUpdateSound: _updateSound,
                              onDeleteSound: _deleteSound,
                              onUpdateSettings: _updateSettings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
