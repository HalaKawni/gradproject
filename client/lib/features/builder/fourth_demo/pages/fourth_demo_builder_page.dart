import 'dart:math' as math;

import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:flame/game.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:highlight/languages/coffeescript.dart';

import '../../scratch_builder/models/instruction_section.dart';
import '../../scratch_builder/widgets/instruction_editor_panel.dart';
import '../../front_view/shared/builder_collectable.dart';
import '../../front_view/shared/builder_character.dart';
import '../controllers/fourth_demo_controller.dart';
import '../flame/fourth_demo_game.dart';
import '../language/game_code_controller.dart';
import '../language/game_code_indenter.dart';
import '../language/game_command.dart';
import '../language/game_language_spec.dart';
import '../models/fourth_demo_project.dart';

class FourthDemoBuilderPage extends StatefulWidget {
  final AuthSession session;

  const FourthDemoBuilderPage({super.key, required this.session});

  @override
  State<FourthDemoBuilderPage> createState() => _FourthDemoBuilderPageState();
}

class _FourthDemoBuilderPageState extends State<FourthDemoBuilderPage> {
  late final FourthDemoController controller;
  late final FourthDemoGame game;
  late final GameCodeController codeController;
  late final TextEditingController titleController;
  final FocusNode stageFocusNode = FocusNode();
  final List<InstructionSection> instructionSections = <InstructionSection>[];
  bool _syncingCodeFromController = false;
  bool _updatingCodeFromEditor = false;
  bool _controllerRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    controller = FourthDemoController()..addListener(_handleControllerChanged);
    game = FourthDemoGame(controller: controller);
    codeController = GameCodeController(
      text: controller.selectedCode,
      language: coffeescript,
      modifiers: const [TabModifier()],
    );
    titleController = TextEditingController(text: controller.project.title)
      ..addListener(_handleTitleChanged);
    instructionSections.addAll(_defaultInstructionSections());
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    controller.dispose();
    game.onRemove();
    codeController.dispose();
    titleController
      ..removeListener(_handleTitleChanged)
      ..dispose();
    stageFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_controllerRefreshScheduled) {
        return;
      }
      _controllerRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controllerRefreshScheduled = false;
        _refreshFromController();
      });
      return;
    }

    _refreshFromController();
  }

  void _refreshFromController() {
    if (!mounted) {
      return;
    }

    if (titleController.text != controller.project.title) {
      titleController.value = titleController.value.copyWith(
        text: controller.project.title,
        selection: TextSelection.collapsed(
          offset: controller.project.title.length,
        ),
      );
    }
    if (!_updatingCodeFromEditor &&
        codeController.text != controller.selectedCode) {
      _syncingCodeFromController = true;
      codeController.value = TextEditingValue(
        text: controller.selectedCode,
        selection: TextSelection.collapsed(
          offset: controller.selectedCode.length,
        ),
      );
      _syncingCodeFromController = false;
    }
    setState(() {});
  }

  void _handleTitleChanged() {
    controller.setTitle(titleController.text);
  }

  void _handleCodeChanged(String value) {
    if (_syncingCodeFromController) {
      return;
    }

    _updatingCodeFromEditor = true;
    try {
      controller.updateSelectedCode(value, notify: false);
    } finally {
      _updatingCodeFromEditor = false;
    }
  }

  void _runCode() {
    if (!controller.runCode()) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        stageFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F4EC),
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: language.t('builder.newLevel'),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.titleLarge,
            cursorColor: Colors.black,
            maxLines: 1,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: controller.saveLocal,
                child: Text(
                  language.t('builder.save'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: controller.isPlaying ? null : controller.loadLocal,
                child: Text(
                  language.t('builder.load'),
                  style: TextStyle(
                    color: controller.isPlaying ? Colors.black38 : Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: controller.isPlaying ? null : _showImportDialog,
                child: Text(
                  language.t('builder.import'),
                  style: TextStyle(
                    color: controller.isPlaying ? Colors.black38 : Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                onPressed: _showExportDialog,
                child: Text(language.t('builder.publish')),
              ),
            ),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              child: _CodeColumn(
                controller: controller,
                codeController: codeController,
                onCodeChanged: _handleCodeChanged,
                onRun: _runCode,
              ),
            ),
            Expanded(
              flex: 44,
              child: _StageColumn(
                controller: controller,
                game: game,
                focusNode: stageFocusNode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final exportController = TextEditingController(
      text: controller.exportJson(),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => _CourseDialog(
        title: AppLanguage.of(context).t('builder.exportProjectJson'),
        action: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLanguage.of(context).t('builder.done')),
        ),
        child: TextField(
          controller: exportController,
          maxLines: 18,
          readOnly: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: _fieldDecoration(
            AppLanguage.of(context).t('builder.projectJson'),
          ),
        ),
      ),
    );
    exportController.dispose();
  }

  Future<void> _showImportDialog() async {
    final importController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => _CourseDialog(
        title: AppLanguage.of(context).t('builder.importProjectJson'),
        action: FilledButton(
          onPressed: () {
            controller.importJson(importController.text);
            Navigator.of(context).pop();
          },
          child: Text(AppLanguage.of(context).t('builder.import')),
        ),
        child: TextField(
          controller: importController,
          maxLines: 18,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: _fieldDecoration(
            AppLanguage.of(context).t('builder.pasteJsonHere'),
          ),
        ),
      ),
    );
    importController.dispose();
  }

  List<InstructionSection> _defaultInstructionSections() {
    final language = AppLanguage.instance;
    return <InstructionSection>[
      InstructionSection(
        id: 'overview',
        type: InstructionSectionType.overview,
        title: language.t('builder.welcomeGameBuilder'),
        content: language.t('builder.fourthOverviewContent'),
      ),
      InstructionSection(
        id: 'code-example',
        type: InstructionSectionType.codeExample,
        title: language.t('builder.codeExample'),
        content: '@step 1',
      ),
      InstructionSection(
        id: 'instructions',
        type: InstructionSectionType.instructions,
        title: language.t('builder.instructions'),
        content: language.t('builder.fourthInstructionsContent'),
      ),
    ];
  }

  void _addInstructionSection(InstructionSectionType type) {
    setState(() {
      instructionSections.add(
        InstructionSection(
          id: 'section-${DateTime.now().microsecondsSinceEpoch}',
          type: type,
          title: instructionSectionLabel(type),
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
      if (index == -1) {
        return;
      }
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
      if (index == -1) {
        return;
      }
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
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      instructionSections[index] = section.copyWith(
        items: <String>[...section.items, ''],
      );
    });
  }

  void _updateInstructionItem(String id, int itemIndex, String value) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) {
        return;
      }
      final items = List<String>.from(section.items)..[itemIndex] = value;
      instructionSections[index] = section.copyWith(items: items);
    });
  }

  void _removeInstructionItem(String id, int itemIndex) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) {
        return;
      }
      final items = List<String>.from(section.items)..removeAt(itemIndex);
      instructionSections[index] = section.copyWith(items: items);
    });
  }
}

class _CodeColumn extends StatelessWidget {
  final FourthDemoController controller;
  final CodeController codeController;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onRun;

  const _CodeColumn({
    required this.controller,
    required this.codeController,
    required this.onCodeChanged,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FA),
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xFFC6D2D9), width: 2),
        ),
      ),
      child: Column(
        children: [
          _CodeHeader(controller: controller, onRun: onRun),
          Expanded(
            child: _CodeEditor(
              controller: controller,
              codeController: codeController,
              onCodeChanged: onCodeChanged,
            ),
          ),
          _FunctionPalette(
            controller: controller,
            codeController: codeController,
          ),
        ],
      ),
    );
  }
}

class _CodeHeader extends StatelessWidget {
  final FourthDemoController controller;
  final VoidCallback onRun;

  const _CodeHeader({required this.controller, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    final sprite = controller.selectedSprite;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD9DEE2), width: 2)),
      ),
      child: Row(
        children: [
          _SpriteAvatar(sprite: sprite, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sprite?.name ?? language.t('builder.noSprite'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          if (controller.codeError != null)
            Flexible(
              child: Text(
                controller.codeError!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD94836),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controller.isPlaying ? controller.stop : onRun,
            icon: Icon(controller.isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(
              controller.isPlaying
                  ? language.t('builder.stop').toUpperCase()
                  : language.t('builder.run').toUpperCase(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: controller.isPlaying
                  ? const Color(0xFFD94836)
                  : const Color(0xFF66B64A),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeEditor extends StatelessWidget {
  final FourthDemoController controller;
  final CodeController codeController;
  final ValueChanged<String> onCodeChanged;

  const _CodeEditor({
    required this.controller,
    required this.codeController,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF6FA),
      child: CodeTheme(
        data: CodeThemeData(styles: atomOneLightTheme),
        child: CodeField(
          controller: codeController,
          expands: true,
          minLines: null,
          maxLines: null,
          readOnly: controller.isPlaying,
          wrap: false,
          background: const Color(0xFFEEF6FA),
          cursorColor: const Color(0xFF24465A),
          gutterStyle: const GutterStyle(
            width: 48,
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Color(0xFF6A8291),
            ),
            background: Color(0xFFDDEBF2),
          ),
          padding: const EdgeInsets.all(14),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            height: 1.45,
            color: Color(0xFF24465A),
          ),
          onChanged: onCodeChanged,
        ),
      ),
    );
  }
}

class _FunctionPalette extends StatefulWidget {
  final FourthDemoController controller;
  final CodeController codeController;

  const _FunctionPalette({
    required this.controller,
    required this.codeController,
  });

  @override
  State<_FunctionPalette> createState() => _FunctionPaletteState();
}

class _FunctionPaletteState extends State<_FunctionPalette> {
  bool _isTyping = false;
  static const int _typingCharactersPerTick = 3;
  static const Duration _typingTickDelay = Duration(milliseconds: 8);
  static const GameCodeIndenter _indenter = GameCodeIndenter();

  @override
  Widget build(BuildContext context) {
    final items = GameLanguageSpec.byCategory(
      _categoryForTab(widget.controller.paletteTab),
    );
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        color: Color(0xFFE7ECEF),
        border: Border(top: BorderSide(color: Color(0xFFC6D2D9), width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in FourthDemoPaletteTab.values)
                _TabButton(
                  text: _paletteLabel(context, tab),
                  active: widget.controller.paletteTab == tab,
                  onTap: () => widget.controller.setPaletteTab(tab),
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final command in items)
                    _CommandPill(
                      label: _commandLabel(context, command),
                      enabled: !widget.controller.isPlaying,
                      onTap: () => _typeSnippet(command),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static GameCommandCategory _categoryForTab(FourthDemoPaletteTab tab) {
    return switch (tab) {
      FourthDemoPaletteTab.movement => GameCommandCategory.movement,
      FourthDemoPaletteTab.events => GameCommandCategory.events,
      FourthDemoPaletteTab.display => GameCommandCategory.display,
      FourthDemoPaletteTab.control => GameCommandCategory.control,
      FourthDemoPaletteTab.operators => GameCommandCategory.operators,
    };
  }

  static String _paletteLabel(BuildContext context, FourthDemoPaletteTab tab) {
    final language = AppLanguage.of(context);
    return switch (tab) {
      FourthDemoPaletteTab.movement => language.t('builder.movement'),
      FourthDemoPaletteTab.events => language.t('builder.events'),
      FourthDemoPaletteTab.display => language.t('builder.display'),
      FourthDemoPaletteTab.control => language.t('builder.control'),
      FourthDemoPaletteTab.operators => language.t('builder.operators'),
    };
  }

  static String _commandLabel(BuildContext context, GameCommand command) {
    return AppLanguage.of(
      context,
    ).tr('builder.command.${command.label}', command.label);
  }

  Future<void> _typeSnippet(GameCommand command) async {
    if (_isTyping || widget.controller.isPlaying) {
      return;
    }
    _isTyping = true;

    try {
      final text = widget.codeController.text;
      final selection = widget.codeController.selection;
      final start = selection.isValid ? selection.start : text.length;
      final end = selection.isValid ? selection.end : text.length;
      final insertion = _indenter.insertCommand(
        code: text,
        start: start,
        end: end,
        command: command,
      );
      final insertText = insertion.text.substring(
        insertion.animationStart,
        insertion.animationEnd,
      );
      var next = text.replaceRange(insertion.animationStart, end, '');
      widget.codeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: insertion.animationStart),
      );

      var offset = insertion.animationStart;
      final units = insertText.characters.toList();
      for (
        var index = 0;
        index < units.length;
        index += _typingCharactersPerTick
      ) {
        if (!mounted) {
          return;
        }

        final chunk = units.skip(index).take(_typingCharactersPerTick).join();
        next = widget.codeController.text.replaceRange(offset, offset, chunk);
        offset += chunk.length;
        widget.codeController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: offset),
        );
        await Future<void>.delayed(_typingTickDelay);
      }

      widget.codeController.value = TextEditingValue(
        text: widget.codeController.text,
        selection: TextSelection.collapsed(offset: insertion.cursorOffset),
      );
      widget.controller.updateSelectedCode(
        widget.codeController.text,
        notify: false,
      );
    } finally {
      _isTyping = false;
    }
  }
}

class _StageColumn extends StatelessWidget {
  final FourthDemoController controller;
  final FourthDemoGame game;
  final FocusNode focusNode;

  const _StageColumn({
    required this.controller,
    required this.game,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F1),
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: _StagePanel(
              controller: controller,
              game: game,
              focusNode: focusNode,
            ),
          ),
          Expanded(flex: 9, child: _AssetManager(controller: controller)),
        ],
      ),
    );
  }
}

class _StagePanel extends StatefulWidget {
  final FourthDemoController controller;
  final FourthDemoGame game;
  final FocusNode focusNode;

  const _StagePanel({
    required this.controller,
    required this.game,
    required this.focusNode,
  });

  @override
  State<_StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<_StagePanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.project.settings;
    return KeyboardListener(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          widget.controller.handleKeyDown(event.logicalKey);
        } else if (event is KeyUpEvent) {
          widget.controller.handleKeyUp(event.logicalKey);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final worldWidth = math.max(
                    settings.worldWidth,
                    constraints.maxWidth,
                  );
                  final worldHeight = math.max(
                    settings.worldHeight,
                    constraints.maxHeight,
                  );
                  return Scrollbar(
                    controller: _verticalController,
                    thumbVisibility:
                        settings.worldHeight > constraints.maxHeight,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility:
                            settings.worldWidth > constraints.maxWidth,
                        notificationPredicate: (notification) =>
                            notification.depth == 1,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: worldWidth,
                            height: worldHeight,
                            child: GestureDetector(
                              onTapDown: (details) {
                                widget.focusNode.requestFocus();
                                final worldPosition = widget.game
                                    .worldPositionFromCanvas(
                                      details.localPosition,
                                    );
                                controller.handleClick(worldPosition);
                                controller.beginDrag(worldPosition);
                                controller.endDrag();
                              },
                              onPanStart: (details) {
                                widget.focusNode.requestFocus();
                                controller.beginDrag(
                                  widget.game.worldPositionFromCanvas(
                                    details.localPosition,
                                  ),
                                );
                              },
                              onPanUpdate: (details) => controller.dragTo(
                                widget.game.worldPositionFromCanvas(
                                  details.localPosition,
                                ),
                              ),
                              onPanEnd: (_) => controller.endDrag(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: GameWidget(game: widget.game),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _ToolButton(
                    icon: Icons.north_west,
                    active: controller.stageTool == FourthDemoStageTool.select,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.select),
                  ),
                  _ToolButton(
                    icon: Icons.open_with,
                    active: controller.stageTool == FourthDemoStageTool.move,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.move),
                  ),
                  _ToolButton(
                    icon: Icons.auto_fix_off,
                    active: controller.stageTool == FourthDemoStageTool.eraser,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.eraser),
                  ),
                  _ToolButton(
                    icon: Icons.brush,
                    active: controller.stageTool == FourthDemoStageTool.brush,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.brush),
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

class _AssetManager extends StatefulWidget {
  final FourthDemoController controller;

  const _AssetManager({required this.controller});

  @override
  State<_AssetManager> createState() => _AssetManagerState();
}

class _AssetManagerState extends State<_AssetManager> {
  String? _editingSpriteId;
  String? _editingWidgetId;
  String? _editingSoundId;

  FourthDemoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in FourthDemoAssetTab.values)
                _TabButton(
                  text: _assetLabel(context, tab),
                  active: controller.assetTab == tab,
                  onTap: () {
                    setState(_clearEditing);
                    controller.setAssetTab(tab);
                  },
                ),
            ],
          ),
          Expanded(
            child: switch (controller.assetTab) {
              FourthDemoAssetTab.sprites =>
                _editingSpriteId == null
                    ? _buildSpritesGrid(context)
                    : _buildSpriteSettings(context),
              FourthDemoAssetTab.widgets =>
                _editingWidgetId == null
                    ? _buildWidgetsGrid(context)
                    : _buildWidgetSettings(context),
              FourthDemoAssetTab.sounds =>
                _editingSoundId == null
                    ? _buildSoundsGrid(context)
                    : _buildSoundSettings(context),
              FourthDemoAssetTab.game => _GameTab(controller: controller),
            },
          ),
        ],
      ),
    );
  }

  static String _assetLabel(BuildContext context, FourthDemoAssetTab tab) {
    final language = AppLanguage.of(context);
    return switch (tab) {
      FourthDemoAssetTab.sprites => language.t('builder.sprites'),
      FourthDemoAssetTab.widgets => language.t('builder.widgets'),
      FourthDemoAssetTab.sounds => language.t('builder.sounds'),
      FourthDemoAssetTab.game => language.t('builder.game'),
    };
  }

  void _clearEditing() {
    _editingSpriteId = null;
    _editingWidgetId = null;
    _editingSoundId = null;
  }

  Widget _buildSpritesGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSprite(context)),
            for (final sprite in controller.project.sprites)
              _SpriteCard(
                sprite: sprite,
                selected: sprite.id == controller.project.selectedSpriteId,
                onTap: () => controller.selectSprite(sprite.id),
                onSettings: () => setState(() => _editingSpriteId = sprite.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSprite(BuildContext context) async {
    final choice = await _showSpriteChoiceDialog(context);
    if (choice == null || !context.mounted) {
      return;
    }
    final sprite = controller.addSpriteFromAsset(
      name: choice.label,
      kind: choice.kind,
      assetId: choice.id,
    );
    setState(() => _editingSpriteId = sprite.id);
  }

  Widget _buildWidgetsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddWidget(context)),
            for (final widget in controller.project.widgets)
              _MiniAssetCard(
                title: widget.name,
                icon: _widgetIcon(widget.type),
                onTap: () => setState(() => _editingWidgetId = widget.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddWidget(BuildContext context) async {
    final type = await _showWidgetChoiceDialog(context);
    if (type == null || !context.mounted) {
      return;
    }
    final widget = controller.addWidget(type);
    setState(() => _editingWidgetId = widget.id);
  }

  Widget _buildSoundsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSound(context)),
            for (final sound in controller.project.sounds)
              _MiniAssetCard(
                title: sound.name,
                icon: Icons.play_arrow,
                onTap: () => setState(() => _editingSoundId = sound.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSound(BuildContext context) async {
    final name = await _showSoundChoiceDialog(context);
    if (name == null || !context.mounted) {
      return;
    }
    final sound = controller.addSound(name);
    setState(() => _editingSoundId = sound.id);
  }

  Widget _buildSpriteSettings(BuildContext context) {
    final sprite = controller.project.sprites
        .where((sprite) => sprite.id == _editingSpriteId)
        .firstOrNull;
    if (sprite == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingSpriteId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _SpriteInlineSettings(
      sprite: sprite,
      onBack: () => setState(() => _editingSpriteId = null),
      onChanged: controller.updateSprite,
      onDelete: () {
        if (controller.deleteSprite(sprite.id)) {
          setState(() => _editingSpriteId = null);
        }
      },
      onDuplicate: () {
        final copy = controller.duplicateSprite(sprite.id);
        if (copy != null) {
          setState(() => _editingSpriteId = copy.id);
        }
      },
    );
  }

  Widget _buildWidgetSettings(BuildContext context) {
    final widget = controller.project.widgets
        .where((widget) => widget.id == _editingWidgetId)
        .firstOrNull;
    if (widget == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingWidgetId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _WidgetInlineSettings(
      widget: widget,
      onBack: () => setState(() => _editingWidgetId = null),
      onChanged: controller.updateWidget,
      onDelete: () {
        controller.deleteWidget(widget.id);
        setState(() => _editingWidgetId = null);
      },
      onDuplicate: () {
        final copy = controller.duplicateWidget(widget.id);
        if (copy != null) {
          setState(() => _editingWidgetId = copy.id);
        }
      },
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    final sound = controller.project.sounds
        .where((sound) => sound.id == _editingSoundId)
        .firstOrNull;
    if (sound == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingSoundId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _SoundInlineSettings(
      sound: sound,
      onBack: () => setState(() => _editingSoundId = null),
      onChanged: controller.updateSound,
      onDelete: () {
        controller.deleteSound(sound.id);
        setState(() => _editingSoundId = null);
      },
    );
  }
}

class _SpriteCard extends StatelessWidget {
  final FourthDemoSprite sprite;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _SpriteCard({
    required this.sprite,
    required this.selected,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF66B64A) : const Color(0xFFD9DEE2),
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            _SpriteAvatar(sprite: sprite, size: 54),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sprite.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: AppLanguage.of(context).t('builder.settings'),
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteInlineSettings extends StatelessWidget {
  final FourthDemoSprite sprite;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoSprite> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SpriteInlineSettings({
    required this.sprite,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.spriteSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetTextField(
            label: AppLanguage.of(context).t('builder.name').toUpperCase(),
            value: sprite.name,
            onChanged: (value) => onChanged(
              sprite.copyWith(
                name: value.trim().isEmpty ? sprite.name : value.trim(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _NumberStepperField(
                label: 'X',
                value: sprite.x,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(x: value, startX: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: sprite.y,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(y: value, startY: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(context).t('builder.scale').toUpperCase(),
                value: sprite.scale,
                step: 0.1,
                min: 0.1,
                decimals: 1,
                onChanged: (value) => onChanged(sprite.copyWith(scale: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(
                  context,
                ).t('builder.rotation').toUpperCase(),
                value: sprite.rotation,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(rotation: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DirectionSelector(
            value: sprite.facing,
            onChanged: (value) => onChanged(sprite.copyWith(facing: value)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              _BoolOption(
                label: AppLanguage.of(context).t('builder.allowGravity'),
                value: sprite.allowGravity,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(allowGravity: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.collideWorldBounds'),
                value: sprite.collideWorldBounds,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideWorldBounds: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.immovable'),
                value: sprite.immovable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(immovable: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.show'),
                value: sprite.visible,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(visible: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.collideOtherSprites'),
                value: sprite.collideOtherSprites,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideOtherSprites: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.draggable'),
                value: sprite.draggable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(draggable: value)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  final FourthDemoSpriteFacing value;
  final ValueChanged<FourthDemoSpriteFacing> onChanged;

  const _DirectionSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.direction').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SegmentedButton<FourthDemoSpriteFacing>(
          segments: [
            ButtonSegment(
              value: FourthDemoSpriteFacing.left,
              icon: const Icon(Icons.arrow_back),
              label: Text(AppLanguage.of(context).t('builder.left')),
            ),
            ButtonSegment(
              value: FourthDemoSpriteFacing.right,
              icon: const Icon(Icons.arrow_forward),
              label: Text(AppLanguage.of(context).t('builder.right')),
            ),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _WidgetInlineSettings extends StatelessWidget {
  final FourthDemoScreenWidget widget;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoScreenWidget> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _WidgetInlineSettings({
    required this.widget,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.widgetSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _widgetIcon(widget.type),
                  color: const Color(0xFF24465A),
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _AssetTextField(
                      label: AppLanguage.of(
                        context,
                      ).t('builder.name').toUpperCase(),
                      value: widget.name,
                      onChanged: (value) => onChanged(
                        widget.copyWith(
                          name: value.trim().isEmpty
                              ? widget.name
                              : value.trim(),
                        ),
                      ),
                    ),
                    _AssetTextField(
                      label: AppLanguage.of(
                        context,
                      ).t('builder.text').toUpperCase(),
                      value: widget.text,
                      onChanged: (value) =>
                          onChanged(widget.copyWith(text: value)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _NumberStepperField(
                label: 'X',
                value: widget.x,
                onChanged: (value) => onChanged(widget.copyWith(x: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: widget.y,
                onChanged: (value) => onChanged(widget.copyWith(y: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(context).t('builder.value').toUpperCase(),
                value: widget.value,
                onChanged: (value) => onChanged(widget.copyWith(value: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(
                  context,
                ).t('builder.opacity').toUpperCase(),
                value: widget.opacity,
                step: 0.1,
                min: 0,
                max: 1,
                decimals: 1,
                onChanged: (value) =>
                    onChanged(widget.copyWith(opacity: value)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BoolOption(
                label: AppLanguage.of(context).t('builder.show'),
                value: widget.visible,
                onChanged: (value) =>
                    onChanged(widget.copyWith(visible: value)),
              ),
              const Spacer(),
              Text(
                AppLanguage.of(context).t('builder.textColor'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              _ColorPickerButton(
                color: Color(widget.textColorValue),
                onChanged: (color) => onChanged(
                  widget.copyWith(textColorValue: color.toARGB32()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _SoundInlineSettings extends StatelessWidget {
  final FourthDemoSound sound;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoSound> onChanged;
  final VoidCallback onDelete;

  const _SoundInlineSettings({
    required this.sound,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.soundSettings'),
      onBack: onBack,
      child: Column(
        children: [
          _AssetTextField(
            label: AppLanguage.of(context).t('builder.name').toUpperCase(),
            value: sound.name,
            onChanged: (value) => onChanged(
              sound.copyWith(
                name: value.trim().isEmpty ? sound.name : value.trim(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.cancel),
              label: Text(
                AppLanguage.of(context).t('builder.delete').toUpperCase(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineSettingsScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _InlineSettingsScaffold({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFD9DEE2))),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: AppLanguage.of(context).t('builder.back'),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _AssetTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _AssetTextField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_AssetTextField> createState() => _AssetTextFieldState();
}

class _AssetTextFieldState extends State<_AssetTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _AssetTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        decoration: _fieldDecoration(widget.label),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _NumberStepperField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double? min;
  final double? max;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumberStepperField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min,
    this.max,
    this.decimals = 0,
  });

  @override
  State<_NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<_NumberStepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _format(widget.value);
    if (oldWidget.value != widget.value && _controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _fieldDecoration(widget.label).copyWith(
          suffixIcon: SizedBox(
            width: 26,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _nudge(widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
                InkWell(
                  onTap: () => _nudge(-widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
              ],
            ),
          ),
        ),
        onChanged: (raw) {
          final value = double.tryParse(raw);
          if (value != null) {
            widget.onChanged(_clamp(value));
          }
        },
      ),
    );
  }

  void _nudge(double amount) {
    final current = double.tryParse(_controller.text) ?? widget.value;
    final next = _clamp(current + amount);
    _controller.text = _format(next);
    widget.onChanged(next);
  }

  double _clamp(double value) {
    final min = widget.min;
    final max = widget.max;
    var next = value;
    if (min != null && next < min) {
      next = min;
    }
    if (max != null && next > max) {
      next = max;
    }
    return next;
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);
}

class _BoolOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BoolOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SettingsActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SettingsActions({required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.cancel),
          label: Text(
            AppLanguage.of(context).t('builder.delete').toUpperCase(),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF777777),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onDuplicate,
          icon: const Icon(Icons.add_circle),
          label: Text(
            AppLanguage.of(context).t('builder.duplicate').toUpperCase(),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF57C78A),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorPickerButton({required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorSelector(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 72,
        height: 42,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: const Color(0xFF777777)),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorSelector(BuildContext context) async {
    var draft = color;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.of(context).t('builder.textColor')),
        content: SizedBox(
          width: 260,
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (value) {
              draft = value;
              onChanged(value);
            },
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(draft);
              Navigator.of(context).pop();
            },
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
        ],
      ),
    );
  }
}

class _AddNewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        height: 124,
        decoration: BoxDecoration(
          color: const Color(0xFF66B64A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3E8D41), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 38),
            const SizedBox(height: 8),
            Text(
              AppLanguage.of(context).t('builder.addNew').toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTab extends StatelessWidget {
  final FourthDemoController controller;

  const _GameTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final settings = controller.project.settings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _SettingRow(
            label: AppLanguage.of(context).t('builder.background'),
            value: settings.background,
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.worldWidth'),
            value: settings.worldWidth,
            onChanged: (value) =>
                controller.updateSettings(settings.copyWith(worldWidth: value)),
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.worldHeight'),
            value: settings.worldHeight,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(worldHeight: value),
            ),
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.gravity'),
            value: settings.gravity,
            onChanged: (value) =>
                controller.updateSettings(settings.copyWith(gravity: value)),
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.physicsMode'),
            value: settings.physicsMode.name,
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.cameraTarget'),
            value: settings.cameraTargetId,
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.tilemap'),
            value: 'ground, platform, obstacle',
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.soundSettingsLabel'),
            value: 'enabled',
          ),
        ],
      ),
    );
  }
}

class _MiniAssetCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniAssetCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 128,
        height: 124,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2B78C2), size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteAvatar extends StatelessWidget {
  final FourthDemoSprite? sprite;
  final double size;

  const _SpriteAvatar({required this.sprite, required this.size});

  @override
  Widget build(BuildContext context) {
    final kind = sprite?.kind;
    final assetId = sprite?.assetId ?? '';
    final playerAssetPath = builderCharacterById(
      assetId.isEmpty ? defaultBuilderCharacterId : assetId,
    ).idlePreviewAssetPath;
    final collectableAssetPath = builderCollectableById(
      assetId.isEmpty ? defaultBuilderCollectableId : assetId,
    ).flutterAssetPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child:
          kind == FourthDemoSpriteKind.player ||
              kind == FourthDemoSpriteKind.collectible
          ? Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(
                kind == FourthDemoSpriteKind.player
                    ? playerAssetPath
                    : collectableAssetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            )
          : Icon(
              switch (kind) {
                FourthDemoSpriteKind.collectible => Icons.eco,
                FourthDemoSpriteKind.prop => Icons.category,
                null => Icons.help,
                FourthDemoSpriteKind.player => Icons.face,
              },
              color: Color(sprite?.colorValue ?? 0xFF66B64A),
              size: size * 0.62,
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? Colors.white : const Color(0xFFD3D9DD),
        borderRadius: active
            ? BorderRadius.zero
            : const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
        child: InkWell(
          onTap: onTap,
          borderRadius: active
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : BorderRadius.zero,
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                  color: active ? Colors.black : const Color(0xFF6C747A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _CommandPill({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEAF8EA) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? const Color(0xFF66B64A) : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.black : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton.filled(
        tooltip: AppLanguage.of(context).t('builder.stageTool'),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: active ? const Color(0xFF66B64A) : Colors.white,
          foregroundColor: active ? Colors.white : const Color(0xFF3A241D),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B78C2),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        decoration: _fieldDecoration(label),
        onFieldSubmitted: (raw) => onChanged(double.tryParse(raw) ?? value),
      ),
    );
  }
}

class _SpriteAssetChoice {
  final String id;
  final String label;
  final String assetPath;
  final FourthDemoSpriteKind kind;

  const _SpriteAssetChoice({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.kind,
  });
}

Future<_SpriteAssetChoice?> _showSpriteChoiceDialog(
  BuildContext context,
) async {
  final choices = <_SpriteAssetChoice>[
    for (final character in builderCharacters)
      _SpriteAssetChoice(
        id: character.id,
        label: localizedBuilderCharacterLabel(
          AppLanguage.of(context),
          character.id,
        ),
        assetPath: character.idlePreviewAssetPath,
        kind: FourthDemoSpriteKind.player,
      ),
    for (final collectable in builderCollectables)
      _SpriteAssetChoice(
        id: collectable.id,
        label: localizedBuilderCollectableLabel(
          AppLanguage.of(context),
          collectable.id,
        ),
        assetPath: collectable.flutterAssetPath,
        kind: FourthDemoSpriteKind.collectible,
      ),
  ];
  var selected = choices.first;

  return showDialog<_SpriteAssetChoice>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSprite'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 520,
            height: 430,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: choices.length,
              itemBuilder: (context, index) {
                final choice = choices[index];
                return _ImageChoiceTile(
                  label: _localizedSpriteChoiceLabel(context, choice),
                  assetPath: choice.assetPath,
                  selected:
                      selected.id == choice.id && selected.kind == choice.kind,
                  onTap: () => setState(() => selected = choice),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Future<FourthDemoWidgetKind?> _showWidgetChoiceDialog(
  BuildContext context,
) async {
  var selected = FourthDemoWidgetKind.counter;

  return showDialog<FourthDemoWidgetKind>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseWidget'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final type in FourthDemoWidgetKind.values)
                  _IconChoiceTile(
                    label: _widgetLabel(context, type),
                    icon: _widgetIcon(type),
                    selected: selected == type,
                    onTap: () => setState(() => selected = type),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> _showSoundChoiceDialog(BuildContext context) async {
  const sounds = <String>[
    'collectSparkle',
    'jumpPop',
    'buttonClick',
    'successChime',
    'timerTick',
    'warningBeep',
  ];
  var selected = sounds.first;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSound'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final sound in sounds)
                  _IconChoiceTile(
                    label: AppLanguage.of(
                      context,
                    ).tr('builder.sound.$sound', sound),
                    icon: Icons.music_note,
                    selected: selected == sound,
                    onTap: () => setState(() => selected = sound),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ImageChoiceTile extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _ImageChoiceTile({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Icon(icon, color: const Color(0xFF2B78C2), size: 38),
    );
  }
}

class _ChoiceShell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _ChoiceShell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF66B64A)
                          : const Color(0xFFD9DEE2),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: child,
                ),
                if (selected)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF2F9F46),
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _widgetIcon(FourthDemoWidgetKind type) {
  return switch (type) {
    FourthDemoWidgetKind.counter => Icons.exposure_plus_1,
    FourthDemoWidgetKind.text => Icons.text_fields,
    FourthDemoWidgetKind.timer => Icons.timer,
    FourthDemoWidgetKind.clock => Icons.schedule,
    FourthDemoWidgetKind.button => Icons.smart_button,
    FourthDemoWidgetKind.dialog => Icons.chat_bubble_outline,
  };
}

String _localizedSpriteChoiceLabel(
  BuildContext context,
  _SpriteAssetChoice choice,
) {
  return switch (choice.kind) {
    FourthDemoSpriteKind.player => localizedBuilderCharacterLabel(
      AppLanguage.of(context),
      choice.id,
    ),
    FourthDemoSpriteKind.collectible => localizedBuilderCollectableLabel(
      AppLanguage.of(context),
      choice.id,
    ),
    FourthDemoSpriteKind.prop => choice.label,
  };
}

String _widgetLabel(BuildContext context, FourthDemoWidgetKind type) {
  final language = AppLanguage.of(context);
  return switch (type) {
    FourthDemoWidgetKind.counter => language.tr(
      'builder.widget.counter',
      'Counter',
    ),
    FourthDemoWidgetKind.text => language.t('builder.text'),
    FourthDemoWidgetKind.timer => language.tr('builder.widget.timer', 'Timer'),
    FourthDemoWidgetKind.clock => language.tr('builder.widget.clock', 'Clock'),
    FourthDemoWidgetKind.button => language.tr(
      'builder.widget.button',
      'Button',
    ),
    FourthDemoWidgetKind.dialog => language.tr(
      'builder.widget.dialog',
      'Dialog',
    ),
  };
}

class _CourseDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget action;

  const _CourseDialog({
    required this.title,
    required this.child,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF3A241D),
        ),
      ),
      content: SizedBox(width: 520, child: child),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLanguage.of(context).t('builder.cancel')),
        ),
        action,
      ],
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD9DEE2)),
    ),
  );
}
