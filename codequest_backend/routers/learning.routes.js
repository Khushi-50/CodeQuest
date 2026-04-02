// routes/learning.routes.js
// Wire this into your main app: app.use('/api/learning', learningRouter)

import express from 'express';
import {
  getCourses,
  getCourseMap,
  getSubtopicQuestions,   // new — the key fix
  getQuizQuestions,
  submitQuizAnswers,
  getSubtopicRevisionQuestions,
} from '../controllers/learning_controller.js';

const router = express.Router();

// GET /api/learning/courses
router.get('/courses', getCourses);

// GET /api/learning/courses/:courseId/map
// courseId can be a MongoDB ObjectId OR a slug like "c-programming"
router.get('/courses/:courseId/map', getCourseMap);

// GET /api/learning/subtopics/:subtopicId/questions  ← THE KEY ENDPOINT
// Returns ALL questions from ALL quizzes inside one subtopic node (map circle).
// Flutter calls this when user taps a node — gets the full quiz in one request.
router.get('/subtopics/:subtopicId/questions', getSubtopicQuestions);

// GET /api/learning/subtopics/:subtopicId/revision
router.get('/subtopics/:subtopicId/revision', getSubtopicRevisionQuestions);

// GET /api/learning/quizzes/:quizId/questions  (kept for backwards compat)
router.get('/quizzes/:quizId/questions', getQuizQuestions);

// POST /api/learning/quizzes/:quizId/submit
router.post('/quizzes/:quizId/submit', submitQuizAnswers);

export default router;
