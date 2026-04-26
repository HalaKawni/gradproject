const Course = require('../../model/course.model');
const BuilderProject = require('../../model/builderProjectModel');
const CourseEnrollment = require('../../model/courseEnrollment.model');

async function attachCourseStats(courses) {
  const courseObjects = courses.map((course) =>
    typeof course.toObject === 'function' ? course.toObject() : course
  );
  const courseKeys = courseObjects
    .flatMap((course) => [course._id?.toString(), course.courseId])
    .filter(Boolean);
  const courseObjectIds = courseObjects
    .map((course) => course._id)
    .filter(Boolean);

  const [levelCounts, enrollmentCounts] = await Promise.all([
    courseKeys.length
      ? BuilderProject.aggregate([
          { $match: { courseId: { $in: courseKeys } } },
          { $group: { _id: '$courseId', totalLevels: { $sum: 1 } } },
        ])
      : [],
    courseObjectIds.length
      ? CourseEnrollment.aggregate([
          { $match: { courseId: { $in: courseObjectIds } } },
          { $group: { _id: '$courseId', enrolledStudents: { $sum: 1 } } },
        ])
      : [],
  ]);

  const levelsByCourse = new Map(
    levelCounts.map((item) => [item._id?.toString(), item.totalLevels])
  );
  const enrollmentsByCourse = new Map(
    enrollmentCounts.map((item) => [
      item._id?.toString(),
      item.enrolledStudents,
    ])
  );

  return courseObjects.map((course) => {
    const objectId = course._id?.toString();
    const totalLevels =
      levelsByCourse.get(course.courseId) || levelsByCourse.get(objectId) || 0;

    return {
      ...course,
      totalLevels,
      enrolledStudents: enrollmentsByCourse.get(objectId) || 0,
    };
  });
}

exports.getCourses = async () => {
  const courses = await Course.find().sort({ createdAt: -1 });
  return attachCourseStats(courses);
};

exports.createCourse = async (data, userId) => {
  const course = await Course.create({
    courseName: data.courseName,
    courseId: data.courseId,
    category: data.category,
    description: data.description,
    isPublic: data.isPublic ?? false,
    createdBy: userId,
  });

  const [courseWithStats] = await attachCourseStats([course]);
  return courseWithStats;
};

exports.updateCourse = async (id, data, userId) => {
  const update = {
    updatedBy: userId,
    updatedAt: new Date(),
  };

  if (data.courseName !== undefined || data.title !== undefined) {
    update.courseName = data.courseName ?? data.title;
  }

  if (data.courseId !== undefined) {
    update.courseId = data.courseId;
  }

  if (data.category !== undefined) {
    update.category = data.category;
  }

  if (data.description !== undefined) {
    update.description = data.description;
  }

  if (data.isPublic !== undefined) {
    update.isPublic = data.isPublic;
  }

  const course = await Course.findByIdAndUpdate(id, update, {
    returnDocument: 'after',
    runValidators: true,
  });

  if (!course) {
    throw new Error('Course not found');
  }

  const [courseWithStats] = await attachCourseStats([course]);
  return courseWithStats;
};

exports.deleteCourse = async (id) => {
  const course = await Course.findByIdAndDelete(id);

  if (!course) {
    throw new Error('Course not found');
  }

  return course;
};
