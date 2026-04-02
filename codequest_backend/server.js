import express from 'express';
import cookieParser from 'cookie-parser';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import cors from 'cors';
import learningRouter from './routers/learning.routes.js';
import userprofilerouter from './routers/user.profile.js';

const app = express();
dotenv.config();
console.log("JWT Secret Check:", process.env.JWT_SECRET ? "LOADED" : "MISSING");
app.use(cors()); 
const DEFAULT_MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/hac7';
app.use(express.json());
app.use(cookieParser());
app.set('trust proxy', true);
app.use(express.urlencoded({ extended: true }));

app.use('/api/user', userprofilerouter);
app.use('/api/learning', learningRouter);
// const cors = require('cors');
// This allows your Flutter app to talk to the API
const PORT = process.env.PORT || 5050;

mongoose.connect(DEFAULT_MONGODB_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.log(err));
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
