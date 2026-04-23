const mongoose = require('mongoose');
const db = require('../config/db');
const bcrypt = require("bcrypt");

const { Schema } = mongoose;

const userSchema = new Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        lowercase: true,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['parent', 'child', 'admin'],
        required: true
    },
    lastLoginAt: {
        type: Date
    },
    },
    {
        timestamps: true
    }
);

userSchema.pre('save', async function () {
    try {
        var user = this;
        if (!user.isModified('password')) {
            return;
        }
        const salt = await (bcrypt.genSalt(10));
        const hashpass = await bcrypt.hash(user.password, salt);

        user.password = hashpass;
    }
    catch (err) {
        throw err
    }
});

userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

const userModel = db.model('user', userSchema);
module.exports = userModel;
