const { model } = require("mongoose");
const UserModel = require('../model/user.model');
const { signToken } = require("../utils/token");

class UserService{
    static async registerUser(name, email, password, role, classroomCode) {
        try{
            const existingUser = await UserModel.findOne({ email });

            if (existingUser) {
                throw new Error("User already exists");
            }

            const userData = { name, email, password, role };
            if (classroomCode) userData.classroomCode = classroomCode.toUpperCase();

            const createUser = new UserModel(userData);
            const savedUser = await createUser.save();
            const token = signToken(savedUser);

            return {
                user: savedUser,
                token
            };
        }
        catch(err){
            throw err;
        }
    }

    static async loginUser(email, password) {
        try {
            const user = await UserModel.findOne({
                $or: [{ email: email }, { name: email }]
            });

            if (!user) {
                throw new Error("Invalid email or password");
            }

            const isPasswordValid = await user.comparePassword(password);

            if (!isPasswordValid) {
                throw new Error("Invalid email or password");
            }

            const token = signToken(user);

            return {
                user,
                token
            };
        }
        catch (err) {
            throw err;
        }
    }

    static async generateLinkCode(userId) {
        const code = Math.random().toString(36).substring(2, 8).toUpperCase();
        await UserModel.findByIdAndUpdate(userId, { linkCode: code });
        return code;
    }

    static async getLinkCode(userId) {
        const user = await UserModel.findById(userId, 'linkCode role');
        if (!user) throw new Error('User not found');
        if (user.role !== 'child') throw new Error('Only child accounts can have a link code');
        return user.linkCode || null;
    }

    static async linkChild(parentId, code) {
        const child = await UserModel.findOne({ linkCode: code.toUpperCase(), role: 'child' });
        if (!child) throw new Error('Invalid link code. Ask your child to generate one from their dashboard.');

        const parent = await UserModel.findById(parentId);
        if (!parent) throw new Error('Parent not found');
        if (parent.role !== 'parent') throw new Error('Only parent accounts can link children');

        await UserModel.findByIdAndUpdate(parentId, {
            $addToSet: { linkedChildren: child._id }
        });

        return { childId: child._id, childName: child.name };
    }

    static async unlinkChild(parentId, childId) {
        await UserModel.findByIdAndUpdate(parentId, {
            $pull: { linkedChildren: childId }
        });
    }

    static async getLinkedChildren(parentId) {
        const parent = await UserModel.findById(parentId).populate('linkedChildren', 'name email');
        if (!parent) throw new Error('Parent not found');
        return parent.linkedChildren || [];
    }

    static async getChildStats(parentId, childId) {
        const parent = await UserModel.findById(parentId);
        if (!parent) throw new Error('Parent not found');

        const isLinked = parent.linkedChildren.some(id => id.toString() === childId.toString());
        if (!isLinked) throw new Error('Not authorized to view this child\'s stats');

        const GameProgressModel = require('../model/game.model');
        const CourseModel       = require('../model/course.model');

        const [allProgress, createdCourses] = await Promise.all([
            GameProgressModel.find({ userId: childId }).sort({ updatedAt: -1 }),
            CourseModel.find({ userId: childId }),
        ]);

        // Count only real activity levels (not quiz/wordsearch offsets)
        const totalSolutions = allProgress.reduce((sum, p) =>
            sum + p.levelResults.filter(r => r.stars > 0).length, 0);

        const coursesStarted  = allProgress.length;
        const coursesCreated  = createdCourses.length;
        const totalStars      = allProgress.reduce((sum, p) => sum + p.totalStars, 0);

        // Most recently updated game = current course
        const currentGame = allProgress[0] ? {
            gameId:       allProgress[0].gameId,
            highestLevel: allProgress[0].highestLevelReached,
            totalStars:   allProgress[0].totalStars,
            totalScore:   allProgress[0].totalScore,
        } : null;

        // Weekly activity: 5 minutes per completed level in the last 7 days
        const now     = new Date();
        const weekAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
        const weeklyMinutes = [0, 0, 0, 0, 0, 0, 0]; // Mon(0)…Sun(6)

        allProgress.forEach(p => {
            p.levelResults.forEach(r => {
                const d = new Date(r.completedAt);
                if (d >= weekAgo && r.stars > 0) {
                    const dayIndex = (d.getDay() + 6) % 7;
                    weeklyMinutes[dayIndex] += 5;
                }
            });
        });

        const games = allProgress.map(p => ({
            gameId:       p.gameId,
            highestLevel: p.highestLevelReached,
            totalStars:   p.totalStars,
            totalScore:   p.totalScore,
            levelCount:   p.levelResults.filter(r => r.stars > 0).length,
        }));

        return {
            totalSolutions,
            coursesStarted,
            coursesCreated,
            totalStars,
            currentGame,
            weeklyMinutes,
            games,
        };
    }
}


module.exports = UserService;