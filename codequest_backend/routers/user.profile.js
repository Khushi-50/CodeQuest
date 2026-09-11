import express from 'express';
import evaluateLevel from '../controllers/evaluateLevel.js';
import getprofiledetails from '../controllers/fetchprofiledetails.js';
import { login } from '../controllers/login.js';
import { signup } from '../controllers/signup.js';
import { setLevel } from '../controllers/setLevel.js';
import { updateLanguage } from '../controllers/updateLanguage.js';
import { syncStats } from '../controllers/syncStats.js';
import { getLeaderboard } from '../controllers/leaderboard.js';
import { getIncorrectQuestions } from '../controllers/fetchincorrectques.js';
import { getRevisionProtocol } from '../controllers/revision.js';
import { verifyToken } from '../middleware/auth.middleware.js';

const router = express.Router();

// Public Auth & Placement routes
router.post('/signup', signup);
router.post('/login', login);
router.post('/evaluate-level', evaluateLevel);

// Protected Runner Profile routes
router.get('/profile', verifyToken, getprofiledetails);
router.get('/profiledetails', verifyToken, getprofiledetails);
router.post('/set-level', verifyToken, setLevel);
router.post('/update-language', verifyToken, updateLanguage);
router.post('/sync', verifyToken, syncStats);
router.get('/leaderboard', getLeaderboard);

// Quarantine Zone / Remediation routes
router.get('/quarantine', verifyToken, getIncorrectQuestions);
router.get('/revision', verifyToken, getRevisionProtocol);

export default router;