const UserService = require("../services/user.services");


exports.register = async(req,res,next)=>{
    try{
        const { name, email, password, role, classroomCode } = req.body;

        if(!name || !email || !password || !role){
            return res.status(400).json({
                status:false,
                error:"Name, email, password, and role are required"
            });
        }

        const successRes = await UserService.registerUser(name, email, password, role, classroomCode);
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