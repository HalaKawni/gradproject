import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/game_parser.dart';
import '../language/game_runtime.dart';
import '../models/fourth_demo_project.dart';

class FourthDemoController extends ChangeNotifier {
  static const String storageKey = 'fourth_demo_course_builder_project';
  static const double stepSize = 48;
  static const double movementAnimationSeconds = 0.12;
  static const double _jumpVelocity = 430;
  static const double _defaultGravity = 980;
  static const double _groundControlSpeed = 260;

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
  final GameParser _parser = const GameParser();
  final GameRuntime _runtime = const GameRuntime();
  final Map<String, _SpriteMotion> _motions = <String, _SpriteMotion>{};
  final Map<String, _PhysicsBody> _physicsBodies = <String, _PhysicsBody>{};
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  String? _continuousHorizontalSpriteId;
  double _continuousHorizontalVelocity = 0;

  FourthDemoSprite? get selectedSprite => project.selectedSprite;

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
    if (isPlaying) {
      return;
    }
    final nextCode = Map<String, String>.from(project.codeBySpriteId);
    nextCode[project.selectedSpriteId] = code;
    project = project.copyWith(codeBySpriteId: nextCode);
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

    final parsed = _parser.parse(code: selectedCode, targetSpriteId: sprite.id);
    if (!parsed.isValid) {
      codeError = parsed.diagnostic?.message;
      statusMessage = parsed.diagnostic?.message ?? 'Check your code.';
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
    _motions.clear();
    _physicsBodies.clear();
    _pressedKeys.clear();
    _stopContinuousHorizontalMovement();
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
    final hit = _spriteAt(worldPosition);
    if (hit == null || hit.destroyed || !hit.enabled) {
      return;
    }
    _runHandlers('onClick', eventSpriteId: hit.id);
  }

  void handleUpdate([double dt = 1 / 60]) {
    if (!isPlaying) {
      return;
    }
    _advanceMotions(dt);
    _advancePhysics(dt);
    _advanceContinuousHorizontalMovement(dt);
    _runHandlers('onUpdate');
  }

  void beginDrag(Offset worldPosition) {
    if (isPlaying ||
        stageTool != FourthDemoStageTool.move &&
            stageTool != FourthDemoStageTool.select) {
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
  }

  void endDrag() {
    draggingSpriteId = null;
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
    project = project.copyWith(
      sprites: sprites,
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
      x: 18,
      y: 18 + project.widgets.length * 34,
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

  FourthDemoSound addSound(String name) {
    final sound = FourthDemoSound(
      id: 'sound-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
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

  void _runHandlers(
    String event, {
    LogicalKeyboardKey? key,
    String? eventSpriteId,
  }) {
    final handlers = project.events.where((handler) => handler.event == event);
    for (final handler in handlers) {
      if (eventSpriteId != null && handler.targetSpriteId != eventSpriteId) {
        continue;
      }
      for (final action in handler.actions) {
        _runAction(handler.targetSpriteId, action, key);
      }
    }
    _handleCollections();
  }

  void _runAction(
    String spriteId,
    FourthDemoAction action,
    LogicalKeyboardKey? key,
  ) {
    if (action.type == FourthDemoActionType.ifCondition) {
      final shouldRun = _runtime.evaluateCondition(
        action.condition,
        GameRuntimeContext(
          project: project,
          currentSpriteId: spriteId,
          key: key,
        ),
      );
      if (shouldRun) {
        for (final child in action.actions) {
          _runAction(spriteId, child, key);
        }
      } else {
        for (final child in action.elseActions) {
          _runAction(spriteId, child, key);
        }
      }
      return;
    }

    if (action.type == FourthDemoActionType.setBackground) {
      project = project.copyWith(
        settings: project.settings.copyWith(background: action.text),
      );
      statusMessage = 'Background set to ${action.text}.';
      notifyListeners();
      return;
    }

    final index = _spriteIndexForAction(spriteId, action);
    if (index == -1) {
      codeError = "I can't find a sprite named ${action.receiver}.";
      statusMessage = codeError!;
      notifyListeners();
      return;
    }
    final sprite = project.sprites[index];
    if (sprite.destroyed || !sprite.enabled) {
      return;
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
            direction.dx * _groundControlSpeed * speed * amount.sign,
          );
          next = sprite.copyWith(
            facing: _facingForHorizontal(direction.dx, sprite.facing),
          );
          break;
        }
        if (_canUseContinuousHorizontalMovement(key, direction)) {
          _setContinuousHorizontalMovement(
            sprite,
            direction.dx * _groundControlSpeed * speed * amount.sign,
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
      case FourthDemoActionType.say:
        statusMessage = action.text.isEmpty ? 'Hello!' : action.text;
        shouldNotify = true;
      case FourthDemoActionType.wait:
      case FourthDemoActionType.repeat:
      case FourthDemoActionType.times:
      case FourthDemoActionType.loop:
      case FourthDemoActionType.ifTouching:
      case FourthDemoActionType.ifCondition:
      case FourthDemoActionType.setBackground:
        statusMessage = 'That block is saved for the next lesson.';
        shouldNotify = true;
    }
    final sprites = List<FourthDemoSprite>.from(project.sprites)
      ..[index] = next;
    project = project.copyWith(sprites: sprites);
    if (shouldNotify) {
      notifyListeners();
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
    final receiver = _normalizeSpriteLookup(action.receiver);
    return project.sprites.indexWhere(
      (sprite) =>
          _normalizeSpriteLookup(sprite.id) == receiver ||
          _normalizeSpriteLookup(sprite.name) == receiver,
    );
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

    final horizontalDirection = _horizontalInputDirection();
    final speed = _speedMultiplier(sprite.speed);
    final horizontalVelocity = _continuousHorizontalSpriteId == sprite.id
        ? _continuousHorizontalVelocity
        : horizontalDirection * _groundControlSpeed * speed;
    body
      ..velocity = Offset(horizontalVelocity, -_jumpVelocity)
      ..grounded = false;
    _motions.remove(sprite.id);

    return sprite.copyWith(
      facing: _facingForHorizontal(horizontalDirection, sprite.facing),
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

  double _horizontalInputDirection() {
    final movingRight =
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD);
    final movingLeft =
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA);
    if (movingRight == movingLeft) {
      return 0;
    }
    return movingRight ? 1 : -1;
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
