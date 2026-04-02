import mongoose from 'mongoose';

const questionSchema = new mongoose.Schema(
  {
    quiz_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Quiz', required: true },
    question_number: { type: Number, default: 0 },
    question_text: { type: String, required: true, trim: true },
    options: { type: [String], default: [] },
    correct_answer: { type: String, required: true },
    xp_value: { type: Number, default: 0 },
  },
  { timestamps: true }
);

questionSchema.index({ quiz_id: 1, question_number: 1 }, { unique: true });

export const Question = mongoose.model('Question', questionSchema);
