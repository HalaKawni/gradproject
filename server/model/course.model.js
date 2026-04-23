const mongoose = require('mongoose');
const db = require('../config/db');
const bcrypt = require("bcrypt");
const { create, updateMany } = require('./user.model');

const { Schema } = mongoose;


const courseSchema = new Schema({
    courseName: {
        type: String,
        required: true, 
        trim: true
    },
    courseId: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    category: {
        type: String,
        // required: true,
        trim: true
    },
    description: {
        type: String,
        // required: true,
        trim: true
    },
    isPublic: {
        type: Boolean,
        default: false
    },
    createdBy: {
        type: Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    updatedBy: {
        type: Schema.Types.ObjectId,
        ref: 'user'
    },
    updatedAt: {
        type: Date
    }
});   