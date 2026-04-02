import mongoose from 'mongoose';

const courseSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, unique: true, trim: true },
    slug: { type: String, required: true, unique: true, lowercase: true, trim: true },
    description: { type: String, default: '' },
    total_chapters: { type: Number, default: 0 },
    thumbnail: { type: String, default: '' },
  },
  { timestamps: true }
);

export const Course = mongoose.model('Course', courseSchema);
