const BuilderProject = require('../model/builderProjectModel');
const Course = require('../model/course.model');
const uploadedAssetService = require('./uploadedAsset.service');
const {
  FRONT_VIEW_COLLECTABLE_ITEMS,
  FRONT_VIEW_PLAYER_CHARACTERS,
  FRONT_VIEW_PLAYER_DIRECTIONS,
} = require('../utils/frontViewAssets');

const DEFAULT_PLAYER_CHARACTER = 'polar';
const DEFAULT_PLAYER_DIRECTION = 'right';
const DEFAULT_COLLECTABLE_ITEM = 'banana';

function buildOwnerSummary(user) {
  return {
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    role: user.role,
  };
}

function buildDraftData(projectData, user) {
  const builderType = projectData.builderType || 'frontView';
  const draftData = {
    ...projectData,
    builderType,
    owner: buildOwnerSummary(user),
  };

  if (builderType !== 'frontView') {
    delete draftData.frontViewDetails;
    return draftData;
  }

  return normalizeFrontViewDraftData(draftData);
}

function normalizeFrontViewDraftData(draftData) {
  const entities = Array.isArray(draftData.entities)
    ? draftData.entities.map(normalizeFrontViewEntity)
    : draftData.entities;

  const normalizedDraftData = {
    ...draftData,
    entities,
  };

  return {
    ...normalizedDraftData,
    frontViewDetails: buildFrontViewDetails(entities),
  };
}

function normalizeFrontViewEntity(entity) {
  if (!entity || typeof entity !== 'object' || Array.isArray(entity)) {
    return entity;
  }

  const config =
    entity.config && typeof entity.config === 'object' && !Array.isArray(entity.config)
      ? { ...entity.config }
      : {};

  if (entity.type === 'playerStart') {
    config.character = normalizeAllowedValue(
      config.character,
      FRONT_VIEW_PLAYER_CHARACTERS,
      DEFAULT_PLAYER_CHARACTER
    );
    config.direction = normalizeAllowedValue(
      config.direction,
      FRONT_VIEW_PLAYER_DIRECTIONS,
      DEFAULT_PLAYER_DIRECTION
    );
  }

  if (entity.type === 'collectable') {
    config.item = normalizeAllowedValue(
      config.item,
      FRONT_VIEW_COLLECTABLE_ITEMS,
      DEFAULT_COLLECTABLE_ITEM
    );
  }

  return {
    ...entity,
    config,
  };
}

function buildFrontViewDetails(entities) {
  const normalizedEntities = Array.isArray(entities) ? entities : [];
  const player = normalizedEntities.find((entity) => entity.type === 'playerStart');
  const collectables = normalizedEntities.filter(
    (entity) => entity.type === 'collectable'
  );

  return {
    player: player ? buildPlayerDetails(player) : null,
    collectables: collectables.map(buildCollectableDetails),
  };
}

function buildPlayerDetails(entity) {
  return {
    entityId: stringifyValue(entity.id),
    character: normalizeAllowedValue(
      entity.config && entity.config.character,
      FRONT_VIEW_PLAYER_CHARACTERS,
      DEFAULT_PLAYER_CHARACTER
    ),
    direction: normalizeAllowedValue(
      entity.config && entity.config.direction,
      FRONT_VIEW_PLAYER_DIRECTIONS,
      DEFAULT_PLAYER_DIRECTION
    ),
    x: normalizeCoordinate(entity.x),
    y: normalizeCoordinate(entity.y),
  };
}

function buildCollectableDetails(entity) {
  return {
    entityId: stringifyValue(entity.id),
    item: normalizeAllowedValue(
      entity.config && entity.config.item,
      FRONT_VIEW_COLLECTABLE_ITEMS,
      DEFAULT_COLLECTABLE_ITEM
    ),
    x: normalizeCoordinate(entity.x),
    y: normalizeCoordinate(entity.y),
  };
}

function normalizeAllowedValue(value, allowedValues, fallback) {
  const normalizedValue = typeof value === 'string' ? value.trim() : '';
  return allowedValues.includes(normalizedValue) ? normalizedValue : fallback;
}

function normalizeCoordinate(value) {
  const coordinate = Number(value);
  return Number.isFinite(coordinate) ? coordinate : 0;
}

function stringifyValue(value) {
  return value === undefined || value === null ? '' : String(value);
}

function serializeProject(project, viewerId) {
  if (!project) {
    return null;
  }

  const source = typeof project.toObject === 'function' ? project.toObject() : project;
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
    ownerId: stringifyValue(source.ownerId),
    playCount: Number(source.playCount) || 0,
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

async function createProject(projectData, user) {
  const owner = buildOwnerSummary(user);
  const draftData = buildDraftData(projectData, user);
  const project = new BuilderProject({
    ownerId: owner.id,
    ownerName: owner.name,
    ownerEmail: owner.email,
    ownerRole: owner.role,
    title: projectData.title || 'New Level',
    description: projectData.description || '',
    coverImageBase64: projectData.coverImageBase64 ?? null,
    coverFrameScale: Number(projectData.coverFrameScale ?? 1),
    coverFrameOffsetX: Number(projectData.coverFrameOffsetX ?? 0),
    coverFrameOffsetY: Number(projectData.coverFrameOffsetY ?? 0),
    status: projectData.status || 'draft',
    builderType: draftData.builderType,
    courseId: projectData.courseId,
    orderInCourse: projectData.orderInCourse,
    difficulty: projectData.difficulty || 'medium',
    ...(projectData.status === 'published' ? { publishedAt: new Date() } : {}),
    frontViewDetails: draftData.frontViewDetails || null,
    draftData,
  });

  const savedProject = await project.save();
  if (projectData.status === 'published') {
    await uploadedAssetService.makeAssetsPublic(
      collectDraftAssetIds(draftData),
      user
    );
  }

  return savedProject;
}

async function updateProject(projectId, projectData, user) {
  const owner = buildOwnerSummary(user);
  const draftData = buildDraftData(projectData, user);

  const project = await BuilderProject.findOneAndUpdate(
    {
      _id: projectId,
      ownerId: owner.id,
    },
    {
      ownerId: owner.id,
      ownerName: owner.name,
      ownerEmail: owner.email,
      ownerRole: owner.role,
      title: projectData.title || 'Untitled',
      description: projectData.description || '',
      ...(projectData.coverImageBase64 !== undefined
        ? { coverImageBase64: projectData.coverImageBase64 }
        : {}),
      ...(projectData.coverFrameScale !== undefined
        ? { coverFrameScale: Number(projectData.coverFrameScale) }
        : {}),
      ...(projectData.coverFrameOffsetX !== undefined
        ? { coverFrameOffsetX: Number(projectData.coverFrameOffsetX) }
        : {}),
      ...(projectData.coverFrameOffsetY !== undefined
        ? { coverFrameOffsetY: Number(projectData.coverFrameOffsetY) }
        : {}),
      status: projectData.status || 'draft',
      builderType: draftData.builderType,
      courseId: projectData.courseId,
      orderInCourse: projectData.orderInCourse,
      difficulty: projectData.difficulty || 'medium',
      ...(projectData.status === 'published' ? { publishedAt: new Date() } : {}),
      frontViewDetails: draftData.frontViewDetails || null,
      draftData,
    },
    {
      returnDocument: 'after',
    }
  );

  if (project && projectData.status === 'published') {
    await uploadedAssetService.makeAssetsPublic(
      collectDraftAssetIds(draftData),
      user
    );
  }

  return project;
}

async function updateProjectSettings(projectId, settingsData, user) {
  const update = {};

  if (settingsData.title !== undefined) {
    update.title = settingsData.title || 'Untitled';
  }

  if (settingsData.description !== undefined) {
    update.description = settingsData.description || '';
  }

  if (settingsData.status !== undefined) {
    update.status = settingsData.status;
    if (settingsData.status === 'published') {
      update.publishedAt = new Date();
    }
  }

  if (settingsData.difficulty !== undefined) {
    update.difficulty = settingsData.difficulty || 'medium';
  }

  if (settingsData.courseId !== undefined) {
    update.courseId = settingsData.courseId;
  }

  if (settingsData.orderInCourse !== undefined) {
    update.orderInCourse = settingsData.orderInCourse;
  }

  if (settingsData.coverImageBase64 !== undefined) {
    update.coverImageBase64 = settingsData.coverImageBase64;
  }

  if (settingsData.coverFrameScale !== undefined) {
    update.coverFrameScale = Number(settingsData.coverFrameScale);
  }

  if (settingsData.coverFrameOffsetX !== undefined) {
    update.coverFrameOffsetX = Number(settingsData.coverFrameOffsetX);
  }

  if (settingsData.coverFrameOffsetY !== undefined) {
    update.coverFrameOffsetY = Number(settingsData.coverFrameOffsetY);
  }

  const previousProject = await BuilderProject.findOne({
    _id: projectId,
    ownerId: user._id.toString(),
  }).select('courseId orderInCourse');

  const project = await BuilderProject.findOneAndUpdate(
    {
      _id: projectId,
      ownerId: user._id.toString(),
    },
    update,
    {
      returnDocument: 'after',
      runValidators: true,
    }
  );

  if (project && project.status === 'published') {
    await uploadedAssetService.makeAssetsPublic(
      collectDraftAssetIds(project.draftData || {}),
      user
    );
  }

  if (project) {
    await notifyVerifiedCourseIfLevelAssignmentChanged(
      previousProject?.courseId,
      project.courseId,
      user._id
    );
  }

  return project;
}

async function notifyVerifiedCourseIfLevelAssignmentChanged(
  previousCourseId,
  nextCourseId,
  userId
) {
  const courseIds = [previousCourseId, nextCourseId].filter(Boolean);
  if (!courseIds.length) {
    return;
  }

  await Course.updateMany(
    {
      verificationStatus: 'approved',
      createdBy: userId,
      courseId: { $in: courseIds },
    },
    {
      $set: {
        hasUnreadUpdateNotification: true,
        lastUpdateNotificationAt: new Date(),
        lastUpdateNotificationMessage: 'Verified course levels were updated',
      },
    }
  );
}

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

async function getProjectById(projectId, user) {
  const project = await BuilderProject.findOne({
    _id: projectId,
    ownerId: user._id.toString(),
  });
  return serializeProject(project, user._id.toString());
}

async function getAllProjects(user) {
  const projects = await BuilderProject.find({
    ownerId: user._id.toString(),
  }).sort({ updatedAt: -1 });
  return projects.map((project) => serializeProject(project, user._id.toString()));
}

async function getPublishedProjects(user) {
  const projects = await BuilderProject.find({
    status: 'published',
    ownerRole: { $ne: 'admin' },
  })
    .select(
      '_id title description status builderType difficulty courseId orderInCourse frontViewDetails coverImageBase64 coverFrameScale coverFrameOffsetX coverFrameOffsetY updatedAt ownerId ownerName ownerRole playCount comments ratings'
    )
    .sort({ updatedAt: -1 });
  return projects.map((project) => serializeProject(project, user?._id?.toString()));
}

async function getPublishedProjectById(projectId, user) {
  const project = await BuilderProject.findOne({
    _id: projectId,
    status: 'published',
  });
  return serializeProject(project, user?._id?.toString());
}

async function incrementProjectPlayCount(projectId, user) {
  const project = await BuilderProject.findOneAndUpdate(
    {
      _id: projectId,
      status: 'published',
      ownerRole: { $ne: 'admin' },
    },
    {
      $inc: { playCount: 1 },
    },
    {
      returnDocument: 'after',
      runValidators: true,
    }
  );

  return serializeProject(project, user?._id?.toString());
}

async function addProjectComment(projectId, message, user) {
  const normalizedMessage = normalizeCommentMessage(message);
  if (!normalizedMessage) {
    throw new Error('Comment cannot be empty.');
  }

  if (normalizedMessage.length > 500) {
    throw new Error('Comment must be 500 characters or fewer.');
  }

  const userId = user._id.toString();
  const project = await BuilderProject.findOneAndUpdate(
    {
      _id: projectId,
      $or: [{ status: 'published' }, { ownerId: userId }],
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
  );

  return serializeProject(project, userId);
}

async function deleteProjectComment(projectId, commentId, user) {
  const userId = user._id.toString();
  const project = await BuilderProject.findOne({
    _id: projectId,
    ownerId: userId,
    'comments._id': commentId,
  });

  if (!project) {
    return null;
  }

  project.comments = project.comments.filter(
    (comment) => stringifyValue(comment._id) !== stringifyValue(commentId)
  );
  await project.save();
  return serializeProject(project, userId);
}

async function rateProject(projectId, rating, user) {
  const normalizedRating = normalizeRatingValue(rating);
  if (normalizedRating == null) {
    throw new Error('Rating must be a whole number between 1 and 5.');
  }

  const project = await BuilderProject.findOne({
    _id: projectId,
    status: 'published',
    ownerRole: { $ne: 'admin' },
  });

  if (!project) {
    return null;
  }

  const userId = user._id.toString();
  const existingRating = project.ratings.find(
    (entry) => stringifyValue(entry.userId) === userId
  );

  if (existingRating) {
    existingRating.value = normalizedRating;
    existingRating.userName = user.name;
  } else {
    project.ratings.push({
      userId,
      userName: user.name,
      value: normalizedRating,
    });
  }

  await project.save();
  return serializeProject(project, userId);
}

async function deleteProject(projectId, user) {
  return await BuilderProject.findOneAndDelete({
    _id: projectId,
    ownerId: user._id.toString(),
  });
}

module.exports = {
  createProject,
  updateProject,
  updateProjectSettings,
  getProjectById,
  getAllProjects,
  getPublishedProjects,
  getPublishedProjectById,
  incrementProjectPlayCount,
  addProjectComment,
  deleteProjectComment,
  rateProject,
  deleteProject,
};
