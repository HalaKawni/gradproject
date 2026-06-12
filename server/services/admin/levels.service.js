const BuilderProject = require('../../model/builderProjectModel');
const uploadedAssetService = require('../uploadedAsset.service');
const { prepareLocalizedInput } = require('../localizedContent.service');

const LEVEL_LOCALIZATION_CONFIG = {
  directFields: ['title', 'description'],
  recursiveFields: ['title', 'description', 'instructions', 'instruction', 'lessonText', 'text', 'content', 'body', 'summary', 'subtitle'],
};

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
  const localizedData = prepareLocalizedInput(data, LEVEL_LOCALIZATION_CONFIG);
  const update = {};

  if (localizedData.title !== undefined) {
    update.title = localizedData.title;
  }

  if (localizedData.description !== undefined) {
    update.description = localizedData.description;
  }

  if (localizedData.coverImageBase64 !== undefined) {
    update.coverImageBase64 = localizedData.coverImageBase64;
  }

  if (localizedData.coverFrameScale !== undefined) {
    update.coverFrameScale = Number(localizedData.coverFrameScale);
  }

  if (localizedData.coverFrameOffsetX !== undefined) {
    update.coverFrameOffsetX = Number(localizedData.coverFrameOffsetX);
  }

  if (localizedData.coverFrameOffsetY !== undefined) {
    update.coverFrameOffsetY = Number(localizedData.coverFrameOffsetY);
  }

  if (localizedData.builderType !== undefined) {
    update.builderType = localizedData.builderType;
  }

  if (localizedData.difficulty !== undefined) {
    update.difficulty = localizedData.difficulty;
  }

  if (localizedData.status !== undefined) {
    update.status = localizedData.status;
  }

  if (localizedData.levelJson !== undefined || localizedData.draftData !== undefined) {
    update.draftData = localizedData.levelJson ?? localizedData.draftData;
  }

  if (localizedData.codeBySpriteId !== undefined && update.draftData) {
    update.draftData = {
      ...update.draftData,
      codeBySpriteId: localizedData.codeBySpriteId,
    };
  }

  if (localizedData.courseId !== undefined) {
    const nextCourseId = localizedData.courseId?.toString() ?? '';
    update.courseId = nextCourseId;

    if (localizedData.orderInCourse === undefined) {
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

  if (localizedData.orderInCourse !== undefined) {
    update.orderInCourse = localizedData.orderInCourse;
  }

  if (localizedData.reviewStatus !== undefined) {
    update.reviewStatus = localizedData.reviewStatus;
  }

  if (localizedData.approvedBy !== undefined) {
    update.approvedBy = localizedData.approvedBy;
  }

  if (localizedData.reviewStatus === 'approved') {
    update.approvedAt = localizedData.approvedAt ? new Date(localizedData.approvedAt) : new Date();
  }

  if (localizedData.status === 'published' && !localizedData.publishedAt) {
    update.publishedAt = new Date();
  }

  const level = await BuilderProject.findByIdAndUpdate(id, update, {
    returnDocument: 'after',
    runValidators: true,
  });

  if (!level) {
    throw new Error('Level not found');
  }

  if (level.status === 'published') {
    await uploadedAssetService.makeAssetsPublicByIds(
      collectDraftAssetIds(level.draftData || {})
    );
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

function collectDraftAssetIds(draftData) {
  const customAssets = Array.isArray(draftData.customAssets)
    ? draftData.customAssets
    : [];

  return customAssets
    .map((asset) =>
      asset && typeof asset === 'object' ? asset.assetId : undefined
    )
    .filter(Boolean);
}
