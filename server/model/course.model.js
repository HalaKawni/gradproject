const mongoose = require('mongoose');
const db = require('../config/db');


const { Schema } = mongoose;


const courseSchema = new mongoose.Schema({
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
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user'
    },
    updatedAt: {
        type: Date
    }
}, {
    timestamps: true
});   

const courseModel = db.model('Course', courseSchema);
module.exports = courseModel;
