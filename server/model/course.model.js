const mongoose = require('mongoose');
const db = require('../config/db');
const { Schema } = mongoose;

const courseSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'user', required: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  courseImageBase64: { type: String, default: null },
  isPublished: { type: Boolean, default: false },
  lessons: [
    {
      number: Number,
      title: String,
      imageBase64: String,
      slides: [Schema.Types.Mixed],
    },
  ],
}, { timestamps: true });

const CourseModel = db.model('course', courseSchema);
module.exports = CourseModel;
