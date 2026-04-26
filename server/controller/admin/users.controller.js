const usersService = require('../../services/admin/users.service');

exports.getUsers = async (req, res) => {
  try {
    const result = await usersService.getUsers(req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await usersService.getUserById(req.params.id);
    res.json(user);
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

exports.createAdminUser = async (req, res) => {
  try {
    const admin = await usersService.createAdminUser(req.body);
    res.status(201).json(admin);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    await usersService.deleteUser(req.params.id);
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.updateUserSuspension = async (req, res) => {
  try {
    const user = await usersService.updateUserSuspension(
      req.params.id,
      req.body.isSuspended === true,
      req.user
    );
    res.json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
