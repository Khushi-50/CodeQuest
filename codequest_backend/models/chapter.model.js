import mongoose from 'mongoose';

const chapterSchema = new mongoose.Schema(
  {
    course_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
    chapter_number: { type: Number, required: true },
    chapter_name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
  },
  { timestamps: true }
);

chapterSchema.index({ course_id: 1, chapter_number: 1 }, { unique: true });

export const Chapter = mongoose.model('Chapter', chapterSchema);
