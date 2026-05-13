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




const createEmailVerificationToken = () => {
    const rawToken = crypto.randomBytes(32).toString("hex");

    const hashedToken = crypto
        .createHash("sha256")
        .update(rawToken)
        .digest("hex");

    return { rawToken, hashedToken };
};

const sendVerificationEmail = async (email, token) => {
    const configuredClientUrl = process.env.CLIENT_URL || "http://localhost:8080";
    const clientUrl = configuredClientUrl.replace(
        /^http:\/\/(localhost|127\.0\.0\.1)(?::\d+)?/,
        "http://localhost:8080"
    );
    const emailUser = process.env.EMAIL_USER;
    const emailPassword = (process.env.EMAIL_APP_PASSWORD || "").replace(/\s/g, "");

    if (!emailUser || !emailPassword) {
        throw new Error("Email service is not configured. Set EMAIL_USER and EMAIL_APP_PASSWORD in server/.env");
    }

    const verifyUrl = `${clientUrl}/#/verify-email?token=${token}`;

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

    await transporter.sendMail({
        from: `"learny(grad project)" <${emailUser}>`,
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



class UserService {
    static async registerUser(name, email, password, role) {
        try {
            const existingUser = await UserModel.findOne({ email });

            if (existingUser) {
                throw new Error("User already exists");
            }

            const { rawToken, hashedToken } = createEmailVerificationToken();

            const createUser = new UserModel({
                name,
                email,
                password,
                role,
                authProvider: 'local',
                authProviders: ['local'],
                lastSignInProvider: 'local',
                emailVerified: false,
                emailVerificationToken: hashedToken,
                emailVerificationExpires: Date.now() + 60 * 60 * 1000 // 1 hour
            });

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

    static async loginUser(email, password) {
        try {
            const user = await UserModel.findOne({ email });

            if (!user) {
                throw new Error("Invalid email or password");
            }

            if (user.isSuspended) {
                throw new Error("There was a problem signing in.");
            }

            if (!user.emailVerified) {
                throw new Error("Please verify your email before logging in.");
            }

            if (!getAuthProviders(user).includes('local')) {
                throw new Error("This account uses Google sign in.");
            }

            const isPasswordValid = await user.comparePassword(password);

            if (!isPasswordValid) {
                throw new Error("Invalid email or password");
            }

            user.lastSignInProvider = 'local';
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
            await user.save();

            return true;
        }
        catch (err) {
            throw err;
        }
    }

    static async loginWithGoogle(idToken, role) {
        try {
            const allowedRoles = ['parent', 'child'];
            const requestedRole = allowedRoles.includes(role) ? role : null;
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


}


module.exports = UserService;
