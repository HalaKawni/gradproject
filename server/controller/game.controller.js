const GameService = require('../services/game.services');

exports.getProgress = async (req, res, next) => {
  try {
    const { gameId } = req.params;
    const progress = await GameService.getProgress(req.user._id, gameId);

    res.json({
      status: true,
      progress,
    });
  } catch (err) {
    res.status(500).json({
      status: false,
      error: err.message || 'Failed to fetch progress',
    });
  }
};

exports.saveLevelResult = async (req, res, next) => {
  try {
    const { gameId } = req.params;
    const { level, stars, score } = req.body;

    if (level === undefined || stars === undefined) {
      return res.status(400).json({
        status: false,
        error: 'level and stars are required',
      });
    }

    const progress = await GameService.saveLevelResult(
      req.user._id,
      gameId,
      { level, stars, score: score || 0 }
    );

    res.json({
      status: true,
      success: 'Level result saved',
      progress,
    });
  } catch (err) {
    res.status(500).json({
      status: false,
      error: err.message || 'Failed to save level result',
    });
  }
};

exports.getLeaderboard = async (req, res, next) => {
  try {
    const { gameId } = req.params;
    const limit = parseInt(req.query.limit) || 10;

    const leaderboard = await GameService.getLeaderboard(gameId, limit);

    res.json({
      status: true,
      leaderboard,
    });
  } catch (err) {
    res.status(500).json({
      status: false,
      error: err.message || 'Failed to fetch leaderboard',
    });
  }
};

exports.resetProgress = async (req, res, next) => {
  try {
    const { gameId } = req.params;
    const result = await GameService.resetProgress(req.user._id, gameId);

    res.json({
      status: true,
      success: result.message,
    });
  } catch (err) {
    res.status(500).json({
      status: false,
      error: err.message || 'Failed to reset progress',
    });
  }
};