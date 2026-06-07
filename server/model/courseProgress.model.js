const mongoose = require('mongoose');
const db = require('../config/db');

const completedCourseLevelSchema = new mongoose.Schema(
  {
    levelId: {
      type: String,
      required: true,
    },
    orderInCourse: {
      type: Number,
      default: 0,
    },
    score: {
      type: Number,
      default: 0,
    },
    totalScore: {
      type: Number,
      default: 0,
    },
    stars: {
      type: Number,
      default: 0,
    },
    completedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const courseProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
    },
    courseId: {
      type: String,
      required: true,
    },
    completedLevels: {
      type: [completedCourseLevelSchema],
      default: [],
    },
    lastCompletedLevelId: {
      type: String,
      default: '',
    },
    lastCompletedOrderInCourse: {
      type: Number,
      default: 0,
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

courseProgressSchema.index({ userId: 1, courseId: 1 }, { unique: true });

module.exports = db.model('CourseProgress', courseProgressSchema);
