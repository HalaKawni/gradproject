const router = require('express').Router();
const CourseController = require('../controller/course.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/', authMiddleware, CourseController.createCourse);
router.get('/', authMiddleware, CourseController.getUserCourses);
router.patch('/:id', authMiddleware, CourseController.updateCourse);
router.delete('/:id', authMiddleware, CourseController.deleteCourse);

module.exports = router;
