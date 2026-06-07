const UserService = require("../services/user.services");

const buildAuthUserResponse = (user) => ({
    id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    emailVerified: user.emailVerified,
    authProvider: user.authProvider,
    authProviders: user.authProviders,
    lastSignInProvider: user.lastSignInProvider,
    photoUrl: user.photoUrl,
    profileAvatarType: user.profileAvatarType,
    profileAvatarAssetPath: user.profileAvatarAssetPath,
    profilePhotoBase64: user.profilePhotoBase64,
    profilePhotoFrameScale: user.profilePhotoFrameScale,
    profilePhotoFrameOffsetX: user.profilePhotoFrameOffsetX,
    profilePhotoFrameOffsetY: user.profilePhotoFrameOffsetY,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    lastLoginAt: user.lastLoginAt
});


exports.register = async(req,res,next)=>{
    try{
        const {name,email,password,role} = req.body;

        if(!name || !email || !password || !role){
            return res.status(400).json({
                status:false,
                error:"Name, email, password, and role are required"
            });
        }

        const successRes = await UserService.registerUser(name,email,password,role);
res.status(201).json({
    status: true,
    success: "User registered successfully. Please check your email to verify your account.",
    user: buildAuthUserResponse(successRes.user)
});
    }
    catch(err){
        res.status(400).json({
            status: false,
            error: err.message || "Registration failed"
        });
    }
};

exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                status: false,
                error: "Email and password are required"
            });
        }

        const successRes = await UserService.loginUser(email, password);

        res.json({
            status: true,
            success: "User logged in successfully",
            token: successRes.token,
            user: buildAuthUserResponse(successRes.user)
        });
    }
    catch (err) {
        res.status(401).json({
            status: false,
            error: err.message || "Login failed"
        });
    }
};

exports.resendVerificationEmail = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                status: false,
                error: "Email is required"
            });
        }

        await UserService.resendVerificationEmail(email);

        res.json({
            status: true,
            success: "Verification email sent. Please check your inbox."
        });
    } catch (err) {
        res.status(400).json({
            status: false,
            error: err.message || "Failed to resend verification email"
        });
    }
};

exports.googleLogin = async (req, res, next) => {
    try {
        const { idToken, role } = req.body;

        if (!idToken) {
            return res.status(400).json({
                status: false,
                error: "Google ID token is required"
            });
        }

        const successRes = await UserService.loginWithGoogle(idToken, role);

        res.json({
            status: true,
            success: "User logged in with Google successfully",
            token: successRes.token,
            user: buildAuthUserResponse(successRes.user)
        });
    }
    catch (err) {
        res.status(401).json({
            status: false,
            error: err.message || "Google login failed"
        });
    }
};

exports.getProfile = async (req, res, next) => {
    try {
        res.json({
            status: true,
            user: buildAuthUserResponse(req.user)
        });
    }
    catch (err) {
        res.status(500).json({
            status: false,
            error: "Failed to fetch profile"
        });
    }
};

exports.updateProfileAvatar = async (req, res, next) => {
    try {
        const {
            profileAvatarType,
            profileAvatarAssetPath,
            profilePhotoBase64,
            profilePhotoFrameScale,
            profilePhotoFrameOffsetX,
            profilePhotoFrameOffsetY
        } = req.body;

        if (!['asset', 'upload'].includes(profileAvatarType)) {
            return res.status(400).json({
                status: false,
                error: "Profile avatar type must be asset or upload"
            });
        }

        if (profileAvatarType === 'asset') {
            if (!profileAvatarAssetPath || typeof profileAvatarAssetPath !== 'string') {
                return res.status(400).json({
                    status: false,
                    error: "Profile avatar asset path is required"
                });
            }

            req.user.profileAvatarType = 'asset';
            req.user.profileAvatarAssetPath = profileAvatarAssetPath;
            req.user.profilePhotoBase64 = undefined;
            req.user.profilePhotoFrameScale = 1;
            req.user.profilePhotoFrameOffsetX = 0;
            req.user.profilePhotoFrameOffsetY = 0;
            req.user.photoUrl = profileAvatarAssetPath;
        } else {
            if (!profilePhotoBase64 || typeof profilePhotoBase64 !== 'string') {
                return res.status(400).json({
                    status: false,
                    error: "Profile photo data is required"
                });
            }

            req.user.profileAvatarType = 'upload';
            req.user.profilePhotoBase64 = profilePhotoBase64;
            req.user.profilePhotoFrameScale = Number(profilePhotoFrameScale ?? 1);
            req.user.profilePhotoFrameOffsetX = Number(profilePhotoFrameOffsetX ?? 0);
            req.user.profilePhotoFrameOffsetY = Number(profilePhotoFrameOffsetY ?? 0);
            req.user.photoUrl = undefined;
        }

        await req.user.save();

        res.json({
            status: true,
            success: "Profile photo updated successfully",
            user: buildAuthUserResponse(req.user)
        });
    }
    catch (err) {
        res.status(400).json({
            status: false,
            error: err.message || "Failed to update profile photo"
        });
    }
};

exports.changePassword = async (req, res, next) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                status: false,
                error: "Current password and new password are required"
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                status: false,
                error: "New password must be at least 6 characters"
            });
        }

        await UserService.changePassword(req.user._id, currentPassword, newPassword);

        res.json({
            status: true,
            success: "Password changed successfully"
        });
    }
    catch (err) {
        res.status(400).json({
            status: false,
            error: err.message || "Failed to change password"
        });
    }
};


exports.verifyEmail = async (req, res) => {
    try {
        const { token } = req.query;

        if (!token) {
            return res.status(400).json({
                status: false,
                error: "Verification token is required"
            });
        }

        await UserService.verifyEmail(token);

        res.json({
            status: true,
            success: "Email verified successfully"
        });
    } catch (err) {
        res.status(400).json({
            status: false,
            error: err.message || "Email verification failed"
        });
    }
};


exports.generateLinkCode = async (req, res) => {
    try {
        const code = await UserService.generateLinkCode(req.user._id);
        res.json({ status: true, linkCode: code });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};

exports.getLinkCode = async (req, res) => {
    try {
        const code = await UserService.getLinkCode(req.user._id);
        res.json({ status: true, linkCode: code });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};

exports.linkChild = async (req, res) => {
    try {
        const { code } = req.body;
        if (!code) return res.status(400).json({ status: false, error: 'Code is required' });
        const result = await UserService.linkChild(req.user._id, code);
        res.json({ status: true, child: result });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};

exports.unlinkChild = async (req, res) => {
    try {
        const { childId } = req.params;
        await UserService.unlinkChild(req.user._id, childId);
        res.json({ status: true, message: 'Child unlinked' });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};

exports.getLinkedChildren = async (req, res) => {
    try {
        const children = await UserService.getLinkedChildren(req.user._id);
        res.json({ status: true, children });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};

exports.getChildStats = async (req, res) => {
    try {
        const { childId } = req.params;
        const stats = await UserService.getChildStats(req.user._id, childId);
        res.json({ status: true, stats });
    } catch (err) {
        res.status(400).json({ status: false, error: err.message });
    }
};
