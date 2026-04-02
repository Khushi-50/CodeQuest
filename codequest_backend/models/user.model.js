import mongoose from 'mongoose';

export const AVAILABLE_COURSES = [
  'c-programming',
  'cpp',
  'java',
  'python',
  'javascript',
  'data-structures',
  'algorithms',
  'web-development',
];

const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    selectedCourse: {
      type: [
        {
          type: String,
          enum: AVAILABLE_COURSES,
          trim: true,
          lowercase: true,
        },
      ],
      default: [],
    },
    joiningtime: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

export const User = mongoose.model('User', userSchema);
