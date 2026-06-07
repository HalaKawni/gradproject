import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/game_parser.dart';
import '../language/game_runtime.dart';
import '../language/game_diagnostics.dart';
import '../models/fourth_demo_project.dart';

class FourthDemoController extends ChangeNotifier {
  static const String storageKey = 'fourth_demo_course_builder_project';
  static const double stepSize = 48;
  static const double movementAnimationSeconds = 0.12;
  static const double _jumpVelocity = 430;
  static const double _defaultGravity = 980;
  static const double _groundControlSpeed = 260;
  static const double _speechDurationSeconds = 2.5;
  static const int maxInstructionsPerEvent = 1000;
  static const int maxLoopIterations = 500;
  static const Set<String> supportedBackgrounds = <String>{
    'forest',
    'sky',
    'desert',
    'green',
  };

  FourthDemoProject project = FourthDemoProject.sample();
  FourthDemoStageTool stageTool = FourthDemoStageTool.select;
  FourthDemoAssetTab assetTab = FourthDemoAssetTab.sprites;
  FourthDemoPaletteTab paletteTab = FourthDemoPaletteTab.movement;
  bool isPlaying = false;
  bool showPreviousSolution = false;
  bool exerciseComplete = false;
  String statusMessage = 'Press RUN, then use the right arrow key.';
  String? codeError;
  List<GameDiagnostic> diagnostics = const <GameDiagnostic>[];
  String? draggingSpriteId;
  String? draggingWidgetId;
  final GameParser _parser = const GameParser();
  final GameRuntime _runtime = const GameRuntime();
  final Map<String, _SpriteMotion> _motions = <String, _SpriteMotion>{};
  final Map<String, _PhysicsBody> _physicsBodies = <String, _PhysicsBody>{};
  Map<String, AudioPlayer>? _soundPlayers;
  Map<String, _SpriteSpeech>? _speechBubbles;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  String? _continuousHorizontalSpriteId;
  double _continuousHorizontalVelocity = 0;
  final Map<String, String> _loopSpriteVariables = <String, String>{};
  FourthDemoProject? _preRunProject;
  int _instructionCount = 0;

  FourthDemoSprite? get selectedSprite => project.selectedSprite;

  Map<String, AudioPlayer> get _activeSoundPlayers {
    return _soundPlayers ??= <String, AudioPlayer>{};
  }

  @override
  void dispose() {
    _stopAllSounds();
    for (final player in _activeSoundPlayers.values) {
      unawaited(player.dispose());
    }
    _activeSoundPlayers.clear();
    super.dispose();
  }

  bool isSpriteWalking(FourthDemoSprite sprite) {
    if (_isAirborne(sprite)) {
      return false;
    }
    if (_continuousHorizontalSpriteId == sprite.id && _hasHorizontalInput) {
      return true;
    }
    final motion = _motions[sprite.id];
    return motion != null && (motion.to.dx - motion.from.dx).abs() > 0.5;
  }

  Offset visualPositionFor(FourthDemoSprite sprite) {
    final motion = _motions[sprite.id];
    if (motion == null) {
      return Offset(sprite.x, sprite.y);
    }
    return motion.position;
  }

  String? speechTextFor(String spriteId) {
    return _activeSpeechBubbles[spriteId]?.text;
  }

  Map<String, _SpriteSpeech> get _activeSpeechBubbles {
    return _speechBubbles ??= <String, _SpriteSpeech>{};
  }

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

  void updateSelectedCode(String code, {bool notify = true}) {
    updateCodeForSprite(project.selectedSpriteId, code, notify: notify);
  }

  void updateCodeForSprite(String spriteId, String code, {bool notify = true}) {
    if (isPlaying) {
      return;
    }
    if (!project.sprites.any((sprite) => sprite.id == spriteId)) {
      return;
    }
    final nextCode = Map<String, String>.from(project.codeBySpriteId);
    nextCode[spriteId] = code;
    project = project.copyWith(codeBySpriteId: nextCode);
    if (codeError != null || diagnostics.isNotEmpty) {
      codeError = null;
      diagnostics = const <GameDiagnostic>[];
    }
    if (notify) {
      notifyListeners();
    }
  }

  void insertSnippet(String snippet) {
    if (isPlaying) {
      return;
    }
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

  void dismissDiagnostics() {
    if (diagnostics.isEmpty && codeError == null) {
      return;
    }
    diagnostics = const <GameDiagnostic>[];
    codeError = null;
    notifyListeners();
  }

  void setAssetTab(FourthDemoAssetTab tab) {
    assetTab = tab;
    notifyListeners();
  }

  void togglePreviousSolution() {
    if (isPlaying) {
      return;
    }
    showPreviousSolution = !showPreviousSolution;
    if (showPreviousSolution) {
      updateSelectedCode('@onKey = (key) =>\n    @step 1');
    } else {
      updateSelectedCode(FourthDemoProject.starterCode);
    }
    statusMessage = showPreviousSolution
        ? 'Previous solution shown'
        : 'Starter code restored';
  }

  bool runCode() {
    if (isPlaying) {
      return false;
    }

    final sprite = selectedSprite;
    if (sprite == null) {
      codeError = 'No player sprite selected.';
      statusMessage = codeError!;
      notifyListeners();
      return false;
    }

    final parsedHandlers = <FourthDemoEventHandler>[];
    for (final codeEntry in project.codeBySpriteId.entries) {
      if (codeEntry.value.trim().isEmpty) {
        continue;
      }
      final parsed = _parser.parse(
        code: codeEntry.value,
        targetSpriteId: codeEntry.key,
        project: project,
      );
      if (!parsed.isValid) {
        final diagnostic = parsed.diagnostic;
        diagnostics = diagnostic == null
            ? const <GameDiagnostic>[]
            : <GameDiagnostic>[diagnostic];
        codeError = diagnostic?.displayMessage;
        statusMessage = codeError ?? 'Check your code.';
        isPlaying = false;
        notifyListeners();
        return false;
      }
      parsedHandlers.addAll(parsed.handlers);
    }

    _preRunProject = project;
    _clearRuntimeState();
    project = project.copyWith(events: parsedHandlers);
    codeError = null;
    diagnostics = const <GameDiagnostic>[];
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
    _clearRuntimeState();
    _preRunProject = null;
    project = FourthDemoProject.sample();
    isPlaying = false;
    showPreviousSolution = false;
    exerciseComplete = false;
    codeError = null;
    diagnostics = const <GameDiagnostic>[];
    statusMessage = 'Exercise restarted';
    notifyListeners();
  }

  void resetRuntime({bool keepMode = false}) {
    _clearRuntimeState();
    final snapshot = _preRunProject;
    if (snapshot != null) {
      project = snapshot;
      _preRunProject = null;
    } else {
      project = project.copyWith(events: const <FourthDemoEventHandler>[]);
    }
    exerciseComplete = false;
    if (!keepMode) {
      isPlaying = false;
    }
  }

  void _clearRuntimeState() {
    _stopAllSounds();
    _motions.clear();
    _physicsBodies.clear();
    _activeSpeechBubbles.clear();
    _pressedKeys.clear();
    _loopSpriteVariables.clear();
    draggingSpriteId = null;
    draggingWidgetId = null;
    _stopContinuousHorizontalMovement();
  }

  void handleKey(LogicalKeyboardKey key) {
    handleKeyDown(key);
  }

  void handleKeyDown(LogicalKeyboardKey key) {
    if (!isPlaying) {
      return;
    }
    if (!_isMovementKey(key)) {
      return;
    }
    _pressedKeys.add(key);
    _runHandlers('onKey', key: key);
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    _pressedKeys.remove(key);
    if (!_hasHorizontalInput) {
      _stopContinuousHorizontalMovement();
    }
  }

  void handleClick(Offset worldPosition) {
    if (!isPlaying) {
      return;
    }
    final widget = _widgetAt(worldPosition);
    if (widget != null) {
      _handleWidgetClick(widget, worldPosition);
      return;
    }
    final hit = _spriteAt(worldPosition);
    if (hit == null || hit.destroyed || !hit.enabled) {
      return;
    }
    _runHandlers('onClick', eventSpriteId: hit.id);
  }

  void handleSwipe(String direction) {
    if (!isPlaying) {
      return;
    }
    _runHandlers('onSwipe', direction: direction);
  }

  FourthDemoSprite? spriteAt(Offset worldPosition) {
    return _spriteAt(worldPosition);
  }

  void handleAnimationEnd(String spriteId, String animationName) {
    if (!isPlaying) {
      return;
    }
    _runHandlers(
      'onAnimationEnd',
      eventSpriteId: spriteId,
      eventArgument: animationName,
    );
  }

  void handleAnimationLoop(String spriteId, String animationName) {
    if (!isPlaying) {
      return;
    }
    _runHandlers(
      'onAnimationLoop',
      eventSpriteId: spriteId,
      eventArgument: animationName,
    );
  }

  void handleUpdate([double dt = 1 / 60]) {
    if (!isPlaying) {
      return;
    }
    _advanceMotions(dt);
    _advancePhysics(dt);
    _advanceContinuousHorizontalMovement(dt);
    _advanceSpeechBubbles(dt);
    _advanceWidgets(dt);
    _runCollisionHandlers();
    _runWorldBoundsHandlers();
    _runHandlers('onUpdate');
  }

  void beginDrag(Offset worldPosition) {
    if (!isPlaying &&
        stageTool != FourthDemoStageTool.move &&
        stageTool != FourthDemoStageTool.select) {
      return;
    }
    if (!isPlaying) {
      final widget = _widgetAt(worldPosition);
      if (widget != null) {
        draggingWidgetId = widget.id;
        draggingSpriteId = null;
        return;
      }
    }
    final hit = _spriteAt(worldPosition);
    draggingSpriteId = hit?.id;
    draggingWidgetId = null;
    if (hit != null && !isPlaying) {
      selectSprite(hit.id);
    }
  }

  void dragTo(Offset worldPosition) {
    final widgetId = draggingWidgetId;
    if (widgetId != null) {
      final widgets = project.widgets.map((widget) {
        if (widget.id != widgetId) {
          return widget;
        }
        return _moveWidgetTo(widget, worldPosition);
      }).toList();
      project = project.copyWith(widgets: widgets);
      return;
    }

    final id = draggingSpriteId;
    if (id == null) {
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
  }

  void endDrag() {
    final id = draggingSpriteId;
    if (isPlaying && id != null) {
      _runHandlers('onDragEnd', eventSpriteId: id);
    }
    draggingSpriteId = null;
    draggingWidgetId = null;
    notifyListeners();
  }

  void updateSprite(FourthDemoSprite updated) {
    if (isPlaying) {
      return;
    }
    final unique = updated.copyWith(
      name: _uniqueSpriteName(updated.name, exceptId: updated.id),
    );
    project = project.copyWith(
      sprites: project.sprites
          .map((sprite) => sprite.id == unique.id ? unique : sprite)
          .toList(),
    );
    notifyListeners();
  }

  bool deleteSprite(String id) {
    if (isPlaying) {
      return false;
    }
    final sprites = project.sprites.where((sprite) => sprite.id != id).toList();
    if (sprites.length == project.sprites.length) {
      return false;
    }
    final code = Map<String, String>.from(project.codeBySpriteId)..remove(id);
    _motions.remove(id);
    _physicsBodies.remove(id);
    if (_continuousHorizontalSpriteId == id) {
      _stopContinuousHorizontalMovement();
    }
    var settings = project.settings;
    if (settings.cameraTargetId == id ||
        !sprites.any((sprite) => sprite.id == settings.cameraTargetId)) {
      settings = settings.copyWith(
        cameraTargetId: sprites.isEmpty ? '' : sprites.first.id,
      );
    }
    project = project.copyWith(
      sprites: sprites,
      settings: settings,
      codeBySpriteId: code,
      selectedSpriteId: sprites.isEmpty ? '' : sprites.first.id,
    );
    notifyListeners();
    return true;
  }

  FourthDemoSprite? duplicateSprite(String id) {
    if (isPlaying) {
      return null;
    }
    final source = project.sprites
        .where((sprite) => sprite.id == id)
        .firstOrNull;
    if (source == null) {
      return null;
    }
    final nextId = 'sprite-${DateTime.now().microsecondsSinceEpoch}';
    final copy = source
        .copyWith(
          name: _uniqueSpriteName(_numberedName(source.name)),
          x: source.x + 24,
          y: source.y + 24,
          startX: source.startX + 24,
          startY: source.startY + 24,
        )
        .withId(nextId);
    project = project.copyWith(
      sprites: <FourthDemoSprite>[...project.sprites, copy],
      selectedSpriteId: nextId,
      codeBySpriteId: <String, String>{
        ...project.codeBySpriteId,
        nextId: project.codeBySpriteId[source.id] ?? '',
      },
    );
    notifyListeners();
    return copy;
  }

  void addPlaceholderSprite() {
    if (isPlaying) {
      return;
    }
    final id = 'sprite-${DateTime.now().millisecondsSinceEpoch}';
    final sprite = FourthDemoSprite(
      id: id,
      name: _uniqueSpriteName('newSprite'),
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
    notifyListeners();
  }

  FourthDemoSprite addSpriteFromAsset({
    required String name,
    required FourthDemoSpriteKind kind,
    required String assetId,
  }) {
    final id = 'sprite-${DateTime.now().microsecondsSinceEpoch}';
    final sprite = FourthDemoSprite(
      id: id,
      name: _uniqueSpriteName(name),
      kind: kind,
      assetId: assetId,
      facing: kind == FourthDemoSpriteKind.player
          ? FourthDemoSpriteFacing.right
          : FourthDemoSpriteFacing.left,
      x: 260,
      y: 270,
      startX: 260,
      startY: 270,
      width: kind == FourthDemoSpriteKind.player ? 58 : 48,
      height: kind == FourthDemoSpriteKind.player ? 58 : 48,
      colorValue: kind == FourthDemoSpriteKind.collectible
          ? 0xFFFFC928
          : 0xFF4CC486,
      immovable: kind == FourthDemoSpriteKind.collectible,
      collideWorldBounds: kind == FourthDemoSpriteKind.player,
      collideOtherSprites: kind == FourthDemoSpriteKind.player,
    );
    project = project.copyWith(
      sprites: <FourthDemoSprite>[...project.sprites, sprite],
      selectedSpriteId: id,
      codeBySpriteId: <String, String>{...project.codeBySpriteId, id: ''},
    );
    notifyListeners();
    return sprite;
  }

  FourthDemoScreenWidget addWidget(FourthDemoWidgetKind type) {
    final id = 'widget-${DateTime.now().microsecondsSinceEpoch}';
    final widget = FourthDemoScreenWidget(
      id: id,
      name: _defaultWidgetName(type),
      type: type,
      x: 200,
      y: 150,
      text: type == FourthDemoWidgetKind.counter
          ? 'Score'
          : _defaultWidgetName(type),
      value: 0,
    );
    project = project.copyWith(
      widgets: <FourthDemoScreenWidget>[...project.widgets, widget],
    );
    notifyListeners();
    return widget;
  }

  void updateWidget(FourthDemoScreenWidget updated) {
    if (isPlaying) {
      return;
    }
    project = project.copyWith(
      widgets: project.widgets
          .map((widget) => widget.id == updated.id ? updated : widget)
          .toList(),
    );
    notifyListeners();
  }

  void deleteWidget(String id) {
    if (isPlaying) {
      return;
    }
    project = project.copyWith(
      widgets: project.widgets.where((widget) => widget.id != id).toList(),
    );
    notifyListeners();
  }

  FourthDemoScreenWidget? duplicateWidget(String id) {
    if (isPlaying) {
      return null;
    }
    final source = project.widgets
        .where((widget) => widget.id == id)
        .firstOrNull;
    if (source == null) {
      return null;
    }
    final copy = source.copyWith(
      id: 'widget-${DateTime.now().microsecondsSinceEpoch}',
      name: _numberedName(source.name),
      x: source.x + 20,
      y: source.y + 20,
    );
    project = project.copyWith(
      widgets: <FourthDemoScreenWidget>[...project.widgets, copy],
    );
    notifyListeners();
    return copy;
  }

  FourthDemoSound addSoundFromAsset({
    required String name,
    required String assetPath,
  }) {
    final sound = FourthDemoSound(
      id: 'sound-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      assetPath: assetPath,
    );
    project = project.copyWith(
      sounds: <FourthDemoSound>[...project.sounds, sound],
    );
    notifyListeners();
    return sound;
  }

  void updateSound(FourthDemoSound updated) {
    if (isPlaying) {
      return;
    }
    project = project.copyWith(
      sounds: project.sounds
          .map((sound) => sound.id == updated.id ? updated : sound)
          .toList(),
    );
    notifyListeners();
  }

  void deleteSound(String id) {
    if (isPlaying) {
      return;
    }
    project = project.copyWith(
      sounds: project.sounds.where((sound) => sound.id != id).toList(),
    );
    notifyListeners();
  }

  void updateSettings(FourthDemoGameSettings settings) {
    if (isPlaying) {
      return;
    }
    project = project.copyWith(settings: settings);
    notifyListeners();
  }

  String _defaultWidgetName(FourthDemoWidgetKind type) {
    return switch (type) {
      FourthDemoWidgetKind.counter => 'Counter',
      FourthDemoWidgetKind.text => 'Text',
      FourthDemoWidgetKind.timer => 'Timer',
      FourthDemoWidgetKind.clock => 'Clock',
      FourthDemoWidgetKind.button => 'Button',
      FourthDemoWidgetKind.dialog => 'Dialog',
    };
  }

  String _numberedName(String name) {
    final match = RegExp(r'^(.*?)(?:\s+(\d+))?$').firstMatch(name.trim());
    final base = match?.group(1)?.trim();
    final number = int.tryParse(match?.group(2) ?? '');
    return '${base == null || base.isEmpty ? name : base} ${(number ?? 1) + 1}';
  }

  String _uniqueSpriteName(String name, {String? exceptId}) {
    final trimmed = name.trim().isEmpty ? 'sprite' : name.trim();
    final existing = project.sprites
        .where((sprite) => sprite.id != exceptId)
        .map((sprite) => sprite.name.trim().toLowerCase())
        .toSet();
    if (!existing.contains(trimmed.toLowerCase())) {
      return trimmed;
    }

    final base = RegExp(
      r'^(.*?)(?:\s+\d+)?$',
    ).firstMatch(trimmed)?.group(1)?.trim();
    final root = base == null || base.isEmpty ? trimmed : base;
    var index = 2;
    while (existing.contains('$root $index'.toLowerCase())) {
      index += 1;
    }
    return '$root $index';
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
    if (isPlaying) {
      statusMessage = 'Stop the run before importing a project.';
      notifyListeners();
      return false;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('The JSON root must be an object.');
      }
      final imported = FourthDemoProject.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final validation = imported.validate();
      if (validation.isNotEmpty) {
        throw FormatException(validation.join(' '));
      }
      project = imported;
      _clearRuntimeState();
      _preRunProject = null;
      isPlaying = false;
      exerciseComplete = false;
      codeError = null;
      diagnostics = const <GameDiagnostic>[];
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

  void _runHandlers(
    String event, {
    LogicalKeyboardKey? key,
    String? eventSpriteId,
    String? eventArgument,
    String? direction,
    Set<String> directions = const <String>{},
  }) {
    final handlers = project.events.where((handler) => handler.event == event);
    for (final handler in handlers) {
      if (eventSpriteId != null && handler.targetSpriteId != eventSpriteId) {
        continue;
      }
      if (eventArgument != null &&
          handler.argument.isNotEmpty &&
          _normalizeSpriteLookup(handler.argument) !=
              _normalizeSpriteLookup(eventArgument)) {
        continue;
      }
      _instructionCount = 0;
      for (final action in handler.actions) {
        if (!_runAction(
          handler.targetSpriteId,
          action,
          key,
          direction: direction,
          directions: directions,
        )) {
          break;
        }
      }
    }
    _handleCollections();
  }

  bool _runAction(
    String spriteId,
    FourthDemoAction action,
    LogicalKeyboardKey? key, {
    String? direction,
    Set<String> directions = const <String>{},
  }) {
    _instructionCount += 1;
    if (_instructionCount > maxInstructionsPerEvent) {
      _runtimeError(
        'Event stopped because it exceeded the safe instruction limit.',
        action,
      );
      return false;
    }

    final context = GameRuntimeContext(
      project: project,
      currentSpriteId: spriteId,
      key: key,
      direction: direction,
      directions: directions,
      spriteVariables: _loopSpriteVariables,
      sourceSpan: action.sourceSpan,
    );

    switch (action.type) {
      case FourthDemoActionType.ifCondition:
        final result = _runtime.evaluateConditionSafe(
          action.condition,
          context,
        );
        if (!result.success) {
          _recordRuntimeDiagnostic(result.diagnostic);
          return false;
        }
        final branch = result.value ? action.actions : action.elseActions;
        for (final child in branch) {
          if (!_runAction(
            spriteId,
            child,
            key,
            direction: direction,
            directions: directions,
          )) {
            return false;
          }
        }
        return true;
      case FourthDemoActionType.repeatTimes:
        for (var index = 0; index < action.count; index += 1) {
          for (final child in action.actions) {
            if (!_runAction(
              spriteId,
              child,
              key,
              direction: direction,
              directions: directions,
            )) {
              return false;
            }
          }
        }
        return true;
      case FourthDemoActionType.repeatForever:
        for (var index = 0; index < maxLoopIterations; index += 1) {
          for (final child in action.actions) {
            if (!_runAction(
              spriteId,
              child,
              key,
              direction: direction,
              directions: directions,
            )) {
              return false;
            }
          }
        }
        _runtimeError(
          'Loop stopped because it exceeded the safe limit.',
          action,
        );
        return false;
      case FourthDemoActionType.until:
        for (var index = 0; index < maxLoopIterations; index += 1) {
          final result = _runtime.evaluateConditionSafe(
            action.condition,
            context,
          );
          if (!result.success) {
            _recordRuntimeDiagnostic(result.diagnostic);
            return false;
          }
          if (result.value) {
            return true;
          }
          for (final child in action.actions) {
            if (!_runAction(
              spriteId,
              child,
              key,
              direction: direction,
              directions: directions,
            )) {
              return false;
            }
          }
        }
        _runtimeError(
          'until stopped because it exceeded the safe limit.',
          action,
        );
        return false;
      case FourthDemoActionType.forEachSprite:
        final previous = _loopSpriteVariables[action.variableName];
        for (final sprite in project.sprites) {
          _loopSpriteVariables[action.variableName] = sprite.id;
          for (final child in action.actions) {
            if (!_runAction(
              spriteId,
              child,
              key,
              direction: direction,
              directions: directions,
            )) {
              if (previous == null) {
                _loopSpriteVariables.remove(action.variableName);
              } else {
                _loopSpriteVariables[action.variableName] = previous;
              }
              return false;
            }
          }
        }
        if (previous == null) {
          _loopSpriteVariables.remove(action.variableName);
        } else {
          _loopSpriteVariables[action.variableName] = previous;
        }
        return true;
      case FourthDemoActionType.functionCall:
        final handlers = project.events.where(
          (handler) =>
              handler.event == 'function:${action.text}' &&
              handler.targetSpriteId == spriteId,
        );
        if (handlers.isEmpty) {
          _runtimeError(
            'Function "${action.text}" was not found for this sprite.',
            action,
            hint: 'Define ${action.text} = () => in this sprite code.',
          );
          return false;
        }
        for (final handler in handlers) {
          for (final child in handler.actions) {
            final diagnosticsBefore = diagnostics.length;
            if (!_runAction(
              spriteId,
              child,
              key,
              direction: direction,
              directions: directions,
            )) {
              return diagnostics.length > diagnosticsBefore ? false : true;
            }
          }
        }
        return true;
      case FourthDemoActionType.returnValue:
        return false;
      case FourthDemoActionType.setBackground:
        if (!supportedBackgrounds.contains(action.text.trim().toLowerCase())) {
          _runtimeError(
            'Background "${action.text}" was not found.',
            action,
            hint: 'Use one of: ${supportedBackgrounds.join(', ')}.',
          );
          return false;
        }
        project = project.copyWith(
          settings: project.settings.copyWith(
            background: action.text.trim().toLowerCase(),
          ),
        );
        statusMessage = 'Background set to ${action.text}.';
        notifyListeners();
        return true;
      case FourthDemoActionType.setWorldWidth:
        project = project.copyWith(
          settings: project.settings.copyWith(
            worldWidth: math.max(100, action.amount),
          ),
        );
        notifyListeners();
        return true;
      case FourthDemoActionType.setWorldHeight:
        project = project.copyWith(
          settings: project.settings.copyWith(
            worldHeight: math.max(100, action.amount),
          ),
        );
        notifyListeners();
        return true;
      case FourthDemoActionType.setWorldSize:
        project = project.copyWith(
          settings: project.settings.copyWith(
            worldWidth: math.max(100, action.amount),
            worldHeight: math.max(100, double.tryParse(action.text) ?? 100),
          ),
        );
        notifyListeners();
        return true;
      case FourthDemoActionType.setGravity:
        project = project.copyWith(
          settings: project.settings.copyWith(gravity: action.amount),
        );
        notifyListeners();
        return true;
      case FourthDemoActionType.setPhysics:
        final mode = FourthDemoPhysicsMode.values
            .where((item) => item.name == action.text.trim().toLowerCase())
            .firstOrNull;
        if (mode == null) {
          _runtimeError(
            'Physics mode "${action.text}" was not found.',
            action,
            hint:
                'Use one of: ${FourthDemoPhysicsMode.values.map((mode) => mode.name).join(', ')}.',
          );
          return false;
        }
        project = project.copyWith(
          settings: project.settings.copyWith(physicsMode: mode),
        );
        notifyListeners();
        return true;
      case FourthDemoActionType.setCameraTarget:
        final target = _normalizeSpriteLookup(action.text);
        final targetExists = project.sprites.any(
          (sprite) =>
              _normalizeSpriteLookup(sprite.id) == target ||
              _normalizeSpriteLookup(sprite.name) == target,
        );
        if (!targetExists) {
          _runtimeError(
            'Sprite "${action.text}" was not found.',
            action,
            hint: 'Check the sprite name in the Sprites panel.',
          );
          return false;
        }
        project = project.copyWith(
          settings: project.settings.copyWith(cameraTargetId: action.text),
        );
        notifyListeners();
        return true;
      default:
        break;
    }

    if (_isWidgetAction(action.type)) {
      return _runWidgetAction(action);
    }
    if (_isSoundAction(action.type)) {
      return _runSoundAction(action);
    }

    final index = _spriteIndexForAction(spriteId, action);
    if (index == -1) {
      _runtimeError(
        'Sprite "${action.receiver}" was not found.',
        action,
        hint: 'Check the sprite name in the Sprites panel.',
      );
      return false;
    }
    final sprite = project.sprites[index];
    if (sprite.destroyed ||
        (!sprite.enabled && action.type != FourthDemoActionType.enable)) {
      _runtimeError(
        'Action failed because sprite "${sprite.name}" is destroyed or disabled.',
        action,
      );
      return false;
    }
    FourthDemoSprite next = sprite;
    var shouldNotify = false;
    switch (action.type) {
      case FourthDemoActionType.step:
        final amount = action.amount == 0 ? 1 : action.amount;
        final direction = _directionForRotation(sprite.rotation);
        final speed = _speedMultiplier(sprite.speed);
        if (_isAirborne(sprite)) {
          _setAirVelocity(
            sprite,
            direction.dx * _groundControlSpeed * speed * amount,
          );
          next = sprite.copyWith(
            facing: _facingForHorizontal(direction.dx, sprite.facing),
          );
          break;
        }
        if (_canUseContinuousHorizontalMovement(key, direction)) {
          _setContinuousHorizontalMovement(
            sprite,
            direction.dx * _groundControlSpeed * speed * amount,
          );
          next = sprite.copyWith(
            facing: _facingForHorizontal(direction.dx, sprite.facing),
          );
          break;
        }
        final distance = amount * stepSize * speed;
        next = _moveSpriteTo(
          sprite,
          x: sprite.x + direction.dx * distance,
          y: sprite.y + direction.dy * distance,
        ).copyWith(facing: _facingForHorizontal(direction.dx, sprite.facing));
      case FourthDemoActionType.jump:
        next = _jumpSprite(sprite);
      case FourthDemoActionType.setX:
        next = _moveSpriteTo(sprite, x: action.amount, y: sprite.y);
      case FourthDemoActionType.setY:
        next = _moveSpriteTo(sprite, x: sprite.x, y: action.amount);
      case FourthDemoActionType.setRotation:
        next = sprite.copyWith(rotation: action.amount);
      case FourthDemoActionType.setSpeed:
        next = sprite.copyWith(speed: action.amount);
      case FourthDemoActionType.setAllowGravity:
        next = sprite.copyWith(
          allowGravity:
              action.text.trim() == 'true' || action.text.trim() == 'yes',
        );
      case FourthDemoActionType.show:
        next = sprite.copyWith(visible: true);
      case FourthDemoActionType.hide:
        next = sprite.copyWith(visible: false);
      case FourthDemoActionType.destroy:
        next = sprite.copyWith(visible: false, destroyed: true, enabled: false);
      case FourthDemoActionType.disable:
        next = sprite.copyWith(enabled: false);
      case FourthDemoActionType.enable:
        next = sprite.copyWith(enabled: true);
      case FourthDemoActionType.setScale:
        next = sprite.copyWith(scale: action.amount);
      case FourthDemoActionType.addAnimation:
        final frames = action.target
            .split(',')
            .map((part) => int.tryParse(part.trim()))
            .whereType<int>()
            .toList();
        final animation = FourthDemoAnimationDefinition(
          name: action.text,
          frames: frames,
          fps: action.amount,
          loop: action.condition == 'true',
        );
        next = sprite.copyWith(
          animations: <FourthDemoAnimationDefinition>[
            ...sprite.animations.where((item) => item.name != animation.name),
            animation,
          ],
        );
      case FourthDemoActionType.startAnimation:
        if (!sprite.animations.any(
          (animation) => animation.name == action.text,
        )) {
          _runtimeError(
            'Animation "${action.text}" was not found.',
            action,
            hint:
                'Add it first using @addAnimation "${action.text}", [0, 1], 8, true.',
          );
          return false;
        }
        next = sprite.copyWith(currentAnimation: action.text);
      case FourthDemoActionType.stopAnimation:
        next = sprite.copyWith(currentAnimation: '');
      case FourthDemoActionType.say:
        final message = action.text.isEmpty ? 'Hello!' : action.text;
        _activeSpeechBubbles[sprite.id] = _SpriteSpeech(
          text: message,
          remainingSeconds: _speechDurationSeconds,
        );
        statusMessage = message;
        shouldNotify = true;
      case FourthDemoActionType.wait:
      case FourthDemoActionType.repeat:
      case FourthDemoActionType.times:
      case FourthDemoActionType.loop:
      case FourthDemoActionType.repeatTimes:
      case FourthDemoActionType.repeatForever:
      case FourthDemoActionType.until:
      case FourthDemoActionType.forEachSprite:
      case FourthDemoActionType.functionCall:
      case FourthDemoActionType.returnValue:
      case FourthDemoActionType.ifTouching:
      case FourthDemoActionType.ifCondition:
      case FourthDemoActionType.setBackground:
      case FourthDemoActionType.setWorldWidth:
      case FourthDemoActionType.setWorldHeight:
      case FourthDemoActionType.setWorldSize:
      case FourthDemoActionType.setGravity:
      case FourthDemoActionType.setPhysics:
      case FourthDemoActionType.setCameraTarget:
      case FourthDemoActionType.getX:
      case FourthDemoActionType.getY:
      case FourthDemoActionType.getRotation:
      case FourthDemoActionType.getDistanceFrom:
      case FourthDemoActionType.getScale:
      case FourthDemoActionType.widgetShow:
      case FourthDemoActionType.widgetHide:
      case FourthDemoActionType.widgetSetText:
      case FourthDemoActionType.widgetSetX:
      case FourthDemoActionType.widgetSetY:
      case FourthDemoActionType.widgetSetOpacity:
      case FourthDemoActionType.widgetSetValue:
      case FourthDemoActionType.widgetAdd:
      case FourthDemoActionType.widgetSubtract:
      case FourthDemoActionType.widgetReset:
      case FourthDemoActionType.widgetAppend:
      case FourthDemoActionType.widgetClear:
      case FourthDemoActionType.widgetStart:
      case FourthDemoActionType.widgetStop:
      case FourthDemoActionType.widgetSetDuration:
      case FourthDemoActionType.widgetEnable:
      case FourthDemoActionType.widgetDisable:
      case FourthDemoActionType.widgetSetTitle:
      case FourthDemoActionType.widgetSetButtonText:
      case FourthDemoActionType.soundPlay:
      case FourthDemoActionType.soundStop:
      case FourthDemoActionType.soundPause:
      case FourthDemoActionType.soundResume:
      case FourthDemoActionType.soundSetVolume:
      case FourthDemoActionType.soundSetLoop:
        statusMessage = 'That block is saved for the next lesson.';
        shouldNotify = true;
    }
    final sprites = List<FourthDemoSprite>.from(project.sprites)
      ..[index] = next;
    project = project.copyWith(sprites: sprites);
    if (shouldNotify) {
      notifyListeners();
    }
    return true;
  }

  bool _runWidgetAction(FourthDemoAction action) {
    final index = _widgetIndexForReceiver(action.receiver);
    if (index == -1) {
      _runtimeError(
        'Widget "${action.receiver}" was not found.',
        action,
        hint: 'Check the widget name in the Widgets panel.',
      );
      return false;
    }

    final widget = project.widgets[index];
    FourthDemoScreenWidget next = widget;
    switch (action.type) {
      case FourthDemoActionType.widgetShow:
        next = widget.copyWith(visible: true);
      case FourthDemoActionType.widgetHide:
        next = widget.copyWith(visible: false);
      case FourthDemoActionType.widgetSetText:
        next = widget.copyWith(text: action.text);
      case FourthDemoActionType.widgetSetX:
        next = widget.copyWith(
          x: action.amount.clamp(0, project.settings.worldWidth).toDouble(),
        );
      case FourthDemoActionType.widgetSetY:
        next = widget.copyWith(
          y: action.amount.clamp(0, project.settings.worldHeight).toDouble(),
        );
      case FourthDemoActionType.widgetSetOpacity:
        next = widget.copyWith(opacity: action.amount.clamp(0, 1).toDouble());
      case FourthDemoActionType.widgetSetValue:
        if (!_widgetSupportsValue(widget)) {
          _runtimeError(
            'Command "setValue" only works on counter, timer, and clock widgets.',
            action,
          );
          return false;
        }
        next = widget.copyWith(value: math.max(0, action.amount));
      case FourthDemoActionType.widgetAdd:
        if (widget.type != FourthDemoWidgetKind.counter) {
          _runtimeError('Command "add" only works on counter widgets.', action);
          return false;
        }
        next = widget.copyWith(value: widget.value + action.amount);
      case FourthDemoActionType.widgetSubtract:
        if (widget.type != FourthDemoWidgetKind.counter) {
          _runtimeError(
            'Command "subtract" only works on counter widgets.',
            action,
          );
          return false;
        }
        next = widget.copyWith(value: widget.value - action.amount);
      case FourthDemoActionType.widgetReset:
        next = switch (widget.type) {
          FourthDemoWidgetKind.timer => widget.copyWith(
            value: widget.durationSeconds.toDouble(),
            running: false,
          ),
          FourthDemoWidgetKind.clock => widget.copyWith(
            value: 0,
            running: false,
          ),
          FourthDemoWidgetKind.counter => widget.copyWith(value: 0),
          _ => widget.copyWith(value: 0),
        };
      case FourthDemoActionType.widgetAppend:
        if (widget.type != FourthDemoWidgetKind.text) {
          _runtimeError('Command "append" only works on text widgets.', action);
          return false;
        }
        next = widget.copyWith(text: '${widget.text}${action.text}');
      case FourthDemoActionType.widgetClear:
        if (widget.type != FourthDemoWidgetKind.text) {
          _runtimeError('Command "clear" only works on text widgets.', action);
          return false;
        }
        next = widget.copyWith(text: '');
      case FourthDemoActionType.widgetStart:
        if (widget.type != FourthDemoWidgetKind.timer &&
            widget.type != FourthDemoWidgetKind.clock) {
          _runtimeError(
            'Command "start" only works on timer and clock widgets.',
            action,
          );
          return false;
        }
        if (widget.type == FourthDemoWidgetKind.timer &&
            widget.durationSeconds <= 0) {
          _runtimeError('Timer "${widget.name}" has no duration.', action);
          return false;
        }
        if (widget.running &&
            (widget.type != FourthDemoWidgetKind.timer || widget.value > 0)) {
          return true;
        }
        next = widget.copyWith(
          running: true,
          value: widget.type == FourthDemoWidgetKind.timer && widget.value <= 0
              ? widget.durationSeconds.toDouble()
              : widget.value,
        );
      case FourthDemoActionType.widgetStop:
        if (widget.type != FourthDemoWidgetKind.timer &&
            widget.type != FourthDemoWidgetKind.clock) {
          _runtimeError(
            'Command "stop" only works on timer and clock widgets.',
            action,
          );
          return false;
        }
        next = widget.copyWith(running: false);
      case FourthDemoActionType.widgetSetDuration:
        if (widget.type != FourthDemoWidgetKind.timer) {
          _runtimeError(
            'Command "setDuration" only works on timer widgets.',
            action,
          );
          return false;
        }
        final duration = math.max(0, action.amount).round();
        next = widget.copyWith(
          durationSeconds: duration,
          value: duration.toDouble(),
        );
      case FourthDemoActionType.widgetEnable:
        next = widget.copyWith(enabled: true);
      case FourthDemoActionType.widgetDisable:
        next = widget.copyWith(enabled: false);
      case FourthDemoActionType.widgetSetTitle:
        if (widget.type != FourthDemoWidgetKind.dialog) {
          _runtimeError(
            'Command "setTitle" only works on dialog widgets.',
            action,
          );
          return false;
        }
        next = widget.copyWith(title: action.text);
      case FourthDemoActionType.widgetSetButtonText:
        if (widget.type != FourthDemoWidgetKind.dialog) {
          _runtimeError(
            'Command "setButtonText" only works on dialog widgets.',
            action,
          );
          return false;
        }
        next = widget.copyWith(buttonText: action.text);
      default:
        return false;
    }

    final widgets = List<FourthDemoScreenWidget>.from(project.widgets)
      ..[index] = next;
    project = project.copyWith(widgets: widgets);
    notifyListeners();
    return true;
  }

  bool _isWidgetAction(FourthDemoActionType type) {
    return switch (type) {
      FourthDemoActionType.widgetShow ||
      FourthDemoActionType.widgetHide ||
      FourthDemoActionType.widgetSetText ||
      FourthDemoActionType.widgetSetX ||
      FourthDemoActionType.widgetSetY ||
      FourthDemoActionType.widgetSetOpacity ||
      FourthDemoActionType.widgetSetValue ||
      FourthDemoActionType.widgetAdd ||
      FourthDemoActionType.widgetSubtract ||
      FourthDemoActionType.widgetReset ||
      FourthDemoActionType.widgetAppend ||
      FourthDemoActionType.widgetClear ||
      FourthDemoActionType.widgetStart ||
      FourthDemoActionType.widgetStop ||
      FourthDemoActionType.widgetSetDuration ||
      FourthDemoActionType.widgetEnable ||
      FourthDemoActionType.widgetDisable ||
      FourthDemoActionType.widgetSetTitle ||
      FourthDemoActionType.widgetSetButtonText => true,
      _ => false,
    };
  }

  bool _isSoundAction(FourthDemoActionType type) {
    return switch (type) {
      FourthDemoActionType.soundPlay ||
      FourthDemoActionType.soundStop ||
      FourthDemoActionType.soundPause ||
      FourthDemoActionType.soundResume ||
      FourthDemoActionType.soundSetVolume ||
      FourthDemoActionType.soundSetLoop => true,
      _ => false,
    };
  }

  bool _runSoundAction(FourthDemoAction action) {
    final index = _soundIndexForReceiver(action.receiver);
    if (index == -1) {
      _runtimeError(
        'Sound "${action.receiver}" was not found.',
        action,
        hint: 'Check the sound name in the Sounds panel.',
      );
      return false;
    }

    final sound = project.sounds[index];
    switch (action.type) {
      case FourthDemoActionType.soundPlay:
        unawaited(_playSound(sound, action));
      case FourthDemoActionType.soundStop:
        unawaited(_activeSoundPlayers[sound.id]?.stop());
        _updateSoundAt(index, sound.copyWith(isPlaying: false));
      case FourthDemoActionType.soundPause:
        unawaited(_activeSoundPlayers[sound.id]?.pause());
        _updateSoundAt(index, sound.copyWith(isPlaying: false));
      case FourthDemoActionType.soundResume:
        unawaited(_activeSoundPlayers[sound.id]?.resume());
        _updateSoundAt(index, sound.copyWith(isPlaying: true));
      case FourthDemoActionType.soundSetVolume:
        final volume = action.amount.clamp(0.0, 1.0).toDouble();
        unawaited(_activeSoundPlayers[sound.id]?.setVolume(volume));
        _updateSoundAt(index, sound.copyWith(volume: volume));
      case FourthDemoActionType.soundSetLoop:
        final loop = const <String>{'true', 'yes'}.contains(action.text);
        final player = _activeSoundPlayers[sound.id];
        if (player != null) {
          unawaited(
            player.setReleaseMode(
              loop ? ReleaseMode.loop : ReleaseMode.release,
            ),
          );
        }
        _updateSoundAt(index, sound.copyWith(loop: loop));
      default:
        return false;
    }
    return true;
  }

  Future<void> _playSound(
    FourthDemoSound sound,
    FourthDemoAction action,
  ) async {
    try {
      final player = _soundPlayerFor(sound);
      await player.stop();
      await player.setVolume(sound.volume.clamp(0.0, 1.0).toDouble());
      await player.setReleaseMode(
        sound.loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      final audio = await _loadSoundAssetData(sound.assetPath);
      final bytes = Uint8List.view(
        audio.buffer,
        audio.offsetInBytes,
        audio.lengthInBytes,
      );
      await player.play(
        BytesSource(bytes, mimeType: _audioMimeType(sound.assetPath)),
      );
      final index = _soundIndexForReceiver(sound.id);
      if (index != -1) {
        _updateSoundAt(index, project.sounds[index].copyWith(isPlaying: true));
      }
    } catch (_) {
      _runtimeError(
        'Could not play sound "${sound.name}".',
        action,
        hint: 'Check that the sound asset is available.',
      );
    }
  }

  AudioPlayer _soundPlayerFor(FourthDemoSound sound) {
    return _activeSoundPlayers.putIfAbsent(sound.id, () {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) {
        final index = _soundIndexForReceiver(sound.id);
        if (index != -1) {
          _updateSoundAt(
            index,
            project.sounds[index].copyWith(isPlaying: false),
          );
        }
      });
      return player;
    });
  }

  void _stopAllSounds() {
    final playersById = _soundPlayers;
    if (playersById == null || playersById.isEmpty) {
      return;
    }

    final players = List<AudioPlayer>.from(playersById.values);
    playersById.clear();

    for (final player in players) {
      unawaited(player.stop().catchError((_) {}));
      unawaited(player.release().catchError((_) {}));
      unawaited(player.dispose().catchError((_) {}));
    }
  }

  int _soundIndexForReceiver(String receiver) {
    final normalized = _normalizeSpriteLookup(receiver);
    return project.sounds.indexWhere(
      (sound) =>
          _normalizeSpriteLookup(sound.id) == normalized ||
          _normalizeSpriteLookup(sound.name) == normalized,
    );
  }

  void _updateSoundAt(int index, FourthDemoSound sound) {
    final sounds = List<FourthDemoSound>.from(project.sounds)..[index] = sound;
    project = project.copyWith(sounds: sounds);
    notifyListeners();
  }

  Future<ByteData> _loadSoundAssetData(String assetPath) async {
    Object? lastError;
    for (final candidate in _soundAssetBundleCandidates(assetPath)) {
      try {
        return await rootBundle.load(candidate);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? FlutterError('Sound asset was not found: $assetPath');
  }

  List<String> _soundAssetBundleCandidates(String assetPath) {
    final normalized = _normalizeSoundAssetPath(assetPath);
    final withoutAssetPrefix = normalized.startsWith('assets/')
        ? normalized.substring('assets/'.length)
        : normalized;
    final withAssetPrefix = withoutAssetPrefix.startsWith('assets/')
        ? withoutAssetPrefix
        : 'assets/$withoutAssetPrefix';
    return <String>{normalized, withAssetPrefix, withoutAssetPrefix}.toList();
  }

  String _normalizeSoundAssetPath(String assetPath) {
    var path = assetPath.trim().replaceAll('\\', '/');
    for (var i = 0; i < 3; i++) {
      try {
        final decoded = Uri.decodeFull(path);
        if (decoded == path) {
          break;
        }
        path = decoded;
      } on FormatException {
        break;
      }
    }
    return path.replaceAll('%20', ' ');
  }

  String _audioMimeType(String assetPath) {
    final extension = assetPath.split('.').last.toLowerCase();
    return switch (extension) {
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      _ => 'application/octet-stream',
    };
  }

  bool _widgetSupportsValue(FourthDemoScreenWidget widget) {
    return widget.type == FourthDemoWidgetKind.counter ||
        widget.type == FourthDemoWidgetKind.timer ||
        widget.type == FourthDemoWidgetKind.clock;
  }

  int _widgetIndexForReceiver(String receiver) {
    final normalized = _normalizeSpriteLookup(receiver);
    return project.widgets.indexWhere(
      (widget) =>
          _normalizeSpriteLookup(widget.id) == normalized ||
          _normalizeSpriteLookup(widget.name) == normalized,
    );
  }

  FourthDemoScreenWidget? _widgetAt(Offset worldPosition) {
    for (final widget in project.widgets.reversed) {
      if (!widget.visible) {
        continue;
      }
      if (_widgetRect(widget).contains(worldPosition)) {
        return widget;
      }
    }
    return null;
  }

  Rect _widgetRect(FourthDemoScreenWidget widget) {
    return switch (widget.type) {
      FourthDemoWidgetKind.dialog => Rect.fromLTWH(
        widget.x,
        widget.y,
        260,
        118,
      ),
      FourthDemoWidgetKind.button => Rect.fromLTWH(widget.x, widget.y, 120, 38),
      _ => Rect.fromLTWH(widget.x - 8, widget.y - 5, 180, 34),
    };
  }

  FourthDemoScreenWidget _moveWidgetTo(
    FourthDemoScreenWidget widget,
    Offset worldPosition,
  ) {
    final rect = _widgetRect(widget);
    final anchorOffset = Offset(widget.x - rect.left, widget.y - rect.top);
    final maxLeft = math.max(0.0, project.settings.worldWidth - rect.width);
    final maxTop = math.max(0.0, project.settings.worldHeight - rect.height);
    final left = (worldPosition.dx - rect.width / 2).clamp(0.0, maxLeft);
    final top = (worldPosition.dy - rect.height / 2).clamp(0.0, maxTop);
    return widget.copyWith(
      x: left.toDouble() + anchorOffset.dx,
      y: top.toDouble() + anchorOffset.dy,
    );
  }

  void _handleWidgetClick(FourthDemoScreenWidget widget, Offset worldPosition) {
    if (widget.type == FourthDemoWidgetKind.dialog) {
      if (!_dialogButtonRect(widget).contains(worldPosition)) {
        return;
      }
      project = project.copyWith(
        widgets: project.widgets
            .map(
              (item) =>
                  item.id == widget.id ? item.copyWith(visible: false) : item,
            )
            .toList(),
      );
      notifyListeners();
      return;
    }
    if (widget.type != FourthDemoWidgetKind.button) {
      return;
    }
    if (!widget.enabled) {
      return;
    }
    _runHandlers('onWidgetClick', eventArgument: widget.name);
    if (_normalizeSpriteLookup(widget.id) !=
        _normalizeSpriteLookup(widget.name)) {
      _runHandlers('onWidgetClick', eventArgument: widget.id);
    }
    _runHandlers('onButtonClick', eventArgument: widget.name);
    if (_normalizeSpriteLookup(widget.id) !=
        _normalizeSpriteLookup(widget.name)) {
      _runHandlers('onButtonClick', eventArgument: widget.id);
    }
  }

  Rect _dialogButtonRect(FourthDemoScreenWidget widget) {
    final rect = _widgetRect(widget);
    return Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom - 22),
      width: 64,
      height: 24,
    );
  }

  void _advanceWidgets(double dt) {
    var changed = false;
    final endedTimers = <FourthDemoScreenWidget>[];
    final widgets = project.widgets.map((widget) {
      if (!widget.running) {
        return widget;
      }
      if (widget.type == FourthDemoWidgetKind.timer) {
        final nextValue = math.max(0.0, widget.value - dt);
        if (nextValue <= 0 && widget.value > 0) {
          changed = true;
          endedTimers.add(widget);
          return widget.copyWith(value: 0, running: false);
        }
        changed = true;
        return widget.copyWith(value: nextValue);
      }
      if (widget.type == FourthDemoWidgetKind.clock) {
        changed = true;
        return widget.copyWith(value: widget.value + dt);
      }
      return widget;
    }).toList();

    if (changed) {
      project = project.copyWith(widgets: widgets);
    }
    for (final widget in endedTimers) {
      _runHandlers('onTimerEnd', eventArgument: widget.name);
      if (_normalizeSpriteLookup(widget.id) !=
          _normalizeSpriteLookup(widget.name)) {
        _runHandlers('onTimerEnd', eventArgument: widget.id);
      }
    }
  }

  Offset _directionForRotation(double rotation) {
    final normalized = rotation % 360;
    final snapped = ((normalized / 90).round() * 90) % 360;
    return switch (snapped) {
      0 => const Offset(1, 0),
      90 => const Offset(0, 1),
      180 || -180 => const Offset(-1, 0),
      270 || -90 => const Offset(0, -1),
      _ => Offset(
        math.cos(rotation * math.pi / 180),
        math.sin(rotation * math.pi / 180),
      ),
    };
  }

  int _spriteIndexForAction(String currentSpriteId, FourthDemoAction action) {
    if (action.receiver == '@') {
      return project.sprites.indexWhere(
        (sprite) => sprite.id == currentSpriteId,
      );
    }
    final variableSpriteId = _loopSpriteVariables[action.receiver];
    if (variableSpriteId != null) {
      return project.sprites.indexWhere(
        (sprite) => sprite.id == variableSpriteId,
      );
    }
    final receiver = _normalizeSpriteLookup(action.receiver);
    return project.sprites.indexWhere(
      (sprite) =>
          _normalizeSpriteLookup(sprite.id) == receiver ||
          _normalizeSpriteLookup(sprite.name) == receiver,
    );
  }

  void _runtimeError(String message, FourthDemoAction action, {String? hint}) {
    _recordRuntimeDiagnostic(
      action.sourceSpan == null
          ? GameDiagnostic(
              message: message,
              line: 1,
              column: 1,
              type: GameDiagnosticType.runtime,
              hint: hint,
            )
          : GameDiagnostic.fromSpan(
              message: message,
              span: action.sourceSpan!,
              type: GameDiagnosticType.runtime,
              hint: hint,
            ),
    );
  }

  void _recordRuntimeDiagnostic(GameDiagnostic? diagnostic) {
    if (diagnostic == null) {
      return;
    }
    diagnostics = <GameDiagnostic>[...diagnostics, diagnostic];
    codeError = diagnostic.displayMessage;
    statusMessage = diagnostic.displayMessage;
    isPlaying = false;
    notifyListeners();
  }

  FourthDemoSprite _moveSpriteTo(
    FourthDemoSprite sprite, {
    required double x,
    required double y,
  }) {
    final from = visualPositionFor(sprite);
    final nextX = x
        .clamp(0, math.max(0, project.settings.worldWidth - sprite.width))
        .toDouble();
    final nextY = y
        .clamp(0, math.max(0, project.settings.worldHeight - sprite.height))
        .toDouble();
    final next = sprite.copyWith(x: nextX, y: nextY);
    if (from.dx != nextX || from.dy != nextY) {
      _motions[sprite.id] = _SpriteMotion(
        from: from,
        to: Offset(nextX, nextY),
        duration: movementAnimationSeconds,
      );
    }
    return next;
  }

  FourthDemoSprite _jumpSprite(FourthDemoSprite sprite) {
    final body = _physicsBodies.putIfAbsent(sprite.id, () => _PhysicsBody());
    if (!body.grounded && !_isNearGround(sprite)) {
      return sprite;
    }

    final horizontalVelocity = _continuousHorizontalSpriteId == sprite.id
        ? _continuousHorizontalVelocity
        : 0.0;
    body
      ..velocity = Offset(horizontalVelocity, -_jumpVelocity)
      ..grounded = false;
    _motions.remove(sprite.id);

    return sprite.copyWith(
      facing: _facingForHorizontal(horizontalVelocity, sprite.facing),
    );
  }

  void _setAirVelocity(FourthDemoSprite sprite, double velocityX) {
    final body = _physicsBodies.putIfAbsent(sprite.id, () => _PhysicsBody());
    body
      ..velocity = Offset(velocityX, body.velocity.dy)
      ..grounded = false;
    _motions.remove(sprite.id);
  }

  void _setContinuousHorizontalMovement(
    FourthDemoSprite sprite,
    double velocityX,
  ) {
    if (velocityX == 0) {
      _stopContinuousHorizontalMovement();
      return;
    }
    _continuousHorizontalSpriteId = sprite.id;
    _continuousHorizontalVelocity = velocityX;
    _motions.remove(sprite.id);
  }

  void _stopContinuousHorizontalMovement() {
    _continuousHorizontalSpriteId = null;
    _continuousHorizontalVelocity = 0;
  }

  String _normalizeSpriteLookup(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  double _speedMultiplier(double speed) {
    if (speed <= 0) {
      return 0;
    }
    return speed > 10 ? 1 : speed;
  }

  void _advanceMotions(double dt) {
    if (_motions.isEmpty) {
      return;
    }
    final finished = <String>[];
    for (final entry in _motions.entries) {
      entry.value.advance(dt);
      if (entry.value.isDone) {
        finished.add(entry.key);
      }
    }
    for (final id in finished) {
      _motions.remove(id);
    }
  }

  void _advancePhysics(double dt) {
    if (_physicsBodies.isEmpty) {
      return;
    }

    final nextSprites = List<FourthDemoSprite>.from(project.sprites);
    var changed = false;
    final gravity = project.settings.gravity <= 0
        ? _defaultGravity
        : project.settings.gravity;

    for (final entry in _physicsBodies.entries.toList()) {
      final index = nextSprites.indexWhere((sprite) => sprite.id == entry.key);
      if (index == -1) {
        _physicsBodies.remove(entry.key);
        continue;
      }

      final sprite = nextSprites[index];
      final body = entry.value;
      if (sprite.destroyed || !sprite.enabled || sprite.immovable) {
        _physicsBodies.remove(entry.key);
        continue;
      }

      final groundY = _groundYFor(sprite);
      final nextVelocity = Offset(
        body.velocity.dx,
        body.velocity.dy + gravity * dt,
      );
      var nextX = sprite.x + nextVelocity.dx * dt;
      var nextY = sprite.y + nextVelocity.dy * dt;
      var landed = false;

      nextX = nextX
          .clamp(0, math.max(0, project.settings.worldWidth - sprite.width))
          .toDouble();
      if (nextY >= groundY) {
        nextY = groundY;
        landed = true;
      }
      nextY = nextY
          .clamp(0, math.max(0, project.settings.worldHeight - sprite.height))
          .toDouble();

      body
        ..velocity = landed ? Offset.zero : nextVelocity
        ..grounded = landed;

      if (landed && nextVelocity.dy >= 0) {
        _physicsBodies.remove(entry.key);
      }

      if (sprite.x != nextX || sprite.y != nextY) {
        nextSprites[index] = sprite.copyWith(x: nextX, y: nextY);
        changed = true;
      }
    }

    if (changed) {
      project = project.copyWith(sprites: nextSprites);
      _handleCollections();
    }
  }

  void _advanceContinuousHorizontalMovement(double dt) {
    final id = _continuousHorizontalSpriteId;
    if (id == null || !_hasHorizontalInput) {
      return;
    }

    final index = project.sprites.indexWhere((sprite) => sprite.id == id);
    if (index == -1) {
      _stopContinuousHorizontalMovement();
      return;
    }

    final sprite = project.sprites[index];
    if (sprite.destroyed || !sprite.enabled || sprite.immovable) {
      _stopContinuousHorizontalMovement();
      return;
    }
    if (_isAirborne(sprite)) {
      return;
    }

    final nextX = (sprite.x + _continuousHorizontalVelocity * dt)
        .clamp(0, math.max(0, project.settings.worldWidth - sprite.width))
        .toDouble();
    final next = sprite.copyWith(
      x: nextX,
      facing: _facingForHorizontal(
        _continuousHorizontalVelocity,
        sprite.facing,
      ),
    );
    final sprites = List<FourthDemoSprite>.from(project.sprites)
      ..[index] = next;
    project = project.copyWith(sprites: sprites);
    _handleCollections();
  }

  void _advanceSpeechBubbles(double dt) {
    final speechBubbles = _activeSpeechBubbles;
    if (speechBubbles.isEmpty) {
      return;
    }

    final expired = <String>[];
    for (final entry in speechBubbles.entries) {
      entry.value.remainingSeconds -= dt;
      if (entry.value.remainingSeconds <= 0) {
        expired.add(entry.key);
      }
    }
    if (expired.isEmpty) {
      return;
    }
    for (final id in expired) {
      speechBubbles.remove(id);
    }
    notifyListeners();
  }

  void _handleCollections() {
    final player = project.sprites
        .where(
          (sprite) =>
              sprite.kind == FourthDemoSpriteKind.player &&
              sprite.visible &&
              !sprite.destroyed,
        )
        .firstOrNull;
    if (player == null) {
      return;
    }
    for (final sprite in project.sprites) {
      if (sprite.kind != FourthDemoSpriteKind.collectible ||
          !sprite.visible ||
          sprite.destroyed ||
          !sprite.enabled) {
        continue;
      }
      if (!_intersects(player, sprite)) {
        continue;
      }
      if (_hasCustomCollisionHandler(player, sprite)) {
        continue;
      }
      final sprites = project.sprites
          .map(
            (item) =>
                item.id == sprite.id ? item.copyWith(visible: false) : item,
          )
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

  bool _hasCustomCollisionHandler(
    FourthDemoSprite player,
    FourthDemoSprite collectible,
  ) {
    return project.events.any((handler) {
      if (handler.event != 'onCollide') {
        return false;
      }
      if (handler.targetSpriteId == player.id) {
        return handler.argument.isEmpty ||
            _normalizeSpriteLookup(handler.argument) ==
                _normalizeSpriteLookup(collectible.name);
      }
      if (handler.targetSpriteId == collectible.id) {
        return handler.argument.isEmpty ||
            _normalizeSpriteLookup(handler.argument) ==
                _normalizeSpriteLookup(player.name);
      }
      return false;
    });
  }

  void _runCollisionHandlers() {
    for (final a in project.sprites) {
      if (!a.visible || a.destroyed || !a.enabled) {
        continue;
      }
      for (final b in project.sprites) {
        if (identical(a, b) || !b.visible || b.destroyed || !b.enabled) {
          continue;
        }
        if (_intersects(a, b)) {
          _runHandlers('onCollide', eventSpriteId: a.id, eventArgument: b.name);
        }
      }
    }
  }

  void _runWorldBoundsHandlers() {
    for (final sprite in project.sprites) {
      if (!sprite.visible || sprite.destroyed || !sprite.enabled) {
        continue;
      }
      final directions = <String>{};
      if (sprite.x <= 0) {
        directions.add('left');
      }
      if (sprite.y <= 0) {
        directions.add('up');
      }
      if (sprite.x + sprite.width >= project.settings.worldWidth) {
        directions.add('right');
      }
      if (sprite.y + sprite.height >= project.settings.worldHeight) {
        directions.add('down');
      }
      if (directions.isNotEmpty) {
        _runHandlers(
          'onCollideWithWorldBounds',
          eventSpriteId: sprite.id,
          directions: directions,
        );
      }
    }
  }

  FourthDemoSprite? _spriteAt(Offset worldPosition) {
    for (final sprite in project.sprites.reversed) {
      final rect = Rect.fromLTWH(
        sprite.x,
        sprite.y,
        sprite.width,
        sprite.height,
      );
      if (rect.contains(worldPosition)) {
        return sprite;
      }
    }
    return null;
  }

  bool _intersects(FourthDemoSprite a, FourthDemoSprite b) {
    return Rect.fromLTWH(
      a.x,
      a.y,
      a.width,
      a.height,
    ).overlaps(Rect.fromLTWH(b.x, b.y, b.width, b.height));
  }

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyS;
  }

  bool _canUseContinuousHorizontalMovement(
    LogicalKeyboardKey? key,
    Offset direction,
  ) {
    return key != null &&
        _horizontalDirectionForKey(key) != 0 &&
        direction.dx != 0;
  }

  bool _isAirborne(FourthDemoSprite sprite) {
    final body = _physicsBodies[sprite.id];
    return body != null && !body.grounded;
  }

  bool _isNearGround(FourthDemoSprite sprite) {
    return (sprite.y - _groundYFor(sprite)).abs() <= 2;
  }

  double _groundYFor(FourthDemoSprite sprite) {
    return math.min(
      sprite.startY,
      project.settings.worldHeight - sprite.height,
    );
  }

  double _horizontalDirectionForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return 1;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return -1;
    }
    return 0;
  }

  bool get _hasHorizontalInput => _heldHorizontalKey != null;

  LogicalKeyboardKey? get _heldHorizontalKey {
    final movingRight =
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD);
    final movingLeft =
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA);
    if (movingRight == movingLeft) {
      return null;
    }
    return movingRight
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
  }

  FourthDemoSpriteFacing _facingForHorizontal(
    double direction,
    FourthDemoSpriteFacing current,
  ) {
    if (direction > 0) {
      return FourthDemoSpriteFacing.right;
    }
    if (direction < 0) {
      return FourthDemoSpriteFacing.left;
    }
    return current;
  }
}

class _SpriteMotion {
  final Offset from;
  final Offset to;
  final double duration;
  double elapsed = 0;

  _SpriteMotion({required this.from, required this.to, required this.duration});

  Offset get position {
    final t = duration <= 0 ? 1.0 : (elapsed / duration).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(t);
    return Offset.lerp(from, to, eased) ?? to;
  }

  bool get isDone => elapsed >= duration;

  void advance(double dt) {
    elapsed += dt;
  }
}

class _PhysicsBody {
  Offset velocity = Offset.zero;
  bool grounded = true;
}

class _SpriteSpeech {
  final String text;
  double remainingSeconds;

  _SpriteSpeech({required this.text, required this.remainingSeconds});
}
