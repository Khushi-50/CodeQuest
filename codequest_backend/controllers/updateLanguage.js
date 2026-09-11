import { User, AVAILABLE_COURSES } from '../models/user.model.js';

export const updateLanguage = async (req, res) => {
  try {
    const { language, course } = req.body;
    const targetCourse = (course || language || '').trim().toLowerCase();

    if (!targetCourse || !AVAILABLE_COURSES.includes(targetCourse)) {
      return res.status(400).json({
        success: false,
        message: `Invalid course/language. Available options: ${AVAILABLE_COURSES.join(', ')}`,
      });
    }

    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { selectedCourse: [targetCourse] },
      { new: true }
    ).select('-password');

    return res.status(200).json({
      success: true,
      message: `Target language set to ${targetCourse}`,
      selectedCourse: updatedUser.selectedCourse,
      user: updatedUser,
    });
  } catch (error) {
    console.error('updateLanguage error:', error);
    return res.status(500).json({ success: false, message: 'Failed to update target language' });
  }
};