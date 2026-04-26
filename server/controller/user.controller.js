const UserService = require("../services/user.services");


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
            status:true,
            success:"User Registered Successfully",
            token: successRes.token,
            user: {
                id: successRes.user._id,
                name: successRes.user.name,
                email: successRes.user.email,
                role: successRes.user.role
            }
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
            user: {
                id: successRes.user._id,
                name: successRes.user.name,
                email: successRes.user.email,
                role: successRes.user.role
            }
        });
    }
    catch (err) {
        res.status(401).json({
            status: false,
            error: err.message || "Login failed"
        });
    }
};

exports.getProfile = async (req, res, next) => {
    try {
        res.json({
            status: true,
            user: req.user
        });
    }
    catch (err) {
        res.status(500).json({
            status: false,
            error: "Failed to fetch profile"
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
