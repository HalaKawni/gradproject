import 'package:client/core/models/auth_session.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../scratch_builder/models/instruction_section.dart';
import '../../scratch_builder/widgets/instruction_editor_panel.dart';
import '../controllers/fourth_demo_controller.dart';
import '../flame/fourth_demo_game.dart';
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
  late final TextEditingController codeController;
  late final TextEditingController titleController;
  final FocusNode stageFocusNode = FocusNode();
  final List<InstructionSection> instructionSections = <InstructionSection>[];

  @override
  void initState() {
    super.initState();
    controller = FourthDemoController()..addListener(_handleControllerChanged);
    game = FourthDemoGame(controller: controller);
    codeController = TextEditingController(text: controller.selectedCode);
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
    if (titleController.text != controller.project.title) {
      titleController.value = titleController.value.copyWith(
        text: controller.project.title,
        selection: TextSelection.collapsed(offset: controller.project.title.length),
      );
    }
    if (codeController.text != controller.selectedCode) {
      codeController.value = TextEditingValue(
        text: controller.selectedCode,
        selection: TextSelection.collapsed(offset: controller.selectedCode.length),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTitleChanged() {
    controller.setTitle(titleController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4EC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'New Level',
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
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: controller.loadLocal,
              child: const Text('Load', style: TextStyle(color: Colors.black)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: _showImportDialog,
              child: const Text('Import', style: TextStyle(color: Colors.black)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton(
              onPressed: _showExportDialog,
              child: const Text('Publish'),
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
    );
  }

  Future<void> _showExportDialog() async {
    final exportController = TextEditingController(text: controller.exportJson());
    await showDialog<void>(
      context: context,
      builder: (context) => _CourseDialog(
        title: 'Export Project JSON',
        action: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        child: TextField(
          controller: exportController,
          maxLines: 18,
          readOnly: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: _fieldDecoration('Project JSON'),
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
        title: 'Import Project JSON',
        action: FilledButton(
          onPressed: () {
            controller.importJson(importController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Import'),
        ),
        child: TextField(
          controller: importController,
          maxLines: 18,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: _fieldDecoration('Paste JSON here'),
        ),
      ),
    );
    importController.dispose();
  }

  List<InstructionSection> _defaultInstructionSections() {
    return const <InstructionSection>[
      InstructionSection(
        id: 'overview',
        type: InstructionSectionType.overview,
        title: 'Welcome to the Game Builder',
        content:
            'Today we will learn how to create a game. The goal of the game is to move the player to get the banana. We will use the onKey function, which is called whenever you press a key on your keyboard. The image of the player character on the screen is called a sprite. The function step moves the sprite. Write inside the onKey function to move the player. Now let us start!',
      ),
      InstructionSection(
        id: 'code-example',
        type: InstructionSectionType.codeExample,
        title: 'Code Example',
        content: '@step 1',
      ),
      InstructionSection(
        id: 'instructions',
        type: InstructionSectionType.instructions,
        title: 'Instructions',
        content:
            'Use @step 1 inside @onKey. Once you are done, click the RUN button.',
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
      final index = instructionSections.indexWhere((section) => section.id == id);
      if (index == -1) {
        return;
      }
      instructionSections[index] = instructionSections[index].copyWith(title: title);
    });
  }

  void _updateInstructionContent(String id, String content) {
    setState(() {
      final index = instructionSections.indexWhere((section) => section.id == id);
      if (index == -1) {
        return;
      }
      instructionSections[index] =
          instructionSections[index].copyWith(content: content);
    });
  }

  void _addInstructionItem(String id) {
    setState(() {
      final index = instructionSections.indexWhere((section) => section.id == id);
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      instructionSections[index] =
          section.copyWith(items: <String>[...section.items, '']);
    });
  }

  void _updateInstructionItem(String id, int itemIndex, String value) {
    setState(() {
      final index = instructionSections.indexWhere((section) => section.id == id);
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
      final index = instructionSections.indexWhere((section) => section.id == id);
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
  final TextEditingController codeController;

  const _CodeColumn({required this.controller, required this.codeController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FA),
        border: Border.symmetric(vertical: BorderSide(color: Color(0xFFC6D2D9), width: 2)),
      ),
      child: Column(
        children: [
          _CodeHeader(controller: controller),
          Expanded(child: _CodeEditor(controller: controller, codeController: codeController)),
          _FunctionPalette(controller: controller, codeController: codeController),
        ],
      ),
    );
  }
}

class _CodeHeader extends StatelessWidget {
  final FourthDemoController controller;

  const _CodeHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
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
              sprite?.name ?? 'No sprite',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          if (controller.codeError != null)
            Flexible(
              child: Text(
                controller.codeError!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD94836), fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: controller.stop,
            icon: const Icon(Icons.stop),
            label: const Text('STOP'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3A241D)),
          ),
          FilledButton.icon(
            onPressed: controller.runCode,
            icon: const Icon(Icons.play_arrow),
            label: const Text('RUN'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF66B64A),
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
  final TextEditingController codeController;

  const _CodeEditor({required this.controller, required this.codeController});

  @override
  Widget build(BuildContext context) {
    final lineCount = codeController.text.split('\n').length.clamp(6, 99);
    return Container(
      color: const Color(0xFFEEF6FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.only(top: 14),
            color: const Color(0xFFDDEBF2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 1; i <= lineCount; i += 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 4),
                    child: Text(
                      '$i',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Color(0xFF6A8291),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: codeController,
              expands: true,
              maxLines: null,
              minLines: null,
              inputFormatters: const [_LessonCodeIndentFormatter()],
              onChanged: controller.updateSelectedCode,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                height: 1.45,
                color: Color(0xFF24465A),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunctionPalette extends StatefulWidget {
  final FourthDemoController controller;
  final TextEditingController codeController;

  const _FunctionPalette({
    required this.controller,
    required this.codeController,
  });

  @override
  State<_FunctionPalette> createState() => _FunctionPaletteState();
}

class _FunctionPaletteState extends State<_FunctionPalette> {
  bool _isTyping = false;

  static const snippets = <FourthDemoPaletteTab, Map<String, String>>{
    FourthDemoPaletteTab.movement: {
      'step': '@step 1',
      'jump': '@jump()',
      'getX': '@getX()',
      'getY': '@getY()',
      'setX': '@setX 100',
      'setY': '@setY 100',
      'setRotation': '@setRotation 90',
      'getRotation': '@getRotation()',
      'setSpeed': '@setSpeed 100',
      'setAllowGravity': '@setAllowGravity true',
      'getDistanceFrom': '@getDistanceFrom banana',
    },
    FourthDemoPaletteTab.events: {
      'onKey': '@onKey = (key) =>',
      'onClick': '@onClick = =>',
      'onCollide': '@onCollide = (sprite) =>',
      'onStart': '@onStart = =>',
      'onUpdate': '@onUpdate = =>',
    },
    FourthDemoPaletteTab.display: {
      'show': '@show()',
      'hide': '@hide()',
      'setScale': '@setScale 1',
      'startAnimation': '@startAnimation run',
      'stopAnimation': '@stopAnimation()',
      'say': '@say "Hello"',
    },
    FourthDemoPaletteTab.control: {
      'if': 'if condition\n    ',
      'if/else': 'if condition\n    \nelse\n    ',
      'repeat': 'repeat 3',
      'loop': 'loop',
      'wait': 'wait 1',
    },
    FourthDemoPaletteTab.operators: {
      '+': '+',
      '-': '-',
      '*': '*',
      '/': '/',
      '==': '==',
      '>': '>',
      '<': '<',
      'and': 'and',
      'or': 'or',
      'not': 'not',
    },
  };

  @override
  Widget build(BuildContext context) {
    final items = snippets[widget.controller.paletteTab]!;
    return Container(
      height: 172,
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
                  text: _paletteLabel(tab),
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
                  for (final entry in items.entries)
                    _CommandPill(
                      label: entry.key,
                      onTap: () => _typeSnippet(entry.value),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _paletteLabel(FourthDemoPaletteTab tab) {
    return switch (tab) {
      FourthDemoPaletteTab.movement => 'Movement',
      FourthDemoPaletteTab.events => 'Events',
      FourthDemoPaletteTab.display => 'Display',
      FourthDemoPaletteTab.control => 'Control',
      FourthDemoPaletteTab.operators => 'Operators',
    };
  }

  Future<void> _typeSnippet(String snippet) async {
    if (_isTyping) {
      return;
    }
    _isTyping = true;
    final text = widget.codeController.text;
    final selection = widget.codeController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final insertText = _snippetWithSpacing(text, start, snippet);
    var next = text.replaceRange(start, end, '');
    widget.codeController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start),
    );
    widget.controller.updateSelectedCode(next);

    var offset = start;
    for (final unit in insertText.characters) {
      if (!mounted) {
        return;
      }
      next = widget.codeController.text.replaceRange(offset, offset, unit);
      offset += unit.length;
      widget.codeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: offset),
      );
      widget.controller.updateSelectedCode(next);
      await Future<void>.delayed(const Duration(milliseconds: 6));
    }
    _isTyping = false;
  }

  String _snippetWithSpacing(String text, int offset, String snippet) {
    final before = text.substring(0, offset);
    final after = text.substring(offset);
    final lineStart = before.lastIndexOf('\n') + 1;
    final currentLineBeforeCursor = before.substring(lineStart);
    final previousLine = _previousNonEmptyLine(before);
    final isEventSnippet = snippet.startsWith('@on');
    final isOperator = _isOperatorSnippet(snippet);
    final baseIndent = _indentForContext(currentLineBeforeCursor, previousLine);

    if (isOperator) {
      return snippet;
    }

    if (isEventSnippet) {
      final prefix = before.trim().isEmpty
          ? ''
          : before.endsWith('\n')
              ? ''
              : '\n';
      final suffix = after.startsWith('\n') || after.isEmpty ? '\n    ' : '';
      return '$prefix$snippet$suffix';
    }

    final formattedSnippet = _indentMultilineSnippet(snippet, baseIndent);
    if (before.isEmpty || before.endsWith('\n')) {
      return formattedSnippet;
    }
    if (currentLineBeforeCursor.trim().isEmpty) {
      final currentIndent = _leadingWhitespace(currentLineBeforeCursor);
      return currentIndent.isEmpty
          ? formattedSnippet
          : _indentMultilineSnippet(snippet, currentIndent, includeFirstLine: false);
    }
    return '\n$formattedSnippet';
  }

  String _indentForContext(String currentLineBeforeCursor, String previousLine) {
    final currentIndent = _leadingWhitespace(currentLineBeforeCursor);
    if (currentIndent.isNotEmpty) {
      return currentIndent;
    }
    final previousIndent = _leadingWhitespace(previousLine);
    final trimmedPrevious = previousLine.trim();
    if (_opensBlock(trimmedPrevious)) {
      return '$previousIndent    ';
    }
    if (previousIndent.isNotEmpty) {
      return previousIndent;
    }
    return _insideEventBlock(previousLine) ? '    ' : '';
  }

  String _previousNonEmptyLine(String before) {
    final lines = before.split('\n');
    for (var i = lines.length - 1; i >= 0; i -= 1) {
      if (lines[i].trim().isNotEmpty) {
        return lines[i];
      }
    }
    return '';
  }

  bool _insideEventBlock(String previousLine) {
    return previousLine.trim().startsWith('@on');
  }

  bool _opensBlock(String line) {
    return line.endsWith('=>') ||
        line.startsWith('@on') ||
        line.startsWith('if ') ||
        line.startsWith('repeat ') ||
        line == 'loop' ||
        line == 'else';
  }

  String _leadingWhitespace(String value) {
    return RegExp(r'^\s*').firstMatch(value)?.group(0) ?? '';
  }

  bool _isOperatorSnippet(String snippet) {
    return const {'+', '-', '*', '/', '==', '>', '<', 'and', 'or', 'not'}.contains(snippet);
  }

  String _indentMultilineSnippet(
    String snippet,
    String indent, {
    bool includeFirstLine = true,
  }) {
    final lines = snippet.split('\n');
    return lines.asMap().entries.map((entry) {
      final isFirst = entry.key == 0;
      if (isFirst && !includeFirstLine) {
        return entry.value;
      }
      return '$indent${entry.value}';
    }).join('\n');
  }
}

class _LessonCodeIndentFormatter extends TextInputFormatter {
  const _LessonCodeIndentFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldSelection = oldValue.selection;
    if (!oldSelection.isValid || newValue.text.length <= oldValue.text.length) {
      return newValue;
    }

    final insertedStart = oldSelection.start;
    final insertedEnd = newValue.selection.end;
    if (insertedStart < 0 || insertedEnd < insertedStart || insertedEnd > newValue.text.length) {
      return newValue;
    }

    final inserted = newValue.text.substring(insertedStart, insertedEnd);
    if (!inserted.contains('\n')) {
      return newValue;
    }

    final before = newValue.text.substring(0, insertedStart);
    final after = newValue.text.substring(insertedEnd);
    final replacement = _withSmartIndent(before, inserted);
    final nextText = '$before$replacement$after';
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: before.length + replacement.length),
      composing: TextRange.empty,
    );
  }

  String _withSmartIndent(String before, String inserted) {
    final buffer = StringBuffer();
    var context = before;
    for (final character in inserted.characters) {
      buffer.write(character);
      context += character;
      if (character == '\n') {
        final indent = _nextLineIndent(context.substring(0, context.length - 1));
        buffer.write(indent);
        context += indent;
      }
    }
    return buffer.toString();
  }

  String _nextLineIndent(String beforeNewLine) {
    final lineStart = beforeNewLine.lastIndexOf('\n') + 1;
    final previousLine = beforeNewLine.substring(lineStart);
    final previousIndent = _leadingWhitespace(previousLine);
    final trimmed = previousLine.trim();
    if (_opensBlock(trimmed)) {
      return '$previousIndent    ';
    }
    return previousIndent;
  }

  bool _opensBlock(String line) {
    return line.endsWith('=>') ||
        line.startsWith('@on') ||
        line.startsWith('if ') ||
        line.startsWith('repeat ') ||
        line == 'loop' ||
        line == 'else';
  }

  String _leadingWhitespace(String value) {
    return RegExp(r'^\s*').firstMatch(value)?.group(0) ?? '';
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
            child: _StagePanel(controller: controller, game: game, focusNode: focusNode),
          ),
          Expanded(
            flex: 9,
            child: _AssetManager(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _StagePanel extends StatelessWidget {
  final FourthDemoController controller;
  final FourthDemoGame game;
  final FocusNode focusNode;

  const _StagePanel({
    required this.controller,
    required this.game,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          controller.handleKey(event.logicalKey);
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
              child: GestureDetector(
                onTapDown: (details) {
                  focusNode.requestFocus();
                  controller.beginDrag(game.worldPositionFromCanvas(details.localPosition));
                  controller.endDrag();
                },
                onPanStart: (details) {
                  focusNode.requestFocus();
                  controller.beginDrag(game.worldPositionFromCanvas(details.localPosition));
                },
                onPanUpdate: (details) => controller.dragTo(game.worldPositionFromCanvas(details.localPosition)),
                onPanEnd: (_) => controller.endDrag(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: GameWidget(game: game),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _ToolButton(icon: Icons.north_west, active: controller.stageTool == FourthDemoStageTool.select, onTap: () => controller.setStageTool(FourthDemoStageTool.select)),
                  _ToolButton(icon: Icons.open_with, active: controller.stageTool == FourthDemoStageTool.move, onTap: () => controller.setStageTool(FourthDemoStageTool.move)),
                  _ToolButton(icon: Icons.auto_fix_off, active: controller.stageTool == FourthDemoStageTool.eraser, onTap: () => controller.setStageTool(FourthDemoStageTool.eraser)),
                  _ToolButton(icon: Icons.brush, active: controller.stageTool == FourthDemoStageTool.brush, onTap: () => controller.setStageTool(FourthDemoStageTool.brush)),
                ],
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: controller.exerciseComplete ? const Color(0xFF66B64A) : const Color(0xFFD9DEE2)),
                ),
                child: Text(
                  controller.statusMessage,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: controller.exerciseComplete ? const Color(0xFF2F9F46) : const Color(0xFF3A241D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetManager extends StatelessWidget {
  final FourthDemoController controller;

  const _AssetManager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECEF),
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in FourthDemoAssetTab.values)
                _TabButton(
                  text: _assetLabel(tab),
                  active: controller.assetTab == tab,
                  onTap: () => controller.setAssetTab(tab),
                ),
            ],
          ),
          Expanded(
            child: switch (controller.assetTab) {
              FourthDemoAssetTab.sprites => _SpritesTab(controller: controller),
              FourthDemoAssetTab.widgets => const _WidgetsTab(),
              FourthDemoAssetTab.sounds => _SoundsTab(controller: controller),
              FourthDemoAssetTab.game => _GameTab(controller: controller),
            },
          ),
        ],
      ),
    );
  }

  static String _assetLabel(FourthDemoAssetTab tab) {
    return switch (tab) {
      FourthDemoAssetTab.sprites => 'Sprites',
      FourthDemoAssetTab.widgets => 'Widgets',
      FourthDemoAssetTab.sounds => 'Sounds',
      FourthDemoAssetTab.game => 'Game',
    };
  }
}

class _SpritesTab extends StatelessWidget {
  final FourthDemoController controller;

  const _SpritesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _AddNewCard(onTap: controller.addPlaceholderSprite),
          for (final sprite in controller.project.sprites)
            _SpriteCard(
              sprite: sprite,
              selected: sprite.id == controller.project.selectedSpriteId,
              onTap: () => controller.selectSprite(sprite.id),
              onSettings: () => _showSpriteSettings(context, controller, sprite),
            ),
        ],
      ),
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
          border: Border.all(color: selected ? const Color(0xFF66B64A) : const Color(0xFFD9DEE2), width: selected ? 3 : 1),
        ),
        child: Column(
          children: [
            _SpriteAvatar(sprite: sprite, size: 54),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(sprite.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                IconButton(
                  tooltip: 'Settings',
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: Colors.white, size: 38),
            SizedBox(height: 8),
            Text('ADD NEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _WidgetsTab extends StatelessWidget {
  const _WidgetsTab();

  @override
  Widget build(BuildContext context) {
    const widgets = ['Counter', 'Text', 'Timer', 'Clock', 'Button', 'Dialog'];
    return _SimpleCardGrid(items: widgets, leadingIcon: Icons.widgets);
  }
}

class _SoundsTab extends StatelessWidget {
  final FourthDemoController controller;

  const _SoundsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          const _MiniAssetCard(title: 'Add sound', icon: Icons.add),
          for (final sound in controller.project.sounds)
            _MiniAssetCard(title: sound.name, icon: Icons.play_arrow),
        ],
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
          _SettingRow(label: 'Background', value: settings.background),
          _NumberSetting(
            label: 'World width',
            value: settings.worldWidth,
            onChanged: (value) => controller.updateSettings(settings.copyWith(worldWidth: value)),
          ),
          _NumberSetting(
            label: 'World height',
            value: settings.worldHeight,
            onChanged: (value) => controller.updateSettings(settings.copyWith(worldHeight: value)),
          ),
          _NumberSetting(
            label: 'Gravity',
            value: settings.gravity,
            onChanged: (value) => controller.updateSettings(settings.copyWith(gravity: value)),
          ),
          _SettingRow(label: 'Physics mode', value: settings.physicsMode.name),
          _SettingRow(label: 'Camera target', value: settings.cameraTargetId),
          const _SettingRow(label: 'Tilemap', value: 'ground, platform, obstacle'),
          const _SettingRow(label: 'Sound settings', value: 'enabled'),
        ],
      ),
    );
  }
}

class _SimpleCardGrid extends StatelessWidget {
  final List<String> items;
  final IconData leadingIcon;

  const _SimpleCardGrid({required this.items, required this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in items) _MiniAssetCard(title: item, icon: leadingIcon),
        ],
      ),
    );
  }
}

class _MiniAssetCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MiniAssetCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF2B78C2)),
          const SizedBox(height: 8),
          Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Icon(
        switch (kind) {
          FourthDemoSpriteKind.player => Icons.face,
          FourthDemoSpriteKind.collectible => Icons.eco,
          FourthDemoSpriteKind.prop => Icons.category,
          null => Icons.help,
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
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFD9DEE2),
            border: const Border(right: BorderSide(color: Color(0xFFC6D2D9))),
          ),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active ? const Color(0xFF3A241D) : const Color(0xFF66757F),
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

  const _CommandPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF66B64A), width: 2),
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFF2F9F46), fontWeight: FontWeight.w900)),
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
        tooltip: 'Stage tool',
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
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value, style: const TextStyle(color: Color(0xFF2B78C2), fontWeight: FontWeight.w800)),
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

Future<void> _showSpriteSettings(
  BuildContext context,
  FourthDemoController controller,
  FourthDemoSprite sprite,
) async {
  var draft = sprite;
  final nameController = TextEditingController(text: sprite.name);
  final xController = TextEditingController(text: sprite.x.toStringAsFixed(0));
  final yController = TextEditingController(text: sprite.y.toStringAsFixed(0));
  final scaleController = TextEditingController(text: sprite.scale.toStringAsFixed(1));
  final rotationController = TextEditingController(text: sprite.rotation.toStringAsFixed(0));

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: '${sprite.name} Settings',
          action: FilledButton(
            onPressed: () {
              draft = draft.copyWith(
                name: nameController.text.trim().isEmpty ? sprite.name : nameController.text.trim(),
                x: double.tryParse(xController.text) ?? sprite.x,
                y: double.tryParse(yController.text) ?? sprite.y,
                startX: double.tryParse(xController.text) ?? sprite.startX,
                startY: double.tryParse(yController.text) ?? sprite.startY,
                scale: double.tryParse(scaleController.text) ?? sprite.scale,
                rotation: double.tryParse(rotationController.text) ?? sprite.rotation,
              );
              controller.updateSprite(draft);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: _fieldDecoration('Name')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: xController, decoration: _fieldDecoration('X'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: yController, decoration: _fieldDecoration('Y'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: scaleController, decoration: _fieldDecoration('Scale'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: rotationController, decoration: _fieldDecoration('Rotation'))),
                ],
              ),
              SwitchListTile(
                value: draft.allowGravity,
                onChanged: (value) => setState(() => draft = draft.copyWith(allowGravity: value)),
                title: const Text('Allow gravity'),
              ),
              SwitchListTile(
                value: draft.collideWorldBounds,
                onChanged: (value) => setState(() => draft = draft.copyWith(collideWorldBounds: value)),
                title: const Text('Collide world bounds'),
              ),
              SwitchListTile(
                value: draft.collideOtherSprites,
                onChanged: (value) => setState(() => draft = draft.copyWith(collideOtherSprites: value)),
                title: const Text('Collide other sprites'),
              ),
              SwitchListTile(
                value: draft.visible,
                onChanged: (value) => setState(() => draft = draft.copyWith(visible: value)),
                title: const Text('Visible'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    controller.deleteSprite(sprite.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete sprite'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  nameController.dispose();
  xController.dispose();
  yController.dispose();
  scaleController.dispose();
  rotationController.dispose();
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3A241D))),
      content: SizedBox(width: 520, child: child),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
