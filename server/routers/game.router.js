const router = require('express').Router();
const GameController = require('../controller/game.controller');
const authMiddleware = require('../middleware/auth.middleware');

// All game routes are protected
router.get('/:gameId/progress', authMiddleware, GameController.getProgress);
router.post('/:gameId/level', authMiddleware, GameController.saveLevelResult);
router.get('/:gameId/leaderboard', authMiddleware, GameController.getLeaderboard);
router.delete('/:gameId/progress', authMiddleware, GameController.resetProgress);

module.exports = router;