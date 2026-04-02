import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';

import { Chapter } from '../models/chapter.model.js';
import { Course } from '../models/course.model.js';
import { Question } from '../models/questions.models,.js';
import { Quiz } from '../models/quiz.schema.js';
import { Subtopic } from '../models/subtopic.model.js';
import { UserProgress } from '../models/userprogress.model.js';

function getTokenFromRequest(req) {
  const authHeader = req.headers.authorization;
  const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
  return req.cookies?.token || bearerToken || null;
}

function getUserIdFromRequest(req) {
  const token = getTokenFromRequest(req);
  if (!token || !process.env.JWT_SECRET) return null;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded.id || null;
  } catch {
    return null;
  }
}

function requireUserId(req, res) {
  const userId = getUserIdFromRequest(req);
  if (!userId) {
    res.status(401).json({ message: 'Unauthorized' });
    return null;
  }
  return userId;
}

function buildQuestionProgressMap(progressDocs) {
  const map = new Map();
  for (const progress of progressDocs) {
    map.set(String(progress.question_id), progress);
  }
  return map;
}

export const getCourses = async (req, res) => {
  try {
    const courses = await Course.find()
      .select('title slug description total_chapters thumbnail')
      .sort({ title: 1 })
      .lean();
    res.status(200).json({ courses });
  } catch (error) {
    console.error('Get courses error:', error);
    res.status(500).json({ message: 'Failed to fetch courses.' });
  }
};

export const getCourseMap = async (req, res) => {
  try {
    const { courseId } = req.params;

    const courseQuery = mongoose.isValidObjectId(courseId)
      ? { _id: courseId }
      : { slug: courseId };

    const course = await Course.findOne(courseQuery)
      .select('title slug description total_chapters thumbnail')
      .lean();

    if (!course) {
      return res.status(404).json({ message: 'Course not found.' });
    }

    const chapters = await Chapter.find({ course_id: course._id })
      .sort({ chapter_number: 1 })
      .lean();

    const chapterIds = chapters.map((c) => c._id);

    const subtopics = await Subtopic.find({ chapter_id: { $in: chapterIds } })
      .sort({ order: 1 })
      .lean();

    const subtopicIds = subtopics.map((s) => s._id);

    const quizzes = await Quiz.find({ subtopic_id: { $in: subtopicIds } })
      .sort({ quiz_number: 1 })
      .lean();

    const quizIds = quizzes.map((q) => q._id);

    const questions = await Question.find({ quiz_id: { $in: quizIds } })
      .select('quiz_id question_number')
      .sort({ question_number: 1 })
      .lean();

    const userId = getUserIdFromRequest(req);
    let questionProgressMap = new Map();

    if (userId && questions.length > 0) {
      const progressDocs = await UserProgress.find({
        user_id: userId,
        question_id: { $in: questions.map((q) => q._id) },
      }).lean();
      questionProgressMap = buildQuestionProgressMap(progressDocs);
    }

    const questionsByQuiz = new Map();
    for (const q of questions) {
      const key = String(q.quiz_id);
      if (!questionsByQuiz.has(key)) questionsByQuiz.set(key, []);
      questionsByQuiz.get(key).push(q);
    }

    const quizzesBySubtopic = new Map();
    for (const quiz of quizzes) {
      const quizQuestions = questionsByQuiz.get(String(quiz._id)) || [];
      const completedQuestions = quizQuestions.filter((q) => {
        const p = questionProgressMap.get(String(q._id));
        return p?.is_correct;
      }).length;
      const failedQuestions = quizQuestions.filter((q) => {
        const p = questionProgressMap.get(String(q._id));
        return p && !p.is_correct;
      }).length;
      const totalQuestions = quizQuestions.length;

      const quizNode = {
        id: quiz._id,
        quiz_number: quiz.quiz_number,
        quiz_title: quiz.quiz_title,
        total_xp: quiz.total_xp,
        total_questions: totalQuestions,
        completed_questions: completedQuestions,
        failed_questions: failedQuestions,
        is_completed: totalQuestions > 0 && completedQuestions === totalQuestions,
        is_unlocked:
          totalQuestions === 0 ||
          completedQuestions > 0 ||
          failedQuestions > 0 ||
          !userId,
      };

      const key = String(quiz.subtopic_id);
      if (!quizzesBySubtopic.has(key)) quizzesBySubtopic.set(key, []);
      quizzesBySubtopic.get(key).push(quizNode);
    }

    const subtopicsByChapter = new Map();
    for (const subtopic of subtopics) {
      const subtopicQuizzes = quizzesBySubtopic.get(String(subtopic._id)) || [];
      const totalQuizzes = subtopicQuizzes.length;
      const completedQuizzes = subtopicQuizzes.filter((q) => q.is_completed).length;

      const subtopicNode = {
        id: subtopic._id,
        order: subtopic.order,
        subtopic_name: subtopic.subtopic_name,
        total_quizzes: totalQuizzes,
        completed_quizzes: completedQuizzes,
        is_completed: totalQuizzes > 0 && completedQuizzes === totalQuizzes,
        is_unlocked:
          !userId ||
          totalQuizzes === 0 ||
          subtopicQuizzes.some((q) => q.is_unlocked),
        quizzes: subtopicQuizzes,
      };

      const key = String(subtopic.chapter_id);
      if (!subtopicsByChapter.has(key)) subtopicsByChapter.set(key, []);
      subtopicsByChapter.get(key).push(subtopicNode);
    }

    const chapterNodes = chapters.map((chapter) => {
      const chapterSubtopics = subtopicsByChapter.get(String(chapter._id)) || [];
      const totalSubtopics = chapterSubtopics.length;
      const completedSubtopics = chapterSubtopics.filter((s) => s.is_completed).length;

      return {
        id: chapter._id,
        chapter_number: chapter.chapter_number,
        chapter_name: chapter.chapter_name,
        description: chapter.description,
        total_subtopics: totalSubtopics,
        completed_subtopics: completedSubtopics,
        is_completed: totalSubtopics > 0 && completedSubtopics === totalSubtopics,
        is_unlocked:
          !userId ||
          totalSubtopics === 0 ||
          chapterSubtopics.some((s) => s.is_unlocked),
        subtopics: chapterSubtopics,
      };
    });

    res.status(200).json({
      course: {
        id: course._id,
        title: course.title,
        slug: course.slug,
        description: course.description,
        total_chapters: course.total_chapters,
        thumbnail: course.thumbnail,
      },
      chapters: chapterNodes,
    });
  } catch (error) {
    console.error('Get course map error:', error);
    res.status(500).json({ message: 'Failed to fetch course map.' });
  }
};

// ─── KEY NEW ENDPOINT ────────────────────────────────────────────────────────
// GET /api/learning/subtopics/:subtopicId/questions
// Returns ALL questions from ALL quizzes inside one subtopic node.
// Flutter calls this when the user taps a map node — gets the full quiz set.
export const getSubtopicQuestions = async (req, res) => {
  try {
    const { subtopicId } = req.params;

    const subtopic = await Subtopic.findById(subtopicId).lean();
    if (!subtopic) {
      return res.status(404).json({ message: 'Subtopic not found.' });
    }

    // Get every quiz that belongs to this subtopic, in order
    const quizzes = await Quiz.find({ subtopic_id: subtopic._id })
      .sort({ quiz_number: 1 })
      .lean();

    if (quizzes.length === 0) {
      return res.status(200).json({ subtopic_name: subtopic.subtopic_name, questions: [] });
    }

    const quizIds = quizzes.map((q) => q._id);

    // Fetch ALL questions across all quizzes, ordered by quiz then question number
    const questions = await Question.find({ quiz_id: { $in: quizIds } })
      .sort({ quiz_id: 1, question_number: 1 })
      .lean();

    // Build a lookup so we can label which quiz each question belongs to
    const quizMap = new Map(quizzes.map((q) => [String(q._id), q]));

    const questionList = questions.map((q) => ({
      id: q._id,
      quiz_id: q.quiz_id,
      quiz_title: quizMap.get(String(q.quiz_id))?.quiz_title || '',
      question_number: q.question_number,
      question: q.question_text,
      options: q.options,
      answer: q.correct_answer,
      xp: q.xp_value,
    }));

    res.status(200).json({
      subtopic_id: subtopic._id,
      subtopic_name: subtopic.subtopic_name,
      total_questions: questionList.length,
      questions: questionList,
    });
  } catch (error) {
    console.error('Get subtopic questions error:', error);
    res.status(500).json({ message: 'Failed to fetch subtopic questions.' });
  }
};

// GET /api/learning/quizzes/:quizId/questions
// Kept for backwards compatibility — looks up by MongoDB _id OR quiz_number
export const getQuizQuestions = async (req, res) => {
  try {
    const { quizId } = req.params;

    // Try MongoDB ObjectId first, then fall back to quiz_number
    let quiz = null;
    if (mongoose.isValidObjectId(quizId)) {
      quiz = await Quiz.findById(quizId).lean();
    }
    if (!quiz) {
      quiz = await Quiz.findOne({ quiz_number: Number(quizId) }).lean();
    }

    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found.' });
    }

    const questions = await Question.find({ quiz_id: quiz._id })
      .sort({ question_number: 1 })
      .lean();

    res.status(200).json({
      quiz: {
        id: quiz._id,
        subtopic_id: quiz.subtopic_id,
        quiz_number: quiz.quiz_number,
        quiz_title: quiz.quiz_title,
        total_xp: quiz.total_xp,
      },
      questions: questions.map((q) => ({
        id: q._id,
        question_number: q.question_number,
        question: q.question_text,
        options: q.options,
        answer: q.correct_answer,
        xp: q.xp_value,
      })),
    });
  } catch (error) {
    console.error('Get quiz questions error:', error);
    res.status(500).json({ message: 'Failed to fetch quiz questions.' });
  }
};

export const submitQuizAnswers = async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;

    const { quizId } = req.params;
    const { answers } = req.body;

    if (!Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({ message: 'Answers array is required.' });
    }

    const questions = await Question.find({ quiz_id: quizId }).lean();
    if (questions.length === 0) {
      return res.status(404).json({ message: 'Quiz or questions not found.' });
    }

    const questionMap = new Map(questions.map((q) => [String(q._id), q]));
    const existingProgress = await UserProgress.find({
      user_id: userId,
      question_id: { $in: questions.map((q) => q._id) },
    });
    const progressMap = new Map(existingProgress.map((item) => [String(item.question_id), item]));

    const results = [];
    let earnedXp = 0;

    for (const answerItem of answers) {
      const question = questionMap.get(String(answerItem.questionId));
      if (!question) continue;

      const isCorrect = answerItem.selectedAnswer === question.correct_answer;
      if (isCorrect) earnedXp += question.xp_value;

      const existingItem = progressMap.get(String(question._id));
      if (existingItem) {
        existingItem.attempts_count += 1;
        existingItem.is_correct = isCorrect;
        existingItem.status = isCorrect ? 'completed' : 'failed';
        existingItem.last_attempted = new Date();
        await existingItem.save();
      } else {
        await UserProgress.create({
          user_id: userId,
          question_id: question._id,
          attempts_count: 1,
          is_correct: isCorrect,
          status: isCorrect ? 'completed' : 'failed',
          last_attempted: new Date(),
        });
      }

      results.push({
        question_id: question._id,
        selected_answer: answerItem.selectedAnswer,
        correct_answer: question.correct_answer,
        is_correct: isCorrect,
        xp_value: isCorrect ? question.xp_value : 0,
      });
    }

    res.status(200).json({
      quiz_id: quizId,
      total_questions: questions.length,
      attempted_questions: results.length,
      correct_answers: results.filter((r) => r.is_correct).length,
      incorrect_answers: results.filter((r) => !r.is_correct).length,
      earned_xp: earnedXp,
      results,
    });
  } catch (error) {
    console.error('Submit quiz answers error:', error);
    res.status(500).json({ message: 'Failed to save quiz progress.' });
  }
};

export const getSubtopicRevisionQuestions = async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;

    const { subtopicId } = req.params;
    const subtopic = await Subtopic.findById(subtopicId).lean();
    if (!subtopic) {
      return res.status(404).json({ message: 'Subtopic not found.' });
    }

    const quizzes = await Quiz.find({ subtopic_id: subtopic._id }).select('_id').lean();
    const questions = await Question.find({
      quiz_id: { $in: quizzes.map((q) => q._id) },
    })
      .sort({ question_number: 1 })
      .lean();

    const failedProgress = await UserProgress.find({
      user_id: userId,
      question_id: { $in: questions.map((q) => q._id) },
      is_correct: false,
    }).lean();

    const failedQuestionIds = new Set(failedProgress.map((p) => String(p.question_id)));
    const revisionQuestions = questions
      .filter((q) => failedQuestionIds.has(String(q._id)))
      .map((q) => ({
        id: q._id,
        question_number: q.question_number,
        question: q.question_text,
        options: q.options,
        answer: q.correct_answer,
        xp: q.xp_value,
      }));

    res.status(200).json({
      subtopic: {
        id: subtopic._id,
        subtopic_name: subtopic.subtopic_name,
        order: subtopic.order,
      },
      total_revision_questions: revisionQuestions.length,
      questions: revisionQuestions,
    });
  } catch (error) {
    console.error('Get revision questions error:', error);
    res.status(500).json({ message: 'Failed to fetch revision questions.' });
  }
};
