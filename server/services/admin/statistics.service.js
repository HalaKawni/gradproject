const User = require('../../model/user.model');
const Course = require('../../model/course.model');
const BuilderProject = require('../../model/builderProjectModel');
const CourseInteraction = require('../../model/courseInteraction.model');

exports.getStatistics = async () => {
  const [usersByRole, levelsByStatus, totalCourses, coursePlayCounts] =
    await Promise.all([
      User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]),

      BuilderProject.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),

      Course.countDocuments(),

      // Rank courses by total level_play events already stored in CourseInteraction
      CourseInteraction.aggregate([
        { $match: { eventType: 'level_play' } },
        { $group: { _id: '$courseId', plays: { $sum: 1 } } },
        { $sort: { plays: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'courses',
            let: { cid: '$_id' },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $or: [
                      { $eq: [{ $toString: '$_id' }, '$$cid'] },
                      { $eq: ['$courseId', '$$cid'] },
                    ],
                  },
                },
              },
              { $project: { courseName: 1, courseId: 1 } },
              { $limit: 1 },
            ],
            as: 'courseInfo',
          },
        },
        {
          $project: {
            plays: 1,
            completions: 1,
            courseName: { $arrayElemAt: ['$courseInfo.courseName', 0] },
            courseId: { $arrayElemAt: ['$courseInfo.courseId', 0] },
          },
        },
      ]),
    ]);

  return {
    usersByRole,
    levelsByStatus,
    totalCourses,
    coursePlayCounts,
  };
};
