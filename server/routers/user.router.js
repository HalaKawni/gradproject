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

// Parent-child linking
router.post('/generate-link-code', authMiddleware, UserController.generateLinkCode);
router.get('/link-code', authMiddleware, UserController.getLinkCode);
router.post('/link-child', authMiddleware, UserController.linkChild);
router.delete('/unlink-child/:childId', authMiddleware, UserController.unlinkChild);
router.get('/linked-children', authMiddleware, UserController.getLinkedChildren);
router.get('/children/:childId/stats', authMiddleware, UserController.getChildStats);

