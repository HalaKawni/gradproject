import 'package:flutter/services.dart';

import 'game_command.dart';

class SnippetInsertion {
  final String text;
  final int cursorOffset;
  final int animationStart;
  final int animationEnd;

  const SnippetInsertion({
    required this.text,
    required this.cursorOffset,
    required this.animationStart,
    required this.animationEnd,
  });
}

class GameCodeIndenter {
  const GameCodeIndenter();

  static const String indentUnit = '    ';

  TextEditingValue applyEnter(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid) {
      return value;
    }

    final start = selection.start.clamp(0, value.text.length).toInt();
    final end = selection.end.clamp(0, value.text.length).toInt();
    final currentLine = lineBeforeCursor(value.text, start);
    final insert = '\n${indentAfterLine(currentLine)}';
    final nextText = value.text.replaceRange(start, end, insert);
    final nextOffset = start + insert.length;

    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
  }

  TextEditingValue applyScopeBackspace({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
  }) {
    if (!oldValue.selection.isValid ||
        !oldValue.selection.isCollapsed ||
        !newValue.selection.isCollapsed ||
        oldValue.text.length != newValue.text.length + 1) {
      return newValue;
    }

    final oldOffset = oldValue.selection.baseOffset;
    final newOffset = newValue.selection.baseOffset;
    if (oldOffset <= 0 || newOffset != oldOffset - 1) {
      return newValue;
    }

    final deleted = oldValue.text.substring(newOffset, oldOffset);
    if (deleted != ' ') {
      return newValue;
    }

    final lineStart = _lineStartOffset(oldValue.text, oldOffset);
    final beforeCursor = oldValue.text.substring(lineStart, oldOffset);
    if (!RegExp(r'^ +$').hasMatch(beforeCursor)) {
      return newValue;
    }

    final previousScopeIndent =
        ((beforeCursor.length - 1) ~/ indentUnit.length) * indentUnit.length;
    final removeStart = lineStart + previousScopeIndent;
    final nextText = oldValue.text.replaceRange(removeStart, oldOffset, '');

    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: removeStart),
      composing: TextRange.empty,
    );
  }

  SnippetInsertion insertCommand({
    required String code,
    required int start,
    required int end,
    required GameCommand command,
  }) {
    final safeStart = start.clamp(0, code.length).toInt();
    final safeEnd = end.clamp(0, code.length).toInt();
    final orderedStart = safeStart <= safeEnd ? safeStart : safeEnd;
    final orderedEnd = safeStart <= safeEnd ? safeEnd : safeStart;
    final currentLine = lineBeforeCursor(code, orderedStart);
    final insertAtTopLevel = _isTopLevelCommand(command);
    final replaceStart = currentLine.trim().isEmpty
        ? _lineStartOffset(code, orderedStart)
        : orderedStart;
    final effectiveLine = lineBeforeCursor(code, replaceStart);
    final prefix = effectiveLine.trim().isNotEmpty ? '\n' : '';
    final indent = insertAtTopLevel ? '' : indentForCursor(code, replaceStart);
    final snippet = _indentSnippet(
      command.insertText,
      indent,
      includeFirstLine: prefix.isNotEmpty || effectiveLine.trim().isEmpty,
    );
    final cursorMarkerIndex = snippet.indexOf(r'$cursor');
    final cleanSnippet = snippet.replaceFirst(r'$cursor', '');
    final inserted = '$prefix$cleanSnippet';
    final nextText = code.replaceRange(replaceStart, orderedEnd, inserted);
    final insertedStart = replaceStart + prefix.length;
    final cursorOffset = cursorMarkerIndex == -1
        ? insertedStart + cleanSnippet.length
        : insertedStart + cursorMarkerIndex;

    return SnippetInsertion(
      text: nextText,
      cursorOffset: cursorOffset,
      animationStart: replaceStart,
      animationEnd: replaceStart + inserted.length,
    );
  }

  String lineBeforeCursor(String text, int cursorOffset) {
    final safeOffset = cursorOffset.clamp(0, text.length).toInt();
    if (safeOffset == 0) {
      return '';
    }
    final lineStart = _lineStartOffset(text, safeOffset);
    return text.substring(lineStart, safeOffset);
  }

  String indentAfterLine(String line) {
    final currentIndent = leadingWhitespace(line);
    final trimmed = line.trim();
    if (opensBlock(trimmed)) {
      return '$currentIndent$indentUnit';
    }
    return currentIndent;
  }

  String indentForCursor(String text, int cursorOffset) {
    final safeOffset = cursorOffset.clamp(0, text.length).toInt();
    final currentLine = lineBeforeCursor(text, safeOffset);
    if (currentLine.trim().isNotEmpty) {
      return indentAfterLine(currentLine);
    }

    final before = text.substring(0, safeOffset);
    final lines = before.split('\n');
    for (var index = lines.length - 2; index >= 0; index -= 1) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        continue;
      }
      return indentAfterLine(line);
    }

    return leadingWhitespace(currentLine);
  }

  String leadingWhitespace(String line) {
    final raw = RegExp(r'^[ \t]*').firstMatch(line)?.group(0) ?? '';
    return raw.replaceAll('\t', indentUnit);
  }

  bool opensBlock(String trimmedLine) {
    return trimmedLine.endsWith('=>') ||
        trimmedLine.startsWith('if ') ||
        trimmedLine == 'else' ||
        trimmedLine == 'loop' ||
        RegExp(r'^\d+\.times\s*=>?$').hasMatch(trimmedLine) ||
        trimmedLine.startsWith('for ') ||
        trimmedLine.startsWith('until ') ||
        RegExp(r'^[A-Za-z_]\w*\s*=\s*\(.*\)\s*=>\s*$').hasMatch(trimmedLine);
  }

  bool _isTopLevelCommand(GameCommand command) {
    return command.category == GameCommandCategory.events &&
        command.insertText.trimLeft().startsWith('@on');
  }

  String _indentSnippet(
    String snippet,
    String indent, {
    required bool includeFirstLine,
  }) {
    if (indent.isEmpty) {
      return snippet;
    }

    final lines = snippet.split('\n');
    return lines
        .asMap()
        .entries
        .map((entry) {
          if (entry.key == 0 && !includeFirstLine) {
            return entry.value;
          }
          if (entry.value.isEmpty) {
            return indent;
          }
          return '$indent${entry.value}';
        })
        .join('\n');
  }

  int _lineStartOffset(String text, int cursorOffset) {
    final safeOffset = cursorOffset.clamp(0, text.length).toInt();
    if (safeOffset == 0) {
      return 0;
    }
    return text.lastIndexOf('\n', safeOffset - 1) + 1;
  }
}
