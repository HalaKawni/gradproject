const int defaultCollectableScore = 10;
const int defaultGoalScore = 50;

int readScoreValue(Object? value, {required int fallback}) {
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return fallback;
  }
  return parsed < 0 ? 0 : parsed;
}

int starsForScore({required int score, required int totalScore}) {
  if (totalScore <= 0) {
    return score > 0 ? 3 : 0;
  }

  final clampedScore = score.clamp(0, totalScore);
  if (clampedScore >= totalScore) {
    return 3;
  }
  if (clampedScore >= totalScore * 2 / 3) {
    return 2;
  }
  if (clampedScore >= totalScore / 3) {
    return 1;
  }
  return 0;
}

class LevelScoreResult {
  final bool success;
  final int score;
  final int totalScore;
  final int stars;

  const LevelScoreResult({
    required this.success,
    required this.score,
    required this.totalScore,
    required this.stars,
  });
}
