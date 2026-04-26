const BuilderProject = require('../../model/builderProjectModel');

exports.getLevels = async (query) => {
  const status = query.status;
  const filter = {};

  if (status === 'published') {
    filter.status = 'published';
    filter.ownerRole = 'admin';
  }

  if (status === 'draft') {
    filter.status = 'draft';
    filter.ownerRole = 'admin';
  }

  if (status === 'userCreated') {
    filter.ownerRole = { $ne: 'admin' };
  }

  return BuilderProject.find(filter).sort({
    orderInCourse: 1,
    updatedAt: -1,
    createdAt: -1,
  });
};

exports.getLevelById = async (id) => {
  const level = await BuilderProject.findById(id);

  if (!level) {
    throw new Error('Level not found');
  }

  return level;
};

async function getNextOrderInCourse(courseId, excludedLevelId) {
  const lastLevel = await BuilderProject.findOne({
    _id: { $ne: excludedLevelId },
    courseId,
  })
    .sort({ orderInCourse: -1, updatedAt: -1 })
    .select('orderInCourse');

  return (lastLevel?.orderInCourse || 0) + 1;
}

exports.updateLevel = async (id, data) => {
  const update = {};

  if (data.title !== undefined) {
    update.title = data.title;
  }

  if (data.difficulty !== undefined) {
    update.difficulty = data.difficulty;
  }

  if (data.status !== undefined) {
    update.status = data.status;
  }

  if (data.levelJson !== undefined || data.draftData !== undefined) {
    update.draftData = data.levelJson ?? data.draftData;
  }

  if (data.courseId !== undefined) {
    const nextCourseId = data.courseId?.toString() ?? '';
    update.courseId = nextCourseId;

    if (data.orderInCourse === undefined) {
      if (nextCourseId === '') {
        update.orderInCourse = 0;
      } else {
        const currentLevel = await BuilderProject.findById(id).select(
          'courseId orderInCourse'
        );

        if (!currentLevel) {
          throw new Error('Level not found');
        }

        if (
          currentLevel.courseId !== nextCourseId ||
          !currentLevel.orderInCourse
        ) {
          update.orderInCourse = await getNextOrderInCourse(nextCourseId, id);
        }
      }
    }
  }

  if (data.orderInCourse !== undefined) {
    update.orderInCourse = data.orderInCourse;
  }

  if (data.reviewStatus !== undefined) {
    update.reviewStatus = data.reviewStatus;
  }

  if (data.approvedBy !== undefined) {
    update.approvedBy = data.approvedBy;
  }

  if (data.reviewStatus === 'approved') {
    update.approvedAt = data.approvedAt ? new Date(data.approvedAt) : new Date();
  }

  if (data.status === 'published' && !data.publishedAt) {
    update.publishedAt = new Date();
  }

  const level = await BuilderProject.findByIdAndUpdate(id, update, {
    returnDocument: 'after',
    runValidators: true,
  });

  if (!level) {
    throw new Error('Level not found');
  }

  return level;
};

exports.deleteLevel = async (id) => {
  const level = await BuilderProject.findByIdAndDelete(id);

  if (!level) {
    throw new Error('Level not found');
  }

  return level;
};
