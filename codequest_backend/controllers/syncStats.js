import { User } from '../models/user.model.js';

export const syncStats = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { xpDelta = 0, uptime } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (xpDelta) {
      user.xp = (user.xp || 0) + Number(xpDelta);
    }
    if (uptime !== undefined) {
      user.uptime = Number(uptime);
    }

    await user.save();

    return res.status(200).json({
      success: true,
      xp: user.xp,
      uptime: user.uptime,
      level: user.level,
    });
  } catch (error) {
    console.error('syncStats error:', error);
    return res.status(500).json({ success: false, message: 'Failed to sync stats' });
  }
};
