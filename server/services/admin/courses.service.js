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
  const courses = await Course.find()
    .populate('createdBy', 'name email role')
    .populate('verifiedBy', 'name email role')
    .populate('verificationReviewedBy', 'name email role')
    .sort({ createdAt: -1, courseName: 1 });
  return attachCourseStats(courses);
};

exports.getNotifications = async () => {
  const courses = await Course.find({
    $or: [
      { verificationStatus: 'pending' },
      { hasUnreadUpdateNotification: true },
    ],
  })
    .populate('createdBy', 'name email role')
    .sort({
      verificationRequestedAt: -1,
      lastUpdateNotificationAt: -1,
      updatedAt: -1,
    });

  return attachCourseStats(courses);
};

exports.createCourse = async (data, userId) => {
  const course = await Course.create({
    courseName: data.courseName,
    courseId: data.courseId,
    category: data.category,
    description: data.description,
    courseImageBase64: data.courseImageBase64 ?? null,
    coverFrameScale: Number(data.coverFrameScale ?? 1),
    coverFrameOffsetX: Number(data.coverFrameOffsetX ?? 0),
    coverFrameOffsetY: Number(data.coverFrameOffsetY ?? 0),
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

  if (data.courseImageBase64 !== undefined) {
    update.courseImageBase64 = data.courseImageBase64;
  }

  if (data.coverFrameScale !== undefined) {
    update.coverFrameScale = Number(data.coverFrameScale);
  }

  if (data.coverFrameOffsetX !== undefined) {
    update.coverFrameOffsetX = Number(data.coverFrameOffsetX);
  }

  if (data.coverFrameOffsetY !== undefined) {
    update.coverFrameOffsetY = Number(data.coverFrameOffsetY);
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

exports.approveVerification = async (id, adminId) => {
  const course = await Course.findByIdAndUpdate(
    id,
    {
      verificationStatus: 'approved',
      verificationReviewedAt: new Date(),
      verificationReviewedBy: adminId,
      verificationRejectedReason: '',
      verifiedAt: new Date(),
      verifiedBy: adminId,
      isPublic: true,
      hasUnreadUpdateNotification: false,
      lastUpdateNotificationMessage: '',
    },
    { returnDocument: 'after', runValidators: true }
  )
    .populate('createdBy', 'name email role')
    .populate('verifiedBy', 'name email role')
    .populate('verificationReviewedBy', 'name email role');

  if (!course) {
    throw new Error('Course not found');
  }

  const [courseWithStats] = await attachCourseStats([course]);
  return courseWithStats;
};

exports.rejectVerification = async (id, adminId, reason = '') => {
  const course = await Course.findByIdAndUpdate(
    id,
    {
      verificationStatus: 'rejected',
      verificationReviewedAt: new Date(),
      verificationReviewedBy: adminId,
      verificationRejectedReason: reason,
      verifiedAt: null,
      verifiedBy: null,
    },
    { returnDocument: 'after', runValidators: true }
  )
    .populate('createdBy', 'name email role')
    .populate('verificationReviewedBy', 'name email role');

  if (!course) {
    throw new Error('Course not found');
  }

  const [courseWithStats] = await attachCourseStats([course]);
  return courseWithStats;
};

exports.dismissUpdateNotification = async (id) => {
  const course = await Course.findByIdAndUpdate(
    id,
    {
      hasUnreadUpdateNotification: false,
      lastUpdateNotificationMessage: '',
    },
    { returnDocument: 'after', runValidators: true }
  ).populate('createdBy', 'name email role');

  if (!course) {
    throw new Error('Course not found');
  }

  const [courseWithStats] = await attachCourseStats([course]);
  return courseWithStats;
};

exports.revokeVerification = async (id, adminId) => {
  const course = await Course.findByIdAndUpdate(
    id,
    {
      verificationStatus: 'none',
      verificationReviewedAt: new Date(),
      verificationReviewedBy: adminId,
      verificationRejectedReason: '',
      verifiedAt: null,
      verifiedBy: null,
      hasUnreadUpdateNotification: false,
      lastUpdateNotificationMessage: '',
    },
    { returnDocument: 'after', runValidators: true }
  )
    .populate('createdBy', 'name email role')
    .populate('verificationReviewedBy', 'name email role');

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
