const mongoose = require('mongoose');
const db = require('../config/db');
const { Schema } = mongoose;

const weeklyChallengeSchema = new Schema({
  classroomCode: { type: String, required: true, index: true },
  creatorId:     { type: Schema.Types.ObjectId, ref: 'user', required: true },
  creatorName:   { type: String, required: true },
  title:         { type: String, required: true },
  gameId:        { type: String, default: '' }, // '' = all games
  targetLevels:  { type: Number, required: true },
  weekStart:     { type: Date, required: true },
  weekEnd:       { type: Date, required: true },
  active:        { type: Boolean, default: true },
}, { timestamps: true });

module.exports = db.model('weeklyChallenge', weeklyChallengeSchema);
