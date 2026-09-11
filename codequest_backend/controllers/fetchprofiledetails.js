import { User } from '../models/user.model.js';

export const getprofiledetails = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const userDetails = await User.findById(userId).select('-password');

    if (!userDetails) {
      return res.status(404).json({ success: false, message: 'User profile not found' });
    }

    return res.status(200).json({
      success: true,
      user: userDetails,
    });
  } catch (err) {
    console.error('getprofiledetails error:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch user details' });
  }
};

export default getprofiledetails;
