const ClassroomService = require('../services/classroom.services');

// ── membership ────────────────────────────────────────────────────────────────

exports.joinClassroom = async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ status: false, error: 'Code is required' });
    const result = await ClassroomService.joinClassroom(req.user._id, code);
    res.json({ status: true, classroomCode: result.classroomCode });
  } catch (err) {
    res.status(400).json({ status: false, error: err.message });
  }
};

exports.getMyClassroom = async (req, res) => {
  res.json({ status: true, classroomCode: req.user.classroomCode || null });
};

// ── members, leaderboard, activity ───────────────────────────────────────────

exports.getMembers = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const members = await ClassroomService.getMembers(code);
    res.json({ status: true, members, classroomCode: code });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.getLeaderboard = async (req, res) => {
  try {
    const { gameId } = req.params;
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const leaderboard = await ClassroomService.getLeaderboard(code, gameId);
    res.json({ status: true, leaderboard, classroomCode: code });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.getActivity = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const activity = await ClassroomService.getActivity(code);
    res.json({ status: true, activity, classroomCode: code });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

// ── stats ─────────────────────────────────────────────────────────────────────

exports.getStats = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const stats = await ClassroomService.getStats(code);
    res.json({ status: true, stats });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

// ── weekly challenge ──────────────────────────────────────────────────────────

exports.getWeeklyChallenge = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const challenge = await ClassroomService.getWeeklyChallenge(code);
    res.json({ status: true, challenge });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.setWeeklyChallenge = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const { title, gameId, targetLevels } = req.body;
    if (!title || !targetLevels) return res.status(400).json({ status: false, error: 'title and targetLevels are required' });
    const challenge = await ClassroomService.setWeeklyChallenge(code, req.user._id, req.user.name, { title, gameId, targetLevels });
    res.json({ status: true, challenge });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

// ── head-to-head challenges ───────────────────────────────────────────────────

exports.sendChallenge = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const { challengedId, challengedName, gameId, challengerScore } = req.body;
    if (!challengedId || !gameId || challengerScore === undefined) {
      return res.status(400).json({ status: false, error: 'challengedId, gameId, challengerScore required' });
    }
    const challenge = await ClassroomService.sendChallenge(
      code, req.user._id, req.user.name,
      challengedId, challengedName, gameId, challengerScore
    );
    res.json({ status: true, challenge });
  } catch (err) {
    res.status(400).json({ status: false, error: err.message });
  }
};

exports.getChallenges = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const challenges = await ClassroomService.getChallenges(req.user._id, code);
    res.json({ status: true, challenges });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

// ── reactions ─────────────────────────────────────────────────────────────────

exports.toggleReaction = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const { activityKey, emoji } = req.body;
    if (!activityKey || !emoji) return res.status(400).json({ status: false, error: 'activityKey and emoji required' });
    await ClassroomService.toggleReaction(activityKey, code, req.user._id, req.user.name, emoji);
    res.json({ status: true });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};

exports.getReactions = async (req, res) => {
  try {
    const code = req.user.classroomCode;
    if (!code) return res.status(400).json({ status: false, error: 'Not in a classroom' });
    const { keys } = req.body; // array of activityKeys
    if (!keys?.length) return res.json({ status: true, reactions: {} });
    const reactions = await ClassroomService.getReactions(code, keys);
    res.json({ status: true, reactions });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message });
  }
};
