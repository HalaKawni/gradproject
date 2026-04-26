const router = require('express').Router();
const dashboardController = require("../controller/admin/dashboard.controller");
const usersController = require("../controller/admin/users.controller");
const coursesController = require("../controller/admin/courses.controller");
const levelsController = require("../controller/admin/levels.controller");
const statisticsController = require("../controller/admin/statistics.controller");


const authMiddleware = require("../middleware/auth.middleware");
const requireAdmin = require('../middleware/requireAdmin');

// const AdminController = require("../controller/admin.controller");

router.use(authMiddleware, requireAdmin);

// dashboard
router.get('/dashboard', dashboardController.getDashboard);

// users
router.get('/users', usersController.getUsers);
router.post('/users/admin', usersController.createAdminUser);
router.get('/users/:id', usersController.getUserById);
router.put('/users/:id/suspension', usersController.updateUserSuspension);
router.delete('/users/:id', usersController.deleteUser);

// courses
router.get('/courses', coursesController.getCourses);
router.post('/courses', coursesController.createCourse);
router.put('/courses/:id', coursesController.updateCourse);
router.delete('/courses/:id', coursesController.deleteCourse);

// levels
router.get('/levels', levelsController.getLevels);
router.get('/levels/:id', levelsController.getLevelById);
router.put('/levels/:id', levelsController.updateLevel);
router.delete('/levels/:id', levelsController.deleteLevel);

// statistics
router.get('/statistics', statisticsController.getStatistics);

module.exports = router;
