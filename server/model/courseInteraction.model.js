const mongoose = require('mongoose');
const db = require('../config/db');

const courseInteractionSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      index: true,
    },
    courseId: {
      type: String,
      required: true,
      index: true,
    },
    eventType: {
      type: String,
      enum: ['view', 'click', 'level_play', 'level_complete'],
      required: true,
      index: true,
    },
    ageGroupAtEvent: {
      type: String,
      enum: ['under_6', '6_8', '9_11', '12_14', '15_17', '18_plus', 'unknown'],
      default: 'unknown',
      index: true,
    },
    genderAtEvent: {
      type: String,
      enum: ['male', 'female', 'unknown'],
      default: 'unknown',
      index: true,
    },
  },
  { timestamps: true }
);

courseInteractionSchema.index({ courseId: 1, eventType: 1, createdAt: -1 });

module.exports = db.model('CourseInteraction', courseInteractionSchema);
