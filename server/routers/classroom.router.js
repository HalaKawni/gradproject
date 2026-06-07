const router = require('express').Router();
const C      = require('../controller/classroom.controller');
const auth   = require('../middleware/auth.middleware');

// membership
router.post('/join',          auth, C.joinClassroom);
router.get('/my-classroom',   auth, C.getMyClassroom);

// core tabs
router.get('/members',        auth, C.getMembers);
router.get('/leaderboard/:gameId', auth, C.getLeaderboard);
router.get('/activity',       auth, C.getActivity);

// stats overview
router.get('/stats',          auth, C.getStats);

// weekly challenge
router.get('/weekly-challenge',  auth, C.getWeeklyChallenge);
router.post('/weekly-challenge', auth, C.setWeeklyChallenge);

// head-to-head challenges
router.post('/challenge',     auth, C.sendChallenge);
router.get('/challenges',     auth, C.getChallenges);

// reactions
router.post('/reaction',      auth, C.toggleReaction);
router.post('/reactions',     auth, C.getReactions);

module.exports = router;
