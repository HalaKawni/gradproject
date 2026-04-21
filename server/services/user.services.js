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
}


module.exports = UserService;