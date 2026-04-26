const levelsService = require('../../services/admin/levels.service');

exports.getLevels = async (req, res) => {
  try {
    const levels = await levelsService.getLevels(req.query);
    res.json(levels);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getLevelById = async (req, res) => {
  try {
    const level = await levelsService.getLevelById(req.params.id);
    res.json(level);
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

exports.updateLevel = async (req, res) => {
  try {
    const level = await levelsService.updateLevel(req.params.id, req.body);
    res.json(level);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteLevel = async (req, res) => {
  try {
    await levelsService.deleteLevel(req.params.id);
    res.json({ message: 'Level deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};