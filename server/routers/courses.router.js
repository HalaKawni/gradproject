const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const coursesController = require('../controller/courses.controller');

router.use(authMiddleware);

router.get('/mine', coursesController.getMineCourses);
router.post('/mine', coursesController.createMineCourse);
router.put('/mine/:id', coursesController.updateMineCourse);
router.delete('/mine/:id', coursesController.deleteMineCourse);
router.post(
  '/mine/:id/verification-request',
  coursesController.requestMineCourseVerification
);
router.get('/public', coursesController.getPublicCourses);
router.get('/community', coursesController.getCommunityCourses);
router.post('/:courseId/events', coursesController.trackCourseEvent);
router.post('/:courseId/comments', coursesController.addCourseComment);
router.delete(
  '/:courseId/comments/:commentId',
  coursesController.deleteCourseComment
);
router.post('/:courseId/rating', coursesController.rateCourse);
router.get('/:courseId/progress', coursesController.getCourseProgress);
router.get('/:courseId/levels', coursesController.getPublicCourseLevels);
router.post(
  '/:courseId/levels/:levelId/complete',
  coursesController.completeCourseLevel
);

module.exports = router;
