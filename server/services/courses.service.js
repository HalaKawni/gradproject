const Course = require('../model/course.model');
const BuilderProject = require('../model/builderProjectModel');
const CourseProgress = require('../model/courseProgress.model');
const CourseInteraction = require('../model/courseInteraction.model');
const { ensureSystemCourses } = require('./systemCourses.service');
const mongoose = require('mongoose');

function stringifyValue(value) {
  return value === undefined || value === null ? '' : String(value);
}

function serializeCourse(course, viewerId) {
  if (!course) {
    return null;
  }

  const source = typeof course.toObject === 'function' ? course.toObject() : course;
  const comments = Array.isArray(source.comments) ? source.comments : [];
  const ratings = Array.isArray(source.ratings) ? source.ratings : [];
  const normalizedComments = comments
    .map((comment) => ({
      _id: stringifyValue(comment._id),
      userId: stringifyValue(comment.userId),
      userName: stringifyValue(comment.userName) || 'User',
      message: stringifyValue(comment.message),
      createdAt: comment.createdAt || null,
      updatedAt: comment.updatedAt || null,
    }))
    .sort((left, right) => {
      return new Date(right.createdAt || 0).getTime() - new Date(left.createdAt || 0).getTime();
    });
  const normalizedRatings = ratings
    .map((rating) => ({
      userId: stringifyValue(rating.userId),
      value: Number(rating.value) || 0,
    }))
    .filter((rating) => rating.value >= 1 && rating.value <= 5);
  const ratingCount = normalizedRatings.length;
  const ratingAverage =
    ratingCount > 0
      ? Number(
          (
            normalizedRatings.reduce((sum, rating) => sum + rating.value, 0) /
            ratingCount
          ).toFixed(1)
        )
      : 0;
  const currentUserRating =
    viewerId == null
      ? null
      : normalizedRatings.find((rating) => rating.userId === viewerId)?.value ?? null;

  return {
    ...source,
    _id: stringifyValue(source._id),
    comments: normalizedComments,
    commentCount: normalizedComments.length,
    ratingAverage,
    ratingCount,
    currentUserRating,
    ratings: undefined,
  };
}

function normalizeCommentMessage(message) {
  return stringifyValue(message).trim().replace(/\s+/g, ' ');
}

function normalizeRatingValue(rating) {
  const parsedRating = Number(rating);
  if (!Number.isFinite(parsedRating)) {
    return null;
  }

  const normalizedRating = Math.round(parsedRating);
  if (normalizedRating < 1 || normalizedRating > 5) {
    return null;
  }

  return normalizedRating;
}

async function getPublicCourses(currentUser) {
  await ensureSystemCourses();
  const courses = await Course.find({
    isPublic: true,
    $or: [{ verificationStatus: 'approved' }, { createdBy: { $exists: true } }],
  })
    .populate('createdBy', 'name email role')
    .sort({
      updatedAt: -1,
      createdAt: -1,
    });

  const eligibleCourses = courses.filter((course) => {
    const creatorRole = course.createdBy?.role;
    return creatorRole === 'admin' || course.verificationStatus === 'approved';
  });

  if (!eligibleCourses.length) {
    return [];
  }

  return (await rankPublicCourses(eligibleCourses, currentUser)).map((course) =>
    serializeCourse(course, currentUser?._id?.toString())
  );
}

async function getCommunityCourses(currentUserId) {
  await ensureSystemCourses();
  const courses = await Course.find({
    isPublic: true,
    verificationStatus: { $ne: 'approved' },
    createdBy: { $ne: currentUserId },
  })
    .populate('createdBy', 'name email role')
    .sort({ updatedAt: -1, createdAt: -1 });

  return courses
    .filter((course) => course.createdBy?.role !== 'admin')
    .map((course) => serializeCourse(course, currentUserId?.toString()));
}

async function getMineCourses(userId) {
  const courses = await Course.find({ createdBy: userId })
    .populate('createdBy', 'name email role')
    .sort({ updatedAt: -1, createdAt: -1, courseName: 1 });
  return attachCourseStats(courses, userId?.toString());
}

async function createMineCourse(data, userId) {
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
    verificationStatus: 'none',
    createdBy: userId,
  });

  const [courseWithStats] = await attachCourseStats([course], userId?.toString());
  return courseWithStats;
}

async function updateMineCourse(id, data, userId) {
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
    if (data.isPublic === false) {
      update.verificationStatus = 'none';
      update.verifiedAt = null;
      update.verifiedBy = null;
      update.verificationRequestedAt = null;
      update.verificationReviewedAt = null;
      update.verificationReviewedBy = null;
      update.verificationRejectedReason = '';
    }
  }

  const existingCourse = await Course.findOne({ _id: id, createdBy: userId });
  if (!existingCourse) {
    throw new Error('Course not found');
  }

  if (
    existingCourse.verificationStatus === 'approved' &&
    data.isPublic !== false
  ) {
    update.hasUnreadUpdateNotification = true;
    update.lastUpdateNotificationAt = new Date();
    update.lastUpdateNotificationMessage = 'Verified course was updated';
  }

  const course = await Course.findOneAndUpdate(
    { _id: id, createdBy: userId },
    update,
    { returnDocument: 'after', runValidators: true }
  ).populate('createdBy', 'name email role');

  if (!course) {
    throw new Error('Course not found');
  }

  const [courseWithStats] = await attachCourseStats([course], userId?.toString());
  return courseWithStats;
}

async function deleteMineCourse(id, userId) {
  const course = await Course.findOneAndDelete({ _id: id, createdBy: userId });

  if (!course) {
    throw new Error('Course not found');
  }

  await BuilderProject.updateMany(
    { courseId: { $in: [course._id.toString(), course.courseId].filter(Boolean) } },
    { $set: { courseId: '', orderInCourse: 0 } }
  );

  return course;
}

async function requestMineCourseVerification(id, userId) {
  const course = await Course.findOne({ _id: id, createdBy: userId });

  if (!course) {
    throw new Error('Course not found');
  }

  if (!course.isPublic) {
    throw new Error('Make the course public before requesting verification');
  }

  if (course.verificationStatus === 'pending') {
    throw new Error('Verification request is already pending');
  }

  if (course.verificationStatus === 'approved') {
    throw new Error('Course is already verified');
  }

  course.verificationStatus = 'pending';
  course.verificationRequestedAt = new Date();
  course.verificationReviewedAt = null;
  course.verificationReviewedBy = null;
  course.verificationRejectedReason = '';
  return course.save();
}

async function attachCourseStats(courses, viewerId) {
  const courseObjects = courses.map((course) =>
    typeof course.toObject === 'function' ? course.toObject() : course
  );
  const courseKeys = courseObjects
    .flatMap((course) => [course._id?.toString(), course.courseId])
    .filter(Boolean);

  const levelCounts = courseKeys.length
    ? await BuilderProject.aggregate([
        { $match: { courseId: { $in: courseKeys } } },
        { $group: { _id: '$courseId', totalLevels: { $sum: 1 } } },
      ])
    : [];
  const levelsByCourse = new Map(
    levelCounts.map((item) => [item._id?.toString(), item.totalLevels])
  );

  return courseObjects.map((course) => {
    const objectId = course._id?.toString();
    return serializeCourse({
      ...course,
      totalLevels:
        levelsByCourse.get(course.courseId) || levelsByCourse.get(objectId) || 0,
    }, viewerId);
  });
}

async function getPublicCourseLevels(courseId) {
  const course = await findPublicCourse(courseId);
  const courseKeys = [course._id.toString(), course.courseId].filter(Boolean);

  return BuilderProject.find({
    courseId: { $in: courseKeys },
    status: 'published',
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

async function completeCourseLevel(courseId, user, levelId, result = {}) {
  const course = await findPublicCourse(courseId);
  const courseKeys = [course._id.toString(), course.courseId].filter(Boolean);
  const level = await BuilderProject.findOne({
    _id: levelId,
    courseId: { $in: courseKeys },
    status: 'published',
  }).select('_id orderInCourse');

  if (!level) {
    throw new Error('Level not found in this course');
  }

  const progress =
    (await CourseProgress.findOne({
      userId: user._id.toString(),
      courseId: course._id.toString(),
    })) ||
    new CourseProgress({
      userId: user._id.toString(),
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
  });
  progress.completedAt =
    levelCount > 0 && progress.completedLevels.length >= levelCount
      ? new Date()
      : null;

  await recordCourseInteractionAndStats({
    courseId: course._id.toString(),
    user,
    eventType: 'level_complete',
  });

  return progress.save();
}

async function trackCourseEvent(courseId, user, eventType) {
  if (!['view', 'click', 'level_play', 'level_complete'].includes(eventType)) {
    throw new Error('Invalid event type');
  }

  const course = await findPublicCourse(courseId);
  return recordCourseInteractionAndStats({
    courseId: course._id.toString(),
    user,
    eventType,
  });
}

async function addCourseComment(courseId, message, user) {
  const normalizedMessage = normalizeCommentMessage(message);
  if (!normalizedMessage) {
    throw new Error('Comment cannot be empty.');
  }

  if (normalizedMessage.length > 500) {
    throw new Error('Comment must be 500 characters or fewer.');
  }

  const userId = user._id.toString();
  const course = await Course.findOneAndUpdate(
    {
      isPublic: true,
      $or: buildCourseLookup(courseId),
    },
    {
      $push: {
        comments: {
          userId,
          userName: user.name,
          message: normalizedMessage,
        },
      },
    },
    {
      returnDocument: 'after',
      runValidators: true,
    }
  ).populate('createdBy', 'name email role');

  return serializeCourse(course, userId);
}

async function deleteCourseComment(courseId, commentId, user) {
  const userId = user._id.toString();
  const course = await Course.findOne({
    isPublic: true,
    createdBy: user._id,
    $or: buildCourseLookup(courseId),
    'comments._id': commentId,
  }).populate('createdBy', 'name email role');

  if (!course) {
    return null;
  }

  course.comments = course.comments.filter(
    (comment) => stringifyValue(comment._id) !== stringifyValue(commentId)
  );
  await course.save();
  return serializeCourse(course, userId);
}

async function rateCourse(courseId, rating, user) {
  const normalizedRating = normalizeRatingValue(rating);
  if (normalizedRating == null) {
    throw new Error('Rating must be a whole number between 1 and 5.');
  }

  const course = await Course.findOne({
    isPublic: true,
    $or: buildCourseLookup(courseId),
  }).populate('createdBy', 'name email role');

  if (!course) {
    return null;
  }

  const userId = user._id.toString();
  const existingRating = course.ratings.find(
    (entry) => stringifyValue(entry.userId) === userId
  );

  if (existingRating) {
    existingRating.value = normalizedRating;
    existingRating.userName = user.name;
  } else {
    course.ratings.push({
      userId,
      userName: user.name,
      value: normalizedRating,
    });
  }

  await course.save();
  return serializeCourse(course, userId);
}

async function findPublicCourse(courseId) {
  await ensureSystemCourses();
  const courseQuery = buildCourseLookup(courseId);

  const course = await Course.findOne({
    isPublic: true,
    $or: courseQuery,
  }).populate('createdBy', 'role');

  if (!course) {
    throw new Error('Course not found');
  }

  const creatorRole = course.createdBy?.role;
  if (!(creatorRole === 'admin' || course.verificationStatus === 'approved')) {
    throw new Error('Course not found');
  }

  return course;
}

function buildCourseLookup(courseId) {
  const courseQuery = [{ courseId }];
  if (mongoose.Types.ObjectId.isValid(courseId)) {
    courseQuery.push({ _id: courseId });
  }
  return courseQuery;
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

async function rankPublicCourses(courses, currentUser) {
  const courseObjects = courses.map((course) =>
    typeof course.toObject === 'function' ? course.toObject() : course
  );
  const courseIds = courseObjects.map((course) => course._id.toString());
  const courseKeyToCourseId = new Map();
  for (const course of courseObjects) {
    const courseId = course._id.toString();
    courseKeyToCourseId.set(courseId, courseId);
    if (course.courseId) {
      courseKeyToCourseId.set(course.courseId, courseId);
    }
  }

  const [publishedLevels, userProgressDocs] = await Promise.all([
    BuilderProject.find({
      courseId: { $in: Array.from(courseKeyToCourseId.keys()) },
      status: 'published',
    })
      .select('courseId builderType difficulty playCount ratings')
      .lean(),
    currentUser?._id
      ? CourseProgress.find({
          userId: currentUser._id.toString(),
          courseId: { $in: courseIds },
        }).lean()
      : [],
  ]);

  const levelStatsByCourseId = buildLevelStatsByCourseId(
    publishedLevels,
    courseKeyToCourseId
  );
  const progressByCourseId = new Map(
    userProgressDocs.map((progress) => [progress.courseId, progress])
  );

  const preferenceProfile = buildPreferenceProfile(
    courseObjects,
    levelStatsByCourseId,
    progressByCourseId
  );

  const cohortAgeGroup = normalizeAgeGroup(currentUser?.ageGroup);
  const cohortGender = normalizeGender(currentUser?.gender);

  const maxValues = {
    click: 0,
    play: 0,
    complete: 0,
    cohortClick: 0,
    cohortPlay: 0,
    cohortComplete: 0,
    totalLevels: 0,
    ratingCount: 0,
  };

  const preparedCourses = courseObjects.map((course) => {
    const courseId = course._id.toString();
    const levelStats = levelStatsByCourseId.get(courseId) || emptyLevelStats();
    const interactionStats = readRecommendationStats(course.recommendationStats);
    const cohortStats = readCohortStats(
      interactionStats,
      cohortAgeGroup,
      cohortGender
    );
    const progress = progressByCourseId.get(courseId);
    const quality = {
      average: levelStats.ratingAverage,
      count: levelStats.ratingCount,
    };
    maxValues.click = Math.max(maxValues.click, interactionStats.click);
    maxValues.play = Math.max(maxValues.play, interactionStats.level_play);
    maxValues.complete = Math.max(
      maxValues.complete,
      interactionStats.level_complete
    );
    maxValues.cohortClick = Math.max(maxValues.cohortClick, cohortStats.click);
    maxValues.cohortPlay = Math.max(maxValues.cohortPlay, cohortStats.level_play);
    maxValues.cohortComplete = Math.max(
      maxValues.cohortComplete,
      cohortStats.level_complete
    );
    maxValues.totalLevels = Math.max(maxValues.totalLevels, levelStats.totalLevels);
    maxValues.ratingCount = Math.max(maxValues.ratingCount, quality.count);

    return {
      ...course,
      _courseId: courseId,
      _levelStats: levelStats,
      _interactionStats: interactionStats,
      _cohortStats: cohortStats,
      _progress: progress,
      _quality: quality,
    };
  });

  const scoredCourses = preparedCourses.map((course) => {
    const globalPopularity =
      0.35 * normalizeCount(course._interactionStats.click, maxValues.click) +
      0.35 *
        normalizeCount(course._interactionStats.level_play, maxValues.play) +
      0.20 *
        normalizeCount(
          course._interactionStats.level_complete,
          maxValues.complete
        ) +
      0.10 * normalizeCount(course._levelStats.totalLevels, maxValues.totalLevels);

    const rawCohortPopularity =
      0.45 * normalizeCount(course._cohortStats.click, maxValues.cohortClick) +
      0.35 *
        normalizeCount(course._cohortStats.level_play, maxValues.cohortPlay) +
      0.20 *
        normalizeCount(
          course._cohortStats.level_complete,
          maxValues.cohortComplete
        );
    const cohortPopularity = shrinkTowardGlobal(
      rawCohortPopularity,
      course._cohortStats.sampleSize,
      globalPopularity
    );

    const personalFit = calculatePersonalFit(
      course,
      course._levelStats,
      preferenceProfile
    );
    const progressFit = calculateProgressFit(course._progress);
    const quality =
      0.70 * normalizeAverageRating(course._quality.average) +
      0.30 * normalizeCount(course._quality.count, maxValues.ratingCount);
    const freshness = calculateFreshness(course.updatedAt);

    const recommendationScore =
      0.30 * personalFit +
      0.25 * cohortPopularity +
      0.20 * globalPopularity +
      0.15 * progressFit +
      0.05 * quality +
      0.05 * freshness;

    return {
      ...course,
      totalLevels: course._levelStats.totalLevels,
      recommendationScore,
      progressFit,
      _sortUpdatedAt: new Date(course.updatedAt || course.createdAt || 0).getTime(),
    };
  });

  scoredCourses.sort((left, right) => {
    if (right.recommendationScore !== left.recommendationScore) {
      return right.recommendationScore - left.recommendationScore;
    }
    if (right.progressFit !== left.progressFit) {
      return right.progressFit - left.progressFit;
    }
    if (right._sortUpdatedAt !== left._sortUpdatedAt) {
      return right._sortUpdatedAt - left._sortUpdatedAt;
    }
    return String(left.courseName || '').localeCompare(String(right.courseName || ''));
  });

  return scoredCourses.map((course) => {
    const {
      _courseId,
      _levelStats,
      _interactionStats,
      _cohortStats,
      _progress,
      _quality,
      _sortUpdatedAt,
      recommendationScore,
      progressFit,
      ...publicCourse
    } = course;
    return publicCourse;
  });
}

function buildLevelStatsByCourseId(levels, courseKeyToCourseId) {
  const statsByCourseId = new Map();
  for (const level of levels) {
    const courseId = courseKeyToCourseId.get(level.courseId);
    if (!courseId) {
      continue;
    }
    const stats = statsByCourseId.get(courseId) || emptyLevelStats();
    stats.totalLevels += 1;
    stats.playCount += Number(level.playCount || 0);
    const builderType = String(level.builderType || '').trim();
    if (builderType) {
      stats.builderTypeCounts.set(
        builderType,
        (stats.builderTypeCounts.get(builderType) || 0) + 1
      );
    }
    const difficulty = String(level.difficulty || '').trim();
    if (difficulty) {
      stats.difficultyCounts.set(
        difficulty,
        (stats.difficultyCounts.get(difficulty) || 0) + 1
      );
    }
    const ratings = Array.isArray(level.ratings) ? level.ratings : [];
    for (const rating of ratings) {
      const value = Number(rating?.value || 0);
      if (!Number.isFinite(value) || value <= 0) {
        continue;
      }
      stats.ratingSum += value;
      stats.ratingCount += 1;
    }
    statsByCourseId.set(courseId, stats);
  }

  for (const stats of statsByCourseId.values()) {
    stats.primaryBuilderType = dominantMapKey(stats.builderTypeCounts);
    stats.primaryDifficulty = dominantMapKey(stats.difficultyCounts);
    stats.ratingAverage =
      stats.ratingCount > 0 ? stats.ratingSum / stats.ratingCount : 0;
  }

  return statsByCourseId;
}

function buildPreferenceProfile(
  courses,
  levelStatsByCourseId,
  progressByCourseId
) {
  const courseById = new Map(courses.map((course) => [course._id.toString(), course]));
  const categoryCounts = new Map();
  const builderTypeCounts = new Map();
  const difficultyCounts = new Map();
  const creatorCounts = new Map();

  for (const [courseId, course] of courseById.entries()) {
    const progress = progressByCourseId.get(courseId);
    const weight = progress ? 2 + progress.completedLevels.length : 0;
    if (weight <= 0) {
      continue;
    }
    const category = String(course.category || '').trim();
    if (category) {
      categoryCounts.set(category, (categoryCounts.get(category) || 0) + weight);
    }
    const levelStats = levelStatsByCourseId.get(courseId) || emptyLevelStats();
    if (levelStats.primaryBuilderType) {
      builderTypeCounts.set(
        levelStats.primaryBuilderType,
        (builderTypeCounts.get(levelStats.primaryBuilderType) || 0) + weight
      );
    }
    if (levelStats.primaryDifficulty) {
      difficultyCounts.set(
        levelStats.primaryDifficulty,
        (difficultyCounts.get(levelStats.primaryDifficulty) || 0) + weight
      );
    }
    const creatorId = course.createdBy?._id?.toString();
    if (creatorId) {
      creatorCounts.set(creatorId, (creatorCounts.get(creatorId) || 0) + weight);
    }
  }

  return {
    categoryCounts,
    builderTypeCounts,
    difficultyCounts,
    creatorCounts,
    categoryMax: maxMapValue(categoryCounts),
    builderTypeMax: maxMapValue(builderTypeCounts),
    difficultyMax: maxMapValue(difficultyCounts),
    creatorMax: maxMapValue(creatorCounts),
  };
}

function calculatePersonalFit(course, levelStats, preferenceProfile) {
  const categoryMatch = normalizedPreferenceScore(
    preferenceProfile.categoryCounts,
    String(course.category || '').trim(),
    preferenceProfile.categoryMax
  );
  const builderTypeMatch = normalizedPreferenceScore(
    preferenceProfile.builderTypeCounts,
    levelStats.primaryBuilderType,
    preferenceProfile.builderTypeMax
  );
  const difficultyMatch = normalizedPreferenceScore(
    preferenceProfile.difficultyCounts,
    levelStats.primaryDifficulty,
    preferenceProfile.difficultyMax
  );
  const creatorAffinity = normalizedPreferenceScore(
    preferenceProfile.creatorCounts,
    course.createdBy?._id?.toString() || '',
    preferenceProfile.creatorMax
  );

  return (
    0.45 * categoryMatch +
    0.25 * builderTypeMatch +
    0.20 * difficultyMatch +
    0.10 * creatorAffinity
  );
}

function calculateProgressFit(progress) {
  if (!progress) {
    return 0.4;
  }
  return progress.completedAt ? 0.1 : 1.0;
}

function calculateFreshness(updatedAt) {
  const timestamp = new Date(updatedAt || 0).getTime();
  if (!Number.isFinite(timestamp) || timestamp <= 0) {
    return 0;
  }
  const ageInDays = Math.max(0, (Date.now() - timestamp) / (1000 * 60 * 60 * 24));
  return Math.exp(-ageInDays / 30);
}

function normalizeCount(value, maxValue) {
  const safeValue = Number(value || 0);
  const safeMax = Number(maxValue || 0);
  if (!Number.isFinite(safeValue) || safeValue <= 0 || safeMax <= 0) {
    return 0;
  }
  return Math.log(1 + safeValue) / Math.log(1 + safeMax);
}

function normalizeAverageRating(value) {
  const rating = Number(value || 0);
  if (!Number.isFinite(rating) || rating <= 0) {
    return 0;
  }
  return Math.min(rating / 5, 1);
}

function shrinkTowardGlobal(cohortScore, sampleSize, globalScore) {
  const confidence = sampleSize > 0 ? sampleSize / (sampleSize + 20) : 0;
  return confidence * cohortScore + (1 - confidence) * globalScore;
}

function normalizedPreferenceScore(map, key, maxValue) {
  if (!key || !maxValue) {
    return 0;
  }
  return (map.get(key) || 0) / maxValue;
}

function dominantMapKey(map) {
  let bestKey = '';
  let bestValue = 0;
  for (const [key, value] of map.entries()) {
    if (value > bestValue) {
      bestKey = key;
      bestValue = value;
    }
  }
  return bestKey;
}

function maxMapValue(map) {
  let maxValue = 0;
  for (const value of map.values()) {
    if (value > maxValue) {
      maxValue = value;
    }
  }
  return maxValue;
}

function emptyLevelStats() {
  return {
    totalLevels: 0,
    playCount: 0,
    builderTypeCounts: new Map(),
    difficultyCounts: new Map(),
    primaryBuilderType: '',
    primaryDifficulty: '',
    ratingSum: 0,
    ratingCount: 0,
    ratingAverage: 0,
  };
}

function emptyInteractionStats() {
  return {
    view: 0,
    click: 0,
    level_play: 0,
    level_complete: 0,
    cohorts: new Map(),
  };
}

function readCohortStats(interactionStats, ageGroup, gender) {
  if (ageGroup === 'unknown' || gender === 'unknown') {
    return {
      click: 0,
      level_play: 0,
      level_complete: 0,
      sampleSize: 0,
    };
  }
  return (
    interactionStats.cohorts.get(buildCohortKey(ageGroup, gender)) || {
      click: 0,
      level_play: 0,
      level_complete: 0,
      sampleSize: 0,
    }
  );
}

function buildCohortKey(ageGroup, gender) {
  return `${ageGroup}_${gender}`;
}

async function recordCourseInteractionAndStats({ courseId, user, eventType }) {
  const interaction = await CourseInteraction.create({
    userId: user._id.toString(),
    courseId,
    eventType,
    ageGroupAtEvent: normalizeAgeGroup(user.ageGroup),
    genderAtEvent: normalizeGender(user.gender),
  });

  await incrementCourseRecommendationStats(courseId, {
    ageGroup: interaction.ageGroupAtEvent,
    gender: interaction.genderAtEvent,
    eventType,
  });

  return interaction;
}

function normalizeAgeGroup(ageGroup) {
  return [
    'under_6',
    '6_8',
    '9_11',
    '12_14',
    '15_17',
    '18_plus',
  ].includes(ageGroup)
    ? ageGroup
    : 'unknown';
}

function normalizeGender(gender) {
  return gender === 'male' || gender === 'female' ? gender : 'unknown';
}

async function incrementCourseRecommendationStats(
  courseId,
  { ageGroup, gender, eventType }
) {
  const counterPath = recommendationEventPath(eventType);
  const update = {
    $inc: {
      [`recommendationStats.global.${counterPath}`]: 1,
    },
    $set: {
      'recommendationStats.updatedAt': new Date(),
    },
  };

  if (ageGroup !== 'unknown' && gender !== 'unknown') {
    const cohortKey = buildCohortKey(ageGroup, gender);
    update.$inc[`recommendationStats.cohorts.${cohortKey}.${counterPath}`] = 1;
    update.$inc[`recommendationStats.cohorts.${cohortKey}.sampleSize`] = 1;
  }

  await Course.updateOne({ _id: courseId }, update);
}

function recommendationEventPath(eventType) {
  return {
    view: 'views',
    click: 'clicks',
    level_play: 'levelPlays',
    level_complete: 'levelCompletions',
  }[eventType];
}

function readRecommendationStats(recommendationStats) {
  const global = recommendationStats?.global || {};
  const cohortEntries = recommendationStats?.cohorts instanceof Map
    ? Array.from(recommendationStats.cohorts.entries())
    : Object.entries(recommendationStats?.cohorts || {});
  const cohorts = new Map();

  for (const [key, value] of cohortEntries) {
    if (!key || !value) {
      continue;
    }
    cohorts.set(key, {
      view: Number(value.views || 0),
      click: Number(value.clicks || 0),
      level_play: Number(value.levelPlays || 0),
      level_complete: Number(value.levelCompletions || 0),
      sampleSize: Number(value.sampleSize || 0),
    });
  }

  return {
    view: Number(global.views || 0),
    click: Number(global.clicks || 0),
    level_play: Number(global.levelPlays || 0),
    level_complete: Number(global.levelCompletions || 0),
    cohorts,
  };
}

module.exports = {
  getMineCourses,
  createMineCourse,
  updateMineCourse,
  deleteMineCourse,
  requestMineCourseVerification,
  getPublicCourses,
  getCommunityCourses,
  getPublicCourseLevels,
  getCourseProgress,
  completeCourseLevel,
  trackCourseEvent,
  addCourseComment,
  deleteCourseComment,
  rateCourse,
};
