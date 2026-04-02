import mongoose from 'mongoose';

const quizSchema = new mongoose.Schema(
  {
    subtopic_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Subtopic', required: true },
    quiz_number: { type: Number, default: 0 },
    quiz_title: { type: String, required: true, trim: true },
    total_xp: { type: Number, default: 0 },
  },
  { timestamps: true }
);

quizSchema.index({ subtopic_id: 1, quiz_number: 1 }, { unique: true });

export const Quiz = mongoose.model('Quiz', quizSchema);
