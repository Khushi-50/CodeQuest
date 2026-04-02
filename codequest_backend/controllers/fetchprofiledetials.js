import jwt from 'jsonwebtoken';
import { User } from '../models/user.model.js';

const getprofiledetails = async (req, res) => {
    const authHeader = req.headers.authorization;
    const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
    const token = req.cookies.token || bearerToken;

    if (!token) {
        return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!process.env.JWT_SECRET) {
        return res.status(500).json({ message: 'JWT secret is not configured.' });
    }

    try {
        const user = jwt.verify(token, process.env.JWT_SECRET);
        const userDetails = await User.findById(user.id).select('-password');

        if (!userDetails) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ user: userDetails });
    } catch (err) {
        return res.status(401).json({ message: 'Invalid token' });
    }
};

export default getprofiledetails;
