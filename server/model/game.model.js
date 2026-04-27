const mongoose = require('mongoose');
const db = require('../config/db');

const { Schema } = mongoose;

const levelResultSchema = new Schema(
  {
    level: { type: Number, required: true },
    stars: { type: Number, min: 0, max: 3, default: 0 },
    score: { type: Number, default: 0 },
    completedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const gameProgressSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'user',
      required: true,
    },
    gameId: {
      type: String,
      required: true,
      // e.g. 'codemonkey-jr', 'linus-the-lemur'
    },
    currentLevel: { type: Number, default: 1 },
    highestLevelReached: { type: Number, default: 1 },
    totalStars: { type: Number, default: 0 },
    totalScore: { type: Number, default: 0 },
    levelResults: [levelResultSchema],
    completed: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// One progress document per user per game
gameProgressSchema.index({ userId: 1, gameId: 1 }, { unique: true });

const gameProgressModel = db.model('gameProgress', gameProgressSchema);
module.exports = gameProgressModel;