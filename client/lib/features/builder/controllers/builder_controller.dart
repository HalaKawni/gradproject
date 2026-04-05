import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/auth_session.dart';
import '../../../services/api_service.dart';
import '../models/builder_playback_state.dart';
import '../models/builder_project.dart';
import '../models/builder_validation.dart';
import '../models/entity_data.dart';
import '../models/level_settings.dart';
import '../models/logic_command.dart';
import '../models/tile_data.dart';
import '../shared/builder_tool.dart';

class BuilderController extends ChangeNotifier {
  static const int _worldExpansionChunk = 8;
  static const int _worldExpansionTriggerPadding = 2;
  static const Duration _playbackStepDuration = Duration(milliseconds: 450);

  BuilderProject project;
  final AuthSession session;

  BuilderTool currentTool = BuilderTool.select;

  int? selectedX;
  int? selectedY;

  BuilderValidation validation = BuilderValidation.initial();
  BuilderPlaybackState? playbackState;
  String? logicStatusMessage;

  String? savedProjectId;
  bool isSaving = false;
  bool isLoading = false;
  String? lastMessage;

  Timer? _playbackTimer;

  bool get hasBlockingValidationIssues {
    return validation.errors.isNotEmpty || validation.warnings.isNotEmpty;
  }

  bool get isPlaybackRunning => playbackState?.isPlaying ?? false;

  List<LogicCommandType> get solutionCommands {
    return project.solutionCommands
        .map(LogicCommandTypeExtension.fromString)
        .toList(growable: false);
  }

  BuilderController({required this.project, required this.session}) {
    project = _normalizeProject(project);
    _runValidation();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void setTool(BuilderTool tool) {
    _clearPlaybackPreview();
    currentTool = tool;
    notifyListeners();
  }

  void setTitle(String title) {
    project = project.copyWith(title: title);
    notifyListeners();
  }

  void setTileSize(double tileSize) {
    _clearPlaybackPreview();
    final normalizedTileSize = LevelSettings.clampTileSize(tileSize);

    if (project.settings.tileSize == normalizedTileSize) {
      return;
    }

    project = project.copyWith(
      settings: project.settings.copyWith(tileSize: normalizedTileSize),
      tiles: _enforceProtectedGroundTiles(
        tiles: project.tiles,
        settings: project.settings.copyWith(tileSize: normalizedTileSize),
      ),
    );
    notifyListeners();
  }

  void setGridSizePreset(BuilderGridSizePreset preset) {
    _clearPlaybackPreview();
    final previousSettings = project.settings;
    final nextSettings = previousSettings.copyWith(
      columns: preset.columns,
      rows: preset.rows,
      tileSize: preset.tileSize,
    );

    final nextTiles = _enforceProtectedGroundTiles(
      tiles: _remapTilesForSettings(previousSettings, nextSettings),
      settings: nextSettings,
    );
    final nextEntities = _remapEntitiesForSettings(previousSettings, nextSettings);

    project = project.copyWith(
      settings: nextSettings,
      tiles: nextTiles,
      entities: nextEntities,
    );

    if (selectedX != null && selectedY != null) {
      selectedX = _remapGridIndex(
        index: selectedX!,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.columns - 1,
      );
      selectedY = _remapGridIndex(
        index: selectedY!,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.rows - 1,
      );
    }

    _runValidation();
    notifyListeners();
  }

  void applyToolAt(BuilderTool tool, int x, int y) {
    _clearPlaybackPreview();
    selectedX = x;
    selectedY = y;

    switch (tool) {
      case BuilderTool.select:
        break;
      case BuilderTool.erase:
        _eraseAt(x, y);
        break;
      case BuilderTool.ground:
        _placeTile('ground', x, y);
        break;
      case BuilderTool.obstacle:
        _placeTile('obstacle', x, y);
        break;
      case BuilderTool.player:
        _placeUniqueEntity('playerStart', x, y);
        break;
      case BuilderTool.collectable:
        _placeEntity('collectable', x, y);
        break;
      case BuilderTool.goal:
        _placeUniqueEntity('goal', x, y);
        break;
    }

    _extendWorldIfNeeded(x);
    _runValidation();
    notifyListeners();
  }

  void selectAt(int x, int y) {
    selectedX = x;
    selectedY = y;
    notifyListeners();
  }

  TileData? tileAt(int x, int y) {
    for (final tile in project.tiles) {
      if (tile.x == x && tile.y == y) {
        return tile;
      }
    }

    return null;
  }

  EntityData? entityAt(int x, int y) {
    for (final entity in project.entities) {
      if (entity.x == x && entity.y == y) {
        return entity;
      }
    }

    return null;
  }

  EntityData? entityById(String entityId) {
    for (final entity in project.entities) {
      if (entity.id == entityId) {
        return entity;
      }
    }

    return null;
  }

  void moveTile(int fromX, int fromY, int toX, int toY) {
    _clearPlaybackPreview();
    final sourceTile = tileAt(fromX, fromY);

    if (sourceTile == null) {
      return;
    }

    if (fromX == toX && fromY == toY) {
      selectAt(toX, toY);
      return;
    }

    final destinationTile = tileAt(toX, toY);
    final updatedTiles = List<TileData>.from(project.tiles)
      ..removeWhere(
        (tile) =>
            (tile.x == fromX && tile.y == fromY) ||
            (tile.x == toX && tile.y == toY),
      );

    updatedTiles.add(sourceTile.copyWith(x: toX, y: toY));

    if (destinationTile != null) {
      updatedTiles.add(destinationTile.copyWith(x: fromX, y: fromY));
    }

    project = project.copyWith(
      tiles: _enforceProtectedGroundTiles(
        tiles: updatedTiles,
        settings: project.settings,
      ),
    );
    selectedX = toX;
    selectedY = toY;
    _extendWorldIfNeeded(toX);
    _runValidation();
    notifyListeners();
  }

  void moveEntity(String entityId, int toX, int toY) {
    _clearPlaybackPreview();
    final sourceEntity = entityById(entityId);

    if (sourceEntity == null) {
      return;
    }

    if (sourceEntity.x == toX && sourceEntity.y == toY) {
      selectAt(toX, toY);
      return;
    }

    final destinationEntity = entityAt(toX, toY);
    final updatedEntities = List<EntityData>.from(project.entities)
      ..removeWhere(
        (entity) =>
            entity.id == entityId || (entity.x == toX && entity.y == toY),
      );

    updatedEntities.add(sourceEntity.copyWith(x: toX, y: toY));

    if (destinationEntity != null && destinationEntity.id != entityId) {
      updatedEntities.add(
        destinationEntity.copyWith(x: sourceEntity.x, y: sourceEntity.y),
      );
    }

    project = project.copyWith(entities: updatedEntities);
    selectedX = toX;
    selectedY = toY;
    _extendWorldIfNeeded(toX);
    _runValidation();
    notifyListeners();
  }

  void placeAt(int x, int y) {
    applyToolAt(currentTool, x, y);
  }

  void addSolutionCommand(LogicCommandType command) {
    _clearPlaybackPreview();
    final nextCommands = List<String>.from(project.solutionCommands)
      ..add(command.value);
    project = project.copyWith(solutionCommands: nextCommands);
    logicStatusMessage = 'Added ${command.label}.';
    notifyListeners();
  }

  void moveSolutionCommand(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= project.solutionCommands.length ||
        toIndex < 0 ||
        toIndex >= project.solutionCommands.length ||
        fromIndex == toIndex) {
      return;
    }

    _clearPlaybackPreview();
    final nextCommands = List<String>.from(project.solutionCommands);
    final movedCommand = nextCommands.removeAt(fromIndex);
    nextCommands.insert(toIndex, movedCommand);
    project = project.copyWith(solutionCommands: nextCommands);
    logicStatusMessage = 'Updated the solution order.';
    notifyListeners();
  }

  void removeSolutionCommandAt(int index) {
    if (index < 0 || index >= project.solutionCommands.length) {
      return;
    }

    _clearPlaybackPreview();
    final removedCommand = LogicCommandTypeExtension.fromString(
      project.solutionCommands[index],
    );
    final nextCommands = List<String>.from(project.solutionCommands)
      ..removeAt(index);
    project = project.copyWith(solutionCommands: nextCommands);
    logicStatusMessage = 'Removed ${removedCommand.label}.';
    notifyListeners();
  }

  void clearSolutionCommands() {
    if (project.solutionCommands.isEmpty) {
      return;
    }

    _clearPlaybackPreview();
    project = project.copyWith(solutionCommands: const []);
    logicStatusMessage = 'Cleared the solution steps.';
    notifyListeners();
  }

  void stopPlayback() {
    if (!isPlaybackRunning) {
      _clearPlaybackPreview();
      notifyListeners();
      return;
    }

    _finishPlayback(
      nextState: null,
      message: 'Playback stopped.',
    );
  }

  void playSolution() {
    _clearPlaybackPreview();

    final playerStart = _playerStartEntity;
    if (playerStart == null) {
      logicStatusMessage = 'Add a player start before testing the level.';
      notifyListeners();
      return;
    }

    if (project.solutionCommands.isEmpty) {
      logicStatusMessage = 'Add at least one arrow block before pressing play.';
      notifyListeners();
      return;
    }

    final startPosition = _resolveFallingPosition(
      startX: playerStart.x,
      startY: playerStart.y,
      collectedCollectableIds: _collectablesAt(playerStart.x, playerStart.y),
    );

    if (startPosition.fellOutOfLevel) {
      logicStatusMessage =
          'The player falls out of the level because there is no ground below.';
      notifyListeners();
      return;
    }

    playbackState = BuilderPlaybackState(
      playerX: startPosition.playerX,
      playerY: startPosition.playerY,
      fromPlayerX: startPosition.playerX,
      fromPlayerY: startPosition.playerY,
      toPlayerX: startPosition.playerX,
      toPlayerY: startPosition.playerY,
      activeCommandIndex: -1,
      movementStartedAtMs: DateTime.now().millisecondsSinceEpoch,
      animatedCommand: null,
      isPlaying: true,
      hasSucceeded: false,
      hasFailed: false,
      collectedCollectableIds: startPosition.collectedCollectableIds,
    );
    logicStatusMessage = 'Playing solution...';
    notifyListeners();

    _playbackTimer = Timer.periodic(_playbackStepDuration, (_) {
      _runNextSolutionStep();
    });
  }

  void _placeTile(String type, int x, int y) {
    final updatedTiles = List<TileData>.from(project.tiles);
    updatedTiles.removeWhere((tile) => tile.x == x && tile.y == y);
    updatedTiles.add(TileData(type: type, x: x, y: y));
    project = project.copyWith(
      tiles: _enforceProtectedGroundTiles(
        tiles: updatedTiles,
        settings: project.settings,
      ),
    );
  }

  void _placeEntity(String type, int x, int y) {
    final updatedEntities = List<EntityData>.from(project.entities);

    updatedEntities.removeWhere((entity) => entity.x == x && entity.y == y);
    updatedEntities.add(
      EntityData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        x: x,
        y: y,
      ),
    );

    project = project.copyWith(entities: updatedEntities);
  }

  void _placeUniqueEntity(String type, int x, int y) {
    final updatedEntities = List<EntityData>.from(project.entities);

    updatedEntities.removeWhere((entity) => entity.type == type);
    updatedEntities.removeWhere((entity) => entity.x == x && entity.y == y);

    updatedEntities.add(
      EntityData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        x: x,
        y: y,
      ),
    );

    project = project.copyWith(entities: updatedEntities);
  }

  void _eraseAt(int x, int y) {
    final updatedTiles = List<TileData>.from(project.tiles)
      ..removeWhere((tile) => tile.x == x && tile.y == y);

    final updatedEntities = List<EntityData>.from(project.entities)
      ..removeWhere((entity) => entity.x == x && entity.y == y);

    project = project.copyWith(
      tiles: _enforceProtectedGroundTiles(
        tiles: updatedTiles,
        settings: project.settings,
      ),
      entities: updatedEntities,
    );
  }

  void clearLevel() {
    _clearPlaybackPreview();
    selectedX = null;
    selectedY = null;
    project = project.copyWith(
      tiles: BuilderProject.buildGroundTemplate(project.settings),
      entities: const [],
      solutionCommands: const [],
    );
    logicStatusMessage = 'Level cleared.';
    lastMessage = 'Level cleared.';
    notifyListeners();
  }

  void clearSelection() {
    selectedX = null;
    selectedY = null;
    notifyListeners();
  }

  Future<bool> saveProject() async {
    try {
      _runValidation();

      final normalizedTitle = project.title.trim().isEmpty
          ? 'Untitled'
          : project.title.trim();

      if (normalizedTitle != project.title) {
        project = project.copyWith(title: normalizedTitle);
      }

      isSaving = true;
      lastMessage = null;
      notifyListeners();

      final projectJson = project.toJson();

      if (savedProjectId == null) {
        final response = await ApiService.createBuilderProject(
          authToken: session.token,
          projectJson: projectJson,
        );

        if (response['success'] == true) {
          savedProjectId = response['data']['_id'];
          lastMessage = response['message'] ?? 'Project created successfully.';
          return true;
        } else {
          lastMessage = response['message'] ?? 'Failed to create project.';
          return false;
        }
      } else {
        final response = await ApiService.updateBuilderProject(
          authToken: session.token,
          projectId: savedProjectId!,
          projectJson: projectJson,
        );

        if (response['success'] == true) {
          lastMessage = response['message'] ?? 'Project updated successfully.';
          return true;
        } else {
          lastMessage = response['message'] ?? 'Failed to update project.';
          return false;
        }
      }
    } catch (e) {
      lastMessage = 'Save failed: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadProject(String projectId) async {
    try {
      isLoading = true;
      lastMessage = null;
      notifyListeners();

      final response = await ApiService.getBuilderProjectById(
        authToken: session.token,
        projectId: projectId,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final draftData = Map<String, dynamic>.from(data['draftData']);

        project = _normalizeProject(BuilderProject.fromJson(draftData));
        savedProjectId = data['_id'];

        _runValidation();
        lastMessage = 'Project loaded successfully.';
      } else {
        lastMessage = response['message'] ?? 'Failed to load project.';
      }
    } catch (e) {
      lastMessage = 'Load failed: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _runValidation() {
    validation = BuilderValidation.initial();
  }

  BuilderProject _normalizeProject(BuilderProject input) {
    final normalizedSettings = input.settings.copyWith(
      tileSize: LevelSettings.clampTileSize(input.settings.tileSize),
    );
    final normalizedTiles = _enforceProtectedGroundTiles(
      tiles: input.tiles
          .map((tile) => tile.copyWith(type: _normalizeTileType(tile.type)))
          .toList(),
      settings: normalizedSettings,
    );

    final normalizedEntities = input.entities
        .map(
          (entity) => entity.copyWith(type: _normalizeEntityType(entity.type)),
        )
        .toList();

    final nextTiles = normalizedTiles.isEmpty
        ? BuilderProject.buildGroundTemplate(normalizedSettings)
        : normalizedTiles;

    return input.copyWith(
      settings: normalizedSettings,
      tiles: nextTiles,
      entities: normalizedEntities,
    );
  }

  String _normalizeTileType(String type) {
    switch (type) {
      case 'floor':
        return 'ground';
      case 'wall':
        return 'obstacle';
      default:
        return type;
    }
  }

  String _normalizeEntityType(String type) {
    switch (type) {
      case 'pickup':
      case 'star':
        return 'collectable';
      default:
        return type;
    }
  }

  void _extendWorldIfNeeded(int targetX) {
    if (targetX < project.settings.columns - _worldExpansionTriggerPadding) {
      return;
    }

    final currentColumns = project.settings.columns;
    final nextColumns = currentColumns + _worldExpansionChunk;
    final nextSettings = project.settings.copyWith(columns: nextColumns);
    final appendedTiles = BuilderProject.buildGroundTemplate(
      nextSettings,
      startColumn: currentColumns,
      endColumnExclusive: nextColumns,
    );

    project = project.copyWith(
      settings: nextSettings,
      tiles: _enforceProtectedGroundTiles(
        tiles: List<TileData>.from(project.tiles)..addAll(appendedTiles),
        settings: nextSettings,
      ),
    );
  }

  EntityData? get _playerStartEntity {
    for (final entity in project.entities) {
      if (entity.type == 'playerStart') {
        return entity;
      }
    }

    return null;
  }

  EntityData? get _goalEntity {
    for (final entity in project.entities) {
      if (entity.type == 'goal') {
        return entity;
      }
    }

    return null;
  }

  void _runNextSolutionStep() {
    final currentPlayback = playbackState;
    if (currentPlayback == null || !currentPlayback.isPlaying) {
      _playbackTimer?.cancel();
      return;
    }

    final nextCommandIndex = currentPlayback.activeCommandIndex + 1;
    if (nextCommandIndex >= project.solutionCommands.length) {
      _finishPlayback(
        nextState: currentPlayback.copyWith(
          isPlaying: false,
          hasFailed: true,
        ),
        message: _buildIncompleteRunMessage(currentPlayback),
      );
      return;
    }

    final command = LogicCommandTypeExtension.fromString(
      project.solutionCommands[nextCommandIndex],
    );
    final nextX = currentPlayback.playerX + command.deltaX;
    final nextY = currentPlayback.playerY + command.deltaY;

    if (!_isInBounds(nextX, nextY)) {
      _finishPlayback(
        nextState: currentPlayback.copyWith(
          activeCommandIndex: nextCommandIndex,
          isPlaying: false,
          hasFailed: true,
        ),
        message: '${command.label} goes outside the level.',
      );
      return;
    }

    if (_isSolidTile(nextX, nextY)) {
      _finishPlayback(
        nextState: currentPlayback.copyWith(
          activeCommandIndex: nextCommandIndex,
          isPlaying: false,
          hasFailed: true,
        ),
        message: '${command.label} is blocked by a tile.',
      );
      return;
    }

    final nextCollectedIds = <String>{
      ...currentPlayback.collectedCollectableIds,
      ..._collectablesAt(nextX, nextY),
    };
    final fallResult = _resolveFallingPosition(
      startX: nextX,
      startY: nextY,
      collectedCollectableIds: nextCollectedIds,
    );

    if (fallResult.fellOutOfLevel) {
      _finishPlayback(
        nextState: currentPlayback.copyWith(
          playerX: fallResult.playerX,
          playerY: fallResult.playerY,
          activeCommandIndex: nextCommandIndex,
          isPlaying: false,
          hasFailed: true,
          collectedCollectableIds: fallResult.collectedCollectableIds,
        ),
        message: '${command.label} makes the player fall out of the level.',
      );
      return;
    }

    final nextPlayback = currentPlayback.copyWith(
      playerX: fallResult.playerX,
      playerY: fallResult.playerY,
      fromPlayerX: currentPlayback.playerX,
      fromPlayerY: currentPlayback.playerY,
      toPlayerX: fallResult.playerX,
      toPlayerY: fallResult.playerY,
      activeCommandIndex: nextCommandIndex,
      movementStartedAtMs: DateTime.now().millisecondsSinceEpoch,
      animatedCommand: command,
      collectedCollectableIds: fallResult.collectedCollectableIds,
    );

    if (_hasSolvedLevel(nextPlayback)) {
      _finishPlayback(
        nextState: nextPlayback.copyWith(
          isPlaying: false,
          hasSucceeded: true,
        ),
        message: 'The player collected everything and reached the goal.',
      );
      return;
    }

    if (nextCommandIndex == project.solutionCommands.length - 1) {
      _finishPlayback(
        nextState: nextPlayback.copyWith(
          isPlaying: false,
          hasFailed: true,
        ),
        message: _buildIncompleteRunMessage(nextPlayback),
      );
      return;
    }

    playbackState = nextPlayback;
    logicStatusMessage =
        'Step ${nextCommandIndex + 1} of ${project.solutionCommands.length}';
    notifyListeners();
  }

  void _finishPlayback({
    required BuilderPlaybackState? nextState,
    required String message,
  }) {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    playbackState = nextState;
    logicStatusMessage = message;
    notifyListeners();
  }

  void _clearPlaybackPreview() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    playbackState = null;
  }

  bool _isInBounds(int x, int y) {
    return x >= 0 &&
        x < project.settings.columns &&
        y >= 0 &&
        y < project.settings.rows;
  }

  bool _isSolidTile(int x, int y) {
    return tileAt(x, y) != null;
  }

  _ResolvedPlaybackPosition _resolveFallingPosition({
    required int startX,
    required int startY,
    required Set<String> collectedCollectableIds,
  }) {
    var currentY = startY;
    final nextCollectedCollectables = <String>{...collectedCollectableIds};

    while (true) {
      final belowY = currentY + 1;

      if (belowY >= project.settings.rows) {
        return _ResolvedPlaybackPosition(
          playerX: startX,
          playerY: currentY,
          collectedCollectableIds: nextCollectedCollectables,
          fellOutOfLevel: true,
        );
      }

      if (_isSolidTile(startX, belowY)) {
        return _ResolvedPlaybackPosition(
          playerX: startX,
          playerY: currentY,
          collectedCollectableIds: nextCollectedCollectables,
          fellOutOfLevel: false,
        );
      }

      currentY = belowY;
      nextCollectedCollectables.addAll(_collectablesAt(startX, currentY));
    }
  }

  Set<String> _collectablesAt(int x, int y) {
    final collectableIds = <String>{};

    for (final entity in project.entities) {
      if (entity.type == 'collectable' && entity.x == x && entity.y == y) {
        collectableIds.add(entity.id);
      }
    }

    return collectableIds;
  }

  bool _hasSolvedLevel(BuilderPlaybackState state) {
    final goal = _goalEntity;
    if (goal == null) {
      return false;
    }

    final totalCollectables = project.entities
        .where((entity) => entity.type == 'collectable')
        .length;

    return state.playerX == goal.x &&
        state.playerY == goal.y &&
        state.collectedCollectableIds.length == totalCollectables;
  }

  String _buildIncompleteRunMessage(BuilderPlaybackState state) {
    final goal = _goalEntity;
    final totalCollectables = project.entities
        .where((entity) => entity.type == 'collectable')
        .length;

    if (goal == null) {
      return 'The run ended, but the level has no goal yet.';
    }

    if (state.collectedCollectableIds.length < totalCollectables) {
      final missingCollectables =
          totalCollectables - state.collectedCollectableIds.length;
      return 'The run ended before collecting all items. $missingCollectables collectable(s) are still missing.';
    }

    return 'The run ended before reaching the goal.';
  }

  List<TileData> _remapTilesForSettings(
    LevelSettings previousSettings,
    LevelSettings nextSettings,
  ) {
    final remappedTiles = <String, TileData>{};

    for (final tile in project.tiles) {
      final nextX = _remapGridIndex(
        index: tile.x,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.columns - 1,
      );
      final nextY = _remapGridIndex(
        index: tile.y,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.rows - 1,
      );

      remappedTiles['$nextX:$nextY'] = tile.copyWith(x: nextX, y: nextY);
    }

    return remappedTiles.values.toList();
  }

  List<TileData> _enforceProtectedGroundTiles({
    required List<TileData> tiles,
    required LevelSettings settings,
  }) {
    final tileMap = <String, TileData>{};

    for (final tile in tiles) {
      final normalizedX = tile.x.clamp(0, settings.columns - 1);
      final normalizedY = tile.y.clamp(0, settings.rows - 1);
      tileMap['$normalizedX:$normalizedY'] = tile.copyWith(
        x: normalizedX,
        y: normalizedY,
      );
    }

    final groundRowCount = LevelSettings.requiredGroundRowsForTileSize(
      settings.tileSize,
    );
    final firstGroundRow = settings.rows - groundRowCount < 0
        ? 0
        : settings.rows - groundRowCount;

    for (int y = firstGroundRow; y < settings.rows; y++) {
      for (int x = 0; x < settings.columns; x++) {
        tileMap['$x:$y'] = TileData(type: 'ground', x: x, y: y);
      }
    }

    return tileMap.values.toList();
  }

  List<EntityData> _remapEntitiesForSettings(
    LevelSettings previousSettings,
    LevelSettings nextSettings,
  ) {
    final remappedEntities = <String, EntityData>{};

    for (final entity in project.entities) {
      final nextX = _remapGridIndex(
        index: entity.x,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.columns - 1,
      );
      final nextY = _remapGridIndex(
        index: entity.y,
        previousTileSize: previousSettings.tileSize,
        nextTileSize: nextSettings.tileSize,
        maxIndex: nextSettings.rows - 1,
      );

      remappedEntities['$nextX:$nextY'] = entity.copyWith(x: nextX, y: nextY);
    }

    return remappedEntities.values.toList();
  }

  int _remapGridIndex({
    required int index,
    required double previousTileSize,
    required double nextTileSize,
    required int maxIndex,
  }) {
    final centeredPixel = (index + 0.5) * previousTileSize;
    final nextIndex = ((centeredPixel / nextTileSize) - 0.5).round();

    if (nextIndex < 0) {
      return 0;
    }

    if (nextIndex > maxIndex) {
      return maxIndex;
    }

    return nextIndex;
  }
}

class _ResolvedPlaybackPosition {
  final int playerX;
  final int playerY;
  final Set<String> collectedCollectableIds;
  final bool fellOutOfLevel;

  const _ResolvedPlaybackPosition({
    required this.playerX,
    required this.playerY,
    required this.collectedCollectableIds,
    required this.fellOutOfLevel,
  });
}
