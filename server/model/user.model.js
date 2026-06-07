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
    authProvider: {
        type: String,
        enum: ['local', 'google'],
        default: 'local'
    },
    authProviders: {
        type: [String],
        enum: ['local', 'google'],
        default: ['local']
    },
    lastSignInProvider: {
        type: String,
        enum: ['local', 'google'],
        default: 'local'
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true
    },
    emailVerified: {
        type: Boolean,
        default: false
    },
    emailVerificationToken: {
        type: String
    },
    emailVerificationExpires: {
        type: Date
    },
    photoUrl: {
        type: String
    },
    profileAvatarType: {
        type: String,
        enum: ['asset', 'upload'],
        default: 'asset'
    },
    profileAvatarAssetPath: {
        type: String,
        default: 'assets/images/sprites/avatar00.png'
    },
    profilePhotoBase64: {
        type: String
    },
    profilePhotoFrameScale: {
        type: Number,
        default: 1
    },
    profilePhotoFrameOffsetX: {
        type: Number,
        default: 0
    },
    profilePhotoFrameOffsetY: {
        type: Number,
        default: 0
    },
    role: {
        type: String,
        enum: ['parent', 'child', 'admin'],
        required: true
    },
    isSuspended: {
        type: Boolean,
        default: false
    },
    suspendedAt: {
        type: Date
    },
    suspendedBy: {
        type: String
    },
    lastLoginAt: {
        type: Date
    },

    linkCode: {
        type: String,
        unique: true,
        sparse: true
    },
    linkedChildren: [{
        type: Schema.Types.ObjectId,
        ref: 'user'
    }]
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

