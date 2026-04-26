const User = require('../../model/user.model');
const Course = require('../../model/course.model');
const BuilderProject = require('../../model/builderProjectModel');

exports.getDashboard = async () => {
  const totalUsers = await User.countDocuments();
  const totalCourses = await Course.countDocuments();
  const totalLevels = await BuilderProject.countDocuments();

  const publishedLevels = await BuilderProject.countDocuments({
    status: 'published',
  });

  const draftLevels = await BuilderProject.countDocuments({
    status: 'draft',
  });

  const userCreatedLevels = await BuilderProject.countDocuments({
    ownerRole: { $ne: 'admin' },
  });

  return {
    totalUsers,
    totalCourses,
    totalLevels,
    publishedLevels,
    draftLevels,
    userCreatedLevels,
  };
};
