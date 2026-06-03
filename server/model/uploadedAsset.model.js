const mongoose = require('mongoose');
const db = require('../config/db');

const { Schema } = mongoose;

const uploadedAssetSchema = new Schema(
  {
    ownerId: {
      type: String,
      required: true,
      index: true,
    },
    ownerName: {
      type: String,
      trim: true,
    },
    ownerRole: {
      type: String,
      enum: ['parent', 'child', 'admin'],
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['character', 'obstacle', 'collectable', 'goal', 'background'],
      required: true,
    },
    mimeType: {
      type: String,
      required: true,
    },
    data: {
      type: Buffer,
      required: true,
    },
    size: {
      type: Number,
      required: true,
    },
    isPublic: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = db.model('UploadedAsset', uploadedAssetSchema);
