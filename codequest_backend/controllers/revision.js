import { UserProgress } from '../models/userprogress.model.js';

export const getRevisionProtocol = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const failedItems = await UserProgress.find({
      user_id: userId,
      is_correct: false,
    })
      .populate('question_id')
      .lean();

    const questions = failedItems.map((item) => item.question_id).filter(Boolean);

    return res.status(200).json({
      success: true,
      protocol: 'PATCH PROTOCOL v1.0',
      quarantineCount: questions.length,
      questions,
    });
  } catch (error) {
    console.error('getRevisionProtocol error:', error);
    return res.status(500).json({ success: false, message: 'Failed to generate revision protocol' });
  }
};

export default getRevisionProtocol;
