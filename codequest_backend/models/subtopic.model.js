import mongoose from 'mongoose';

const subtopicSchema = new mongoose.Schema(
  {
    chapter_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Chapter', required: true },
    subtopic_name: { type: String, required: true, trim: true },
    order: { type: Number, required: true },
  },
  { timestamps: true }
);

subtopicSchema.index({ chapter_id: 1, order: 1 }, { unique: true });

export const Subtopic = mongoose.model('Subtopic', subtopicSchema);
