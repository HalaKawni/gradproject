import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import 'game_autocomplete_engine.dart';
import 'game_code_indenter.dart';

class GameCodeController extends CodeController {
  GameCodeController({
    super.text,
    super.language,
    super.modifiers = const [TabModifier()],
  });

  static const GameCodeIndenter _indenter = GameCodeIndenter();
  static const GameAutocompleteEngine _autocomplete = GameAutocompleteEngine();

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
    );

    if (suggestions.isEmpty) {
      popupController.hide();
      return;
    }

    popupController.show(suggestions);
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
