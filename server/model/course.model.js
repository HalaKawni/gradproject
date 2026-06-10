const mongoose = require('mongoose');
const db = require('../config/db');

const recommendationCounterSchema = new mongoose.Schema(
    {
        views: {
            type: Number,
            default: 0,
            min: 0
        },
        clicks: {
            type: Number,
            default: 0,
            min: 0
        },
        levelPlays: {
            type: Number,
            default: 0,
            min: 0
        },
        levelCompletions: {
            type: Number,
            default: 0,
            min: 0
        }
    },
    { _id: false }
);

const recommendationCohortSchema = new mongoose.Schema(
    {
        views: {
            type: Number,
            default: 0,
            min: 0
        },
        clicks: {
            type: Number,
            default: 0,
            min: 0
        },
        levelPlays: {
            type: Number,
            default: 0,
            min: 0
        },
        levelCompletions: {
            type: Number,
            default: 0,
            min: 0
        },
        sampleSize: {
            type: Number,
            default: 0,
            min: 0
        }
    },
    { _id: false }
);

const recommendationStatsSchema = new mongoose.Schema(
    {
        global: {
            type: recommendationCounterSchema,
            default: () => ({})
        },
        cohorts: {
            type: Map,
            of: recommendationCohortSchema,
            default: () => new Map()
        },
        updatedAt: {
            type: Date,
            default: null
        }
    },
    { _id: false }
);

const courseCommentSchema = new mongoose.Schema(
    {
        userId: {
            type: String,
            required: true
        },
        userName: {
            type: String,
            required: true
        },
        message: {
            type: String,
            required: true,
            trim: true,
            maxlength: 500
        }
    },
    {
        timestamps: true,
        _id: true
    }
);

const courseRatingSchema = new mongoose.Schema(
    {
        userId: {
            type: String,
            required: true
        },
        userName: {
            type: String,
            required: true
        },
        value: {
            type: Number,
            required: true,
            min: 1,
            max: 5
        }
    },
    {
        timestamps: true,
        _id: true
    }
);

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
    courseDeliveryType: {
        type: String,
        enum: ['builder_levels', 'legacy_page'],
        default: 'builder_levels'
    },
    legacyPageKey: {
        type: String,
        default: '',
        trim: true
    },
    courseImageBase64: {
        type: String,
        default: null
    },
    coverFrameScale: {
        type: Number,
        default: 1
    },
    coverFrameOffsetX: {
        type: Number,
        default: 0
    },
    coverFrameOffsetY: {
        type: Number,
        default: 0
    },
    isPublic: {
        type: Boolean,
        default: false
    },
    verificationStatus: {
        type: String,
        enum: ['none', 'pending', 'approved', 'rejected'],
        default: 'none'
    },
    verificationRequestedAt: {
        type: Date
    },
    verificationReviewedAt: {
        type: Date
    },
    verificationReviewedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user'
    },
    verificationRejectedReason: {
        type: String,
        default: ''
    },
    verifiedAt: {
        type: Date
    },
    verifiedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user'
    },
    hasUnreadUpdateNotification: {
        type: Boolean,
        default: false
    },
    lastUpdateNotificationAt: {
        type: Date
    },
    lastUpdateNotificationMessage: {
        type: String,
        default: ''
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
    },
    recommendationStats: {
        type: recommendationStatsSchema,
        default: () => ({})
    },
    comments: {
        type: [courseCommentSchema],
        default: []
    },
    ratings: {
        type: [courseRatingSchema],
        default: []
    }
}, {
    timestamps: true
});   

const courseModel = db.model('Course', courseSchema);
module.exports = courseModel;
