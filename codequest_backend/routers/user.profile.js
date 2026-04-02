import express from 'express';

import getprofiledetails from '../controllers/fetchprofiledetials.js';
import { login } from '../controllers/login.js';
import { signup } from '../controllers/signup.js';

const router = express.Router();
console.log('router');
router.post('/signup', signup);
router.post('/login', login);
router.get('/profile', getprofiledetails);
router.get('/profiledetails', getprofiledetails);

export default router;
