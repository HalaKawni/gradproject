const statisticsService = require('../../services/admin/statistics.service');

exports.getStatistics = async (req, res) => {
  try {
    const data = await statisticsService.getStatistics();
    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};