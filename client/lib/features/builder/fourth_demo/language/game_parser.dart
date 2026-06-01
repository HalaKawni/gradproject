import '../models/fourth_demo_project.dart';
import 'game_diagnostics.dart';
import 'game_language_spec.dart';

class GameParseResult {
  final List<FourthDemoEventHandler> handlers;
  final GameDiagnostic? diagnostic;

  const GameParseResult._({required this.handlers, this.diagnostic});

  bool get isValid => diagnostic == null;

  factory GameParseResult.success(List<FourthDemoEventHandler> handlers) {
    return GameParseResult._(handlers: handlers);
  }

  factory GameParseResult.failure(GameDiagnostic diagnostic) {
    return GameParseResult._(
      handlers: const <FourthDemoEventHandler>[],
      diagnostic: diagnostic,
    );
  }
}

class GameParser {
  const GameParser();

  static const Set<String> _eventNames = <String>{
    'onStart',
    'onKey',
    'onUpdate',
    'onClick',
    'onCollide',
    'onDragEnd',
    'onCollideWithWorldBounds',
    'onSwipe',
    'onAnimationEnd',
    'onAnimationLoop',
  };

  static const Set<String> _spriteCommands = <String>{
    'step',
    'jump',
    'setX',
    'setY',
    'setRotation',
    'setSpeed',
    'setAllowGravity',
    'show',
    'hide',
    'destroy',
    'disable',
    'enable',
    'setScale',
    'say',
    'addAnimation',
    'startAnimation',
    'stopAnimation',
  };

  GameParseResult parse({
    required String code,
    required String targetSpriteId,
    FourthDemoProject? project,
  }) {
    final lines = _logicalLines(code);
    final state = _ParseState(lines: lines, project: project);
    final handlers = <FourthDemoEventHandler>[];
    final functions = <String, List<FourthDemoAction>>{};
    final functionLines = <String, int>{};
    final calls = <_FunctionCallRef>[];

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      if (line.isIgnorable) {
        index += 1;
        continue;
      }
      if (line.indent != 0) {
        return GameParseResult.failure(
          state.error(
            line,
            'This line needs to be indented under an event or function.',
            type: GameDiagnosticType.syntax,
          ),
        );
      }

      final event = _parseEventHeader(line);
      if (event != null) {
        final block = _parseBlock(
          state,
          startIndex: index + 1,
          parentIndent: line.indent,
          calls: calls,
          loopVariables: const <String>{},
        );
        if (block.diagnostic != null) {
          return GameParseResult.failure(block.diagnostic!);
        }
        if (block.actions.isEmpty) {
          return GameParseResult.failure(
            state.error(line, 'This event needs code inside it.'),
          );
        }
        handlers.add(
          FourthDemoEventHandler(
            event: event.name,
            targetSpriteId: targetSpriteId,
            actions: block.actions,
            argument: event.argument,
          ),
        );
        index = block.nextIndex;
        continue;
      }

      final function = _parseFunctionHeader(line);
      if (function != null) {
        if (functions.containsKey(function)) {
          return GameParseResult.failure(
            state.error(
              line,
              'Function "$function" is already defined.',
              type: GameDiagnosticType.validation,
            ),
          );
        }
        final block = _parseBlock(
          state,
          startIndex: index + 1,
          parentIndent: line.indent,
          calls: calls,
          loopVariables: const <String>{},
        );
        if (block.diagnostic != null) {
          return GameParseResult.failure(block.diagnostic!);
        }
        if (block.actions.isEmpty) {
          return GameParseResult.failure(
            state.error(line, 'This function needs code inside it.'),
          );
        }
        functions[function] = block.actions;
        functionLines[function] = line.number;
        index = block.nextIndex;
        continue;
      }

      if (line.text.startsWith('@on')) {
        return GameParseResult.failure(_eventSyntaxError(state, line));
      }
      if (line.text.startsWith('@') || line.text.startsWith('game.')) {
        return GameParseResult.failure(
          state.error(line, 'This line needs to be indented.'),
        );
      }
      return GameParseResult.failure(
        state.error(
          line,
          'I expected an event like @onKey = (key) => or a function definition.',
        ),
      );
    }

    if (handlers.isEmpty && functions.isEmpty) {
      return GameParseResult.failure(
        GameDiagnostic(
          message: 'I could not find an event. Try using the Events tab.',
          line: 1,
          column: 1,
          sourceLine: lines.isEmpty ? '' : lines.first.raw,
        ),
      );
    }

    for (final call in calls) {
      if (!functions.containsKey(call.name)) {
        return GameParseResult.failure(
          state.error(
            call.line,
            'Function "${call.name}" is not defined.',
            type: GameDiagnosticType.validation,
          ),
        );
      }
    }

    final functionHandlers = functions.entries.map((entry) {
      return FourthDemoEventHandler(
        event: 'function:${entry.key}',
        targetSpriteId: targetSpriteId,
        actions: entry.value,
      );
    });

    return GameParseResult.success(<FourthDemoEventHandler>[
      ...handlers,
      ...functionHandlers,
    ]);
  }

  _BlockResult _parseBlock(
    _ParseState state, {
    required int startIndex,
    required int parentIndent,
    required List<_FunctionCallRef> calls,
    required Set<String> loopVariables,
  }) {
    final actions = <FourthDemoAction>[];
    int? blockIndent;
    var index = startIndex;

    while (index < state.lines.length) {
      final line = state.lines[index];
      if (line.isIgnorable) {
        index += 1;
        continue;
      }
      if (line.indent <= parentIndent) {
        break;
      }
      blockIndent ??= line.indent;
      if (line.indent != blockIndent) {
        return _BlockResult.failure(
          state.error(line, 'Invalid indentation. Keep sibling lines aligned.'),
        );
      }
      if (line.text == 'else') {
        return _BlockResult.failure(
          state.error(line, 'else must come directly after an if block.'),
        );
      }

      final parsed = _parseStatement(
        state,
        index,
        blockIndent,
        calls,
        loopVariables,
      );
      if (parsed.diagnostic != null) {
        return _BlockResult.failure(parsed.diagnostic!);
      }
      actions.add(parsed.action!);
      index = parsed.nextIndex;
    }

    return _BlockResult.success(actions: actions, nextIndex: index);
  }

  _StatementResult _parseStatement(
    _ParseState state,
    int index,
    int indent,
    List<_FunctionCallRef> calls,
    Set<String> loopVariables,
  ) {
    final line = state.lines[index];
    final text = line.text;

    if (text.startsWith('if ')) {
      final condition = text.substring(3).trim();
      if (!_looksLikeCondition(condition)) {
        return _StatementResult.failure(
          state.error(line, 'This if needs a valid condition.'),
        );
      }
      final body = _parseBlock(
        state,
        startIndex: index + 1,
        parentIndent: indent,
        calls: calls,
        loopVariables: loopVariables,
      );
      if (body.diagnostic != null) {
        return _StatementResult.failure(body.diagnostic!);
      }
      if (body.actions.isEmpty) {
        return _StatementResult.failure(
          state.error(line, 'This if needs indented code under it.'),
        );
      }
      var nextIndex = body.nextIndex;
      var elseActions = const <FourthDemoAction>[];
      if (nextIndex < state.lines.length) {
        final next = state.lines[nextIndex];
        if (!next.isIgnorable && next.indent == indent && next.text == 'else') {
          final elseBody = _parseBlock(
            state,
            startIndex: nextIndex + 1,
            parentIndent: indent,
            calls: calls,
            loopVariables: loopVariables,
          );
          if (elseBody.diagnostic != null) {
            return _StatementResult.failure(elseBody.diagnostic!);
          }
          if (elseBody.actions.isEmpty) {
            return _StatementResult.failure(
              state.error(next, 'This else needs indented code under it.'),
            );
          }
          elseActions = elseBody.actions;
          nextIndex = elseBody.nextIndex;
        }
      }
      return _StatementResult.success(
        FourthDemoAction(
          type: FourthDemoActionType.ifCondition,
          condition: condition,
          actions: body.actions,
          elseActions: elseActions,
          sourceSpan: line.span,
        ),
        nextIndex,
      );
    }

    final loopMatch = RegExp(r'^(\d+)\.times\s*=>\s*$').firstMatch(text);
    if (loopMatch != null) {
      final count = int.parse(loopMatch.group(1)!);
      if (count < 0 || count > 500) {
        return _StatementResult.failure(
          state.error(line, 'Repeat count must be between 0 and 500.'),
        );
      }
      return _parseNestedAction(
        state,
        index,
        indent,
        calls,
        loopVariables: loopVariables,
        type: FourthDemoActionType.repeatTimes,
        count: count,
        emptyMessage: 'This repeat block needs indented code under it.',
      );
    }

    if (text == 'loop') {
      return _parseNestedAction(
        state,
        index,
        indent,
        calls,
        loopVariables: loopVariables,
        type: FourthDemoActionType.repeatForever,
        emptyMessage: 'This loop needs indented code under it.',
      );
    }

    if (text.startsWith('until ')) {
      final condition = text.substring(6).trim();
      if (!_looksLikeCondition(condition)) {
        return _StatementResult.failure(
          state.error(line, 'until needs a valid condition.'),
        );
      }
      return _parseNestedAction(
        state,
        index,
        indent,
        calls,
        loopVariables: loopVariables,
        type: FourthDemoActionType.until,
        condition: condition,
        emptyMessage: 'This until block needs indented code under it.',
      );
    }

    final forMatch = RegExp(
      r'^for\s+([A-Za-z_]\w*)\s+in\s+sprites\s*$',
    ).firstMatch(text);
    if (forMatch != null) {
      final variableName = forMatch.group(1)!;
      final body = _parseBlock(
        state,
        startIndex: index + 1,
        parentIndent: indent,
        calls: calls,
        loopVariables: <String>{...loopVariables, variableName},
      );
      if (body.diagnostic != null) {
        return _StatementResult.failure(body.diagnostic!);
      }
      if (body.actions.isEmpty) {
        return _StatementResult.failure(
          state.error(line, 'This for block needs indented code under it.'),
        );
      }
      return _StatementResult.success(
        FourthDemoAction(
          type: FourthDemoActionType.forEachSprite,
          variableName: variableName,
          actions: body.actions,
          sourceSpan: line.span,
        ),
        body.nextIndex,
      );
    }

    if (text.startsWith('for ')) {
      return _StatementResult.failure(
        state.error(
          line,
          'Invalid for syntax.',
          hint: 'Example: for sprite in sprites',
        ),
      );
    }

    if (text.startsWith('return')) {
      return _StatementResult.success(
        FourthDemoAction(
          type: FourthDemoActionType.returnValue,
          text: text.length > 6 ? text.substring(6).trim() : '',
          sourceSpan: line.span,
        ),
        index + 1,
      );
    }

    final functionCall = RegExp(
      r'^([A-Za-z_]\w*)\s*\(\s*\)\s*$',
    ).firstMatch(text);
    if (functionCall != null) {
      final name = functionCall.group(1)!;
      calls.add(_FunctionCallRef(name: name, line: line));
      return _StatementResult.success(
        FourthDemoAction(
          type: FourthDemoActionType.functionCall,
          text: name,
          sourceSpan: line.span,
        ),
        index + 1,
      );
    }

    final action = _parseAction(state, line, loopVariables);
    if (action.diagnostic != null) {
      return _StatementResult.failure(action.diagnostic!);
    }
    return _StatementResult.success(action.action!, index + 1);
  }

  _StatementResult _parseNestedAction(
    _ParseState state,
    int index,
    int indent,
    List<_FunctionCallRef> calls, {
    required Set<String> loopVariables,
    required FourthDemoActionType type,
    String condition = '',
    int count = 0,
    String variableName = '',
    required String emptyMessage,
  }) {
    final line = state.lines[index];
    final body = _parseBlock(
      state,
      startIndex: index + 1,
      parentIndent: indent,
      calls: calls,
      loopVariables: loopVariables,
    );
    if (body.diagnostic != null) {
      return _StatementResult.failure(body.diagnostic!);
    }
    if (body.actions.isEmpty) {
      return _StatementResult.failure(state.error(line, emptyMessage));
    }
    return _StatementResult.success(
      FourthDemoAction(
        type: type,
        condition: condition,
        count: count,
        variableName: variableName,
        actions: body.actions,
        sourceSpan: line.span,
      ),
      body.nextIndex,
    );
  }

  _ActionResult _parseAction(
    _ParseState state,
    _CodeLine line,
    Set<String> loopVariables,
  ) {
    final call = _splitReceiver(line.text);
    if (call.command.isEmpty) {
      return _ActionResult.failure(state.error(line, 'Unknown command.'));
    }
    if (call.receiver == 'game') {
      if (call.command != 'setBackground') {
        return _ActionResult.failure(
          state.error(line, 'Unknown game command "${call.command}".'),
        );
      }
      final background = _singleStringArg(call.args);
      if (background == null) {
        return _ActionResult.failure(
          state.error(
            line,
            'game.setBackground needs a background name.',
            hint: 'Example: game.setBackground "forest"',
          ),
        );
      }
      return _ActionResult.success(
        FourthDemoAction(
          type: FourthDemoActionType.setBackground,
          text: background,
          receiver: 'game',
          sourceSpan: line.span,
        ),
      );
    }

    if (!_spriteCommands.contains(call.command)) {
      return _ActionResult.failure(
        state.error(
          line,
          'Unknown command "${call.rawCommand}".',
          hint: _hintForCommand(call.command),
          type: GameDiagnosticType.validation,
        ),
      );
    }

    if (!_validReceiver(state, call.receiver, loopVariables)) {
      return _ActionResult.failure(
        state.error(
          line,
          'Unknown receiver "${call.receiver}".',
          type: GameDiagnosticType.validation,
        ),
      );
    }

    double? numberArg(String command, {required bool required}) {
      if (call.args.isEmpty) {
        return required ? null : 0;
      }
      return double.tryParse(call.args.first);
    }

    FourthDemoAction action(
      FourthDemoActionType type, {
      double amount = 0,
      String text = '',
      String target = '',
    }) {
      return FourthDemoAction(
        type: type,
        amount: amount,
        text: text,
        target: target,
        receiver: call.receiver,
        sourceSpan: line.span,
      );
    }

    switch (call.command) {
      case 'step':
      case 'setX':
      case 'setY':
      case 'setRotation':
      case 'setSpeed':
      case 'setScale':
        final amount = numberArg(call.command, required: true);
        if (amount == null) {
          return _ActionResult.failure(
            state.error(
              line,
              'Expected a number after ${call.rawCommand}.',
              hint: 'Example: ${call.rawCommand} 100',
            ),
          );
        }
        final type = switch (call.command) {
          'step' => FourthDemoActionType.step,
          'setX' => FourthDemoActionType.setX,
          'setY' => FourthDemoActionType.setY,
          'setRotation' => FourthDemoActionType.setRotation,
          'setSpeed' => FourthDemoActionType.setSpeed,
          _ => FourthDemoActionType.setScale,
        };
        return _ActionResult.success(action(type, amount: amount));
      case 'jump':
        return _ActionResult.success(action(FourthDemoActionType.jump));
      case 'setAllowGravity':
        final raw = call.args.join(' ').trim();
        if (!const <String>{'true', 'false', 'yes', 'no'}.contains(raw)) {
          return _ActionResult.failure(
            state.error(
              line,
              'Expected true or false after ${call.rawCommand}.',
              hint: 'Example: ${call.rawCommand} true',
            ),
          );
        }
        return _ActionResult.success(
          action(FourthDemoActionType.setAllowGravity, text: raw),
        );
      case 'show':
        return _ActionResult.success(action(FourthDemoActionType.show));
      case 'hide':
        return _ActionResult.success(action(FourthDemoActionType.hide));
      case 'destroy':
        return _ActionResult.success(action(FourthDemoActionType.destroy));
      case 'disable':
        return _ActionResult.success(action(FourthDemoActionType.disable));
      case 'enable':
        return _ActionResult.success(action(FourthDemoActionType.enable));
      case 'say':
        return _ActionResult.success(
          action(FourthDemoActionType.say, text: _unquote(call.args.join(' '))),
        );
      case 'addAnimation':
        final parsed = _parseAnimationArgs(call.args.join(' '));
        if (parsed == null) {
          return _ActionResult.failure(
            state.error(
              line,
              'Invalid animation syntax.',
              hint: 'Example: @addAnimation "run", [0, 1, 2, 3], 8, true',
            ),
          );
        }
        return _ActionResult.success(
          action(
            FourthDemoActionType.addAnimation,
            text: parsed.name,
            target: parsed.frames.join(','),
            amount: parsed.fps,
          ).copyWithAnimationLoop(parsed.loop),
        );
      case 'startAnimation':
        final name = _singleStringArg(call.args);
        if (name == null) {
          return _ActionResult.failure(
            state.error(line, '@startAnimation needs an animation name.'),
          );
        }
        return _ActionResult.success(
          action(FourthDemoActionType.startAnimation, text: name),
        );
      case 'stopAnimation':
        return _ActionResult.success(
          action(FourthDemoActionType.stopAnimation),
        );
    }

    return _ActionResult.failure(state.error(line, 'Unknown command.'));
  }

  _ParsedEvent? _parseEventHeader(_CodeLine line) {
    final text = line.text;
    final name = RegExp(r'^@(\w+)').firstMatch(text)?.group(1);
    if (name == null || !_eventNames.contains(name)) {
      return null;
    }
    var argument = '';
    final collideMatch = RegExp(
      r'^@onCollide\s+("[^"]+"|[A-Za-z_][\w -]*)\s*,\s*\(\s*\)\s*=>\s*$',
    ).firstMatch(text);
    final animationMatch = RegExp(
      '^@$name\\s+"([^"]+)"\\s*,\\s*\\(\\s*\\)\\s*=>\\s*\$',
    ).firstMatch(text);
    if (collideMatch != null) {
      argument = _unquote(collideMatch.group(1)!);
    }
    if (animationMatch != null) {
      argument = animationMatch.group(1)!;
    }
    final valid = switch (name) {
      'onStart' || 'onUpdate' || 'onClick' || 'onDragEnd' => RegExp(
        '^@$name\\s*=\\s*\\(\\s*\\)\\s*=>\\s*\$',
      ).hasMatch(text),
      'onKey' => RegExp(r'^@onKey\s*=\s*\(\s*key\s*\)\s*=>\s*$').hasMatch(text),
      'onCollideWithWorldBounds' => RegExp(
        r'^@onCollideWithWorldBounds\s*=\s*\(\s*directions\s*\)\s*=>\s*$',
      ).hasMatch(text),
      'onSwipe' => RegExp(
        r'^@onSwipe\s*=\s*\(\s*direction\s*\)\s*=>\s*$',
      ).hasMatch(text),
      'onCollide' => collideMatch != null,
      'onAnimationEnd' || 'onAnimationLoop' => animationMatch != null,
      _ => false,
    };
    return valid ? _ParsedEvent(name, argument) : null;
  }

  GameDiagnostic _eventSyntaxError(_ParseState state, _CodeLine line) {
    if (!line.text.contains('=>')) {
      return state.error(line, 'This event needs =>.');
    }
    return state.error(line, 'Invalid event syntax.');
  }

  String? _parseFunctionHeader(_CodeLine line) {
    final match = RegExp(
      r'^([A-Za-z_]\w*)\s*=\s*\(\s*\)\s*=>\s*$',
    ).firstMatch(line.text);
    return match?.group(1);
  }

  bool _looksLikeCondition(String condition) {
    if (condition.trim().isEmpty) {
      return false;
    }
    return !condition.contains('=>');
  }

  bool _validReceiver(
    _ParseState state,
    String receiver,
    Set<String> loopVariables,
  ) {
    if (receiver == '@' || loopVariables.contains(receiver)) {
      return true;
    }
    final project = state.project;
    if (project == null) {
      return RegExp(r'^[A-Za-z_]\w*$').hasMatch(receiver);
    }
    final normalized = receiver.toLowerCase();
    return project.sprites.any(
      (sprite) =>
          sprite.id.toLowerCase() == normalized ||
          sprite.name.toLowerCase() == normalized,
    );
  }

  _ParsedCall _splitReceiver(String line) {
    var receiver = '@';
    var rest = line.trim();
    if (rest.startsWith('@')) {
      rest = rest.substring(1);
    } else {
      final match = RegExp(r'^([A-Za-z_]\w*)\.').firstMatch(rest);
      if (match != null) {
        receiver = match.group(1)!;
        rest = rest.substring(match.end);
      }
    }
    rest = rest.replaceFirst(RegExp(r'\(\s*\)'), '');
    final command = RegExp(r'^([A-Za-z_]\w*)').firstMatch(rest)?.group(1) ?? '';
    final args = command.isEmpty ? '' : rest.substring(command.length).trim();
    return _ParsedCall(
      receiver: receiver,
      command: command,
      rawCommand: receiver == '@' ? '@$command' : '$receiver.$command',
      args: _splitArgs(args),
    );
  }

  List<String> _splitArgs(String args) {
    if (args.trim().isEmpty) {
      return const <String>[];
    }
    final parts = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    var bracketDepth = 0;
    for (var i = 0; i < args.length; i += 1) {
      final char = args[i];
      if (char == '"') {
        inQuote = !inQuote;
      }
      if (!inQuote && char == '[') {
        bracketDepth += 1;
      }
      if (!inQuote && char == ']') {
        bracketDepth -= 1;
      }
      if (!inQuote && bracketDepth == 0 && RegExp(r'\s').hasMatch(char)) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        continue;
      }
      buffer.write(char);
    }
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }
    return parts;
  }

  _AnimationArgs? _parseAnimationArgs(String raw) {
    final match = RegExp(
      r'^"([^"]+)"\s*,\s*\[([0-9,\s]+)\]\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*(true|false|yes|no)\s*$',
    ).firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    final frames = match
        .group(2)!
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .toList();
    if (frames.any((frame) => frame == null)) {
      return null;
    }
    return _AnimationArgs(
      name: match.group(1)!,
      frames: frames.cast<int>(),
      fps: double.parse(match.group(3)!),
      loop: const <String>{'true', 'yes'}.contains(match.group(4)!),
    );
  }

  String? _singleStringArg(List<String> args) {
    if (args.isEmpty) {
      return null;
    }
    final raw = args.join(' ').trim();
    if (raw.isEmpty) {
      return null;
    }
    return _unquote(raw);
  }

  String _unquote(String raw) {
    final value = raw.trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  String? _hintForCommand(String command) {
    final candidates = GameLanguageSpec.commands.map((item) => item.label);
    for (final candidate in candidates) {
      if (candidate.toLowerCase().startsWith(command.toLowerCase()) ||
          command.toLowerCase().startsWith(candidate.substring(0, 1))) {
        return 'Did you mean "$candidate"?';
      }
    }
    return null;
  }

  List<_CodeLine> _logicalLines(String code) {
    final raw = code.replaceAll('\r\n', '\n').split('\n');
    return <_CodeLine>[
      for (var index = 0; index < raw.length; index += 1)
        _CodeLine(number: index + 1, raw: raw[index]),
    ];
  }
}

extension on FourthDemoAction {
  FourthDemoAction copyWithAnimationLoop(bool loop) {
    return FourthDemoAction(
      type: type,
      amount: amount,
      text: text,
      target: target,
      receiver: receiver,
      condition: loop ? 'true' : 'false',
      actions: actions,
      elseActions: elseActions,
      count: count,
      variableName: variableName,
      sourceSpan: sourceSpan,
    );
  }
}

class _ParseState {
  final List<_CodeLine> lines;
  final FourthDemoProject? project;

  const _ParseState({required this.lines, required this.project});

  GameDiagnostic error(
    _CodeLine line,
    String message, {
    GameDiagnosticType type = GameDiagnosticType.syntax,
    String? hint,
  }) {
    return GameDiagnostic(
      message: message,
      line: line.number,
      column: line.column,
      type: type,
      hint: hint,
      sourceLine: line.raw,
    );
  }
}

class _CodeLine {
  final int number;
  final String raw;

  const _CodeLine({required this.number, required this.raw});

  String get text => raw.trim();
  int get indent => RegExp(r'^[ \t]*').firstMatch(raw)!.group(0)!.length;
  int get column => indent + 1;
  bool get isIgnorable => text.isEmpty || text.startsWith('#');
  GameSourceSpan get span =>
      GameSourceSpan(line: number, column: column, sourceLine: raw);
}

class _ParsedEvent {
  final String name;
  final String argument;

  const _ParsedEvent(this.name, [this.argument = '']);
}

class _ParsedCall {
  final String receiver;
  final String command;
  final String rawCommand;
  final List<String> args;

  const _ParsedCall({
    required this.receiver,
    required this.command,
    required this.rawCommand,
    required this.args,
  });
}

class _AnimationArgs {
  final String name;
  final List<int> frames;
  final double fps;
  final bool loop;

  const _AnimationArgs({
    required this.name,
    required this.frames,
    required this.fps,
    required this.loop,
  });
}

class _FunctionCallRef {
  final String name;
  final _CodeLine line;

  const _FunctionCallRef({required this.name, required this.line});
}

class _BlockResult {
  final List<FourthDemoAction> actions;
  final int nextIndex;
  final GameDiagnostic? diagnostic;

  const _BlockResult._({
    required this.actions,
    required this.nextIndex,
    this.diagnostic,
  });

  factory _BlockResult.success({
    required List<FourthDemoAction> actions,
    required int nextIndex,
  }) {
    return _BlockResult._(actions: actions, nextIndex: nextIndex);
  }

  factory _BlockResult.failure(GameDiagnostic diagnostic) {
    return _BlockResult._(
      actions: const <FourthDemoAction>[],
      nextIndex: 0,
      diagnostic: diagnostic,
    );
  }
}

class _StatementResult {
  final FourthDemoAction? action;
  final int nextIndex;
  final GameDiagnostic? diagnostic;

  const _StatementResult._({
    this.action,
    required this.nextIndex,
    this.diagnostic,
  });

  factory _StatementResult.success(FourthDemoAction action, int nextIndex) {
    return _StatementResult._(action: action, nextIndex: nextIndex);
  }

  factory _StatementResult.failure(GameDiagnostic diagnostic) {
    return _StatementResult._(nextIndex: 0, diagnostic: diagnostic);
  }
}

class _ActionResult {
  final FourthDemoAction? action;
  final GameDiagnostic? diagnostic;

  const _ActionResult._({this.action, this.diagnostic});

  factory _ActionResult.success(FourthDemoAction action) {
    return _ActionResult._(action: action);
  }

  factory _ActionResult.failure(GameDiagnostic diagnostic) {
    return _ActionResult._(diagnostic: diagnostic);
  }
}
