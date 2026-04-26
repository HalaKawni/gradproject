import 'dart:async';

import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';
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
  final bool requireAllCollectablesForSuccess;
  final bool useAdminLevelApi;

  BuilderTool currentTool = BuilderTool.ground;

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
  _PlaybackPlan? _playbackPlan;

  bool get hasBlockingValidationIssues {
    return validation.errors.isNotEmpty || validation.warnings.isNotEmpty;
  }

  bool get isPlaybackRunning => playbackState?.isPlaying ?? false;

  List<LogicCommandNode> get solutionCommands =>
      List<LogicCommandNode>.unmodifiable(project.solutionCommands);

  int get logicCommandBlockCount =>
      _countSolutionCommandBlocks(project.solutionCommands);

  int get totalCollectableCount =>
      project.entities.where((entity) => entity.type == 'collectable').length;

  int get collectedCollectableCount =>
      playbackState?.collectedCollectableIds.length ?? 0;

  BuilderController({
    required this.project,
    required this.session,
    this.requireAllCollectablesForSuccess = true,
    this.useAdminLevelApi = false,
  }) {
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
    final nextEntities = _remapEntitiesForSettings(
      previousSettings,
      nextSettings,
    );

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
    if (selectedX == x && selectedY == y) {
      return;
    }

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

  void deleteTileAt(int x, int y) {
    _clearPlaybackPreview();
    final sourceTile = tileAt(x, y);

    if (sourceTile == null) {
      return;
    }

    final updatedTiles = List<TileData>.from(project.tiles)
      ..removeWhere((tile) => tile.x == x && tile.y == y);

    project = project.copyWith(
      tiles: _enforceProtectedGroundTiles(
        tiles: updatedTiles,
        settings: project.settings,
      ),
    );
    selectedX = x;
    selectedY = y;
    _runValidation();
    notifyListeners();
  }

  void deleteEntity(String entityId) {
    _clearPlaybackPreview();
    final sourceEntity = entityById(entityId);

    if (sourceEntity == null) {
      return;
    }

    final updatedEntities = List<EntityData>.from(project.entities)
      ..removeWhere((entity) => entity.id == entityId);

    project = project.copyWith(entities: updatedEntities);
    selectedX = sourceEntity.x;
    selectedY = sourceEntity.y;
    _runValidation();
    notifyListeners();
  }

  void placeAt(int x, int y) {
    applyToolAt(currentTool, x, y);
  }

  String addSolutionCommand(
    LogicCommandType command, {
    String? parentLoopId,
    int? targetIndex,
  }) {
    _clearPlaybackPreview();
    final nextCommand = LogicCommandNode.action(command: command);
    project = project.copyWith(
      solutionCommands: _insertSolutionCommandNode(
        commands: project.solutionCommands,
        targetParentId: parentLoopId,
        targetIndex: targetIndex,
        node: nextCommand,
      ),
    );
    logicStatusMessage = parentLoopId == null
        ? 'Added ${command.label}.'
        : 'Added ${command.label} inside the loop.';
    notifyListeners();
    return nextCommand.id;
  }

  String addLoopCommand({String? parentLoopId, int? targetIndex}) {
    _clearPlaybackPreview();
    final nextLoop = LogicCommandNode.loop();
    project = project.copyWith(
      solutionCommands: _insertSolutionCommandNode(
        commands: project.solutionCommands,
        targetParentId: parentLoopId,
        targetIndex: targetIndex,
        node: nextLoop,
      ),
    );
    logicStatusMessage = parentLoopId == null
        ? 'Added a loop.'
        : 'Added a loop inside the loop.';
    notifyListeners();
    return nextLoop.id;
  }

  LogicCommandNode? solutionCommandById(String commandId) {
    return _findSolutionCommandLocation(
      project.solutionCommands,
      commandId,
    )?.node;
  }

  bool containsSolutionCommand(String commandId) {
    return solutionCommandById(commandId) != null;
  }

  bool canMoveSolutionCommand(String commandId, int offset) {
    final location = _findSolutionCommandLocation(
      project.solutionCommands,
      commandId,
    );
    if (location == null) {
      return false;
    }

    final siblingCount = _childCommandsForParent(
      project.solutionCommands,
      location.parentId,
    )?.length;
    if (siblingCount == null) {
      return false;
    }

    final nextIndex = location.index + offset;
    return nextIndex >= 0 && nextIndex < siblingCount;
  }

  bool moveSolutionCommandByOffset(String commandId, int offset) {
    final location = _findSolutionCommandLocation(
      project.solutionCommands,
      commandId,
    );
    if (location == null) {
      return false;
    }

    return moveSolutionCommand(
      commandId: commandId,
      targetLoopId: location.parentId,
      targetIndex: location.index + offset,
    );
  }

  bool moveSolutionCommand({
    required String commandId,
    String? targetLoopId,
    required int targetIndex,
  }) {
    final sourceLocation = _findSolutionCommandLocation(
      project.solutionCommands,
      commandId,
    );
    if (sourceLocation == null) {
      return false;
    }

    final resolvedTargetParentId = _resolveTargetLoopId(
      commands: project.solutionCommands,
      targetLoopId: targetLoopId,
    );
    final targetParentLocation = resolvedTargetParentId == null
        ? null
        : _findSolutionCommandLocation(
            project.solutionCommands,
            resolvedTargetParentId,
          );

    if (resolvedTargetParentId == commandId ||
        (targetParentLocation != null &&
            _pathStartsWith(targetParentLocation.path, sourceLocation.path))) {
      return false;
    }

    var adjustedTargetIndex = targetIndex;
    if (sourceLocation.parentId == resolvedTargetParentId &&
        adjustedTargetIndex > sourceLocation.index) {
      adjustedTargetIndex -= 1;
    }

    _clearPlaybackPreview();

    LogicCommandNode? movedCommand;
    final commandsWithoutSource = _removeSolutionCommandAtPath(
      commands: project.solutionCommands,
      path: sourceLocation.path,
      onRemoved: (removed) {
        movedCommand = removed;
      },
    );
    final commandToMove = movedCommand;
    if (commandToMove == null) {
      return false;
    }

    project = project.copyWith(
      solutionCommands: _insertSolutionCommandNode(
        commands: commandsWithoutSource,
        targetParentId: resolvedTargetParentId,
        targetIndex: adjustedTargetIndex,
        node: commandToMove,
      ),
    );
    logicStatusMessage = 'Updated the solution order.';
    notifyListeners();
    return true;
  }

  bool removeSolutionCommand(String commandId) {
    final location = _findSolutionCommandLocation(
      project.solutionCommands,
      commandId,
    );
    if (location == null) {
      return false;
    }

    _clearPlaybackPreview();
    project = project.copyWith(
      solutionCommands: _removeSolutionCommandAtPath(
        commands: project.solutionCommands,
        path: location.path,
      ),
    );
    logicStatusMessage = 'Removed ${location.node.label}.';
    notifyListeners();
    return true;
  }

  void clearSolutionCommands({
    String? statusMessage = 'Cleared the solution blocks.',
  }) {
    if (project.solutionCommands.isEmpty) {
      return;
    }

    _clearPlaybackPreview();
    project = project.copyWith(solutionCommands: const []);
    logicStatusMessage = statusMessage;
    notifyListeners();
  }

  void stopPlayback() {
    if (!isPlaybackRunning) {
      _clearPlaybackPreview();
      notifyListeners();
      return;
    }

    _finishPlayback(nextState: null, message: 'Playback stopped.');
  }

  void resetPlaybackPreview() {
    if (playbackState == null &&
        _playbackPlan == null &&
        _playbackTimer == null) {
      return;
    }

    _clearPlaybackPreview();
    logicStatusMessage = 'Preview reset.';
    notifyListeners();
  }

  void playSolution() {
    _clearPlaybackPreview();

    final playerStart = _playerStartEntity;
    if (playerStart == null) {
      logicStatusMessage = 'Add a player start before testing the level.';
      notifyListeners();
      return;
    }

    if (!_hasExecutableSolutionCommands(project.solutionCommands)) {
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

    final initialState = _PlaybackSimulationState(
      playerX: startPosition.playerX,
      playerY: startPosition.playerY,
      collectedCollectableIds: startPosition.collectedCollectableIds,
    );
    final playbackPlan = _buildPlaybackPlan(initialState);

    if (playbackPlan.steps.isEmpty) {
      logicStatusMessage = playbackPlan.outcome.message;
      notifyListeners();
      return;
    }

    _playbackPlan = playbackPlan;
    playbackState = BuilderPlaybackState(
      playerX: initialState.playerX,
      playerY: initialState.playerY,
      fromPlayerX: initialState.playerX,
      fromPlayerY: initialState.playerY,
      toPlayerX: initialState.playerX,
      toPlayerY: initialState.playerY,
      activeStepIndex: -1,
      totalStepCount: playbackPlan.steps.length,
      activeCommandId: null,
      movementStartedAtMs: DateTime.now().millisecondsSinceEpoch,
      animatedCommand: null,
      isPlaying: true,
      hasSucceeded: false,
      hasFailed: false,
      collectedCollectableIds: initialState.collectedCollectableIds,
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

  Future<bool> saveProject() {
    return _persistProject(
      createSuccessMessage: 'Project created successfully.',
      updateSuccessMessage: 'Project updated successfully.',
      createFailureMessage: 'Failed to create project.',
      updateFailureMessage: 'Failed to update project.',
      failurePrefix: 'Save failed',
    );
  }

  Future<bool> publishProject() {
    return _persistProject(
      createSuccessMessage: 'Project published successfully.',
      updateSuccessMessage: 'Project published successfully.',
      createFailureMessage: 'Failed to publish project.',
      updateFailureMessage: 'Failed to publish project.',
      failurePrefix: 'Publish failed',
      statusOverride: 'published',
    );
  }

  Future<void> loadProject(
    String projectId, {
    bool allowPublishedAccess = false,
  }) async {
    try {
      isLoading = true;
      lastMessage = null;
      notifyListeners();

      final response = useAdminLevelApi
          ? await ApiService.getAdminLevelById(
              authToken: session.token,
              levelId: projectId,
            )
          : allowPublishedAccess
          ? await ApiService.getPublishedBuilderProjectById(
              authToken: session.token,
              projectId: projectId,
            )
          : await ApiService.getBuilderProjectById(
              authToken: session.token,
              projectId: projectId,
            );

      if (response['success'] == true) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final rawDraftData = data['draftData'];
        final draftData = rawDraftData is Map
            ? Map<String, dynamic>.from(rawDraftData)
            : data;
        final loadedProject = BuilderProject.fromJson(draftData);

        project = _normalizeProject(
          loadedProject.copyWith(
            title: data['title']?.toString() ?? loadedProject.title,
            description:
                data['description']?.toString() ?? loadedProject.description,
            status: data['status']?.toString() ?? loadedProject.status,
          ),
        );
        savedProjectId = data['_id']?.toString() ?? projectId;

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

  Future<bool> _persistProject({
    required String createSuccessMessage,
    required String updateSuccessMessage,
    required String createFailureMessage,
    required String updateFailureMessage,
    required String failurePrefix,
    String? statusOverride,
  }) async {
    final previousStatus = project.status;

    try {
      _runValidation();

      final normalizedTitle = project.title.trim().isEmpty
          ? 'Untitled'
          : project.title.trim();

      if (normalizedTitle != project.title) {
        project = project.copyWith(title: normalizedTitle);
      }

      if (statusOverride != null && project.status != statusOverride) {
        project = project.copyWith(status: statusOverride);
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
          final data = response['data'];
          if (data is Map && data['_id'] != null) {
            savedProjectId = data['_id'].toString();
          }
          lastMessage = response['message'] ?? createSuccessMessage;
          return true;
        }

        if (statusOverride != null && previousStatus != project.status) {
          project = project.copyWith(status: previousStatus);
        }
        lastMessage = response['message'] ?? createFailureMessage;
        return false;
      }

      if (useAdminLevelApi) {
        final response = await ApiService.updateAdminLevel(
          authToken: session.token,
          levelId: savedProjectId!,
          levelJson: {
            'title': project.title,
            'description': project.description,
            'status': project.status,
            'draftData': projectJson,
          },
        );

        if (response['success'] == true) {
          lastMessage = response['message'] ?? updateSuccessMessage;
          return true;
        }

        if (statusOverride != null && previousStatus != project.status) {
          project = project.copyWith(status: previousStatus);
        }
        lastMessage = response['message'] ?? updateFailureMessage;
        return false;
      }

      final response = await ApiService.updateBuilderProject(
        authToken: session.token,
        projectId: savedProjectId!,
        projectJson: projectJson,
      );

      if (response['success'] == true) {
        lastMessage = response['message'] ?? updateSuccessMessage;
        return true;
      }

      if (statusOverride != null && previousStatus != project.status) {
        project = project.copyWith(status: previousStatus);
      }
      lastMessage = response['message'] ?? updateFailureMessage;
      return false;
    } catch (e) {
      if (statusOverride != null && previousStatus != project.status) {
        project = project.copyWith(status: previousStatus);
      }
      lastMessage = '$failurePrefix: $e';
      return false;
    } finally {
      isSaving = false;
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

  int _countSolutionCommandBlocks(List<LogicCommandNode> commands) {
    var total = 0;

    for (final command in commands) {
      total += 1;
      total += _countSolutionCommandBlocks(command.children);
    }

    return total;
  }

  bool _hasExecutableSolutionCommands(List<LogicCommandNode> commands) {
    for (final command in commands) {
      if (command.isAction) {
        return true;
      }

      if (_hasExecutableSolutionCommands(command.children)) {
        return true;
      }
    }

    return false;
  }

  String? _resolveTargetLoopId({
    required List<LogicCommandNode> commands,
    required String? targetLoopId,
  }) {
    if (targetLoopId == null) {
      return null;
    }

    final targetLocation = _findSolutionCommandLocation(commands, targetLoopId);
    if (targetLocation == null || !targetLocation.node.isLoop) {
      return null;
    }

    return targetLoopId;
  }

  List<LogicCommandNode> _insertSolutionCommandNode({
    required List<LogicCommandNode> commands,
    required String? targetParentId,
    int? targetIndex,
    required LogicCommandNode node,
  }) {
    final resolvedTargetParentId = _resolveTargetLoopId(
      commands: commands,
      targetLoopId: targetParentId,
    );

    if (resolvedTargetParentId == null) {
      final nextCommands = List<LogicCommandNode>.from(commands);
      final safeIndex = _clampInsertIndex(targetIndex, nextCommands.length);
      nextCommands.insert(safeIndex, node);
      return nextCommands;
    }

    final parentLocation = _findSolutionCommandLocation(
      commands,
      resolvedTargetParentId,
    );
    if (parentLocation == null || !parentLocation.node.isLoop) {
      final nextCommands = List<LogicCommandNode>.from(commands);
      final safeIndex = _clampInsertIndex(targetIndex, nextCommands.length);
      nextCommands.insert(safeIndex, node);
      return nextCommands;
    }

    return _insertSolutionCommandAtPath(
      commands: commands,
      parentPath: parentLocation.path,
      targetIndex: targetIndex,
      node: node,
    );
  }

  List<LogicCommandNode> _insertSolutionCommandAtPath({
    required List<LogicCommandNode> commands,
    required List<int> parentPath,
    required int? targetIndex,
    required LogicCommandNode node,
  }) {
    if (parentPath.isEmpty) {
      final nextCommands = List<LogicCommandNode>.from(commands);
      final safeIndex = _clampInsertIndex(targetIndex, nextCommands.length);
      nextCommands.insert(safeIndex, node);
      return nextCommands;
    }

    final nextCommands = List<LogicCommandNode>.from(commands);
    final parentIndex = parentPath.first;
    final parentNode = nextCommands[parentIndex];

    nextCommands[parentIndex] = parentNode.copyWith(
      children: _insertSolutionCommandAtPath(
        commands: parentNode.children,
        parentPath: parentPath.sublist(1),
        targetIndex: targetIndex,
        node: node,
      ),
    );

    return nextCommands;
  }

  List<LogicCommandNode> _removeSolutionCommandAtPath({
    required List<LogicCommandNode> commands,
    required List<int> path,
    void Function(LogicCommandNode removed)? onRemoved,
  }) {
    final nextCommands = List<LogicCommandNode>.from(commands);
    final currentIndex = path.first;

    if (path.length == 1) {
      final removed = nextCommands.removeAt(currentIndex);
      onRemoved?.call(removed);
      return nextCommands;
    }

    final currentNode = nextCommands[currentIndex];
    nextCommands[currentIndex] = currentNode.copyWith(
      children: _removeSolutionCommandAtPath(
        commands: currentNode.children,
        path: path.sublist(1),
        onRemoved: onRemoved,
      ),
    );

    return nextCommands;
  }

  List<LogicCommandNode>? _childCommandsForParent(
    List<LogicCommandNode> commands,
    String? parentId,
  ) {
    if (parentId == null) {
      return commands;
    }

    final parentLocation = _findSolutionCommandLocation(commands, parentId);
    if (parentLocation == null || !parentLocation.node.isLoop) {
      return null;
    }

    return parentLocation.node.children;
  }

  _SolutionCommandLocation? _findSolutionCommandLocation(
    List<LogicCommandNode> commands,
    String commandId, {
    String? parentId,
    List<int> currentPath = const [],
  }) {
    for (int index = 0; index < commands.length; index++) {
      final command = commands[index];
      final nextPath = [...currentPath, index];

      if (command.id == commandId) {
        return _SolutionCommandLocation(
          node: command,
          parentId: parentId,
          path: nextPath,
        );
      }

      if (!command.isLoop) {
        continue;
      }

      final nestedLocation = _findSolutionCommandLocation(
        command.children,
        commandId,
        parentId: command.id,
        currentPath: nextPath,
      );
      if (nestedLocation != null) {
        return nestedLocation;
      }
    }

    return null;
  }

  bool _pathStartsWith(List<int> value, List<int> prefix) {
    if (prefix.length > value.length) {
      return false;
    }

    for (int index = 0; index < prefix.length; index++) {
      if (value[index] != prefix[index]) {
        return false;
      }
    }

    return true;
  }

  int _clampInsertIndex(int? index, int length) {
    if (index == null) {
      return length;
    }

    if (index < 0) {
      return 0;
    }

    if (index > length) {
      return length;
    }

    return index;
  }

  _PlaybackPlan _buildPlaybackPlan(_PlaybackSimulationState initialState) {
    final steps = <_PlaybackPlanStep>[];
    var currentState = initialState;
    final maxStepCount = _computeMaxPlaybackSteps();

    for (final command in project.solutionCommands) {
      if (command.isLoop) {
        final loopResult = _appendLoopToPlan(
          loop: command,
          startState: currentState,
          committedSteps: steps,
          maxStepCount: maxStepCount,
        );
        currentState = loopResult.endingState;

        if (loopResult.outcome != null) {
          return _PlaybackPlan(steps: steps, outcome: loopResult.outcome!);
        }

        continue;
      }

      if (steps.length >= maxStepCount) {
        return _PlaybackPlan(
          steps: steps,
          outcome: _buildFailureOutcome(
            message: 'The run used too many steps.',
            state: currentState,
            activeCommandId: steps.isEmpty ? null : steps.last.commandId,
          ),
        );
      }

      final actionResult = _simulateActionCommand(
        commandNode: command,
        currentState: currentState,
      );
      if (!actionResult.wasSuccessful) {
        return _PlaybackPlan(
          steps: steps,
          outcome: _buildFailureOutcome(
            message: actionResult.failureMessage ?? 'The run failed.',
            state: actionResult.nextState,
            activeCommandId: command.id,
          ),
        );
      }

      steps.add(actionResult.step!);
      currentState = actionResult.nextState;

      if (actionResult.didSolveLevel) {
        return _PlaybackPlan(
          steps: steps,
          outcome: _buildSuccessOutcome(
            state: currentState,
            activeCommandId: command.id,
          ),
        );
      }
    }

    return _PlaybackPlan(
      steps: steps,
      outcome: _buildFailureOutcome(
        message: _buildIncompleteRunMessageFromState(currentState),
        state: currentState,
        activeCommandId: steps.isEmpty ? null : steps.last.commandId,
      ),
    );
  }

  _LoopPlanBuildResult _appendLoopToPlan({
    required LogicCommandNode loop,
    required _PlaybackSimulationState startState,
    required List<_PlaybackPlanStep> committedSteps,
    required int maxStepCount,
  }) {
    if (loop.children.isEmpty) {
      return _LoopPlanBuildResult(endingState: startState);
    }

    var currentState = startState;

    while (true) {
      final remainingBudget = maxStepCount - committedSteps.length;
      if (remainingBudget <= 0) {
        return _LoopPlanBuildResult(
          endingState: currentState,
          outcome: _buildFailureOutcome(
            message: 'The run used too many steps.',
            state: currentState,
            activeCommandId: loop.id,
          ),
        );
      }

      final iterationResult = _trySimulateSequenceOnce(
        nodes: loop.children,
        startState: currentState,
        stepBudget: remainingBudget,
      );

      switch (iterationResult.status) {
        case _TransactionalSequenceStatus.softFailure:
          return _LoopPlanBuildResult(endingState: currentState);
        case _TransactionalSequenceStatus.hardFailure:
          return _LoopPlanBuildResult(
            endingState: currentState,
            outcome: _buildFailureOutcome(
              message: iterationResult.message ?? 'The loop failed.',
              state: currentState,
              activeCommandId: iterationResult.activeCommandId ?? loop.id,
            ),
          );
        case _TransactionalSequenceStatus.success:
          if (iterationResult.steps.isEmpty) {
            return _LoopPlanBuildResult(endingState: currentState);
          }

          if (!_didStateChange(currentState, iterationResult.endingState)) {
            return _LoopPlanBuildResult(
              endingState: currentState,
              outcome: _buildFailureOutcome(
                message: 'The loop repeats without making progress.',
                state: currentState,
                activeCommandId: loop.id,
              ),
            );
          }

          committedSteps.addAll(iterationResult.steps);
          currentState = iterationResult.endingState;

          if (iterationResult.didSolveLevel) {
            return _LoopPlanBuildResult(
              endingState: currentState,
              outcome: _buildSuccessOutcome(
                state: currentState,
                activeCommandId: iterationResult.lastCommandId ?? loop.id,
              ),
            );
          }

          break;
      }
    }
  }

  _TransactionalSequenceResult _trySimulateSequenceOnce({
    required List<LogicCommandNode> nodes,
    required _PlaybackSimulationState startState,
    required int stepBudget,
  }) {
    final localSteps = <_PlaybackPlanStep>[];
    var currentState = startState;

    for (final command in nodes) {
      if (localSteps.length >= stepBudget) {
        return _TransactionalSequenceResult.hardFailure(
          endingState: startState,
          message: 'The run used too many steps.',
          activeCommandId: command.id,
        );
      }

      if (command.isLoop) {
        var nestedLoopState = currentState;

        while (true) {
          final remainingBudget = stepBudget - localSteps.length;
          if (remainingBudget <= 0) {
            return _TransactionalSequenceResult.hardFailure(
              endingState: startState,
              message: 'The run used too many steps.',
              activeCommandId: command.id,
            );
          }

          final nestedIteration = _trySimulateSequenceOnce(
            nodes: command.children,
            startState: nestedLoopState,
            stepBudget: remainingBudget,
          );

          if (nestedIteration.status ==
              _TransactionalSequenceStatus.softFailure) {
            break;
          }

          if (nestedIteration.status ==
              _TransactionalSequenceStatus.hardFailure) {
            return _TransactionalSequenceResult.hardFailure(
              endingState: startState,
              message: nestedIteration.message,
              activeCommandId: nestedIteration.activeCommandId ?? command.id,
            );
          }

          if (nestedIteration.steps.isEmpty) {
            break;
          }

          if (!_didStateChange(nestedLoopState, nestedIteration.endingState)) {
            return _TransactionalSequenceResult.hardFailure(
              endingState: startState,
              message: 'The loop repeats without making progress.',
              activeCommandId: command.id,
            );
          }

          localSteps.addAll(nestedIteration.steps);
          nestedLoopState = nestedIteration.endingState;

          if (nestedIteration.didSolveLevel) {
            return _TransactionalSequenceResult.success(
              endingState: nestedLoopState,
              steps: localSteps,
              didSolveLevel: true,
            );
          }
        }

        currentState = nestedLoopState;
        continue;
      }

      final actionResult = _simulateActionCommand(
        commandNode: command,
        currentState: currentState,
      );

      if (!actionResult.wasSuccessful) {
        return _TransactionalSequenceResult.softFailure(
          endingState: startState,
          message: actionResult.failureMessage,
          activeCommandId: command.id,
        );
      }

      localSteps.add(actionResult.step!);
      currentState = actionResult.nextState;

      if (actionResult.didSolveLevel) {
        return _TransactionalSequenceResult.success(
          endingState: currentState,
          steps: localSteps,
          didSolveLevel: true,
        );
      }
    }

    return _TransactionalSequenceResult.success(
      endingState: currentState,
      steps: localSteps,
      didSolveLevel: false,
    );
  }

  _ActionSimulationResult _simulateActionCommand({
    required LogicCommandNode commandNode,
    required _PlaybackSimulationState currentState,
  }) {
    final command = commandNode.command;
    if (command == null) {
      return _ActionSimulationResult.failure(
        message: 'A command is missing its action.',
        nextState: currentState,
      );
    }

    final nextX = currentState.playerX + command.deltaX;
    final nextY = currentState.playerY + command.deltaY;

    if (!_isInBounds(nextX, nextY)) {
      return _ActionSimulationResult.failure(
        message: '${command.label} goes outside the level.',
        nextState: currentState,
      );
    }

    if (_isSolidTile(nextX, nextY)) {
      return _ActionSimulationResult.failure(
        message: '${command.label} is blocked by a tile.',
        nextState: currentState,
      );
    }

    final nextCollectedIds = <String>{
      ...currentState.collectedCollectableIds,
      ..._collectablesAt(nextX, nextY),
    };
    final fallResult = _resolveFallingPosition(
      startX: nextX,
      startY: nextY,
      collectedCollectableIds: nextCollectedIds,
    );
    final nextState = _PlaybackSimulationState(
      playerX: fallResult.playerX,
      playerY: fallResult.playerY,
      collectedCollectableIds: fallResult.collectedCollectableIds,
    );

    if (fallResult.fellOutOfLevel) {
      return _ActionSimulationResult.failure(
        message: '${command.label} makes the player fall out of the level.',
        nextState: nextState,
      );
    }

    return _ActionSimulationResult.success(
      nextState: nextState,
      step: _PlaybackPlanStep(
        commandId: commandNode.id,
        command: command,
        fromPlayerX: currentState.playerX,
        fromPlayerY: currentState.playerY,
        toPlayerX: nextState.playerX,
        toPlayerY: nextState.playerY,
        collectedCollectableIds: nextState.collectedCollectableIds,
      ),
      didSolveLevel: _hasSolvedLevelFromState(nextState),
    );
  }

  _PlaybackPlanOutcome _buildFailureOutcome({
    required String message,
    required _PlaybackSimulationState state,
    required String? activeCommandId,
  }) {
    return _PlaybackPlanOutcome(
      hasSucceeded: false,
      hasFailed: true,
      message: message,
      playerX: state.playerX,
      playerY: state.playerY,
      collectedCollectableIds: state.collectedCollectableIds,
      activeCommandId: activeCommandId,
    );
  }

  _PlaybackPlanOutcome _buildSuccessOutcome({
    required _PlaybackSimulationState state,
    required String? activeCommandId,
  }) {
    return _PlaybackPlanOutcome(
      hasSucceeded: true,
      hasFailed: false,
      message: requireAllCollectablesForSuccess
          ? 'The player collected everything and reached the goal.'
          : 'The player reached the goal.',
      playerX: state.playerX,
      playerY: state.playerY,
      collectedCollectableIds: state.collectedCollectableIds,
      activeCommandId: activeCommandId,
    );
  }

  int _computeMaxPlaybackSteps() {
    final candidate = project.settings.columns * project.settings.rows * 4;
    if (candidate < 48) {
      return 48;
    }

    if (candidate > 600) {
      return 600;
    }

    return candidate;
  }

  bool _didStateChange(
    _PlaybackSimulationState previous,
    _PlaybackSimulationState next,
  ) {
    final collectedChanged =
        previous.collectedCollectableIds.length !=
            next.collectedCollectableIds.length ||
        !previous.collectedCollectableIds.containsAll(
          next.collectedCollectableIds,
        );

    return previous.playerX != next.playerX ||
        previous.playerY != next.playerY ||
        collectedChanged;
  }

  void _runNextSolutionStep() {
    final currentPlayback = playbackState;
    final currentPlaybackPlan = _playbackPlan;
    if (currentPlayback == null ||
        currentPlaybackPlan == null ||
        !currentPlayback.isPlaying) {
      _playbackTimer?.cancel();
      return;
    }

    final nextStepIndex = currentPlayback.activeStepIndex + 1;
    if (nextStepIndex >= currentPlaybackPlan.steps.length) {
      final outcome = currentPlaybackPlan.outcome;
      _finishPlayback(
        nextState: currentPlayback.copyWith(
          playerX: outcome.playerX,
          playerY: outcome.playerY,
          fromPlayerX: outcome.playerX,
          fromPlayerY: outcome.playerY,
          toPlayerX: outcome.playerX,
          toPlayerY: outcome.playerY,
          activeStepIndex: currentPlaybackPlan.steps.length - 1,
          activeCommandId: outcome.activeCommandId,
          animatedCommand: null,
          isPlaying: false,
          hasSucceeded: outcome.hasSucceeded,
          hasFailed: outcome.hasFailed,
          collectedCollectableIds: outcome.collectedCollectableIds,
        ),
        message: outcome.message,
      );
      return;
    }

    final nextStep = currentPlaybackPlan.steps[nextStepIndex];
    playbackState = currentPlayback.copyWith(
      playerX: nextStep.toPlayerX,
      playerY: nextStep.toPlayerY,
      fromPlayerX: nextStep.fromPlayerX,
      fromPlayerY: nextStep.fromPlayerY,
      toPlayerX: nextStep.toPlayerX,
      toPlayerY: nextStep.toPlayerY,
      activeStepIndex: nextStepIndex,
      totalStepCount: currentPlaybackPlan.steps.length,
      activeCommandId: nextStep.commandId,
      movementStartedAtMs: DateTime.now().millisecondsSinceEpoch,
      animatedCommand: nextStep.command,
      collectedCollectableIds: nextStep.collectedCollectableIds,
    );
    logicStatusMessage =
        'Step ${nextStepIndex + 1} of ${currentPlaybackPlan.steps.length}';
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
    _playbackPlan = null;
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

  bool _hasSolvedLevelFromState(_PlaybackSimulationState state) {
    final goal = _goalEntity;
    if (goal == null) {
      return false;
    }

    final isAtGoal = state.playerX == goal.x && state.playerY == goal.y;
    if (!isAtGoal) {
      return false;
    }

    if (!requireAllCollectablesForSuccess) {
      return true;
    }

    return state.collectedCollectableIds.length == totalCollectableCount;
  }

  String _buildIncompleteRunMessageFromState(_PlaybackSimulationState state) {
    final goal = _goalEntity;

    if (goal == null) {
      return 'The run ended, but the level has no goal yet.';
    }

    if (requireAllCollectablesForSuccess &&
        state.playerX == goal.x &&
        state.playerY == goal.y &&
        state.collectedCollectableIds.length < totalCollectableCount) {
      final missingCollectables =
          totalCollectableCount - state.collectedCollectableIds.length;
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

class _SolutionCommandLocation {
  final LogicCommandNode node;
  final String? parentId;
  final List<int> path;

  const _SolutionCommandLocation({
    required this.node,
    required this.parentId,
    required this.path,
  });

  int get index => path.last;
}

class _PlaybackSimulationState {
  final int playerX;
  final int playerY;
  final Set<String> collectedCollectableIds;

  const _PlaybackSimulationState({
    required this.playerX,
    required this.playerY,
    required this.collectedCollectableIds,
  });
}

class _PlaybackPlan {
  final List<_PlaybackPlanStep> steps;
  final _PlaybackPlanOutcome outcome;

  const _PlaybackPlan({required this.steps, required this.outcome});
}

class _PlaybackPlanStep {
  final String commandId;
  final LogicCommandType command;
  final int fromPlayerX;
  final int fromPlayerY;
  final int toPlayerX;
  final int toPlayerY;
  final Set<String> collectedCollectableIds;

  const _PlaybackPlanStep({
    required this.commandId,
    required this.command,
    required this.fromPlayerX,
    required this.fromPlayerY,
    required this.toPlayerX,
    required this.toPlayerY,
    required this.collectedCollectableIds,
  });
}

class _PlaybackPlanOutcome {
  final bool hasSucceeded;
  final bool hasFailed;
  final String message;
  final int playerX;
  final int playerY;
  final Set<String> collectedCollectableIds;
  final String? activeCommandId;

  const _PlaybackPlanOutcome({
    required this.hasSucceeded,
    required this.hasFailed,
    required this.message,
    required this.playerX,
    required this.playerY,
    required this.collectedCollectableIds,
    required this.activeCommandId,
  });
}

class _LoopPlanBuildResult {
  final _PlaybackSimulationState endingState;
  final _PlaybackPlanOutcome? outcome;

  const _LoopPlanBuildResult({required this.endingState, this.outcome});
}

class _ActionSimulationResult {
  final bool wasSuccessful;
  final _PlaybackSimulationState nextState;
  final _PlaybackPlanStep? step;
  final String? failureMessage;
  final bool didSolveLevel;

  const _ActionSimulationResult._({
    required this.wasSuccessful,
    required this.nextState,
    required this.step,
    required this.failureMessage,
    required this.didSolveLevel,
  });

  factory _ActionSimulationResult.success({
    required _PlaybackSimulationState nextState,
    required _PlaybackPlanStep step,
    required bool didSolveLevel,
  }) {
    return _ActionSimulationResult._(
      wasSuccessful: true,
      nextState: nextState,
      step: step,
      failureMessage: null,
      didSolveLevel: didSolveLevel,
    );
  }

  factory _ActionSimulationResult.failure({
    required String message,
    required _PlaybackSimulationState nextState,
  }) {
    return _ActionSimulationResult._(
      wasSuccessful: false,
      nextState: nextState,
      step: null,
      failureMessage: message,
      didSolveLevel: false,
    );
  }
}

enum _TransactionalSequenceStatus { success, softFailure, hardFailure }

class _TransactionalSequenceResult {
  final _TransactionalSequenceStatus status;
  final _PlaybackSimulationState endingState;
  final List<_PlaybackPlanStep> steps;
  final bool didSolveLevel;
  final String? message;
  final String? activeCommandId;

  const _TransactionalSequenceResult._({
    required this.status,
    required this.endingState,
    required this.steps,
    required this.didSolveLevel,
    required this.message,
    required this.activeCommandId,
  });

  factory _TransactionalSequenceResult.success({
    required _PlaybackSimulationState endingState,
    required List<_PlaybackPlanStep> steps,
    required bool didSolveLevel,
  }) {
    return _TransactionalSequenceResult._(
      status: _TransactionalSequenceStatus.success,
      endingState: endingState,
      steps: List<_PlaybackPlanStep>.unmodifiable(steps),
      didSolveLevel: didSolveLevel,
      message: null,
      activeCommandId: steps.isEmpty ? null : steps.last.commandId,
    );
  }

  factory _TransactionalSequenceResult.softFailure({
    required _PlaybackSimulationState endingState,
    required String? message,
    required String? activeCommandId,
  }) {
    return _TransactionalSequenceResult._(
      status: _TransactionalSequenceStatus.softFailure,
      endingState: endingState,
      steps: const [],
      didSolveLevel: false,
      message: message,
      activeCommandId: activeCommandId,
    );
  }

  factory _TransactionalSequenceResult.hardFailure({
    required _PlaybackSimulationState endingState,
    required String? message,
    required String? activeCommandId,
  }) {
    return _TransactionalSequenceResult._(
      status: _TransactionalSequenceStatus.hardFailure,
      endingState: endingState,
      steps: const [],
      didSolveLevel: false,
      message: message,
      activeCommandId: activeCommandId,
    );
  }

  String? get lastCommandId => steps.isEmpty ? null : steps.last.commandId;
}
