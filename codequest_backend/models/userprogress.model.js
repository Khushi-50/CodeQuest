import mongoose from 'mongoose';

const userProgressSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    question_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Question', required: true },
    status: {
      type: String,
      enum: ['unlocked', 'completed', 'failed'],
      default: 'unlocked',
    },
    
    attempts_count: { type: Number, default: 0 },
    is_correct: { type: Boolean, default: false },
    last_attempted: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

userProgressSchema.index({ user_id: 1, question_id: 1 }, { unique: true });

export const UserProgress = mongoose.model('UserProgress', userProgressSchema);
