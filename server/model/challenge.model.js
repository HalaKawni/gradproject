const mongoose = require('mongoose');
const db = require('../config/db');
const { Schema } = mongoose;

const challengeSchema = new Schema({
  classroomCode:   { type: String, required: true, index: true },
  challengerId:    { type: Schema.Types.ObjectId, ref: 'user', required: true },
  challengerName:  { type: String, required: true },
  challengedId:    { type: Schema.Types.ObjectId, ref: 'user', required: true },
  challengedName:  { type: String, required: true },
  gameId:          { type: String, required: true },
  challengerScore: { type: Number, required: true },
  challengedScore: { type: Number, default: null },
  status:          { type: String, enum: ['pending', 'completed'], default: 'pending' },
  winner:          { type: String, default: null }, // name of winner or 'tie'
}, { timestamps: true });

module.exports = db.model('challenge', challengeSchema);
