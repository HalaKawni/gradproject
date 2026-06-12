const mongoose = require('mongoose');
const db = require('../config/db');

const { Schema } = mongoose;

const slideCourseSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'user', required: true },
  title: { type: Schema.Types.Mixed, required: true },
  description: { type: Schema.Types.Mixed, default: () => ({ en: '' }) },
  courseImageBase64: { type: String, default: null },
  isPublished: { type: Boolean, default: false },
  lessons: [
    {
      number: Number,
      title: Schema.Types.Mixed,
      imageBase64: String,
      slides: [Schema.Types.Mixed],
    },
  ],
}, { timestamps: true });

const SlideCourseModel = db.model('SlideCourse', slideCourseSchema, 'courses');

module.exports = SlideCourseModel;
