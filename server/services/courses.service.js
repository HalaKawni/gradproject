const Course = require('../model/course.model');
const BuilderProject = require('../model/builderProjectModel');
const mongoose = require('mongoose');

async function getPublicCourses() {
  return Course.find({ isPublic: true }).sort({
    updatedAt: -1,
    createdAt: -1,
  });
}

async function getPublicCourseLevels(courseId) {
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

module.exports = {
  getPublicCourses,
  getPublicCourseLevels,
};
