const BuilderProject = require('../model/builderProjectModel');
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
  return await BuilderProject.findOne({
    _id: projectId,
    ownerId: user._id.toString(),
  });
}

async function getAllProjects(user) {
  return await BuilderProject.find({
    ownerId: user._id.toString(),
  }).sort({ updatedAt: -1 });
}

async function getPublishedProjects() {
  return await BuilderProject.find({
    status: 'published',
  })
    .select(
      '_id title description status builderType difficulty courseId orderInCourse frontViewDetails updatedAt ownerName'
    )
    .sort({ updatedAt: -1 });
}

async function getPublishedProjectById(projectId) {
  return await BuilderProject.findOne({
    _id: projectId,
    status: 'published',
  });
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
  getProjectById,
  getAllProjects,
  getPublishedProjects,
  getPublishedProjectById,
  deleteProject,
};
