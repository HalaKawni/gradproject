const User = require('../../model/user.model');
const Course = require('../../model/course.model');
const BuilderProject = require('../../model/builderProjectModel');

exports.getStatistics = async () => {
  const usersByRole = await User.aggregate([
    {
      $group: {
        _id: '$role',
        count: { $sum: 1 },
      },
    },
  ]);

  const levelsByStatus = await BuilderProject.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
      },
    },
  ]);

  const totalCourses = await Course.countDocuments();

  return {
    usersByRole,
    levelsByStatus,
    totalCourses,
  };
};