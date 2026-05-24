import '../models/fourth_demo_project.dart';
import 'game_diagnostics.dart';

class GameParseResult {
  final List<FourthDemoEventHandler> handlers;
  final GameDiagnostic? diagnostic;

  const GameParseResult._({required this.handlers, this.diagnostic});

  bool get isValid => diagnostic == null;

  factory GameParseResult.success(List<FourthDemoEventHandler> handlers) {
    return GameParseResult._(handlers: handlers);
  }

  factory GameParseResult.failure(String message, int line) {
    return GameParseResult._(
      handlers: const <FourthDemoEventHandler>[],
      diagnostic: GameDiagnostic(message: message, line: line),
    );
  }
}

class GameParser {
  const GameParser();

  GameParseResult parse({
    required String code,
    required String targetSpriteId,
  }) {
    final rawLines = code.replaceAll('\r\n', '\n').split('\n');
    final handlers = <FourthDemoEventHandler>[];

    for (var index = 0; index < rawLines.length; index += 1) {
      final line = rawLines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (!_isEvent(trimmed)) {
        return GameParseResult.failure(
          'I expected an event like @onKey = (key) =>.',
          index + 1,
        );
      }

      if (!trimmed.contains('=>')) {
        return GameParseResult.failure(
          'This event needs => at the end.',
          index + 1,
        );
      }

      final event = _eventName(trimmed);
      final block = _collectBlock(rawLines, index + 1, _indentOf(line));
      if (block.lines.isEmpty) {
        return GameParseResult.failure(
          'This event needs code inside it.',
          index + 1,
        );
      }

      final actions = _parseActions(block.lines, block.startLine);
      if (actions.diagnostic != null) {
        return GameParseResult._(
          handlers: const <FourthDemoEventHandler>[],
          diagnostic: actions.diagnostic,
        );
      }

      handlers.add(
        FourthDemoEventHandler(
          event: event,
          targetSpriteId: targetSpriteId,
          actions: actions.actions,
        ),
      );

      index = block.endIndex;
    }

    if (handlers.isEmpty) {
      return GameParseResult.failure(
        'I could not find an event. Try using the Events tab.',
        1,
      );
    }

    return GameParseResult.success(handlers);
  }

  _ActionParseResult _parseActions(List<String> lines, int firstLineNumber) {
    final actions = <FourthDemoAction>[];

    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (_indentOf(line) == 0) {
        return _ActionParseResult.failure(
          'This line needs to be indented.',
          firstLineNumber + index,
        );
      }

      if (trimmed.startsWith('if ')) {
        final block = _collectBlock(lines, index + 1, _indentOf(line));
        if (block.lines.isEmpty) {
          return _ActionParseResult.failure(
            'This if needs indented code under it.',
            firstLineNumber + index,
          );
        }
        final nested = _parseActions(
          block.lines,
          firstLineNumber + block.startLine - 1,
        );
        if (nested.diagnostic != null) {
          return nested;
        }
        var elseActions = const <FourthDemoAction>[];
        var nextIndex = block.endIndex;
        if (nextIndex + 1 < lines.length &&
            _indentOf(lines[nextIndex + 1]) == _indentOf(line) &&
            lines[nextIndex + 1].trim() == 'else') {
          final elseIndex = nextIndex + 1;
          final elseBlock = _collectBlock(
            lines,
            elseIndex + 1,
            _indentOf(line),
          );
          if (elseBlock.lines.isEmpty) {
            return _ActionParseResult.failure(
              'This else needs indented code under it.',
              firstLineNumber + elseIndex,
            );
          }
          final parsedElse = _parseActions(
            elseBlock.lines,
            firstLineNumber + elseBlock.startLine - 1,
          );
          if (parsedElse.diagnostic != null) {
            return parsedElse;
          }
          elseActions = parsedElse.actions;
          nextIndex = elseBlock.endIndex;
        }
        final condition = trimmed.substring(3).trim();
        if (condition.isEmpty) {
          return _ActionParseResult.failure(
            'This if needs a condition, like: if key == keyboard.right',
            firstLineNumber + index,
          );
        }
        actions.add(
          FourthDemoAction(
            type: FourthDemoActionType.ifCondition,
            condition: condition,
            actions: nested.actions,
            elseActions: elseActions,
          ),
        );
        index = nextIndex;
        continue;
      }

      FourthDemoAction? action;
      try {
        action = _parseAction(trimmed);
      } on FormatException catch (error) {
        return _ActionParseResult.failure(
          error.message,
          firstLineNumber + index,
        );
      }
      if (action == null) {
        final command = trimmed.split(RegExp(r'\s+')).first;
        return _ActionParseResult.failure(
          "I don't know the command $command.",
          firstLineNumber + index,
        );
      }
      actions.add(action);
    }

    return _ActionParseResult.success(actions);
  }

  FourthDemoAction? _parseAction(String line) {
    final call = _splitReceiver(line);
    final command = call.command;
    final args = call.args;

    double number([double fallback = 0, String commandName = 'this command']) {
      if (args.isEmpty) {
        return fallback;
      }
      final parsed = double.tryParse(args.first);
      if (parsed == null) {
        throw FormatException('Expected a number after @$commandName.');
      }
      return parsed;
    }

    switch (command) {
      case 'step':
        final amount = number(double.nan, 'step');
        if (amount.isNaN) {
          throw const FormatException('Expected a number after @step.');
        }
        return FourthDemoAction(
          type: FourthDemoActionType.step,
          amount: amount,
          receiver: call.receiver,
        );
      case 'jump':
        return FourthDemoAction(
          type: FourthDemoActionType.jump,
          receiver: call.receiver,
        );
      case 'setX':
        return FourthDemoAction(
          type: FourthDemoActionType.setX,
          amount: number(0, 'setX'),
          receiver: call.receiver,
        );
      case 'setY':
        return FourthDemoAction(
          type: FourthDemoActionType.setY,
          amount: number(0, 'setY'),
          receiver: call.receiver,
        );
      case 'setRotation':
        return FourthDemoAction(
          type: FourthDemoActionType.setRotation,
          amount: number(0, 'setRotation'),
          receiver: call.receiver,
        );
      case 'setSpeed':
        return FourthDemoAction(
          type: FourthDemoActionType.setSpeed,
          amount: number(1, 'setSpeed'),
          receiver: call.receiver,
        );
      case 'setAllowGravity':
        return FourthDemoAction(
          type: FourthDemoActionType.setAllowGravity,
          text: args.join(' '),
          receiver: call.receiver,
        );
      case 'show':
        return FourthDemoAction(
          type: FourthDemoActionType.show,
          receiver: call.receiver,
        );
      case 'hide':
        return FourthDemoAction(
          type: FourthDemoActionType.hide,
          receiver: call.receiver,
        );
      case 'destroy':
        return FourthDemoAction(
          type: FourthDemoActionType.destroy,
          receiver: call.receiver,
        );
      case 'disable':
        return FourthDemoAction(
          type: FourthDemoActionType.disable,
          receiver: call.receiver,
        );
      case 'enable':
        return FourthDemoAction(
          type: FourthDemoActionType.enable,
          receiver: call.receiver,
        );
      case 'setScale':
        return FourthDemoAction(
          type: FourthDemoActionType.setScale,
          amount: number(1, 'setScale'),
          receiver: call.receiver,
        );
      case 'startAnimation':
        return FourthDemoAction(
          type: FourthDemoActionType.say,
          text: 'Animation started: ${args.join(' ')}',
          receiver: call.receiver,
        );
      case 'stopAnimation':
        return FourthDemoAction(
          type: FourthDemoActionType.say,
          text: 'Animation stopped',
          receiver: call.receiver,
        );
      case 'say':
        return FourthDemoAction(
          type: FourthDemoActionType.say,
          text: args.join(' ').replaceAll('"', ''),
          receiver: call.receiver,
        );
      case 'setBackground':
        return FourthDemoAction(
          type: FourthDemoActionType.setBackground,
          text: args.join(' ').replaceAll('"', ''),
        );
    }

    return null;
  }

  bool _isEvent(String line) {
    return line.startsWith('@onKey') ||
        line.startsWith('@onStart') ||
        line.startsWith('@onClick') ||
        line.startsWith('@onUpdate') ||
        line.startsWith('@onCollide') ||
        line.startsWith('@onDragEnd') ||
        line.startsWith('@onCollideWithWorldBounds') ||
        line.startsWith('@onSwipe') ||
        line.startsWith('@onAnimationEnd') ||
        line.startsWith('@onAnimationLoop');
  }

  String _eventName(String line) {
    final match = RegExp(r'^@(\w+)').firstMatch(line);
    return match?.group(1) ?? 'onStart';
  }

  _LineBlock _collectBlock(
    List<String> lines,
    int startIndex,
    int parentIndent,
  ) {
    final block = <String>[];
    var endIndex = startIndex - 1;

    for (var index = startIndex; index < lines.length; index += 1) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        block.add(line);
        endIndex = index;
        continue;
      }
      if (_indentOf(line) <= parentIndent) {
        break;
      }
      block.add(line);
      endIndex = index;
    }

    return _LineBlock(
      lines: block,
      startLine: startIndex + 1,
      endIndex: endIndex,
    );
  }

  int _indentOf(String line) {
    return RegExp(r'^\s*').firstMatch(line)?.group(0)?.length ?? 0;
  }

  _ParsedCall _splitReceiver(String line) {
    var receiver = '@';
    var rest = line.trim();
    if (rest.startsWith('@')) {
      rest = rest.substring(1);
    } else {
      final match = RegExp(r'^([A-Za-z_][\w -]*)\.').firstMatch(rest);
      if (match != null) {
        receiver = match.group(1)!.trim();
        rest = rest.substring(match.end);
      }
    }
    rest = rest.replaceFirst(RegExp(r'\(\s*\)'), '');
    final parts = rest
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return _ParsedCall(
      receiver: receiver,
      command: parts.isEmpty ? '' : parts.first,
      args: parts.length <= 1 ? const <String>[] : parts.skip(1).toList(),
    );
  }
}

class _ParsedCall {
  final String receiver;
  final String command;
  final List<String> args;

  const _ParsedCall({
    required this.receiver,
    required this.command,
    required this.args,
  });
}

class _LineBlock {
  final List<String> lines;
  final int startLine;
  final int endIndex;

  const _LineBlock({
    required this.lines,
    required this.startLine,
    required this.endIndex,
  });
}

class _ActionParseResult {
  final List<FourthDemoAction> actions;
  final GameDiagnostic? diagnostic;

  const _ActionParseResult._({required this.actions, this.diagnostic});

  factory _ActionParseResult.success(List<FourthDemoAction> actions) {
    return _ActionParseResult._(actions: actions);
  }

  factory _ActionParseResult.failure(String message, int line) {
    return _ActionParseResult._(
      actions: const <FourthDemoAction>[],
      diagnostic: GameDiagnostic(message: message, line: line),
    );
  }
}
