import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fourth_demo_project.dart';

class FourthDemoController extends ChangeNotifier {
  static const String storageKey = 'fourth_demo_course_builder_project';

  FourthDemoProject project = FourthDemoProject.sample();
  FourthDemoStageTool stageTool = FourthDemoStageTool.select;
  FourthDemoAssetTab assetTab = FourthDemoAssetTab.sprites;
  FourthDemoPaletteTab paletteTab = FourthDemoPaletteTab.movement;
  bool isPlaying = false;
  bool showPreviousSolution = false;
  bool exerciseComplete = false;
  String statusMessage = 'Press RUN, then use the right arrow key.';
  String? codeError;
  String? draggingSpriteId;

  FourthDemoSprite? get selectedSprite => project.selectedSprite;

  String get selectedCode {
    return project.codeBySpriteId[project.selectedSpriteId] ??
        FourthDemoProject.starterCode;
  }

  void setTitle(String title) {
    project = project.copyWith(
      title: title.trim().isEmpty ? 'Mini Course Exercise 1' : title.trim(),
    );
    notifyListeners();
  }

  void selectSprite(String id) {
    if (!project.sprites.any((sprite) => sprite.id == id)) {
      return;
    }
    project = project.copyWith(selectedSpriteId: id);
    notifyListeners();
  }

  void updateSelectedCode(String code) {
    final nextCode = Map<String, String>.from(project.codeBySpriteId);
    nextCode[project.selectedSpriteId] = code;
    project = project.copyWith(codeBySpriteId: nextCode);
    notifyListeners();
  }

  void insertSnippet(String snippet) {
    final current = selectedCode;
    final needsLineBreak = current.trim().isNotEmpty && !current.endsWith('\n');
    updateSelectedCode('$current${needsLineBreak ? '\n    ' : ''}$snippet');
  }

  void setStageTool(FourthDemoStageTool tool) {
    stageTool = tool;
    notifyListeners();
  }

  void setPaletteTab(FourthDemoPaletteTab tab) {
    paletteTab = tab;
    notifyListeners();
  }

  void setAssetTab(FourthDemoAssetTab tab) {
    assetTab = tab;
    notifyListeners();
  }

  void togglePreviousSolution() {
    showPreviousSolution = !showPreviousSolution;
    if (showPreviousSolution) {
      updateSelectedCode('@onKey = (key) =>\n    @step 1');
    } else {
      updateSelectedCode(FourthDemoProject.starterCode);
    }
    statusMessage = showPreviousSolution ? 'Previous solution shown' : 'Starter code restored';
  }

  bool runCode() {
    final sprite = selectedSprite;
    if (sprite == null) {
      codeError = 'No player sprite selected.';
      statusMessage = codeError!;
      notifyListeners();
      return false;
    }

    final parsed = FourthDemoCodeInterpreter.parse(
      code: selectedCode,
      targetSpriteId: sprite.id,
    );
    if (!parsed.isValid) {
      codeError = parsed.error;
      statusMessage = parsed.error ?? 'Check your code.';
      isPlaying = false;
      notifyListeners();
      return false;
    }

    project = project.copyWith(events: parsed.handlers);
    codeError = null;
    resetRuntime(keepMode: true);
    isPlaying = true;
    statusMessage = 'Running. Press an arrow key to move ${sprite.name}.';
    notifyListeners();
    _runHandlers('onStart');
    return true;
  }

  void stop() {
    isPlaying = false;
    resetRuntime();
    statusMessage = 'Stopped. Edit your code and run again.';
    notifyListeners();
  }

  void restartExercise() {
    project = FourthDemoProject.sample();
    isPlaying = false;
    showPreviousSolution = false;
    exerciseComplete = false;
    codeError = null;
    statusMessage = 'Exercise restarted';
    notifyListeners();
  }

  void resetRuntime({bool keepMode = false}) {
    final resetSprites = project.sprites
        .map(
          (sprite) => sprite.copyWith(
            x: sprite.startX,
            y: sprite.startY,
            visible: true,
          ),
        )
        .toList();
    final resetWidgets = project.widgets
        .map(
          (widget) => widget.type == FourthDemoWidgetKind.counter
              ? widget.copyWith(value: 0, visible: true)
              : widget.copyWith(visible: true),
        )
        .toList();
    project = project.copyWith(sprites: resetSprites, widgets: resetWidgets);
    exerciseComplete = false;
    if (!keepMode) {
      isPlaying = false;
    }
  }

  void handleKey(LogicalKeyboardKey key) {
    if (!isPlaying) {
      return;
    }
    if (key != LogicalKeyboardKey.arrowRight &&
        key != LogicalKeyboardKey.arrowLeft &&
        key != LogicalKeyboardKey.arrowUp &&
        key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.keyD &&
        key != LogicalKeyboardKey.keyA &&
        key != LogicalKeyboardKey.keyW &&
        key != LogicalKeyboardKey.keyS) {
      return;
    }
    _runHandlers('onKey', key: key);
  }

  void beginDrag(Offset worldPosition) {
    if (isPlaying || stageTool != FourthDemoStageTool.move && stageTool != FourthDemoStageTool.select) {
      return;
    }
    final hit = _spriteAt(worldPosition);
    draggingSpriteId = hit?.id;
    if (hit != null) {
      selectSprite(hit.id);
    }
  }

  void dragTo(Offset worldPosition) {
    final id = draggingSpriteId;
    if (id == null || isPlaying) {
      return;
    }
    final sprites = project.sprites.map((sprite) {
      if (sprite.id != id || !sprite.draggable) {
        return sprite;
      }
      final x = (worldPosition.dx - sprite.width / 2)
          .clamp(0, project.settings.worldWidth - sprite.width)
          .toDouble();
      final y = (worldPosition.dy - sprite.height / 2)
          .clamp(0, project.settings.worldHeight - sprite.height)
          .toDouble();
      return sprite.copyWith(x: x, y: y, startX: x, startY: y);
    }).toList();
    project = project.copyWith(sprites: sprites);
    notifyListeners();
  }

  void endDrag() {
    draggingSpriteId = null;
  }

  void updateSprite(FourthDemoSprite updated) {
    project = project.copyWith(
      sprites: project.sprites
          .map((sprite) => sprite.id == updated.id ? updated : sprite)
          .toList(),
    );
    notifyListeners();
  }

  void deleteSprite(String id) {
    if (id == 'monkey') {
      statusMessage = 'The exercise needs the monkey sprite.';
      notifyListeners();
      return;
    }
    final sprites = project.sprites.where((sprite) => sprite.id != id).toList();
    final code = Map<String, String>.from(project.codeBySpriteId)..remove(id);
    project = project.copyWith(
      sprites: sprites,
      codeBySpriteId: code,
      selectedSpriteId: sprites.isEmpty ? '' : sprites.first.id,
    );
    notifyListeners();
  }

  void addPlaceholderSprite() {
    final id = 'sprite-${DateTime.now().millisecondsSinceEpoch}';
    final sprite = FourthDemoSprite(
      id: id,
      name: 'newSprite',
      kind: FourthDemoSpriteKind.prop,
      x: 260,
      y: 270,
      startX: 260,
      startY: 270,
      width: 48,
      height: 48,
      colorValue: 0xFF4CC486,
    );
    project = project.copyWith(
      sprites: <FourthDemoSprite>[...project.sprites, sprite],
      selectedSpriteId: id,
      codeBySpriteId: <String, String>{...project.codeBySpriteId, id: ''},
    );
    statusMessage = 'New sprite added';
    notifyListeners();
  }

  void updateSettings(FourthDemoGameSettings settings) {
    project = project.copyWith(settings: settings);
    notifyListeners();
  }

  Future<void> saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, project.encode());
    statusMessage = 'Saved locally';
    notifyListeners();
  }

  Future<bool> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      statusMessage = 'No local project saved yet';
      notifyListeners();
      return false;
    }
    return importJson(raw);
  }

  bool importJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('The JSON root must be an object.');
      }
      final imported = FourthDemoProject.fromJson(Map<String, dynamic>.from(decoded));
      final validation = imported.validate();
      if (validation.isNotEmpty) {
        throw FormatException(validation.join(' '));
      }
      project = imported;
      isPlaying = false;
      exerciseComplete = false;
      codeError = null;
      statusMessage = 'Imported project';
      notifyListeners();
      return true;
    } catch (error) {
      statusMessage = 'Import failed. $error';
      notifyListeners();
      return false;
    }
  }

  String exportJson() {
    statusMessage = 'Export ready';
    notifyListeners();
    return project.encode();
  }

  void _runHandlers(String event, {LogicalKeyboardKey? key}) {
    final handlers = project.events.where((handler) => handler.event == event);
    for (final handler in handlers) {
      for (final action in handler.actions) {
        _runAction(handler.targetSpriteId, action, key);
      }
    }
    _handleCollections();
  }

  void _runAction(String spriteId, FourthDemoAction action, LogicalKeyboardKey? key) {
    final index = project.sprites.indexWhere((sprite) => sprite.id == spriteId);
    if (index == -1) {
      return;
    }
    final sprite = project.sprites[index];
    FourthDemoSprite next = sprite;
    switch (action.type) {
      case FourthDemoActionType.step:
        final amount = action.amount == 0 ? 1 : action.amount;
        final direction = _directionForKey(key);
        next = sprite.copyWith(
          x: (sprite.x + direction.dx * sprite.speed * amount)
              .clamp(0, project.settings.worldWidth - sprite.width)
              .toDouble(),
          y: (sprite.y + direction.dy * sprite.speed * amount)
              .clamp(0, project.settings.worldHeight - sprite.height)
              .toDouble(),
        );
      case FourthDemoActionType.jump:
        next = sprite.copyWith(y: math.max(0, sprite.y - 56));
      case FourthDemoActionType.setX:
        next = sprite.copyWith(x: action.amount.clamp(0, project.settings.worldWidth));
      case FourthDemoActionType.setY:
        next = sprite.copyWith(y: action.amount.clamp(0, project.settings.worldHeight));
      case FourthDemoActionType.setRotation:
        next = sprite.copyWith(rotation: action.amount);
      case FourthDemoActionType.setSpeed:
        next = sprite.copyWith(speed: action.amount);
      case FourthDemoActionType.show:
        next = sprite.copyWith(visible: true);
      case FourthDemoActionType.hide:
        next = sprite.copyWith(visible: false);
      case FourthDemoActionType.say:
        statusMessage = action.text.isEmpty ? 'Hello!' : action.text;
      case FourthDemoActionType.wait:
      case FourthDemoActionType.repeat:
      case FourthDemoActionType.ifTouching:
        statusMessage = 'That block is saved for the next lesson.';
    }
    final sprites = List<FourthDemoSprite>.from(project.sprites)..[index] = next;
    project = project.copyWith(sprites: sprites);
    notifyListeners();
  }

  Offset _directionForKey(LogicalKeyboardKey? key) {
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return const Offset(-1, 0);
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return const Offset(0, -1);
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return const Offset(0, 1);
    }
    return const Offset(1, 0);
  }

  void _handleCollections() {
    final player = project.sprites
        .where((sprite) => sprite.kind == FourthDemoSpriteKind.player && sprite.visible)
        .firstOrNull;
    if (player == null) {
      return;
    }
    for (final sprite in project.sprites) {
      if (sprite.kind != FourthDemoSpriteKind.collectible || !sprite.visible) {
        continue;
      }
      if (!_intersects(player, sprite)) {
        continue;
      }
      final sprites = project.sprites
          .map((item) => item.id == sprite.id ? item.copyWith(visible: false) : item)
          .toList();
      final widgets = project.widgets
          .map(
            (widget) => widget.type == FourthDemoWidgetKind.counter
                ? widget.copyWith(value: widget.value + 1)
                : widget,
          )
          .toList();
      project = project.copyWith(sprites: sprites, widgets: widgets);
      exerciseComplete = true;
      statusMessage = 'Great job! The banana was collected.';
      notifyListeners();
      return;
    }
  }

  FourthDemoSprite? _spriteAt(Offset worldPosition) {
    for (final sprite in project.sprites.reversed) {
      final rect = Rect.fromLTWH(sprite.x, sprite.y, sprite.width, sprite.height);
      if (rect.contains(worldPosition)) {
        return sprite;
      }
    }
    return null;
  }

  bool _intersects(FourthDemoSprite a, FourthDemoSprite b) {
    return Rect.fromLTWH(a.x, a.y, a.width, a.height)
        .overlaps(Rect.fromLTWH(b.x, b.y, b.width, b.height));
  }
}

class FourthDemoParseResult {
  final List<FourthDemoEventHandler> handlers;
  final String? error;

  const FourthDemoParseResult._({required this.handlers, this.error});

  bool get isValid => error == null;

  factory FourthDemoParseResult.success(List<FourthDemoEventHandler> handlers) {
    return FourthDemoParseResult._(handlers: handlers);
  }

  factory FourthDemoParseResult.failure(String error) {
    return FourthDemoParseResult._(handlers: const <FourthDemoEventHandler>[], error: error);
  }
}

class FourthDemoCodeInterpreter {
  static FourthDemoParseResult parse({
    required String code,
    required String targetSpriteId,
  }) {
    final lines = code.replaceAll('\r\n', '\n').split('\n');
    String? currentEvent;
    var sawOnKey = false;
    final actionsByEvent = <String, List<FourthDemoAction>>{};

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      if (trimmed.startsWith('@onKey')) {
        if (!trimmed.contains('=>')) {
          return FourthDemoParseResult.failure('Use this shape: @onKey = (key) =>');
        }
        currentEvent = 'onKey';
        sawOnKey = true;
        actionsByEvent.putIfAbsent(currentEvent, () => <FourthDemoAction>[]);
        continue;
      }
      if (trimmed.startsWith('@onClick')) {
        currentEvent = 'onClick';
        actionsByEvent.putIfAbsent(currentEvent, () => <FourthDemoAction>[]);
        continue;
      }
      if (trimmed.startsWith('@onStart')) {
        currentEvent = 'onStart';
        actionsByEvent.putIfAbsent(currentEvent, () => <FourthDemoAction>[]);
        continue;
      }
      if (trimmed.startsWith('@onUpdate')) {
        currentEvent = 'onUpdate';
        actionsByEvent.putIfAbsent(currentEvent, () => <FourthDemoAction>[]);
        continue;
      }
      if (currentEvent == null) {
        return FourthDemoParseResult.failure('I could not find @onKey. Try using the Events tab.');
      }
      if (!rawLine.startsWith(' ') && !rawLine.startsWith('\t')) {
        return FourthDemoParseResult.failure('Your code should be indented inside @onKey.');
      }
      FourthDemoAction? action;
      try {
        action = _parseAction(trimmed);
      } on FormatException catch (error) {
        return FourthDemoParseResult.failure(error.message);
      }
      if (action == null) {
        return FourthDemoParseResult.failure('I do not know "$trimmed" yet. Try @step 1.');
      }
      actionsByEvent[currentEvent]!.add(action);
    }

    if (!sawOnKey) {
      return FourthDemoParseResult.failure('I could not find @onKey. Try using the Events tab.');
    }
    final onKeyActions = actionsByEvent['onKey'] ?? const <FourthDemoAction>[];
    if (onKeyActions.isEmpty) {
      return FourthDemoParseResult.failure('Add @step 1 inside @onKey.');
    }
    return FourthDemoParseResult.success(
      actionsByEvent.entries
          .map(
            (entry) => FourthDemoEventHandler(
              event: entry.key,
              targetSpriteId: targetSpriteId,
              actions: entry.value,
            ),
          )
          .toList(),
    );
  }

  static FourthDemoAction? _parseAction(String line) {
    final parts = line.split(RegExp(r'\s+'));
    final command = parts.first;
    double number([double fallback = 0]) {
      if (parts.length < 2) {
        return fallback;
      }
      return double.tryParse(parts[1]) ?? double.nan;
    }

    switch (command) {
      case '@step':
        final amount = number(double.nan);
        if (amount.isNaN) {
          throwParserStep();
        }
        return FourthDemoAction(type: FourthDemoActionType.step, amount: amount);
      case '@jump()':
      case '@jump':
        return const FourthDemoAction(type: FourthDemoActionType.jump);
      case '@setX':
        return FourthDemoAction(type: FourthDemoActionType.setX, amount: number());
      case '@setY':
        return FourthDemoAction(type: FourthDemoActionType.setY, amount: number());
      case '@setRotation':
        return FourthDemoAction(type: FourthDemoActionType.setRotation, amount: number());
      case '@setSpeed':
        return FourthDemoAction(type: FourthDemoActionType.setSpeed, amount: number(100));
      case '@show()':
      case '@show':
        return const FourthDemoAction(type: FourthDemoActionType.show);
      case '@hide()':
      case '@hide':
        return const FourthDemoAction(type: FourthDemoActionType.hide);
      case '@say':
        return FourthDemoAction(
          type: FourthDemoActionType.say,
          text: line.replaceFirst('@say', '').trim().replaceAll('"', ''),
        );
      case 'wait':
        return FourthDemoAction(type: FourthDemoActionType.wait, amount: number(1));
      case 'repeat':
        return FourthDemoAction(type: FourthDemoActionType.repeat, amount: number(1));
      case 'if':
        return FourthDemoAction(type: FourthDemoActionType.ifTouching, target: parts.skip(1).join(' '));
    }
    return null;
  }

  static Never throwParserStep() {
    throw const FormatException('I found @step, but it needs a number. Example: @step 1');
  }
}
