const db = require('../config/db');
const Course = require('../model/course.model');
const CourseInteraction = require('../model/courseInteraction.model');

function emptyGlobalCounters() {
  return {
    views: 0,
    clicks: 0,
    levelPlays: 0,
    levelCompletions: 0,
  };
}

function emptyCohortCounters() {
  return {
    views: 0,
    clicks: 0,
    levelPlays: 0,
    levelCompletions: 0,
    sampleSize: 0,
  };
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

function buildCohortKey(ageGroup, gender) {
  return `${ageGroup}_${gender}`;
}

function counterFieldForEvent(eventType) {
  return {
    view: 'views',
    click: 'clicks',
    level_play: 'levelPlays',
    level_complete: 'levelCompletions',
  }[eventType];
}

async function backfillCourseRecommendationStats() {
  console.log('Resetting course recommendation stats...');
  await Course.updateMany(
    {},
    {
      $set: {
        recommendationStats: {
          global: emptyGlobalCounters(),
          cohorts: {},
          updatedAt: null,
        },
      },
    }
  );

  console.log('Reading raw course interactions...');
  const statsByCourseId = new Map();
  const latestTimestampByCourseId = new Map();

  const cursor = CourseInteraction.find({})
    .select('courseId eventType ageGroupAtEvent genderAtEvent createdAt')
    .lean()
    .cursor();

  for await (const interaction of cursor) {
    const courseId = String(interaction.courseId || '').trim();
    const counterField = counterFieldForEvent(interaction.eventType);
    if (!courseId || !counterField) {
      continue;
    }

    const stats =
      statsByCourseId.get(courseId) || {
        global: emptyGlobalCounters(),
        cohorts: {},
      };
    stats.global[counterField] += 1;

    const ageGroup = normalizeAgeGroup(interaction.ageGroupAtEvent);
    const gender = normalizeGender(interaction.genderAtEvent);
    if (ageGroup !== 'unknown' && gender !== 'unknown') {
      const cohortKey = buildCohortKey(ageGroup, gender);
      const cohortStats =
        stats.cohorts[cohortKey] || emptyCohortCounters();
      cohortStats[counterField] += 1;
      cohortStats.sampleSize += 1;
      stats.cohorts[cohortKey] = cohortStats;
    }

    statsByCourseId.set(courseId, stats);

    const createdAt = interaction.createdAt ? new Date(interaction.createdAt) : null;
    if (createdAt && Number.isFinite(createdAt.getTime())) {
      const currentLatest = latestTimestampByCourseId.get(courseId);
      if (!currentLatest || createdAt > currentLatest) {
        latestTimestampByCourseId.set(courseId, createdAt);
      }
    }
  }

  if (!statsByCourseId.size) {
    console.log('No raw interactions found. Backfill completed with zeroed stats.');
    return;
  }

  console.log(`Writing rebuilt stats for ${statsByCourseId.size} courses...`);
  const operations = [];
  for (const [courseId, stats] of statsByCourseId.entries()) {
    operations.push({
      updateOne: {
        filter: { _id: courseId },
        update: {
          $set: {
            recommendationStats: {
              global: stats.global,
              cohorts: stats.cohorts,
              updatedAt: latestTimestampByCourseId.get(courseId) || new Date(),
            },
          },
        },
      },
    });
  }

  if (operations.length) {
    await Course.bulkWrite(operations, { ordered: false });
  }

  console.log('Course recommendation stats backfill completed successfully.');
}

db.asPromise()
  .then(() => backfillCourseRecommendationStats())
  .then(async () => {
    await db.close();
  })
  .catch(async (error) => {
    console.error('Backfill failed:', error);
    try {
      await db.close();
    } catch (closeError) {
      console.error('Failed to close database connection:', closeError);
    }
    process.exitCode = 1;
  });
