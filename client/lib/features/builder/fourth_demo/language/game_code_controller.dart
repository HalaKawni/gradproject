import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import 'game_autocomplete_engine.dart';
import 'game_code_indenter.dart';
import '../models/fourth_demo_project.dart';

class GameCodeController extends CodeController {
  GameCodeController({
    super.text,
    super.language,
    super.modifiers = const [TabModifier()],
  });

  static const GameCodeIndenter _indenter = GameCodeIndenter();
  static const GameAutocompleteEngine _autocomplete = GameAutocompleteEngine();
  FourthDemoProject? projectContext;

  @override
  set value(TextEditingValue newValue) {
    super.value = _indenter.applyScopeBackspace(
      oldValue: value,
      newValue: newValue,
    );
  }

  @override
  void onEnterKeyAction() {
    if (popupController.shouldShow) {
      insertSelectedWord();
      return;
    }

    value = _indenter.applyEnter(value);
  }

  @override
  void insertSelectedWord() {
    final selectedWord = popupController.getSelectedWord();
    final range = _completionPrefixRange();
    if (range == null) {
      popupController.hide();
      return;
    }

    final replacedText = text.replaceRange(
      range.start,
      range.end,
      selectedWord,
    );
    final nextOffset = range.start + selectedWord.length;

    value = TextEditingValue(
      text: replacedText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
    popupController.hide();
  }

  @override
  Future<void> generateSuggestions() async {
    final suggestions = _autocomplete.suggestionsFor(
      text,
      selection.baseOffset,
      project: projectContext,
    );

    if (suggestions.isEmpty) {
      popupController.hide();
      return;
    }

    popupController.show(suggestions);
  }

  void moveCursorToLineColumn(int line, int column) {
    final safeLine = line < 1 ? 1 : line;
    final safeColumn = column < 1 ? 1 : column;
    final lines = text.split('\n');
    var offset = 0;
    for (var index = 0; index < safeLine - 1 && index < lines.length; index++) {
      offset += lines[index].length + 1;
    }
    if (lines.isNotEmpty) {
      final lineIndex = (safeLine - 1).clamp(0, lines.length - 1).toInt();
      offset += (safeColumn - 1).clamp(0, lines[lineIndex].length).toInt();
    }
    value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, text.length).toInt(),
      ),
    );
  }

  TextRange? _completionPrefixRange() {
    final offset = selection.baseOffset;
    if (!selection.isValid || !selection.isCollapsed || offset < 0) {
      return null;
    }

    var start = offset.clamp(0, text.length).toInt();
    while (start > 0) {
      final char = text[start - 1];
      if (!RegExp(r'[\w@.]').hasMatch(char)) {
        break;
      }
      start -= 1;
    }

    if (start == offset) {
      return null;
    }

    return TextRange(start: start, end: offset);
  }
}
