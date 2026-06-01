import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/fourth_demo_project.dart';
import 'game_diagnostics.dart';

class GameRuntimeContext {
  final FourthDemoProject project;
  final String currentSpriteId;
  final LogicalKeyboardKey? key;
  final String? direction;
  final Set<String> directions;
  final Map<String, String> spriteVariables;
  final GameSourceSpan? sourceSpan;

  const GameRuntimeContext({
    required this.project,
    required this.currentSpriteId,
    this.key,
    this.direction,
    this.directions = const <String>{},
    this.spriteVariables = const <String, String>{},
    this.sourceSpan,
  });
}

class GameValueResult {
  final Object? value;
  final GameDiagnostic? diagnostic;

  const GameValueResult.value(this.value) : diagnostic = null;
  const GameValueResult.failure(this.diagnostic) : value = null;

  bool get success => diagnostic == null;
}

class GameBoolResult {
  final bool value;
  final GameDiagnostic? diagnostic;

  const GameBoolResult.value(this.value) : diagnostic = null;
  const GameBoolResult.failure(this.diagnostic) : value = false;

  bool get success => diagnostic == null;
}

class GameRuntime {
  const GameRuntime();

  bool evaluateCondition(String condition, GameRuntimeContext context) {
    return evaluateConditionSafe(condition, context).value;
  }

  GameBoolResult evaluateConditionSafe(
    String condition,
    GameRuntimeContext context,
  ) {
    final normalized = _stripOuterParens(condition.trim());
    if (normalized.isEmpty) {
      return _conditionError('Condition is empty.', context);
    }

    final orParts = _splitLogical(normalized, 'or');
    if (orParts.length > 1) {
      for (final part in orParts) {
        final result = evaluateConditionSafe(part, context);
        if (!result.success) {
          return result;
        }
        if (result.value) {
          return const GameBoolResult.value(true);
        }
      }
      return const GameBoolResult.value(false);
    }

    final andParts = _splitLogical(normalized, 'and');
    if (andParts.length > 1) {
      for (final part in andParts) {
        final result = evaluateConditionSafe(part, context);
        if (!result.success) {
          return result;
        }
        if (!result.value) {
          return const GameBoolResult.value(false);
        }
      }
      return const GameBoolResult.value(true);
    }

    if (normalized.startsWith('not ')) {
      final result = evaluateConditionSafe(normalized.substring(4), context);
      if (!result.success) {
        return result;
      }
      return GameBoolResult.value(!result.value);
    }

    for (final operator in const ['<=', '>=', '!=', '==', '<', '>']) {
      final parts = _splitComparison(normalized, operator);
      if (parts == null) {
        continue;
      }
      final left = resolveValueSafe(parts.$1, context);
      if (!left.success) {
        return GameBoolResult.failure(left.diagnostic);
      }
      final right = resolveValueSafe(parts.$2, context);
      if (!right.success) {
        return GameBoolResult.failure(right.diagnostic);
      }
      final comparison = _compare(left.value, right.value, operator, context);
      if (comparison.diagnostic != null) {
        return GameBoolResult.failure(comparison.diagnostic);
      }
      return GameBoolResult.value(comparison.value);
    }

    final value = resolveValueSafe(normalized, context);
    if (!value.success) {
      return GameBoolResult.failure(value.diagnostic);
    }
    if (value.value is bool) {
      return GameBoolResult.value(value.value! as bool);
    }
    if (value.value is num) {
      return GameBoolResult.value((value.value! as num) != 0);
    }
    return _conditionError('Condition "$condition" is not true or false.', context);
  }

  Object resolveValue(String raw, GameRuntimeContext context) {
    return resolveValueSafe(raw, context).value ?? '';
  }

  GameValueResult resolveValueSafe(String raw, GameRuntimeContext context) {
    final value = raw.trim();
    if (value.isEmpty) {
      return _valueError('Missing value.', context);
    }
    if (_isQuoted(value)) {
      return GameValueResult.value(value.substring(1, value.length - 1));
    }
    if (value == 'true' || value == 'yes') {
      return const GameValueResult.value(true);
    }
    if (value == 'false' || value == 'no') {
      return const GameValueResult.value(false);
    }
    if (const <String>{
      'keyboard.right',
      'keyboard.left',
      'keyboard.up',
      'keyboard.down',
      'A',
      'D',
      'W',
      'S',
    }.contains(value)) {
      return GameValueResult.value(_keyboardTextAlias(value) ?? value);
    }
    if (value == 'key') {
      return GameValueResult.value(_keyboardAlias(context.key) ?? '');
    }
    if (value == 'direction') {
      return GameValueResult.value(context.direction ?? '');
    }
    final directionMatch = RegExp(
      r'^directions\.(left|right|up|down)$',
    ).firstMatch(value);
    if (directionMatch != null) {
      return GameValueResult.value(
        context.directions.contains(directionMatch.group(1)!),
      );
    }
    final getter = RegExp(
      r'^(@|[A-Za-z_]\w*)\.(getX|getY|getRotation|getScale)\(\)$',
    ).firstMatch(value);
    if (getter != null) {
      return _spriteGetter(getter.group(1)!, getter.group(2)!, context);
    }
    final currentGetter = RegExp(
      r'^@(getX|getY|getRotation|getScale)\(\)$',
    ).firstMatch(value);
    if (currentGetter != null) {
      return _spriteGetter('@', currentGetter.group(1)!, context);
    }
    final distanceMatch = RegExp(
      r'^@getDistanceFrom\s+([A-Za-z_]\w*)$',
    ).firstMatch(value);
    if (distanceMatch != null) {
      final current = _currentSprite(context);
      final other = _spriteNamed(context.project, distanceMatch.group(1)!);
      if (current == null) {
        return _valueError('Current sprite was not found.', context);
      }
      if (other == null) {
        return _valueError(
          'Sprite "${distanceMatch.group(1)!}" was not found.',
          context,
        );
      }
      return GameValueResult.value(
        math.sqrt(
          math.pow(current.x - other.x, 2) + math.pow(current.y - other.y, 2),
        ),
      );
    }
    if (context.spriteVariables.containsKey(value)) {
      return GameValueResult.value(context.spriteVariables[value]!);
    }
    return GameValueResult.value(num.tryParse(value) ?? value);
  }

  GameValueResult _spriteGetter(
    String receiver,
    String getter,
    GameRuntimeContext context,
  ) {
    final sprite = receiver == '@'
        ? _currentSprite(context)
        : _spriteNamed(
            context.project,
            context.spriteVariables[receiver] ?? receiver,
          );
    if (sprite == null) {
      return _valueError('Sprite "$receiver" was not found.', context);
    }
    return GameValueResult.value(
      switch (getter) {
        'getX' => sprite.x,
        'getY' => sprite.y,
        'getRotation' => sprite.rotation,
        'getScale' => sprite.scale,
        _ => 0,
      },
    );
  }

  ({bool value, GameDiagnostic? diagnostic}) _compare(
    Object? left,
    Object? right,
    String operator,
    GameRuntimeContext context,
  ) {
    if (operator == '==' || operator == '!=') {
      final matches = _normalizeComparable(left) == _normalizeComparable(right);
      return (value: operator == '==' ? matches : !matches, diagnostic: null);
    }

    final leftNumber = _asNumber(left);
    final rightNumber = _asNumber(right);
    if (leftNumber == null || rightNumber == null) {
      return (
        value: false,
        diagnostic: _runtimeDiagnostic(
          'Comparison "$operator" needs numbers.',
          context,
        ),
      );
    }
    return (
      value: switch (operator) {
        '<' => leftNumber < rightNumber,
        '>' => leftNumber > rightNumber,
        '<=' => leftNumber <= rightNumber,
        '>=' => leftNumber >= rightNumber,
        _ => false,
      },
      diagnostic: null,
    );
  }

  List<String> _splitLogical(String value, String operator) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    var inQuote = false;
    for (var i = 0; i < value.length; i += 1) {
      final char = value[i];
      if (char == '"') {
        inQuote = !inQuote;
      } else if (!inQuote && char == '(') {
        depth += 1;
      } else if (!inQuote && char == ')') {
        depth -= 1;
      }
      final token = ' $operator ';
      if (!inQuote &&
          depth == 0 &&
          value.substring(i).startsWith(token)) {
        parts.add(buffer.toString().trim());
        buffer.clear();
        i += token.length - 1;
        continue;
      }
      buffer.write(char);
    }
    parts.add(buffer.toString().trim());
    return parts;
  }

  (String, String)? _splitComparison(String value, String operator) {
    var depth = 0;
    var inQuote = false;
    for (var i = 0; i <= value.length - operator.length; i += 1) {
      final char = value[i];
      if (char == '"') {
        inQuote = !inQuote;
      } else if (!inQuote && char == '(') {
        depth += 1;
      } else if (!inQuote && char == ')') {
        depth -= 1;
      }
      if (!inQuote && depth == 0 && value.substring(i).startsWith(operator)) {
        return (
          value.substring(0, i).trim(),
          value.substring(i + operator.length).trim(),
        );
      }
    }
    return null;
  }

  String _stripOuterParens(String value) {
    var text = value;
    while (text.startsWith('(') && text.endsWith(')')) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  bool _isQuoted(String value) {
    return value.length >= 2 && value.startsWith('"') && value.endsWith('"');
  }

  Object _normalizeComparable(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is num || value is bool) {
      return value;
    }
    final text = value.toString().trim();
    return _keyboardTextAlias(text) ?? text.toLowerCase();
  }

  String? _keyboardAlias(LogicalKeyboardKey? key) {
    if (key == null) {
      return null;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return 'keyboard.right';
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return 'keyboard.left';
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return 'keyboard.up';
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return 'keyboard.down';
    }
    return key.keyLabel;
  }

  String? _keyboardTextAlias(String value) {
    switch (value.toLowerCase()) {
      case 'keyboard.right':
      case 'arrowright':
      case 'keyd':
      case 'd':
        return 'keyboard.right';
      case 'keyboard.left':
      case 'arrowleft':
      case 'keya':
      case 'a':
        return 'keyboard.left';
      case 'keyboard.up':
      case 'arrowup':
      case 'keyw':
      case 'w':
        return 'keyboard.up';
      case 'keyboard.down':
      case 'arrowdown':
      case 'keys':
      case 's':
        return 'keyboard.down';
    }
    return null;
  }

  double? _asNumber(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  FourthDemoSprite? _currentSprite(GameRuntimeContext context) {
    return context.project.sprites
        .where((sprite) => sprite.id == context.currentSpriteId)
        .firstOrNull;
  }

  FourthDemoSprite? _spriteNamed(FourthDemoProject project, String name) {
    final normalized = name.trim().toLowerCase();
    return project.sprites
        .where(
          (sprite) =>
              sprite.name.trim().toLowerCase() == normalized ||
              sprite.id.trim().toLowerCase() == normalized,
        )
        .firstOrNull;
  }

  GameBoolResult _conditionError(String message, GameRuntimeContext context) {
    return GameBoolResult.failure(_runtimeDiagnostic(message, context));
  }

  GameValueResult _valueError(String message, GameRuntimeContext context) {
    return GameValueResult.failure(_runtimeDiagnostic(message, context));
  }

  GameDiagnostic _runtimeDiagnostic(String message, GameRuntimeContext context) {
    final span = context.sourceSpan;
    if (span == null) {
      return GameDiagnostic(
        message: message,
        line: 1,
        column: 1,
        type: GameDiagnosticType.runtime,
      );
    }
    return GameDiagnostic.fromSpan(
      message: message,
      span: span,
      type: GameDiagnosticType.runtime,
    );
  }
}
