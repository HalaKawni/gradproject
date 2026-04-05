function validateBuilderProject(payload) {
  const errors = [];

  if (!payload) {
    errors.push('Payload is required.');
    return { isValid: false, errors };
  }

  if (!payload.title || typeof payload.title !== 'string') {
    errors.push('Project title is required.');
  }

  if (!payload.settings || typeof payload.settings !== 'object') {
    errors.push('Project settings are required.');
  }

  if (!Array.isArray(payload.tiles)) {
    errors.push('Project tiles must be an array.');
  }

  if (!Array.isArray(payload.entities)) {
    errors.push('Project entities must be an array.');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

module.exports = {
  validateBuilderProject,
};