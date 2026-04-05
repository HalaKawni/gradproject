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
  },
  {
    timestamps: true,
  }
);

module.exports = db.model('BuilderProject', BuilderProjectSchema);
