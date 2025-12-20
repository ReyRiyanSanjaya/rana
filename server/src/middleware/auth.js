const jwt = require('jsonwebtoken');
const { errorResponse } = require('../utils/response');

const verifyToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return errorResponse(res, "Access Denied. No token provided.", 401);
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_key_change_in_prod');
        req.user = decoded; // { userId, tenantId, role }
        next();
    } catch (error) {
        return errorResponse(res, "Invalid Token", 403);
    }
};

module.exports = verifyToken;
