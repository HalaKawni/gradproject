const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const builderController = require('../controller/builderController');

router.use(authMiddleware);

router.post('/projects', builderController.createProject);
router.put('/projects/:id', builderController.updateProject);
router.delete('/projects/:id', builderController.deleteProject);
router.get('/projects/published', builderController.getPublishedProjects);
router.get('/projects/published/:id', builderController.getPublishedProjectById);
router.get('/projects/:id', builderController.getProjectById);
router.get('/projects', builderController.getAllProjects);

module.exports = router;
