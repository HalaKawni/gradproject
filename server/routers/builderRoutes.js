const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const builderController = require('../controller/builderController');

router.use(authMiddleware);

router.post('/projects', builderController.createProject);
router.put('/projects/:id', builderController.updateProject);
router.get('/projects/:id', builderController.getProjectById);
router.get('/projects', builderController.getAllProjects);

module.exports = router;
