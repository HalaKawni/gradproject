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

    const project = await builderService.createProject(req.body, req.user, req.query.lang);

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

    const project = await builderService.updateProject(id, req.body, req.user, req.query.lang);

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

async function updateProjectSettings(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.updateProjectSettings(
      id,
      req.body,
      req.user,
      req.query.lang
    );

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Project settings updated successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update project settings.',
      error: error.message,
    });
  }
}

async function getProjectById(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.getProjectById(id, req.user, req.query.lang);

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
    const projects = await builderService.getAllProjects(req.user, req.query.lang);

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

async function getPublishedProjects(req, res) {
  try {
    const projects = await builderService.getPublishedProjects(req.user, req.query.lang);

    return res.status(200).json({
      success: true,
      data: projects,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch published projects.',
      error: error.message,
    });
  }
}

async function getPublishedProjectById(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.getPublishedProjectById(id, req.user, req.query.lang);

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Published project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch published project.',
      error: error.message,
    });
  }
}

async function incrementProjectPlayCount(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.incrementProjectPlayCount(id, req.user, req.query.lang);

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Published project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Play count updated successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update play count.',
      error: error.message,
    });
  }
}

async function addProjectComment(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.addProjectComment(
      id,
      req.body.message,
      req.user,
      req.query.lang
    );

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Comment added successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to add comment.',
    });
  }
}

async function deleteProjectComment(req, res) {
  try {
    const { id, commentId } = req.params;
    const project = await builderService.deleteProjectComment(
      id,
      commentId,
      req.user,
      req.query.lang
    );

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Comment deleted successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to delete comment.',
    });
  }
}

async function rateProject(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.rateProject(
      id,
      req.body.rating,
      req.user,
      req.query.lang
    );

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Published project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Rating saved successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to save rating.',
    });
  }
}

async function deleteProject(req, res) {
  try {
    const { id } = req.params;
    const project = await builderService.deleteProject(id, req.user);

    if (!project) {
      return res.status(404).json({
        success: false,
        message: 'Project not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Project deleted successfully.',
      data: project,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to delete project.',
      error: error.message,
    });
  }
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
