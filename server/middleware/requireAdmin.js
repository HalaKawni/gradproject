
function requireAdmin(req, res, next) {

  if (!req.user) {
    return res.status(401).json({
      message: 'Unauthorized',
    });
  }

  if (req.user.role !== 'admin') {
    return res.status(403).json({
      message: 'Forbidden: admin access only',
    });
  }

  next();
}

module.exports = requireAdmin;