const mongoose = require('mongoose');
const db = require('../config/db');

const { Schema } = mongoose;

function extractTitleSeed(title) {
  if (typeof title === 'string') {
    return title;
  }

  if (title && typeof title === 'object') {
    const englishTitle = typeof title.en === 'string' ? title.en : '';
    if (englishTitle.trim()) {
      return englishTitle;
    }

    for (const value of Object.values(title)) {
      if (typeof value === 'string' && value.trim()) {
        return value;
      }
    }
  }

  return 'slide-course';
}

function buildCourseId(title) {
  const seed = extractTitleSeed(title)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  const normalizedSeed = seed || 'slide-course';
  const uniqueSuffix = Math.random().toString(36).slice(2, 8);
  return `${normalizedSeed}-${Date.now()}-${uniqueSuffix}`;
}

const slideCourseSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'user', required: true },
  courseId: { type: String, required: true, unique: true, trim: true },
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

slideCourseSchema.pre('validate', function ensureCourseId() {
  if (!this.courseId || !this.courseId.trim()) {
    this.courseId = buildCourseId(this.title);
  }
});

const SlideCourseModel = db.model('SlideCourse', slideCourseSchema, 'courses');

module.exports = SlideCourseModel;
