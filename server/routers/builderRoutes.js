const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const builderController = require('../controller/builderController');
const uploadedAssetController = require('../controller/uploadedAsset.controller');

router.use(authMiddleware);

router.post('/assets', uploadedAssetController.createAsset);
router.get('/assets', uploadedAssetController.listAssets);
router.get('/assets/public', uploadedAssetController.listPublicAssets);
router.get('/assets/:id/data', uploadedAssetController.getAssetData);
router.get('/assets/:id', uploadedAssetController.getAssetMetadata);
router.put('/assets/:id', uploadedAssetController.updateAsset);
router.delete('/assets/:id', uploadedAssetController.deleteAsset);
router.post('/projects', builderController.createProject);
router.put('/projects/:id', builderController.updateProject);
router.delete('/projects/:id', builderController.deleteProject);
router.get('/projects/published', builderController.getPublishedProjects);
router.get('/projects/published/:id', builderController.getPublishedProjectById);
router.get('/projects/:id', builderController.getProjectById);
router.get('/projects', builderController.getAllProjects);

module.exports = router;
