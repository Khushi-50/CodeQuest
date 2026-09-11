import { UserProgress } from '../models/userprogress.model.js';

export const getIncorrectQuestions = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const failedProgress = await UserProgress.find({
      user_id: userId,
      is_correct: false,
    })
      .populate('question_id')
      .lean();

    const questions = failedProgress
      .map((p) => p.question_id)
      .filter((q) => q != null);

    return res.status(200).json({
      success: true,
      count: questions.length,
      questions,
    });
  } catch (error) {
    console.error('getIncorrectQuestions error:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch quarantine questions' });
  }
};

export default getIncorrectQuestions;
