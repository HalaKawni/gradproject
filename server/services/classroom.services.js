const UserModel           = require('../model/user.model');
const GameProgressModel   = require('../model/game.model');
const WeeklyChallengeModel= require('../model/weeklyChallenge.model');
const ChallengeModel      = require('../model/challenge.model');
const ReactionModel       = require('../model/reaction.model');

// ── helpers ──────────────────────────────────────────────────────────────────

function dateKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
}

function calcStreak(allProgress) {
  const playDates = new Set();
  allProgress.forEach(p => {
    p.levelResults.forEach(r => {
      if (r.stars > 0) playDates.add(dateKey(new Date(r.completedAt)));
    });
  });
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let streak = 0;
  let cursor = new Date(today);
  if (!playDates.has(dateKey(cursor))) cursor.setDate(cursor.getDate() - 1);
  while (playDates.has(dateKey(cursor))) {
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function weekBounds() {
  const now  = new Date();
  const day  = now.getDay(); // 0=Sun
  const start = new Date(now);
  start.setDate(now.getDate() - day);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(start.getDate() + 7);
  return { start, end };
}

// ── ClassroomService ──────────────────────────────────────────────────────────

class ClassroomService {

  // ── membership ──

  static async joinClassroom(userId, classroomCode) {
    await UserModel.findByIdAndUpdate(userId, { classroomCode: classroomCode.toUpperCase() });
    return { classroomCode: classroomCode.toUpperCase() };
  }

  static async getMyClassroomCode(userId) {
    const user = await UserModel.findById(userId, 'classroomCode');
    return user?.classroomCode || null;
  }

  // ── members (with streaks) ──

  static async getMembers(classroomCode) {
    const code    = classroomCode.toUpperCase();
    const members = await UserModel.find({ classroomCode: code, role: 'child' }, '_id name');
    if (!members.length) return [];

    const memberIds = members.map(m => m._id);
    const memberMap = {};
    members.forEach(m => (memberMap[m._id.toString()] = m.name));

    const allProgress = await GameProgressModel.find({ userId: { $in: memberIds } });

    // Group progress by user
    const progressByUser = {};
    allProgress.forEach(p => {
      const uid = p.userId.toString();
      if (!progressByUser[uid]) progressByUser[uid] = [];
      progressByUser[uid].push(p);
    });

    const result = members.map(m => {
      const uid   = m._id.toString();
      const progs = progressByUser[uid] || [];
      const totalStars  = progs.reduce((s, p) => s + p.totalStars, 0);
      const totalScore  = progs.reduce((s, p) => s + p.totalScore, 0);
      const streak      = calcStreak(progs);
      const games       = progs.map(p => ({
        gameId:      p.gameId,
        totalStars:  p.totalStars,
        totalScore:  p.totalScore,
        highestLevel:p.highestLevelReached,
      }));
      return { id: m._id, name: m.name, totalStars, totalScore, streak, games };
    });

    result.sort((a, b) => b.totalScore - a.totalScore);
    result.forEach((m, i) => (m.rank = i + 1));
    return result;
  }

  // ── leaderboard ──

  static async getLeaderboard(classroomCode, gameId, limit = 20) {
    const code    = classroomCode.toUpperCase();
    const members = await UserModel.find({ classroomCode: code, role: 'child' }, '_id name');
    if (!members.length) return [];

    const memberIds = members.map(m => m._id);
    const memberMap = {};
    members.forEach(m => (memberMap[m._id.toString()] = m.name));

    const progress = await GameProgressModel
      .find({ userId: { $in: memberIds }, gameId })
      .sort({ totalScore: -1, totalStars: -1 })
      .limit(limit);

    return progress.map((p, i) => ({
      rank:         i + 1,
      name:         memberMap[p.userId.toString()] || 'Unknown',
      totalScore:   p.totalScore,
      totalStars:   p.totalStars,
      highestLevel: p.highestLevelReached,
    }));
  }

  // ── activity (with userId for reaction keys) ──

  static async getActivity(classroomCode, limit = 30) {
    const code    = classroomCode.toUpperCase();
    const members = await UserModel.find({ classroomCode: code, role: 'child' }, '_id name');
    if (!members.length) return [];

    const memberIds = members.map(m => m._id);
    const memberMap = {};
    members.forEach(m => (memberMap[m._id.toString()] = m.name));

    const allProgress = await GameProgressModel.find({ userId: { $in: memberIds } });

    const activities = [];
    allProgress.forEach(p => {
      p.levelResults.forEach(r => {
        if (r.stars > 0) {
          const uid = p.userId.toString();
          activities.push({
            activityKey: `${uid}-${p.gameId}-${r.level}`,
            userId:      uid,
            name:        memberMap[uid] || 'Unknown',
            gameId:      p.gameId,
            level:       r.level,
            stars:       r.stars,
            score:       r.score,
            completedAt: r.completedAt,
          });
        }
      });
    });

    activities.sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt));
    return activities.slice(0, limit);
  }

  // ── stats overview ──

  static async getStats(classroomCode) {
    const code    = classroomCode.toUpperCase();
    const members = await UserModel.find({ classroomCode: code, role: 'child' }, '_id name');
    if (!members.length) return { totalStars: 0, totalScore: 0, totalLevels: 0, weeklyLevels: 0, memberCount: 0, mostActiveName: null };

    const memberIds = members.map(m => m._id);
    const memberMap = {};
    members.forEach(m => (memberMap[m._id.toString()] = m.name));

    const allProgress  = await GameProgressModel.find({ userId: { $in: memberIds } });
    const { start: weekStart } = weekBounds();

    let totalStars = 0, totalScore = 0, totalLevels = 0, weeklyLevels = 0;
    const activityCount = {};

    allProgress.forEach(p => {
      totalStars += p.totalStars;
      totalScore += p.totalScore;
      const uid = p.userId.toString();
      p.levelResults.forEach(r => {
        if (r.stars > 0) {
          totalLevels++;
          activityCount[uid] = (activityCount[uid] || 0) + 1;
          if (new Date(r.completedAt) >= weekStart) weeklyLevels++;
        }
      });
    });

    let mostActiveName = null, maxAct = 0;
    Object.entries(activityCount).forEach(([uid, count]) => {
      if (count > maxAct) { maxAct = count; mostActiveName = memberMap[uid]; }
    });

    return { totalStars, totalScore, totalLevels, weeklyLevels, memberCount: members.length, mostActiveName };
  }

  // ── weekly challenge ──

  static async getWeeklyChallenge(classroomCode) {
    const code      = classroomCode.toUpperCase();
    const challenge = await WeeklyChallengeModel.findOne({ classroomCode: code, active: true }).sort({ createdAt: -1 });
    if (!challenge) return null;

    // Compute progress: levels completed by all members since weekStart
    const members   = await UserModel.find({ classroomCode: code, role: 'child' }, '_id');
    const memberIds = members.map(m => m._id);
    const query     = { userId: { $in: memberIds } };
    if (challenge.gameId) query.gameId = challenge.gameId;

    const allProgress = await GameProgressModel.find(query);
    let completedLevels = 0;
    allProgress.forEach(p => {
      p.levelResults.forEach(r => {
        if (r.stars > 0 && new Date(r.completedAt) >= challenge.weekStart) completedLevels++;
      });
    });

    return {
      _id:           challenge._id,
      title:         challenge.title,
      gameId:        challenge.gameId,
      targetLevels:  challenge.targetLevels,
      completedLevels,
      creatorName:   challenge.creatorName,
      weekStart:     challenge.weekStart,
      weekEnd:       challenge.weekEnd,
      done:          completedLevels >= challenge.targetLevels,
    };
  }

  static async setWeeklyChallenge(classroomCode, userId, userName, { title, gameId, targetLevels }) {
    const code = classroomCode.toUpperCase();
    // Deactivate any existing active challenge
    await WeeklyChallengeModel.updateMany({ classroomCode: code, active: true }, { active: false });

    const { start, end } = weekBounds();
    const challenge = await WeeklyChallengeModel.create({
      classroomCode: code,
      creatorId:    userId,
      creatorName:  userName,
      title,
      gameId:       gameId || '',
      targetLevels: Number(targetLevels),
      weekStart:    start,
      weekEnd:      end,
      active:       true,
    });
    return challenge;
  }

  // ── head-to-head challenges ──

  static async sendChallenge(classroomCode, challengerId, challengerName, challengedId, challengedName, gameId, challengerScore) {
    const existing = await ChallengeModel.findOne({ challengerId, challengedId, gameId, status: 'pending' });
    if (existing) throw new Error('You already have a pending challenge with this person for this game');

    return await ChallengeModel.create({
      classroomCode,
      challengerId, challengerName,
      challengedId, challengedName,
      gameId,
      challengerScore,
      status: 'pending',
    });
  }

  static async getChallenges(userId, classroomCode) {
    const challenges = await ChallengeModel.find({
      classroomCode,
      $or: [{ challengerId: userId }, { challengedId: userId }],
    }).sort({ createdAt: -1 }).limit(20);

    // Auto-resolve: check if challenged user has beaten the score
    const pendingChallenged = challenges.filter(
      c => c.status === 'pending' && c.challengedId.toString() === userId.toString()
    );

    for (const c of pendingChallenged) {
      const progress = await GameProgressModel.findOne({ userId: c.challengedId, gameId: c.gameId });
      if (progress && progress.totalScore > c.challengerScore) {
        c.challengedScore = progress.totalScore;
        c.status = 'completed';
        c.winner = progress.totalScore > c.challengerScore ? c.challengedName : c.challengerName;
        await c.save();
      }
    }

    return challenges;
  }

  // ── reactions ──

  static async toggleReaction(activityKey, classroomCode, reactorId, reactorName, emoji) {
    const existing = await ReactionModel.findOne({ activityKey, reactorId });
    if (existing) {
      if (existing.emoji === emoji) {
        await existing.deleteOne(); // toggle off
        return null;
      } else {
        existing.emoji = emoji; // switch emoji
        await existing.save();
        return existing;
      }
    }
    return await ReactionModel.create({ activityKey, classroomCode, reactorId, reactorName, emoji });
  }

  static async getReactions(classroomCode, activityKeys) {
    const reactions = await ReactionModel.find({ classroomCode, activityKey: { $in: activityKeys } });
    // Group by activityKey
    const grouped = {};
    reactions.forEach(r => {
      if (!grouped[r.activityKey]) grouped[r.activityKey] = [];
      grouped[r.activityKey].push({ emoji: r.emoji, reactorName: r.reactorName, reactorId: r.reactorId });
    });
    return grouped;
  }
}

module.exports = ClassroomService;
