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

  static async getMyStats(userId) {
    const allProgress = await GameProgressModel.find({ userId }).sort({ updatedAt: -1 });

    // Collect unique play-dates from completed level results
    function dateKey(d) {
      return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    }

    const playDates = new Set();
    allProgress.forEach(p => {
      p.levelResults.forEach(r => {
        if (r.stars > 0) playDates.add(dateKey(new Date(r.completedAt)));
      });
    });

    // Streak: count consecutive days going back from today (or yesterday)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    let streak = 0;
    let cursor = new Date(today);
    if (!playDates.has(dateKey(cursor))) {
      cursor.setDate(cursor.getDate() - 1); // allow until end of today
    }
    while (playDates.has(dateKey(cursor))) {
      streak++;
      cursor.setDate(cursor.getDate() - 1);
    }

    // Last 7 days activity flags (oldest → newest)
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      last7Days.push(playDates.has(dateKey(d)));
    }

    const totalScore = allProgress.reduce((s, p) => s + p.totalScore, 0);
    const totalStars  = allProgress.reduce((s, p) => s + p.totalStars, 0);

    const games = allProgress.map(p => ({
      gameId:       p.gameId,
      highestLevel: p.highestLevelReached,
      totalStars:   p.totalStars,
      totalScore:   p.totalScore,
      levelCount:   p.levelResults.filter(r => r.stars > 0).length,
    }));

    return { streak, totalScore, totalStars, last7Days, games };
  }
}

module.exports = GameService;