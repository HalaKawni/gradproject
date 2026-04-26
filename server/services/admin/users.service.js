const User = require('../../model/user.model');

exports.getUsers = async (query) => {
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const search = query.search || '';

  const filter = search
    ? {
        $or: [
          { name: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
        ],
      }
    : {};

  const users = await User.find(filter)
    .select('-password')
    .skip((page - 1) * limit)
    .limit(limit)
    .sort({ createdAt: -1 });

  const total = await User.countDocuments(filter);

  return {
    users,
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
};

exports.getUserById = async (id) => {
  const user = await User.findById(id).select('-password');

  if (!user) {
    throw new Error('User not found');
  }

  return user;
};

exports.createAdminUser = async (data) => {
  const existingUser = await User.findOne({ email: data.email });

  if (existingUser) {
    throw new Error('Email already exists');
  }

  const user = await User.create({
    name: data.name,
    email: data.email,
    password: data.password,
    role: 'admin',
  });

  const result = user.toObject();
  delete result.password;

  return result;
};

exports.deleteUser = async (id) => {
  const user = await User.findById(id);

  if (!user) {
    throw new Error('User not found');
  }

  if (user.role === 'admin') {
    throw new Error('Admin accounts cannot be deleted');
  }

  await user.deleteOne();

  return user;
};

exports.updateUserSuspension = async (id, isSuspended, adminUser) => {
  const user = await User.findById(id);

  if (!user) {
    throw new Error('User not found');
  }

  if (user.role === 'admin') {
    throw new Error('Admin accounts cannot be suspended');
  }

  user.isSuspended = isSuspended;
  user.suspendedAt = isSuspended ? new Date() : undefined;
  user.suspendedBy = isSuspended ? adminUser._id?.toString() : undefined;

  await user.save();

  const result = user.toObject();
  delete result.password;

  return result;
};
