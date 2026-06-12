const TRANSLATE_API_URL = 'https://translation.googleapis.com/language/translate/v2';

function getTranslationApiKey() {
  if (process.env.GOOGLE_CLOUD_TRANSLATION_DISABLED === 'true') {
    return '';
  }

  return String(process.env.TRANSLATION_API_KEY || '').trim();
}

async function translateText(text, targetLanguage, sourceLanguage = 'en') {
  const normalizedText = typeof text === 'string' ? text.trim() : '';
  if (!normalizedText) {
    return '';
  }

  const apiKey = getTranslationApiKey();
  if (!apiKey) {
    throw new Error('Google Translation API key is missing.');
  }

  const response = await fetch(`${TRANSLATE_API_URL}?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      q: normalizedText,
      source: sourceLanguage,
      target: targetLanguage,
      format: 'text',
    }),
  });

  const payload = await response.json().catch(() => null);
  if (!response.ok) {
    const message =
      payload?.error?.message ||
      `Translation API request failed with status ${response.status}`;
    throw new Error(message);
  }

  const translatedText = payload?.data?.translations?.[0]?.translatedText;
  return typeof translatedText === 'string' ? translatedText : normalizedText;
}

module.exports = {
  translateText,
};
