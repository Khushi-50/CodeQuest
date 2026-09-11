import express from 'express';
import cookieParser from 'cookie-parser';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import cors from 'cors';
import learningRouter from './routers/learning.routes.js';
import userprofilerouter from './routers/user.profile.js';

dotenv.config();

const app = express();

console.log("JWT Secret Check:", process.env.JWT_SECRET ? "LOADED" : "USING FALLBACK");

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

app.use(express.json());
app.use(cookieParser());
app.set('trust proxy', true);
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'CodeQuest NETRUNNER Core Engine operational' });
});

// API Routers
app.use('/api/user', userprofilerouter);
app.use('/api/learning', learningRouter);

// Centralized error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});

const DEFAULT_MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/hac7';
const PORT = process.env.PORT || 5050;

mongoose.connect(DEFAULT_MONGODB_URI)
  .then(() => console.log('✅ CodeQuest MongoDB database connected successfully.'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

app.listen(PORT, () => {
  console.log(`⚡ CodeQuest NETRUNNER server running on port ${PORT}`);
});

export default app;
