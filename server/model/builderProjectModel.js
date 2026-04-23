const mongoose = require('mongoose');
const db = require('../config/db');

const BuilderProjectSchema = new mongoose.Schema(
  {
    ownerId: {
      type: String,
      required: true,
    },
    ownerName: {
      type: String,
      required: true,
    },
    ownerEmail: {
      type: String,
      required: true,
    },
    ownerRole: {
      type: String,
      enum: ['parent', 'child', 'admin'],
      required: true,
    },
    title: {
      type: String,
      required: true,
      default: 'New Level',
    },
    description: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      enum: ['draft', 'published'],
      default: 'draft',
    },
    draftData: {
      type: Object,
      required: true,
    },
    courseId: {
      type: String,
      //required: true,
    },
    orderInCourse: {
      type: Number,
      //required: true,
    },
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard'],
      default: 'medium',
    },
    // sourceType: {
    //   type: String,
    //   enum: ['internal', 'external'],
    //   required: true,
    // },
    reviewStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    publishedAt: {
      type: Date,
    },
    approvedBy: {
      type: String,
    },
    approvedAt: {
      type: Date,
    }
  },
  {
    timestamps: true,
  }
);

module.exports = db.model('BuilderProject', BuilderProjectSchema);
