import { User } from '../models/user.model.js';

const VALID_LEVELS = ['Beginner', 'Intermediate', 'Advanced'];

export const setLevel = async (req, res) => {
  try {
    const { level, learnerType } = req.body;

    if (!level || !VALID_LEVELS.includes(level)) {
      return res.status(400).json({
        success: false,
        message: `Invalid level. Must be one of: ${VALID_LEVELS.join(', ')}`,
      });
    }

    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const updateData = { level };
    if (learnerType) {
      updateData.learnerType = learnerType;
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('-password');

    return res.status(200).json({ success: true, level, user: updatedUser });
  } catch (error) {
    console.error('setLevel error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};