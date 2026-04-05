const builderService = require('../services/builderService');
const { validateBuilderProject } = require('../utils/builderValidator');

async function createProject(req, res) {
  try {
    const validation = validateBuilderProject(req.body);

    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        errors: validation.errors,
      });
    }

    const project = await builderService.createProject(req.body, req.user);

    return res.status(201).json({
      success: true,
      message: 'Project created successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to create project.',
      error: error.message,
    });
  }
}

async function updateProject(req, res) {
  try {
    const { id } = req.params;
    const validation = validateBuilderProject(req.body);

    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        errors: validation.errors,
      });
    }

    const project = await builderService.updateProject(id, req.body, req.user);

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Project updated successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update project.',
      error: error.message,
    });
  }
}

async function getProjectById(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.getProjectById(id, req.user);

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch project.',
      error: error.message,
    });
  }
}

async function getAllProjects(req, res) {
  try {
    const projects = await builderService.getAllProjects(req.user);

    return res.status(200).json({
      success: true,
      data: projects,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch projects.',
      error: error.message,
    });
  }
}

module.exports = {
  createProject,
  updateProject,
  getProjectById,
  getAllProjects,
};
