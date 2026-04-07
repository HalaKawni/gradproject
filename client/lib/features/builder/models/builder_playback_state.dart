import 'logic_command.dart';

class BuilderPlaybackState {
  final int playerX;
  final int playerY;
  final int fromPlayerX;
  final int fromPlayerY;
  final int toPlayerX;
  final int toPlayerY;
  final int activeStepIndex;
  final int totalStepCount;
  final String? activeCommandId;
  final int movementStartedAtMs;
  final LogicCommandType? animatedCommand;
  final bool isPlaying;
  final bool hasSucceeded;
  final bool hasFailed;
  final Set<String> collectedCollectableIds;

  const BuilderPlaybackState({
    required this.playerX,
    required this.playerY,
    required this.fromPlayerX,
    required this.fromPlayerY,
    required this.toPlayerX,
    required this.toPlayerY,
    required this.activeStepIndex,
    required this.totalStepCount,
    required this.activeCommandId,
    required this.movementStartedAtMs,
    required this.animatedCommand,
    required this.isPlaying,
    required this.hasSucceeded,
    required this.hasFailed,
    required this.collectedCollectableIds,
  });

  BuilderPlaybackState copyWith({
    int? playerX,
    int? playerY,
    int? fromPlayerX,
    int? fromPlayerY,
    int? toPlayerX,
    int? toPlayerY,
    int? activeStepIndex,
    int? totalStepCount,
    Object? activeCommandId = _playbackUnset,
    int? movementStartedAtMs,
    bool? isPlaying,
    bool? hasSucceeded,
    bool? hasFailed,
    Set<String>? collectedCollectableIds,
    Object? animatedCommand = _playbackUnset,
  }) {
    return BuilderPlaybackState(
      playerX: playerX ?? this.playerX,
      playerY: playerY ?? this.playerY,
      fromPlayerX: fromPlayerX ?? this.fromPlayerX,
      fromPlayerY: fromPlayerY ?? this.fromPlayerY,
      toPlayerX: toPlayerX ?? this.toPlayerX,
      toPlayerY: toPlayerY ?? this.toPlayerY,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      totalStepCount: totalStepCount ?? this.totalStepCount,
      activeCommandId: identical(activeCommandId, _playbackUnset)
          ? this.activeCommandId
          : activeCommandId as String?,
      movementStartedAtMs: movementStartedAtMs ?? this.movementStartedAtMs,
      isPlaying: isPlaying ?? this.isPlaying,
      hasSucceeded: hasSucceeded ?? this.hasSucceeded,
      hasFailed: hasFailed ?? this.hasFailed,
      collectedCollectableIds:
          collectedCollectableIds ?? this.collectedCollectableIds,
      animatedCommand: identical(animatedCommand, _playbackUnset)
          ? this.animatedCommand
          : animatedCommand as LogicCommandType?,
    );
  }
}

const Object _playbackUnset = Object();
