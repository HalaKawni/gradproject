const BuilderProject = require('../model/builderProjectModel');

function buildOwnerSummary(user) {
  return {
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    role: user.role,
  };
}

function buildDraftData(projectData, user) {
  return {
    ...projectData,
    owner: buildOwnerSummary(user),
  };
}

async function createProject(projectData, user) {
  const owner = buildOwnerSummary(user);
  const project = new BuilderProject({
    ownerId: owner.id,
    ownerName: owner.name,
    ownerEmail: owner.email,
    ownerRole: owner.role,
    title: projectData.title || 'New Level',
    description: projectData.description || '',
    status: projectData.status || 'draft',
    draftData: buildDraftData(projectData, user),
  });

  return await project.save();
}

async function updateProject(projectId, projectData, user) {
  const owner = buildOwnerSummary(user);

  return await BuilderProject.findOneAndUpdate(
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
      draftData: buildDraftData(projectData, user),
    },
    {
      new: true,
    }
  );
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
    .select('_id title description status updatedAt ownerName')
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
