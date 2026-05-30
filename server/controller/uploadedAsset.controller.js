const uploadedAssetService = require('../services/uploadedAsset.service');

async function createAsset(req, res) {
  try {
    const asset = await uploadedAssetService.createAsset(req.body, req.user);
    return res.status(201).json({
      success: true,
      message: 'Asset uploaded successfully.',
      data: asset,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to upload asset.',
    });
  }
}

async function listAssets(req, res) {
  try {
    const assets = await uploadedAssetService.listAssets(req.user);
    return res.status(200).json({
      success: true,
      data: assets,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch assets.',
    });
  }
}

async function getAssetMetadata(req, res) {
  try {
    const asset = await uploadedAssetService.getAssetMetadata(
      req.params.id,
      req.user
    );

    if (!asset) {
      return res.status(404).json({
        success: false,
        message: 'Asset not found.',
      });
    }

    return res.status(200).json({
      success: true,
      data: asset,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch asset.',
    });
  }
}

async function getAssetData(req, res) {
  try {
    const asset = await uploadedAssetService.getAssetForData(
      req.params.id,
      req.user
    );

    if (!asset) {
      return res.status(404).json({
        success: false,
        message: 'Asset not found.',
      });
    }

    res.set('Content-Type', asset.mimeType);
    res.set('Content-Length', asset.size.toString());
    res.set('Cache-Control', 'private, max-age=3600');
    return res.send(asset.data);
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch asset data.',
    });
  }
}

async function updateAsset(req, res) {
  try {
    const asset = await uploadedAssetService.updateAsset(
      req.params.id,
      req.body,
      req.user
    );

    if (!asset) {
      return res.status(404).json({
        success: false,
        message: 'Asset not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Asset updated successfully.',
      data: asset,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || 'Failed to update asset.',
    });
  }
}

async function deleteAsset(req, res) {
  try {
    const asset = await uploadedAssetService.deleteAsset(req.params.id, req.user);

    if (!asset) {
      return res.status(404).json({
        success: false,
        message: 'Asset not found.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Asset deleted successfully.',
      data: asset,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete asset.',
    });
  }
}

module.exports = {
  createAsset,
  listAssets,
  getAssetMetadata,
  getAssetData,
  updateAsset,
  deleteAsset,
};
