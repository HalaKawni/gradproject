const {
  buildLocalizedValue,
  detectTextLanguage,
  getEnglishValue,
  getLocalizedValue,
  isLanguageMatch,
  isLocalizedValue,
  isPlainObject,
  normalizeLanguage,
  toLocalizedInputValue,
} = require('../utils/localization');
const { translateText } = require('./translation.service');

const DEFAULT_RECURSIVE_TEXT_FIELDS = [
  'title',
  'description',
  'instructions',
  'instruction',
  'lessonText',
  'text',
  'content',
  'body',
  'summary',
  'subtitle',
];

function isTranslatableFieldValue(value) {
  return typeof value === 'string' || isLocalizedValue(value);
}

function buildFieldSet(fields) {
  return new Set((fields || []).filter(Boolean));
}

function isPathAllowed(path, allowPaths) {
  if (!Array.isArray(allowPaths) || allowPaths.length == 0) {
    return true;
  }

  return allowPaths.some((matcher) => {
    if (!matcher) {
      return false;
    }
    if (matcher instanceof RegExp) {
      return matcher.test(path);
    }
    return matcher === path;
  });
}

function pickTranslationSource(value, targetLanguage) {
  const normalizedTargetLanguage = normalizeLanguage(targetLanguage);

  if (typeof value === 'string') {
    const text = value.trim();
    if (!text) {
      return null;
    }

    return {
      text,
      language: detectTextLanguage(text),
    };
  }

  if (!isLocalizedValue(value)) {
    return null;
  }

  for (const [language, localizedValue] of Object.entries(value)) {
    const text =
      typeof localizedValue === 'string' ? localizedValue.trim() : '';
    if (!text) {
      continue;
    }

    const detectedLanguage = detectTextLanguage(text);
    if (detectedLanguage !== normalizedTargetLanguage) {
      return {
        text,
        language: detectedLanguage,
      };
    }
  }

  for (const localizedValue of Object.values(value)) {
    const text =
      typeof localizedValue === 'string' ? localizedValue.trim() : '';
    if (!text) {
      continue;
    }

    return {
      text,
      language: detectTextLanguage(text),
    };
  }

  return null;
}

async function localizeFieldValue(value, language) {
  const normalizedLanguage = normalizeLanguage(language);
  const existingLocalizedValue = getLocalizedValue(value, normalizedLanguage);
  if (
    existingLocalizedValue.trim() &&
    isLanguageMatch(existingLocalizedValue, normalizedLanguage)
  ) {
    return {
      storageValue: value,
      responseValue: existingLocalizedValue,
      changed: false,
    };
  }

  const translationSource = pickTranslationSource(value, normalizedLanguage);
  if (!translationSource || !translationSource.text.trim()) {
    return {
      storageValue: value,
      responseValue: existingLocalizedValue,
      changed: false,
    };
  }

  if (translationSource.language === normalizedLanguage) {
    return {
      storageValue: buildLocalizedValue(value, {
        [normalizedLanguage]: translationSource.text,
      }),
      responseValue: translationSource.text,
      changed: true,
    };
  }

  try {
    const translatedValue = await translateText(
      translationSource.text,
      normalizedLanguage,
      translationSource.language
    );
    const storageValue = buildLocalizedValue(value, {
      [translationSource.language]: translationSource.text,
      [normalizedLanguage]: translatedValue,
    });

    return {
      storageValue,
      responseValue: translatedValue || translationSource.text,
      changed: true,
    };
  } catch (error) {
    return {
      storageValue: value,
      responseValue: existingLocalizedValue || translationSource.text,
      changed: false,
    };
  }
}

async function processNode(
  value,
  options,
  currentKey = null,
  rootKey = null,
  pathSegments = []
) {
  const {
    directFields,
    recursiveFields,
    allowPaths,
  } = options;

  const isDirectField = currentKey != null && directFields.has(currentKey);
  const isRecursiveField = currentKey != null && recursiveFields.has(currentKey);
  const currentPath = pathSegments.join('.');
  const canTranslatePath = isPathAllowed(currentPath, allowPaths);

  if (
    canTranslatePath &&
    (isDirectField || isRecursiveField) &&
    isTranslatableFieldValue(value)
  ) {
    const localized = await localizeFieldValue(value, options.language);
    return {
      storageValue: localized.storageValue,
      responseValue: localized.responseValue,
      changedRoots: localized.changed && rootKey ? new Set([rootKey]) : new Set(),
    };
  }

  if (Array.isArray(value)) {
    const storageValue = [];
    const responseValue = [];
    const changedRoots = new Set();

    for (const item of value) {
      const nextIndex = storageValue.length.toString();
      const processedItem = await processNode(
        item,
        options,
        null,
        rootKey,
        [...pathSegments, nextIndex]
      );
      storageValue.push(processedItem.storageValue);
      responseValue.push(processedItem.responseValue);
      mergeSets(changedRoots, processedItem.changedRoots);
    }

    return { storageValue, responseValue, changedRoots };
  }

  if (!isPlainObject(value)) {
    return {
      storageValue: value,
      responseValue: value,
      changedRoots: new Set(),
    };
  }

  const storageValue = {};
  const responseValue = {};
  const changedRoots = new Set();

  for (const [key, childValue] of Object.entries(value)) {
    const nextRootKey = rootKey || key;
    const processedChild = await processNode(
      childValue,
      options,
      key,
      nextRootKey,
      [...pathSegments, key]
    );

    storageValue[key] = processedChild.storageValue;
    responseValue[key] = processedChild.responseValue;
    mergeSets(changedRoots, processedChild.changedRoots);
  }

  return { storageValue, responseValue, changedRoots };
}

function mergeSets(target, source) {
  for (const value of source) {
    target.add(value);
  }
}

async function localizeDocument(document, config = {}) {
  const language = normalizeLanguage(config.language);
  const directFields = buildFieldSet(config.directFields);
  const recursiveFields = buildFieldSet(
    config.recursiveFields || DEFAULT_RECURSIVE_TEXT_FIELDS
  );
  const allowPaths = Array.isArray(config.allowPaths) ? config.allowPaths : null;
  const source =
    document && typeof document.toObject === 'function' ? document.toObject() : document;

  const processed = await processNode(source, {
    language,
    directFields,
    recursiveFields,
    allowPaths,
  });

  if (
    document &&
    typeof document.save === 'function' &&
    processed.changedRoots.size > 0
  ) {
    // Save only the top-level roots we actually changed to keep updates simple.
    for (const rootKey of processed.changedRoots) {
      document.set(rootKey, processed.storageValue[rootKey]);
      document.markModified(rootKey);
    }

    await document.save();
  }

  return processed.responseValue;
}

async function localizeDocuments(documents, config = {}) {
  return Promise.all((documents || []).map((document) => localizeDocument(document, config)));
}

function prepareLocalizedInput(data, config = {}) {
  const directFields = buildFieldSet(config.directFields);
  const recursiveFields = buildFieldSet(
    config.recursiveFields || DEFAULT_RECURSIVE_TEXT_FIELDS
  );
  const allowPaths = Array.isArray(config.allowPaths) ? config.allowPaths : null;

  return prepareNode(data, directFields, recursiveFields, null, [], allowPaths);
}

function prepareNode(
  value,
  directFields,
  recursiveFields,
  currentKey = null,
  pathSegments = [],
  allowPaths = null
) {
  const isDirectField = currentKey != null && directFields.has(currentKey);
  const isRecursiveField = currentKey != null && recursiveFields.has(currentKey);
  const currentPath = pathSegments.join('.');
  const canTranslatePath = isPathAllowed(currentPath, allowPaths);

  if (
    canTranslatePath &&
    (isDirectField || isRecursiveField) &&
    isTranslatableFieldValue(value)
  ) {
    return toLocalizedInputValue(value);
  }

  if (Array.isArray(value)) {
    return value.map((item, index) =>
      prepareNode(
        item,
        directFields,
        recursiveFields,
        null,
        [...pathSegments, index.toString()],
        allowPaths
      )
    );
  }

  if (!isPlainObject(value)) {
    return value;
  }

  const preparedValue = {};

  for (const [key, childValue] of Object.entries(value)) {
    preparedValue[key] = prepareNode(
      childValue,
      directFields,
      recursiveFields,
      key,
      [...pathSegments, key],
      allowPaths
    );
  }

  return preparedValue;
}

module.exports = {
  DEFAULT_RECURSIVE_TEXT_FIELDS,
  localizeDocument,
  localizeDocuments,
  prepareLocalizedInput,
};
