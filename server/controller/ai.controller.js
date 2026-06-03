const Groq = require('groq-sdk');

exports.generateWordSearchWords = async (req, res) => {
  try {
    const { slideTexts = [], lessonNumber } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!slideTexts.length) {
      return res.status(400).json({ status: false, error: 'No slide texts provided' });
    }

    const combinedText = slideTexts.join('\n\n');

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 64,
      messages: [
        {
          role: 'user',
          content: `You are a vocabulary extractor for a children's educational word search game.
Read the lesson text below and pick exactly 6 important vocabulary words.

Rules:
- Single words only (no spaces, no hyphens)
- Between 4 and 10 letters each
- Uppercase only
- Most important/frequent terms from the lesson
- Reply with ONLY the 6 words separated by commas, nothing else

Lesson text:
${combinedText}`,
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const words = raw
      .split(',')
      .map((w) => w.trim().toUpperCase())
      .filter((w) => /^[A-Z]{4,10}$/.test(w))
      .slice(0, 6);

    if (words.length < 4) {
      return res.status(500).json({ status: false, error: 'Could not extract enough words from lesson content' });
    }

    res.json({ status: true, words });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};

exports.generateWordMatchPairs = async (req, res) => {
  try {
    const { slideTexts = [], lessonNumber } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!slideTexts.length) {
      return res.status(400).json({ status: false, error: 'No slide texts provided' });
    }

    const combinedText = slideTexts.join('\n\n');

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 256,
      messages: [
        {
          role: 'user',
          content: `You are a vocabulary pair generator for a children's educational matching game.
Read the lesson text below and create exactly 4 word-definition pairs.

Rules:
- Each word should be a key term from the lesson (1-3 words max)
- Each definition should be a short, simple sentence (max 10 words)
- Format EXACTLY like this, one pair per line:
Word1|Definition1
Word2|Definition2
Word3|Definition3
Word4|Definition4
- No numbering, no extra text, nothing else

Lesson text:
${combinedText}`,
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const pairs = raw
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.includes('|'))
      .map((line) => {
        const idx = line.indexOf('|');
        return {
          word: line.substring(0, idx).trim(),
          definition: line.substring(idx + 1).trim(),
        };
      })
      .filter((p) => p.word.length > 0 && p.definition.length > 0)
      .slice(0, 4);

    if (pairs.length < 2) {
      return res.status(500).json({ status: false, error: 'Could not generate enough pairs from lesson content' });
    }

    res.json({ status: true, pairs });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};

exports.generateQuizQuestions = async (req, res) => {
  try {
    const { slideTexts = [], lessonNumber } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!slideTexts.length) {
      return res.status(400).json({ status: false, error: 'No slide texts provided' });
    }

    const combinedText = slideTexts.join('\n\n');

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 512,
      messages: [
        {
          role: 'user',
          content: `You are a quiz generator for a children's educational game.
Read the lesson text below and create exactly 5 multiple-choice questions.

Format EXACTLY like this, one question per line:
Question text|Option A|Option B|Option C|Option D|CorrectIndex

Rules:
- CorrectIndex is 0, 1, 2, or 3 (which option is correct)
- Keep questions simple and clear for children
- Options should be short (under 10 words each)
- No numbering, no extra text, nothing else

Lesson text:
${combinedText}`,
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const questions = raw
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.split('|').length === 6)
      .map((line) => {
        const parts = line.split('|');
        const correctIndex = parseInt(parts[5].trim(), 10);
        if (isNaN(correctIndex) || correctIndex < 0 || correctIndex > 3) return null;
        return {
          question: parts[0].trim(),
          options: [parts[1].trim(), parts[2].trim(), parts[3].trim(), parts[4].trim()],
          correctIndex,
        };
      })
      .filter(Boolean)
      .slice(0, 5);

    if (questions.length < 3) {
      return res.status(500).json({ status: false, error: 'Could not generate enough questions' });
    }

    res.json({ status: true, questions });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};

exports.generateSwipeConcepts = async (req, res) => {
  try {
    const { slideTexts = [], lessonNumber } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!slideTexts.length) {
      return res.status(400).json({ status: false, error: 'No slide texts provided' });
    }

    const combinedText = slideTexts.join('\n\n');

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 512,
      messages: [
        {
          role: 'user',
          content: `You are a game content generator for a children's digital safety game.
Read the lesson text and generate exactly 7 digital safety scenarios.
Some should be SAFE (allow) and some RISKY (block). Mix at least 3 safe and 3 risky.

Format EXACTLY like this, one scenario per line:
LABEL|positive|SENDER|Short preview message here.

Rules:
- LABEL: short concept name in CAPS, max 2 words, use \\n for line break between words
- positive: the word true if safe/allow, the word false if risky/block
- SENDER: short sender name like a username or app name (no spaces, max 15 chars)
- Short preview: a notification message, max 12 words
- No numbering, no extra text, nothing else

Example lines:
STRONG\\nPASSWORD|true|PASSGUARD|Password updated with letters, numbers, and symbols.
PHISHING|false|BANK-ALERT|Verify your account now or it will be locked.

Lesson text:
${combinedText}`,
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const concepts = raw
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.split('|').length >= 4)
      .map((line) => {
        const parts = line.split('|');
        return {
          text: parts[0].trim(),
          positive: parts[1].trim().toLowerCase() === 'true',
          sender: parts[2].trim().substring(0, 20),
          preview: parts.slice(3).join('|').trim(),
        };
      })
      .filter((c) => c.text.length > 0 && c.preview.length > 0)
      .slice(0, 7);

    if (concepts.length < 3) {
      return res.status(500).json({ status: false, error: 'Could not generate enough concepts from lesson content' });
    }

    res.json({ status: true, concepts });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};

exports.generateLessonText = async (req, res) => {
  try {
    const { message, lessonTitle = 'Lesson', lessonNumber = 1, history = [] } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!message || !message.trim()) {
      return res.status(400).json({ status: false, error: 'No message provided' });
    }

    const messages = [
      {
        role: 'system',
        content: `You are an AI assistant helping a teacher create educational lesson slides for children aged 8–14.
The teacher is building slides for Lesson ${lessonNumber}: "${lessonTitle}".
When asked to write slide content:
- Be concise and engaging (2–4 sentences unless more is requested)
- Use simple, age-appropriate language
- Respond with plain text only — no bullet symbols, no markdown, no asterisks
Reply directly with the content, no preamble like "Here is..." or "Sure!".`,
      },
      ...history.map((h) => ({ role: h.role, content: h.content })),
      { role: 'user', content: message },
    ];

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 350,
      messages,
    });

    const text = completion.choices[0].message.content.trim();
    res.json({ status: true, text });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};

exports.generateFillBlanks = async (req, res) => {
  try {
    const { slideTexts = [], lessonNumber } = req.body;
    const client = new Groq({ apiKey: process.env.GROQ_API_KEY });

    if (!slideTexts.length) {
      return res.status(400).json({ status: false, error: 'No slide texts provided' });
    }

    const combinedText = slideTexts.join('\n\n');

    const completion = await client.chat.completions.create({
      model: 'llama-3.1-8b-instant',
      max_tokens: 400,
      messages: [
        {
          role: 'user',
          content: `You are a fill-in-the-blank generator for a children's educational game.
Read the lesson text and create exactly 4 sentences, each with 1 or 2 blanks.
Mark each blank with {{answer}} like this: "Computer {{hardware}} includes the {{monitor}}."
On the very last line write "DISTRACTORS:" followed by 4 extra words from the lesson that are NOT answers, comma-separated.

Rules:
- Sentences must be simple (under 20 words)
- Answers must be key vocabulary from the lesson
- No numbering, no extra explanation, nothing else

Lesson text:
${combinedText}`,
        },
      ],
    });

    const raw = completion.choices[0].message.content.trim();
    const lines = raw.split('\n').map((l) => l.trim()).filter(Boolean);

    const distractorLine = lines.find((l) => l.startsWith('DISTRACTORS:'));
    const distractors = distractorLine
      ? distractorLine.replace('DISTRACTORS:', '').split(',').map((w) => w.trim()).filter(Boolean)
      : [];

    const sentenceLines = lines.filter((l) => !l.startsWith('DISTRACTORS:') && l.includes('{{'));

    if (sentenceLines.length < 2) {
      return res.status(500).json({ status: false, error: 'Could not generate enough sentences' });
    }

    res.json({ status: true, sentences: sentenceLines.slice(0, 4), distractors });
  } catch (err) {
    res.status(500).json({ status: false, error: err.message || 'AI generation failed' });
  }
};
