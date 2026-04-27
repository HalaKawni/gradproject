const router = require('express').Router();
const UserController = require("../controller/user.controller");
const authMiddleware = require("../middleware/auth.middleware");

router.post('/registration',UserController.register);
router.post('/login', UserController.login);
router.get('/profile', authMiddleware, UserController.getProfile);
<<<<<<< HEAD
router.put('/profile/password', authMiddleware, UserController.changePassword);


module.exports = router;
=======


module.exports = router;
>>>>>>> hala
