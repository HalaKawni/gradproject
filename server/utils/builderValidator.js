const {
  FRONT_VIEW_COLLECTABLE_ITEMS,
  FRONT_VIEW_PLAYER_CHARACTERS,
  FRONT_VIEW_PLAYER_DIRECTIONS,
} = require('./frontViewAssets');

function validateBuilderProject(payload) {
  const errors = [];

  if (!payload) {
    errors.push('Payload is required.');
    return { isValid: false, errors };
  }

  if (!payload.title || typeof payload.title !== 'string') {
    errors.push('Project title is required.');
  }

  const builderType = payload.builderType || 'frontView';
  if (!['frontView', 'topView', 'scratch'].includes(builderType)) {
    errors.push('Project builderType must be frontView, topView, or scratch.');
  }

  if (builderType === 'topView') {
    validateTopViewProject(payload, errors);
  } else if (builderType === 'scratch') {
    validateScratchProject(payload, errors);
  } else {
    validateFrontViewProject(payload, errors);
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

function validateFrontViewProject(payload, errors) {
  if (!payload.settings || typeof payload.settings !== 'object') {
    errors.push('Project settings are required.');
  }

  if (!Array.isArray(payload.tiles)) {
    errors.push('Project tiles must be an array.');
  }

  if (!Array.isArray(payload.entities)) {
    errors.push('Project entities must be an array.');
    return;
  }

  validateFrontViewEntities(payload.entities, errors);
}

function validateFrontViewEntities(entities, errors) {
  entities.forEach((entity, index) => {
    if (!entity || typeof entity !== 'object' || Array.isArray(entity)) {
      errors.push(`Front view entity at index ${index} must be an object.`);
      return;
    }

    const config = entity.config;
    if (config === undefined || config === null) {
      return;
    }

    if (typeof config !== 'object' || Array.isArray(config)) {
      errors.push(`Front view entity at index ${index} config must be an object.`);
      return;
    }

    if (entity.type === 'playerStart') {
      validateAllowedConfigValue({
        value: config.character,
        allowedValues: FRONT_VIEW_PLAYER_CHARACTERS,
        errors,
        message: `Front view player character at entity index ${index} must be one of: ${FRONT_VIEW_PLAYER_CHARACTERS.join(', ')}.`,
      });
      validateAllowedConfigValue({
        value: config.direction,
        allowedValues: FRONT_VIEW_PLAYER_DIRECTIONS,
        errors,
        message: `Front view player direction at entity index ${index} must be left or right.`,
      });
    }

    if (entity.type === 'collectable') {
      validateAllowedConfigValue({
        value: config.item,
        allowedValues: FRONT_VIEW_COLLECTABLE_ITEMS,
        errors,
        message: `Front view collectable item at entity index ${index} must be one of: ${FRONT_VIEW_COLLECTABLE_ITEMS.join(', ')}.`,
      });
    }
  });
}

function validateAllowedConfigValue({ value, allowedValues, errors, message }) {
  if (value === undefined || value === null) {
    return;
  }

  const normalizedValue = typeof value === 'string' ? value.trim() : '';
  if (!allowedValues.includes(normalizedValue)) {
    errors.push(message);
  }
}

function validateScratchProject(payload, errors) {
  if (!payload.settings || typeof payload.settings !== 'object') {
    errors.push('Scratch settings are required.');
  }

  if (!Array.isArray(payload.workspaceBlocks)) {
    errors.push('Scratch workspaceBlocks must be an array.');
  }

  if (!payload.sprite || typeof payload.sprite !== 'object') {
    errors.push('Scratch sprite state is required.');
  }

  if (payload.status !== 'published' || errors.length > 0) {
    return;
  }

  if (payload.workspaceBlocks.length === 0) {
    errors.push('Published scratch levels must include at least one block.');
  }
}

function validateTopViewProject(payload, errors) {
  const settings = payload.settings;
  if (!settings || typeof settings !== 'object') {
    errors.push('Top view settings are required.');
  }

  const columns = Number(settings && settings.columns);
  const rows = Number(settings && settings.rows);
  if (!Number.isInteger(columns) || columns <= 0) {
    errors.push('Top view settings.columns must be a positive integer.');
  }
  if (!Number.isInteger(rows) || rows <= 0) {
    errors.push('Top view settings.rows must be a positive integer.');
  }

  if (!Array.isArray(payload.items)) {
    errors.push('Top view items must be an array.');
  }

  if (!Array.isArray(payload.allowedBlocks)) {
    errors.push('Top view allowedBlocks must be an array.');
  }

  if (typeof payload.solutionCode !== 'string') {
    errors.push('Top view solutionCode must be a string.');
  }

  if (payload.status !== 'published' || errors.length > 0) {
    return;
  }

  const publishValidation = validateTopViewPublishedSolution(payload);
  if (!publishValidation.isValid) {
    errors.push(...publishValidation.errors);
  }
}

function validateTopViewPublishedSolution(payload) {
  const errors = [];
  const settings = payload.settings || {};
  const columns = Number(settings.columns);
  const rows = Number(settings.rows);
  const items = Array.isArray(payload.items) ? payload.items : [];
  const solutionCode =
    typeof payload.solutionCode === 'string' ? payload.solutionCode : '';

  const playerItems = items.filter((item) => item.type === 'player');
  const goalItems = items.filter((item) => item.type === 'goal');
  const collectables = items.filter((item) => item.type === 'collectable');

  if (playerItems.length !== 1) {
    errors.push('Published top view levels must have exactly one player.');
  }
  if (goalItems.length !== 1) {
    errors.push('Published top view levels must have exactly one goal.');
  }
  if (solutionCode.trim().length === 0) {
    errors.push('Published top view levels must include a solution code.');
  }
  if (!Array.isArray(payload.allowedBlocks) || payload.allowedBlocks.length === 0) {
    errors.push('Published top view levels must include solution blocks.');
  }

  if (errors.length > 0) {
    return { isValid: false, errors };
  }

  const simulation = simulateTopViewSolution({
    columns,
    rows,
    player: playerItems[0],
    goal: goalItems[0],
    collectables,
    initialDirectionDegrees: Number(payload.initialDirectionDegrees) || 0,
    solutionCode,
  });

  if (!simulation.success) {
    errors.push(simulation.message);
  }

  return { isValid: errors.length === 0, errors };
}

function simulateTopViewSolution({
  columns,
  rows,
  player,
  goal,
  collectables,
  initialDirectionDegrees,
  solutionCode,
}) {
  const steps = parseTopViewCode(solutionCode);
  if (steps.length === 0) {
    return { success: false, message: 'Published top view solution has no executable steps.' };
  }

  let x = Number(player.column);
  let y = Number(player.row);
  let heading = normalizeDegrees(initialDirectionDegrees);
  const collected = new Set();
  collectAtPosition(collectables, collected, x, y);

  for (const step of steps) {
    if (step.type === 'turn') {
      heading = normalizeDegrees(step.value);
      continue;
    }

    const direction = directionForHeading(heading);
    const stepDirection = step.value < 0 ? -1 : 1;
    let remaining = Math.abs(step.value);

    while (remaining > 0) {
      const distance = Math.min(1, remaining);
      x += direction.dx * distance * stepDirection;
      y += direction.dy * distance * stepDirection;

      if (!isIntegerPosition(x, y) || x < 0 || x >= columns || y < 0 || y >= rows) {
        return {
          success: false,
          message: 'Published top view solution moves the player out of bounds.',
        };
      }

      collectAtPosition(collectables, collected, x, y);
      remaining -= distance;
    }
  }

  if (collected.size !== collectables.length) {
    return {
      success: false,
      message: 'Published top view solution must collect all collectables.',
    };
  }

  if (x !== Number(goal.column) || y !== Number(goal.row)) {
    return {
      success: false,
      message: 'Published top view solution must finish on the goal.',
    };
  }

  return { success: true };
}

function parseTopViewCode(code) {
  return code
    .split('\n')
    .map((line) => line.trim().toLowerCase())
    .filter(Boolean)
    .map((line) => {
      const parts = line.split(/\s+/);
      const command = parts[0];

      if (command === 'turn' && parts.length > 1) {
        const numericAngle = Number(parts[1]);
        if (Number.isFinite(numericAngle)) {
          return { type: 'turn', value: Math.round(numericAngle) };
        }
        const direction = screenDirectionDegrees(parts[1]);
        return direction === null ? null : { type: 'turn', value: direction };
      }

      const direction = screenDirectionDegrees(command);
      if (direction !== null) {
        return { type: 'turn', value: direction };
      }

      if (command === 'step') {
        const amount = parts.length > 1 ? Number(parts[1]) : 1;
        return {
          type: 'step',
          value: Number.isFinite(amount) ? Math.round(amount) : 1,
        };
      }

      return null;
    })
    .filter(Boolean);
}

function screenDirectionDegrees(direction) {
  switch (direction) {
    case 'right':
      return 0;
    case 'up':
      return 90;
    case 'left':
      return 180;
    case 'down':
      return 270;
    default:
      return null;
  }
}

function directionForHeading(heading) {
  const normalized = normalizeDegrees(heading);
  if (normalized === 90) {
    return { dx: 0, dy: -1 };
  }
  if (normalized === 180) {
    return { dx: -1, dy: 0 };
  }
  if (normalized === 270) {
    return { dx: 0, dy: 1 };
  }
  return { dx: 1, dy: 0 };
}

function normalizeDegrees(degrees) {
  const normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

function collectAtPosition(collectables, collected, x, y) {
  for (const item of collectables) {
    if (Number(item.column) === x && Number(item.row) === y) {
      collected.add(`${item.column}:${item.row}`);
    }
  }
}

function isIntegerPosition(x, y) {
  return Number.isInteger(x) && Number.isInteger(y);
}

module.exports = {
  validateBuilderProject,
};
