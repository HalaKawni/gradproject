const { verifyToken } = require("../utils/token");
const UserModel = require("../model/user.model");

const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return res.status(401).json({
                status: false,
                error: "Authorization token is required"
            });
        }

        const token = authHeader.split(" ")[1];
        const decoded = verifyToken(token);
        const user = await UserModel.findById(decoded.id).select("-password");

        if (!user) {
            return res.status(401).json({
                status: false,
                error: "Invalid token"
            });
        }

        req.user = user;
        next();
    }
    catch (err) {
        return res.status(401).json({
            status: false,
            error: "Invalid or expired token"
        });
    }
};

module.exports = authMiddleware;