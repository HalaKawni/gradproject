const router = require('express').Router();
const UserController = require("../controller/user.controller");
const authMiddleware = require("../middleware/auth.middleware");

router.post('/registration',UserController.register);
router.post('/login', UserController.login);
router.post('/resend-verification', UserController.resendVerificationEmail);
router.post('/login/google', UserController.googleLogin);
router.get('/profile', authMiddleware, UserController.getProfile);
router.put('/profile/password', authMiddleware, UserController.changePassword);
router.get('/verify-email', UserController.verifyEmail);

module.exports = router;


