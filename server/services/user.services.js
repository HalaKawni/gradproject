const { model } = require("mongoose");
const UserModel = require('../model/user.model');
class UserService{
    static async registerUser(email,password) {
        try{
            const createUser = new UserModel({email,password});
            return createUser.save();
        }
        catch(err){
            throw err;
        }
    }
}


module.exports = UserService;