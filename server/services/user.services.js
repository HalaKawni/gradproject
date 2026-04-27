const { model } = require("mongoose");
const UserModel = require('../model/user.model');
const { signToken } = require("../utils/token");

class UserService{
    static async registerUser(name,email,password,role) {
        try{
            const existingUser = await UserModel.findOne({ email });

            if (existingUser) {
                throw new Error("User already exists");
            }

            const createUser = new UserModel({name,email,password,role});
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
            const user = await UserModel.findOne({ email });

            if (!user) {
                throw new Error("Invalid email or password");
            }

<<<<<<< HEAD
            if (user.isSuspended) {
                throw new Error("There was a problem signing in.");
            }

=======
>>>>>>> hala
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
<<<<<<< HEAD

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
}


module.exports = UserService;
=======
}


module.exports = UserService;
>>>>>>> hala
