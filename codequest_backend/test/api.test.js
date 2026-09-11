import assert from 'node:assert';
import { test, describe, before, after } from 'node:test';
import express from 'express';
import userprofilerouter from '../routers/user.profile.js';
import learningRouter from '../routers/learning.routes.js';
import evaluateLevel from '../controllers/evaluateLevel.js';

describe('CodeQuest Backend API Suite', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/user', userprofilerouter);
  app.use('/api/learning', learningRouter);

  test('Neural Scan Level Evaluation', async () => {
    const mockAnswers = [
      { category: 'Sequential', isCorrect: true },
      { category: 'Conditional', isCorrect: true },
      { category: 'Loop', isCorrect: true },
    ];

    const req = { body: { answers: mockAnswers } };
    let resStatus = 0;
    let resBody = null;
    const res = {
      status: (code) => {
        resStatus = code;
        return {
          json: (data) => {
            resBody = data;
            return data;
          },
        };
      },
    };

    evaluateLevel(req, res);
    assert.strictEqual(resStatus, 200);
    assert.strictEqual(resBody.success, true);
    assert.strictEqual(resBody.level, 'Advanced');
    assert.strictEqual(resBody.learnerType, 'Logic Builder');
  });
});
