import mongoose from 'mongoose';

export const AVAILABLE_COURSES = ['c-programming', 'python', 'java', 'cpp', 'javascript'];

const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    level: { 
      type: String, 
      enum: ['Beginner', 'Intermediate', 'Advanced', null], 
      default: null 
    },
    learnerType: {
      type: String,
      default: 'Step-by-Step Thinker',
    },
    selectedCourse: {
      type: [{ type: String, enum: AVAILABLE_COURSES, trim: true, lowercase: true }],
      default: ['c-programming'],
    },
    xp: { type: Number, default: 0 },
    uptime: { type: Number, default: 1 },
    joiningtime: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

export const User = mongoose.model('User', userSchema);