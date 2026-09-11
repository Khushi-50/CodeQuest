import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { User } from '../models/user.model.js';

export const signup = async (req, res) => {
  console.log('Signup request received:', req.body);
  try {
    const { username, email, password } = req.body;

    const normalizedUsername = (username || '').trim();
    const normalizedEmail = (email || '').trim().toLowerCase();

    if (!normalizedUsername || !normalizedEmail || !password) {
      return res.status(400).json({ success: false, message: 'Username, email, and password are required.' });
    }

    const existingUser = await User.findOne({
      $or: [{ email: normalizedEmail }, { username: normalizedUsername }],
    });

    if (existingUser) {
      if (existingUser.email === normalizedEmail) {
        return res.status(400).json({ success: false, message: 'Email already in use.' });
      }
      return res.status(400).json({ success: false, message: 'Username already in use.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      username: normalizedUsername,
      email: normalizedEmail,
      password: hashedPassword,
    });

    await newUser.save();

    const secret = process.env.JWT_SECRET || 'netrunner_fallback_secret_key_2026';
    const token = jwt.sign(
      { id: newUser._id },
      secret,
      { expiresIn: '7d' }
    );

    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      token,
      user: {
        id: newUser._id,
        username: newUser.username,
        email: newUser.email,
        level: newUser.level,
        selectedCourse: newUser.selectedCourse,
      },
    });
  } catch (error) {
    console.error('Signup error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};
