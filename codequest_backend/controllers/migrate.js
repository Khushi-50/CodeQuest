import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import mongoose from 'mongoose';

import { Course } from '../models/course.model.js';
import { Chapter } from '../models/chapter.model.js';
import { Subtopic } from '../models/subtopic.model.js';
import { Quiz } from '../models/quiz.schema.js';
import { Question } from '../models/questions.models,.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendRoot = path.resolve(__dirname, '..');

const DEFAULT_MONGODB_URI =
  process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/hac7';

const excludedDirectories = new Set(['controllers', 'models', 'node_modules']);

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function sanitizeJson(rawText) {
  return rawText.replace(/,\s*([}\]])/g, '$1');
}

function parseCourseFile(filePath) {
  const rawText = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(sanitizeJson(rawText));
}

function getTargetCourseDirectories() {
  const folderArgs = process.argv.slice(2);

  if (folderArgs.length > 0) {
    return folderArgs.map((folderName) => path.resolve(backendRoot, folderName));
  }

  return fs
    .readdirSync(backendRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !excludedDirectories.has(entry.name))
    .map((entry) => path.join(backendRoot, entry.name));
}

async function importCourseFolder(folderPath) {
  const folderName = path.basename(folderPath);

  if (!fs.existsSync(folderPath)) {
    throw new Error(`Course folder not found: ${folderName}`);
  }

  const jsonFiles = fs
    .readdirSync(folderPath)
    .filter((fileName) => fileName.endsWith('.json'))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  if (jsonFiles.length === 0) {
    console.log(`Skipping ${folderName}: no JSON files found.`);
    return;
  }

  const chapters = jsonFiles.map((fileName) => parseCourseFile(path.join(folderPath, fileName)));
  const courseTitle = chapters[0]?.course || folderName;
  const slug = slugify(courseTitle || folderName);

  const course = await Course.findOneAndUpdate(
    { slug },
    {
      title: courseTitle,
      slug,
      total_chapters: chapters.length,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  const existingChapters = await Chapter.find({ course_id: course._id }).select('_id');
  const existingChapterIds = existingChapters.map((chapter) => chapter._id);

  if (existingChapterIds.length > 0) {
    const existingSubtopics = await Subtopic.find({ chapter_id: { $in: existingChapterIds } }).select('_id');
    const existingSubtopicIds = existingSubtopics.map((subtopic) => subtopic._id);

    if (existingSubtopicIds.length > 0) {
      const existingQuizzes = await Quiz.find({ subtopic_id: { $in: existingSubtopicIds } }).select('_id');
      const existingQuizIds = existingQuizzes.map((quiz) => quiz._id);

      if (existingQuizIds.length > 0) {
        await Question.deleteMany({ quiz_id: { $in: existingQuizIds } });
      }

      await Quiz.deleteMany({ subtopic_id: { $in: existingSubtopicIds } });
    }

    await Subtopic.deleteMany({ chapter_id: { $in: existingChapterIds } });
    await Chapter.deleteMany({ course_id: course._id });
  }

  for (const chapterData of chapters) {
    const chapter = await Chapter.create({
      course_id: course._id,
      chapter_number: chapterData.chapter,
      chapter_name: chapterData.chapter_name,
      description: chapterData.description || '',
    });

    for (const subtopicData of chapterData.subtopics || []) {
      const subtopic = await Subtopic.create({
        chapter_id: chapter._id,
        subtopic_name: subtopicData.subtopic_name,
        order: subtopicData.subtopic_id,
      });

      for (const quizData of subtopicData.quizzes || []) {
        const totalXp = (quizData.questions || []).reduce(
          (sum, question) => sum + Number(question.xp || 0),
          0
        );

        const quiz = await Quiz.create({
          subtopic_id: subtopic._id,
          quiz_number: quizData.quiz_id || 0,
          quiz_title: quizData.quiz_title,
          total_xp: totalXp,
        });

        const questionDocs = (quizData.questions || []).map((questionData) => ({
          quiz_id: quiz._id,
          question_number: questionData.id || 0,
          question_text: questionData.question,
          options: questionData.options || [],
          correct_answer: questionData.answer,
          xp_value: Number(questionData.xp || 0),
        }));

        if (questionDocs.length > 0) {
          await Question.insertMany(questionDocs);
        }
      }
    }
  }

  console.log(`Imported ${courseTitle} from ${folderName}.`);
}

async function seedDB() {
  try {
    await mongoose.connect(DEFAULT_MONGODB_URI);

    const courseDirectories = getTargetCourseDirectories();

    if (courseDirectories.length === 0) {
      console.log('No course folders found to import.');
      return;
    }

    for (const folderPath of courseDirectories) {
      await importCourseFolder(folderPath);
    }

    console.log('Database seeded successfully.');
  } catch (error) {
    console.error('Seeding error:', error);
  } finally {
    await mongoose.connection.close();
  }
}

seedDB();
