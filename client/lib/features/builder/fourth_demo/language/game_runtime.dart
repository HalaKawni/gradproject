import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/fourth_demo_project.dart';

class GameRuntimeContext {
  final FourthDemoProject project;
  final String currentSpriteId;
  final LogicalKeyboardKey? key;

  const GameRuntimeContext({
    required this.project,
    required this.currentSpriteId,
    this.key,
  });
}

class GameRuntime {
  const GameRuntime();

  bool evaluateCondition(String condition, GameRuntimeContext context) {
    final normalized = condition.trim();
    if (normalized.isEmpty) {
      return false;
    }

    final orParts = normalized.split(RegExp(r'\s+or\s+'));
    if (orParts.length > 1) {
      return orParts.any((part) => evaluateCondition(part, context));
    }

    final andParts = normalized.split(RegExp(r'\s+and\s+'));
    if (andParts.length > 1) {
      return andParts.every((part) => evaluateCondition(part, context));
    }

    if (normalized.startsWith('not ')) {
      return !evaluateCondition(normalized.substring(4), context);
    }

    for (final operator in const ['!=', '==', '<', '>']) {
      final pieces = normalized.split(operator);
      if (pieces.length == 2) {
        final left = resolveValue(pieces[0].trim(), context);
        final right = resolveValue(pieces[1].trim(), context);
        return switch (operator) {
          '!=' => !_valuesMatch(left, right),
          '==' => _valuesMatch(left, right),
          '<' => _asNumber(left) < _asNumber(right),
          '>' => _asNumber(left) > _asNumber(right),
          _ => false,
        };
      }
    }

    final value = resolveValue(normalized, context);
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  }

  Object resolveValue(String raw, GameRuntimeContext context) {
    final value = raw.trim().replaceAll('"', '');
    if (value == 'true' || value == 'yes') {
      return true;
    }
    if (value == 'false' || value == 'no') {
      return false;
    }
    if (value == 'keyboard.right') {
      return 'keyboard.right';
    }
    if (value == 'keyboard.left') {
      return 'keyboard.left';
    }
    if (value == 'keyboard.up') {
      return 'keyboard.up';
    }
    if (value == 'keyboard.down') {
      return 'keyboard.down';
    }
    if (value == 'key') {
      return _keyboardAlias(context.key) ?? '';
    }
    if (value == '@getX()') {
      return _currentSprite(context)?.x ?? 0;
    }
    if (value == '@getY()') {
      return _currentSprite(context)?.y ?? 0;
    }
    if (value == '@getRotation()') {
      return _currentSprite(context)?.rotation ?? 0;
    }
    if (value == '@getScale()') {
      return _currentSprite(context)?.scale ?? 1;
    }
    final distanceMatch = RegExp(
      r'^@getDistanceFrom\s+(\w+)$',
    ).firstMatch(value);
    if (distanceMatch != null) {
      final current = _currentSprite(context);
      final other = _spriteNamed(context.project, distanceMatch.group(1)!);
      if (current == null || other == null) {
        return double.infinity;
      }
      return math.sqrt(
        math.pow(current.x - other.x, 2) + math.pow(current.y - other.y, 2),
      );
    }
    return num.tryParse(value) ?? value;
  }

  bool _valuesMatch(Object left, Object right) {
    return _normalizeComparable(left) == _normalizeComparable(right);
  }

  Object _normalizeComparable(Object value) {
    if (value is num) {
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

  double _asNumber(Object value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  FourthDemoSprite? _currentSprite(GameRuntimeContext context) {
    return context.project.sprites
        .where((sprite) => sprite.id == context.currentSpriteId)
        .firstOrNull;
  }

  FourthDemoSprite? _spriteNamed(FourthDemoProject project, String name) {
    return project.sprites
        .where((sprite) => sprite.name == name || sprite.id == name)
        .firstOrNull;
  }
}
