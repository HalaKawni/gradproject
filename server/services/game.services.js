const GameProgressModel = require('../model/game.model');

class GameService {

  static async getProgress(userId, gameId) {
    let progress = await GameProgressModel.findOne({ userId, gameId });

    if (!progress) {
      // Auto-create on first fetch
      progress = await GameProgressModel.create({ userId, gameId });
    }

    return progress;
  }

  static async saveLevelResult(userId, gameId, { level, stars, score }) {
    let progress = await GameProgressModel.findOne({ userId, gameId });

    if (!progress) {
      progress = new GameProgressModel({ userId, gameId });
    }

    // Check if level already exists
    const existingIndex = progress.levelResults.findIndex(
      (r) => r.level === level
    );

    if (existingIndex >= 0) {
      // Only update if better result
      const existing = progress.levelResults[existingIndex];
      if (stars > existing.stars || score > existing.score) {
        progress.levelResults[existingIndex] = {
          level,
          stars: Math.max(stars, existing.stars),
          score: Math.max(score, existing.score),
          completedAt: new Date(),
        };
      }
    } else {
      progress.levelResults.push({ level, stars, score });
    }

    // Update summary fields
    progress.currentLevel = level + 1;
    progress.highestLevelReached = Math.max(
      progress.highestLevelReached,
      level
    );
    progress.totalStars = progress.levelResults.reduce(
      (sum, r) => sum + r.stars,
      0
    );
    progress.totalScore = progress.levelResults.reduce(
      (sum, r) => sum + r.score,
      0
    );

    await progress.save();
    return progress;
  }

  static async getLeaderboard(gameId, limit = 10) {
    const results = await GameProgressModel.find({ gameId })
      .sort({ totalScore: -1, totalStars: -1 })
      .limit(limit)
      .populate('userId', 'name');

    return results.map((p, index) => ({
      rank: index + 1,
      name: p.userId?.name || 'Unknown',
      totalScore: p.totalScore,
      totalStars: p.totalStars,
      highestLevel: p.highestLevelReached,
    }));
  }

  static async resetProgress(userId, gameId) {
    await GameProgressModel.findOneAndDelete({ userId, gameId });
    return { message: 'Progress reset successfully' };
  }
}

module.exports = GameService;