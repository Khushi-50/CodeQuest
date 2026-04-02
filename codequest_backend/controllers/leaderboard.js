// controllers/leaderboard.js
import { User } from '../models/user.model.js';

export const getLeaderboard = async (req, res) => {
  try {
    // Top 50 users sorted by XP descending
    // Select only public fields — no email, no password
    const users = await User.find()
      .select('username xp')
      .sort({ xp: -1 })
      .limit(50)
      .lean();

    const leaderboard = users.map((user, index) => ({
      rank: index + 1,
      username: user.username,
      xp: user.xp ?? 0,
      level: Math.floor((user.xp ?? 0) / 100) + 1,
    }));

    res.status(200).json({ leaderboard });
  } catch (error) {
    console.error('Leaderboard error:', error);
    res.status(500).json({ message: 'Failed to fetch leaderboard.' });
  }
};
