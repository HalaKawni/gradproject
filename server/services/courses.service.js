const Course = require('../model/course.model');
const BuilderProject = require('../model/builderProjectModel');
const CourseProgress = require('../model/courseProgress.model');
const mongoose = require('mongoose');

async function getPublicCourses() {
  return Course.find({ isPublic: true }).sort({
    updatedAt: -1,
    createdAt: -1,
  });
}

async function getPublicCourseLevels(courseId) {
  const course = await findPublicCourse(courseId);
  const courseKeys = [course._id.toString(), course.courseId].filter(Boolean);

  return BuilderProject.find({
    courseId: { $in: courseKeys },
    status: 'published',
    ownerRole: 'admin',
  })
    .select(
      '_id title description status builderType difficulty courseId orderInCourse ownerName updatedAt'
    )
    .sort({ orderInCourse: 1, updatedAt: -1 });
}

async function getCourseProgress(courseId, userId) {
  const course = await findPublicCourse(courseId);
  const progress = await CourseProgress.findOne({
    userId: userId.toString(),
    courseId: course._id.toString(),
  });

  return progress || emptyCourseProgress(course, userId);
}

async function completeCourseLevel(courseId, userId, levelId, result = {}) {
  const course = await findPublicCourse(courseId);
  const courseKeys = [course._id.toString(), course.courseId].filter(Boolean);
  const level = await BuilderProject.findOne({
    _id: levelId,
    courseId: { $in: courseKeys },
    status: 'published',
    ownerRole: 'admin',
  }).select('_id orderInCourse');

  if (!level) {
    throw new Error('Level not found in this course');
  }

  const progress =
    (await CourseProgress.findOne({
      userId: userId.toString(),
      courseId: course._id.toString(),
    })) ||
    new CourseProgress({
      userId: userId.toString(),
      courseId: course._id.toString(),
      completedLevels: [],
    });

  const levelIdText = level._id.toString();
  const orderInCourse = Number(level.orderInCourse || 0);
  const existingIndex = progress.completedLevels.findIndex(
    (item) => item.levelId === levelIdText
  );
  const score = readPositiveInteger(result.score);
  const totalScore = readPositiveInteger(result.totalScore);
  const stars = Math.min(readPositiveInteger(result.stars), 3);
  const existingLevel =
    existingIndex === -1 ? null : progress.completedLevels[existingIndex];
  const bestScore = Math.max(score, Number(existingLevel?.score || 0));
  const bestStars = Math.max(stars, Number(existingLevel?.stars || 0));
  const storedTotalScore =
    totalScore > 0 ? totalScore : Number(existingLevel?.totalScore || 0);
  const completedLevel = {
    levelId: levelIdText,
    orderInCourse,
    score: bestScore,
    totalScore: storedTotalScore,
    stars: bestStars,
    completedAt: new Date(),
  };

  if (existingIndex === -1) {
    progress.completedLevels.push(completedLevel);
  } else {
    progress.completedLevels[existingIndex] = completedLevel;
  }

  progress.completedLevels.sort(
    (a, b) => Number(a.orderInCourse || 0) - Number(b.orderInCourse || 0)
  );

  const lastCompleted = progress.completedLevels.reduce(
    (best, item) =>
      Number(item.orderInCourse || 0) > Number(best?.orderInCourse || 0)
        ? item
        : best,
    null
  );
  progress.lastCompletedLevelId = lastCompleted?.levelId || '';
  progress.lastCompletedOrderInCourse = Number(
    lastCompleted?.orderInCourse || 0
  );

  const levelCount = await BuilderProject.countDocuments({
    courseId: { $in: courseKeys },
    status: 'published',
    ownerRole: 'admin',
  });
  progress.completedAt =
    levelCount > 0 && progress.completedLevels.length >= levelCount
      ? new Date()
      : null;

  return progress.save();
}

async function findPublicCourse(courseId) {
  const courseQuery = [{ courseId }];
  if (mongoose.Types.ObjectId.isValid(courseId)) {
    courseQuery.push({ _id: courseId });
  }

  const course = await Course.findOne({
    isPublic: true,
    $or: courseQuery,
  });

  if (!course) {
    throw new Error('Course not found');
  }

  return course;
}

function emptyCourseProgress(course, userId) {
  return {
    userId: userId.toString(),
    courseId: course._id.toString(),
    completedLevels: [],
    lastCompletedLevelId: '',
    lastCompletedOrderInCourse: 0,
    completedAt: null,
  };
}

function readPositiveInteger(value) {
  const numericValue = Number(value);
  if (!Number.isFinite(numericValue) || numericValue < 0) {
    return 0;
  }
  return Math.floor(numericValue);
}

module.exports = {
  getPublicCourses,
  getPublicCourseLevels,
  getCourseProgress,
  completeCourseLevel,
};
