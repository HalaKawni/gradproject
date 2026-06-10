const crypto = require("crypto");
const { OAuth2Client } = require("google-auth-library");
const UserModel = require('../model/user.model');
const { signToken } = require("../utils/token");
const nodemailer = require("nodemailer");

const googleClientId =
    process.env.GOOGLE_CLIENT_ID ||
    "285752649985-a8c6gp0bogkgiq3jpjau40vrhndnhv2r.apps.googleusercontent.com";
const googleClient = new OAuth2Client(googleClientId);

const getAuthProviders = (user) => {
    if (Array.isArray(user.authProviders) && user.authProviders.length > 0) {
        return user.authProviders;
    }

    if (user.googleId || user.authProvider === 'google') {
        return ['google'];
    }

    return ['local'];
};

const addAuthProvider = (user, provider) => {
    return Array.from(new Set([...getAuthProviders(user), provider]));
};




const createHashedToken = () => {
    const rawToken = crypto.randomBytes(32).toString("hex");

    const hashedToken = crypto
        .createHash("sha256")
        .update(rawToken)
        .digest("hex");

    return { rawToken, hashedToken };
};

const createEmailVerificationToken = () => createHashedToken();

const createPasswordResetToken = () => createHashedToken();

const createEmailTransporter = async () => {
    const emailUser = process.env.EMAIL_USER;
    const emailPassword = (process.env.EMAIL_APP_PASSWORD || "").replace(/\s/g, "");

    if (!emailUser || !emailPassword) {
        throw new Error("Email service is not configured. Set EMAIL_USER and EMAIL_APP_PASSWORD in server/.env");
    }

    const transporter = nodemailer.createTransport({
        host: "smtp.gmail.com",
        port: 587,
        secure: false,
        family: 4,
        requireTLS: true,
        auth: {
            user: emailUser,
            pass: emailPassword
        }
    });

    await transporter.verify();

    return { transporter, emailUser };
};

const getClientUrl = () => {
    const configuredClientUrl = process.env.CLIENT_URL || "http://localhost:8080";
    return configuredClientUrl.replace(
        /^http:\/\/(localhost|127\.0\.0\.1)(?::\d+)?/,
        "http://localhost:8080"
    );
};

const sendVerificationEmail = async (email, token) => {
    const clientUrl = getClientUrl();
    const verifyUrl = `${clientUrl}/#/verify-email?token=${token}`;
    const { transporter, emailUser } = await createEmailTransporter();

    await transporter.sendMail({
        from: `"Codey" <${emailUser}>`,
        to: email,
        subject: "Verify your email",
        html: `
            <h2>Verify your email</h2>
            <p>Click the link below to verify your account:</p>
            <a href="${verifyUrl}">Verify Email</a>
            <p>This link expires in 1 hour.</p>
        `
    });
};

const sendPasswordResetEmail = async (email, token) => {
    const clientUrl = getClientUrl();
    const resetUrl = `${clientUrl}/#/reset-password?token=${token}`;
    const { transporter, emailUser } = await createEmailTransporter();

    await transporter.sendMail({
        from: `"Codey" <${emailUser}>`,
        to: email,
        subject: "Reset your password",
        html: `
            <h2>Reset your password</h2>
            <p>We received a request to reset your password.</p>
            <p>Click the link below to choose a new password:</p>
            <a href="${resetUrl}">Reset Password</a>
            <p>This link expires in 1 hour and can only be used once.</p>
            <p>If you did not request this change, you can safely ignore this email.</p>
        `
    });
};




class UserService{
    static async registerUser(name, email, password, role, classroomCode, ageGroup, gender) {
        try{
            const existingUser = await UserModel.findOne({ email });

            if (existingUser) {
                throw new Error("User already exists");
            }

            const { rawToken, hashedToken } = createEmailVerificationToken();

            const userData = {
                name,
                email,
                password,
                role,
                authProvider: 'local',
                authProviders: ['local'],
                lastSignInProvider: 'local',
                ageGroup: normalizeAgeGroup(ageGroup),
                gender: normalizeGender(gender),
                emailVerified: false,
                emailVerificationToken: hashedToken,
                emailVerificationExpires: Date.now() + 60 * 60 * 1000 // 1 hour
            };
            if (classroomCode) {
                userData.classroomCode = classroomCode.toUpperCase();
            }

            const createUser = new UserModel(userData);
            const savedUser = await createUser.save();

            await sendVerificationEmail(savedUser.email, rawToken);

            return {
                user: savedUser
            };
        }
        catch (err) {
            console.error("Registration failed:", err.message);
            throw err;
        }
    }

    static async resendVerificationEmail(email) {
        const normalizedEmail = email.toLowerCase().trim();
        const user = await UserModel.findOne({ email: normalizedEmail });

        if (!user) {
            throw new Error("No account was found for this email.");
        }

        if (user.emailVerified) {
            throw new Error("This email is already verified.");
        }

        const { rawToken, hashedToken } = createEmailVerificationToken();
        user.emailVerificationToken = hashedToken;
        user.emailVerificationExpires = Date.now() + 60 * 60 * 1000;
        await user.save();

        try {
            await sendVerificationEmail(user.email, rawToken);
        } catch (err) {
            console.error("Verification email failed:", err.message);
            throw new Error(
                "Could not send verification email. Check the server email settings."
            );
        }

        return true;
    }

    static async requestPasswordReset(email) {
        const normalizedEmail = email.toLowerCase().trim();
        const user = await UserModel.findOne({ email: normalizedEmail });

        if (!user || !getAuthProviders(user).includes('local') || user.isSuspended) {
            return true;
        }

        const { rawToken, hashedToken } = createPasswordResetToken();
        user.passwordResetToken = hashedToken;
        user.passwordResetExpires = Date.now() + 60 * 60 * 1000;
        await user.save();

        try {
            await sendPasswordResetEmail(user.email, rawToken);
        } catch (err) {
            console.error("Password reset email failed:", err.message);
            throw new Error(
                "Could not send reset email. Check the server email settings."
            );
        }

        return true;
    }

    static async loginUser(email, password) {
        try {
            const user = await UserModel.findOne({
                $or: [{ email: email }, { name: email }]
            });

            if (!user) {
                throw new Error("Invalid email or password");
            }

            if (user.isSuspended) {
                throw new Error("There was a problem signing in.");
            }

            if (!getAuthProviders(user).includes('local')) {
                throw new Error("This account uses Google sign in.");
            }

            const isPasswordValid = await user.comparePassword(password);

            if (!isPasswordValid) {
                throw new Error("Invalid email or password");
            }

            user.lastSignInProvider = 'local';
            user.lastLoginAt = new Date();
            await user.save();

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

    static async changePassword(userId, currentPassword, newPassword) {
        try {
            const user = await UserModel.findById(userId);

            if (!user) {
                throw new Error("User not found");
            }

            const isPasswordValid = await user.comparePassword(currentPassword);

            if (!isPasswordValid) {
                throw new Error("Current password is incorrect");
            }

            user.password = newPassword;
            user.passwordResetToken = undefined;
            user.passwordResetExpires = undefined;
            await user.save();

            return true;
        }
        catch (err) {
            throw err;
        }
    }

    static async resetPassword(token, newPassword) {
        const hashedToken = crypto
            .createHash("sha256")
            .update(token)
            .digest("hex");

        const user = await UserModel.findOne({
            passwordResetToken: hashedToken,
            passwordResetExpires: { $gt: Date.now() }
        });

        if (!user) {
            throw new Error("Reset link is invalid or expired");
        }

        if (!getAuthProviders(user).includes('local')) {
            throw new Error("This account does not use password sign in");
        }

        user.password = newPassword;
        user.passwordResetToken = undefined;
        user.passwordResetExpires = undefined;
        user.lastSignInProvider = 'local';

        await user.save();

        return true;
    }

    static async loginWithGoogle(idToken, role, ageGroup, gender) {
        try {
            const allowedRoles = ['parent', 'child'];
            const requestedRole = allowedRoles.includes(role) ? role : null;
            const normalizedAgeGroup = normalizeAgeGroup(ageGroup);
            const normalizedGender = normalizeGender(gender);
            const ticket = await googleClient.verifyIdToken({
                idToken,
                audience: googleClientId
            });
            const payload = ticket.getPayload();

            if (!payload || !payload.email || !payload.sub) {
                throw new Error("Invalid Google account");
            }

            if (payload.email_verified !== true) {
                throw new Error("Google email is not verified");
            }

            const email = payload.email.toLowerCase();
            let user = await UserModel.findOne({ googleId: payload.sub });

            if (!user) {
                user = await UserModel.findOne({ email });
            }

            if (user) {
                if (user.isSuspended) {
                    throw new Error("There was a problem signing in.");
                }

                if (user.googleId && user.googleId !== payload.sub) {
                    throw new Error("This email is linked to a different Google account.");
                }

                if (!user.googleId) {
                    user.googleId = payload.sub;
                }
                user.authProviders = addAuthProvider(user, 'google');
                user.authProvider = user.authProviders.includes('local') ? 'local' : 'google';
                user.lastSignInProvider = 'google';
                user.emailVerified = true;
                if (user.role === 'child') {
                    if ((!user.ageGroup || user.ageGroup === 'unknown') && normalizedAgeGroup !== 'unknown') {
                        user.ageGroup = normalizedAgeGroup;
                    }
                    if ((!user.gender || user.gender === 'unknown') && normalizedGender !== 'unknown') {
                        user.gender = normalizedGender;
                    }
                }
                user.lastLoginAt = new Date();
                await user.save();

                return {
                    user,
                    token: signToken(user)
                };
            }

            if (!requestedRole) {
                throw new Error("Choose parent or child signup before using Google sign in.");
            }

            user = await UserModel.create({
                name: payload.name || email,
                email,
                password: crypto.randomBytes(32).toString("hex"),
                role: requestedRole,
                authProvider: 'google',
                authProviders: ['google'],
                lastSignInProvider: 'google',
                ageGroup: requestedRole === 'child' ? normalizedAgeGroup : 'unknown',
                gender: requestedRole === 'child' ? normalizedGender : 'unknown',
                googleId: payload.sub,
                emailVerified: true,
                lastLoginAt: new Date()
            });

            return {
                user,
                token: signToken(user)
            };
        }
        catch (err) {
            throw err;
        }
    }


    static async verifyEmail(token) {
        const hashedToken = crypto
            .createHash("sha256")
            .update(token)
            .digest("hex");

        const user = await UserModel.findOne({
            emailVerificationToken: hashedToken,
            emailVerificationExpires: { $gt: Date.now() }
        });

        if (!user) {
            throw new Error("Verification link is invalid or expired");
        }

        user.emailVerified = true;
        user.emailVerificationToken = undefined;
        user.emailVerificationExpires = undefined;

        await user.save();

        return user;
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
        const SlideCourseModel  = require('../model/slideCourse.model');

        const [allProgress, createdCourses] = await Promise.all([
            GameProgressModel.find({ userId: childId }).sort({ updatedAt: -1 }),
            SlideCourseModel.find({ userId: childId }),
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

function normalizeAgeGroup(ageGroup) {
    const allowedAgeGroups = new Set([
        'under_6',
        '6_8',
        '9_11',
        '12_14',
        '15_17',
        '18_plus',
        'unknown',
    ]);
    return allowedAgeGroups.has(ageGroup) ? ageGroup : 'unknown';
}

function normalizeGender(gender) {
    return gender === 'male' || gender === 'female' ? gender : 'unknown';
}


module.exports = UserService;
