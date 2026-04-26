const dashboardService = require('../../services/admin/dashboard.service');

exports.getDashboard = async (req, res) => {
  try {
    const data = await dashboardService.getDashboard();
    res.json(data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};