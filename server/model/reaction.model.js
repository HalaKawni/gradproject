const mongoose = require('mongoose');
const db = require('../config/db');
const { Schema } = mongoose;

const reactionSchema = new Schema({
  activityKey:  { type: String, required: true }, // userId-gameId-level
  classroomCode:{ type: String, required: true },
  reactorId:    { type: Schema.Types.ObjectId, ref: 'user', required: true },
  reactorName:  { type: String, required: true },
  emoji:        { type: String, required: true },
}, { timestamps: true });

// One reaction per person per activity (toggle: update if exists)
reactionSchema.index({ activityKey: 1, reactorId: 1 }, { unique: true });

module.exports = db.model('reaction', reactionSchema);
