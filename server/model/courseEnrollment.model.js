const mongoose = require('mongoose');
const db = require('../config/db');
const bcrypt = require("bcrypt");

const { Schema } = mongoose;

const courseEnrollmentSchema = new mongoose.Schema({
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'course',
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    Status:{
        type: String,
        enum: ['not enrolled','enrolled', 'completed', 'dropped'],
        default: 'not enrolled'
    },
    enrolledAt: {
        type: Date,
        default: Date.now
    },
    completedAt: {
        type: Date
    },
    progress: {
        type: Number,
        default: 0
    }
});


const courseEnrollmentModel = db.model('CourseEnrollment', courseEnrollmentSchema);
module.exports = courseEnrollmentModel;