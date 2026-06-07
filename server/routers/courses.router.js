const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const coursesController = require('../controller/courses.controller');

router.use(authMiddleware);

router.get('/public', coursesController.getPublicCourses);
router.get('/:courseId/progress', coursesController.getCourseProgress);
router.get('/:courseId/levels', coursesController.getPublicCourseLevels);
router.post(
  '/:courseId/levels/:levelId/complete',
  coursesController.completeCourseLevel
);

module.exports = router;
