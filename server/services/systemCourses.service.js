const crypto = require('crypto');
const Course = require('../model/course.model');
const User = require('../model/user.model');

const SYSTEM_COURSE_OWNER_EMAIL = 'system-courses@local.invalid';

const SYSTEM_PUBLIC_COURSES = [
  {
    courseId: 'legacy-data-is-everywhere',
    courseName: 'Data is Everywhere',
    category: 'CS Topics',
    description:
      'Get a glimpse into the world of data. Learn what data is and how to collect it. You will also learn how to organize your data using different graphing visualizations.',
    legacyPageKey: 'data_is_everywhere',
  },
  {
    courseId: 'legacy-banana-tales',
    courseName: 'Banana Tales',
    category: 'Text Coding',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'banana_tales',
  },
  {
    courseId: 'legacy-digital-literacy',
    courseName: 'Digital Literacy',
    category: 'Digital Literacy',
    description:
      'A short introduction to some important topics in the digital world: How to use computers, what are software and hardware, possible threats online and protecting your privacy.',
    legacyPageKey: 'digital_literacy',
  },
  {
    courseId: 'legacy-game-builder',
    courseName: 'Game Builder',
    category: 'Text Coding',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'game_builder',
  },
  {
    courseId: 'legacy-coding-chatbots',
    courseName: 'Coding Chatbots',
    category: 'Coding',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'coding_chatbots',
  },
  {
    courseId: 'legacy-data-science',
    courseName: 'Data Science',
    category: 'Text Coding',
    description: 'Start this course to learn exciting coding concepts!',
    legacyPageKey: 'data_science',
  },
];

let ensureSystemCoursesPromise = null;

async function ensureSystemCourses() {
  if (!ensureSystemCoursesPromise) {
    ensureSystemCoursesPromise = syncSystemCourses().catch((error) => {
      ensureSystemCoursesPromise = null;
      throw error;
    });
  }

  return ensureSystemCoursesPromise;
}

async function syncSystemCourses() {
  const owner = await findOrCreateSystemCourseOwner();
  const timestamp = new Date();
  const activeCourseIds = SYSTEM_PUBLIC_COURSES.map((course) => course.courseId);

  const operations = SYSTEM_PUBLIC_COURSES.map((course) => ({
    updateOne: {
      filter: { courseId: course.courseId },
      update: {
        $set: {
          courseName: course.courseName,
          category: course.category,
          description: course.description,
          courseDeliveryType: 'legacy_page',
          legacyPageKey: course.legacyPageKey,
          isPublic: true,
          verificationStatus: 'approved',
          verificationReviewedAt: timestamp,
          verificationReviewedBy: owner._id,
          verifiedAt: timestamp,
          verifiedBy: owner._id,
          hasUnreadUpdateNotification: false,
          lastUpdateNotificationMessage: '',
        },
        $setOnInsert: {
          createdBy: owner._id,
          updatedBy: owner._id,
          createdAt: timestamp,
          updatedAt: timestamp,
        },
      },
      upsert: true,
    },
  }));

  if (!operations.length) {
    return;
  }

  await Course.collection.bulkWrite(operations, { ordered: false });
  await Course.updateMany(
    {
      courseDeliveryType: 'legacy_page',
      courseId: { $nin: activeCourseIds },
    },
    {
      $set: {
        isPublic: false,
      },
    }
  );
}

async function findOrCreateSystemCourseOwner() {
  const existingOwner = await User.findOne({
    email: SYSTEM_COURSE_OWNER_EMAIL,
  }).select('_id');
  if (existingOwner) {
    return existingOwner;
  }

  return User.create({
    name: 'System Courses',
    email: SYSTEM_COURSE_OWNER_EMAIL,
    password: crypto.randomUUID(),
    role: 'admin',
    emailVerified: true,
    authProvider: 'local',
    authProviders: ['local'],
    lastSignInProvider: 'local',
  });
}

module.exports = {
  ensureSystemCourses,
};
