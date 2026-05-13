const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const coursesController = require('../controller/courses.controller');

router.use(authMiddleware);

router.get('/public', coursesController.getPublicCourses);
router.get('/:courseId/levels', coursesController.getPublicCourseLevels);

module.exports = router;
