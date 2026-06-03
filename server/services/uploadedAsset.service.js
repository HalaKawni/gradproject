const UploadedAsset = require('../model/uploadedAsset.model');
const User = require('../model/user.model');

const ALLOWED_IMAGE_MIME_TYPES = new Set([
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
]);
const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

function sanitizeName(name) {
  const normalizedName = typeof name === 'string' ? name.trim() : '';
  return normalizedName || 'Untitled asset';
}

function validateAssetType(type) {
  return ['character', 'obstacle', 'collectable', 'goal', 'background'].includes(
    type
  );
}

function toMetadata(asset, owner) {
  return {
    _id: asset._id,
    id: asset._id,
    ownerId: asset.ownerId,
    ownerName: owner && owner.name ? owner.name : asset.ownerName,
    ownerRole: owner && owner.role ? owner.role : asset.ownerRole,
    name: asset.name,
    type: asset.type,
    mimeType: asset.mimeType,
    size: asset.size,
    isPublic: asset.isPublic,
    createdAt: asset.createdAt,
    updatedAt: asset.updatedAt,
  };
}

function decodeBase64Image(imageBase64) {
  if (!imageBase64 || typeof imageBase64 !== 'string') {
    throw new Error('Image data is required.');
  }

  const cleaned = imageBase64.includes(',')
    ? imageBase64.split(',').pop()
    : imageBase64;
  return Buffer.from(cleaned, 'base64');
}

async function createAsset(payload, user) {
  const mimeType = payload.mimeType;
  const type = payload.type;

  if (!ALLOWED_IMAGE_MIME_TYPES.has(mimeType)) {
    throw new Error('Unsupported image type.');
  }

  if (!validateAssetType(type)) {
    throw new Error('Unsupported asset type.');
  }

  const data = decodeBase64Image(payload.imageBase64);
  if (data.length === 0) {
    throw new Error('Image data is empty.');
  }
  if (data.length > MAX_IMAGE_BYTES) {
    throw new Error('Image must be 2 MB or smaller.');
  }

  const asset = await UploadedAsset.create({
    ownerId: user._id.toString(),
    ownerName: user.name,
    ownerRole: user.role,
    name: sanitizeName(payload.name),
    type,
    mimeType,
    data,
    size: data.length,
    isPublic: payload.isPublic === true,
  });

  return toMetadata(asset, user);
}

async function listAssets(user) {
  const assets = await UploadedAsset.find({
    ownerId: user._id.toString(),
  })
    .select('-data')
    .sort({ updatedAt: -1 });

  return assets.map((asset) => toMetadata(asset, user));
}

async function listPublicAssets() {
  const owners = await User.find({ role: { $ne: 'admin' } }).select(
    '_id name role'
  );
  const ownerById = new Map(
    owners.map((owner) => [owner._id.toString(), owner])
  );

  if (ownerById.size === 0) {
    return [];
  }

  const assets = await UploadedAsset.find({
    isPublic: true,
    ownerId: { $in: Array.from(ownerById.keys()) },
  })
    .select('-data')
    .sort({ updatedAt: -1 });

  return assets.map((asset) => toMetadata(asset, ownerById.get(asset.ownerId)));
}

async function getAssetMetadata(assetId, user) {
  const asset = await UploadedAsset.findById(assetId).select('-data');
  if (!asset) {
    return null;
  }

  const isOwner = user && asset.ownerId === user._id.toString();
  if (!isOwner && asset.isPublic !== true) {
    return null;
  }

  return toMetadata(asset);
}

async function getAssetForData(assetId, user) {
  const asset = await UploadedAsset.findById(assetId);
  if (!asset) {
    return null;
  }

  const isOwner = user && asset.ownerId === user._id.toString();
  if (!isOwner && asset.isPublic !== true) {
    return null;
  }

  return asset;
}

async function updateAsset(assetId, payload, user) {
  const update = {};

  if (payload.name !== undefined) {
    update.name = sanitizeName(payload.name);
  }

  if (payload.type !== undefined) {
    if (!validateAssetType(payload.type)) {
      throw new Error('Unsupported asset type.');
    }
    update.type = payload.type;
  }

  if (payload.isPublic !== undefined) {
    update.isPublic = payload.isPublic === true;
  }

  const asset = await UploadedAsset.findOneAndUpdate(
    {
      _id: assetId,
      ownerId: user._id.toString(),
    },
    update,
    {
      returnDocument: 'after',
      runValidators: true,
    }
  ).select('-data');

  return asset ? toMetadata(asset, user) : null;
}

async function deleteAsset(assetId, user) {
  const asset = await UploadedAsset.findOneAndDelete({
    _id: assetId,
    ownerId: user._id.toString(),
  }).select('-data');

  return asset ? toMetadata(asset, user) : null;
}

async function makeAssetsPublic(assetIds, user) {
  const ids = Array.from(
    new Set(
      assetIds
        .map((assetId) => (assetId === undefined || assetId === null ? '' : String(assetId)))
        .filter(Boolean)
    )
  );

  if (ids.length === 0) {
    return;
  }

  await UploadedAsset.updateMany(
    {
      _id: { $in: ids },
      ownerId: user._id.toString(),
    },
    {
      $set: { isPublic: true },
    }
  );
}

async function makeAssetsPublicByIds(assetIds) {
  const ids = normalizeAssetIds(assetIds);

  if (ids.length === 0) {
    return;
  }

  await UploadedAsset.updateMany(
    {
      _id: { $in: ids },
    },
    {
      $set: { isPublic: true },
    }
  );
}

function normalizeAssetIds(assetIds) {
  return Array.from(
    new Set(
      assetIds
        .map((assetId) => (assetId === undefined || assetId === null ? '' : String(assetId)))
        .filter(Boolean)
    )
  );
}

module.exports = {
  createAsset,
  listAssets,
  listPublicAssets,
  getAssetMetadata,
  getAssetForData,
  updateAsset,
  deleteAsset,
  makeAssetsPublic,
  makeAssetsPublicByIds,
};
