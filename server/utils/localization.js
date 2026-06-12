const SUPPORTED_LANGUAGES = ['en', 'ar'];
const DEFAULT_LANGUAGE = 'en';
const ARABIC_CHAR_REGEX = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/;

function isPlainObject(value) {
  return (
    value != null &&
    typeof value === 'object' &&
    !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype
  );
}

function normalizeLanguage(language) {
  const normalizedLanguage = String(language || DEFAULT_LANGUAGE)
    .trim()
    .toLowerCase();

  return SUPPORTED_LANGUAGES.includes(normalizedLanguage)
    ? normalizedLanguage
    : DEFAULT_LANGUAGE;
}

function detectTextLanguage(value) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) {
    return DEFAULT_LANGUAGE;
  }

  return ARABIC_CHAR_REGEX.test(text) ? 'ar' : 'en';
}

function isLanguageMatch(value, language) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) {
    return false;
  }

  const normalizedLanguage = normalizeLanguage(language);
  return detectTextLanguage(text) === normalizedLanguage;
}

function isLocalizedValue(value) {
  if (!isPlainObject(value)) {
    return false;
  }

  return SUPPORTED_LANGUAGES.some((language) =>
    Object.prototype.hasOwnProperty.call(value, language)
  );
}

function getEnglishValue(value) {
  if (value === undefined || value === null) {
    return '';
  }

  if (typeof value === 'string') {
    return value;
  }

  if (!isLocalizedValue(value)) {
    return '';
  }

  if (typeof value.en === 'string') {
    const englishValue = value.en.trim();
    if (englishValue !== '') {
      return value.en;
    }
  }

  for (const language of SUPPORTED_LANGUAGES) {
    if (typeof value[language] === 'string' && value[language].trim() !== '') {
      return value[language];
    }
  }

  return '';
}

function getLocalizedValue(value, language) {
  const normalizedLanguage = normalizeLanguage(language);

  if (value === undefined || value === null) {
    return '';
  }

  if (typeof value === 'string') {
    return value;
  }

  if (!isLocalizedValue(value)) {
    return '';
  }

  if (
    typeof value[normalizedLanguage] === 'string' &&
    value[normalizedLanguage].trim() !== ''
  ) {
    return value[normalizedLanguage];
  }

  return getEnglishValue(value);
}

function buildLocalizedValue(value, translations = {}) {
  const localizedValue = isLocalizedValue(value) ? { ...value } : {};

  if (typeof value === 'string' && value.trim() !== '') {
    localizedValue[detectTextLanguage(value)] = value;
  }

  for (const [language, translation] of Object.entries(translations || {})) {
    if (!SUPPORTED_LANGUAGES.includes(language)) {
      continue;
    }

    if (typeof translation === 'string') {
      localizedValue[language] = translation;
    }
  }

  if (
    !SUPPORTED_LANGUAGES.some(
      (language) =>
        typeof localizedValue[language] === 'string' &&
        localizedValue[language].trim() !== ''
    )
  ) {
    localizedValue.en = '';
  }

  return localizedValue;
}

function toLocalizedInputValue(value) {
  if (value === undefined) {
    return undefined;
  }

  if (value === null) {
    return { en: '' };
  }

  if (typeof value === 'string') {
    return { en: value };
  }

  if (isLocalizedValue(value)) {
    return buildLocalizedValue(value);
  }

  return value;
}

module.exports = {
  DEFAULT_LANGUAGE,
  SUPPORTED_LANGUAGES,
  buildLocalizedValue,
  detectTextLanguage,
  getEnglishValue,
  getLocalizedValue,
  isLanguageMatch,
  isLocalizedValue,
  isPlainObject,
  normalizeLanguage,
  toLocalizedInputValue,
};
