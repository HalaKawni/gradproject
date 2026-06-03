const router = require('express').Router();
const AiController = require('../controller/ai.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/lesson-chat',      authMiddleware, AiController.generateLessonText);
router.post('/wordsearch-words', authMiddleware, AiController.generateWordSearchWords);
router.post('/wordmatch-pairs', authMiddleware, AiController.generateWordMatchPairs);
router.post('/quiz-questions', authMiddleware, AiController.generateQuizQuestions);
router.post('/fill-blanks',    authMiddleware, AiController.generateFillBlanks);
router.post('/swipe-concepts', authMiddleware, AiController.generateSwipeConcepts);

module.exports = router;
