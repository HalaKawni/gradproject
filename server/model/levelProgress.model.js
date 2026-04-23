const mongoose = require('mongoose');
const db = require('../config/db');
const bcrypt = require("bcrypt");

const { Schema } = mongoose;


const levelProgressSchema = new Schema({
    userId: {
        type: String,
        required: true
    },
    levelId: {
        type: String,
        required: true
    },
    progress: {
        type: Number,
        required: true
    },
    score:{
        type: Number,
        required: true
    }
});


