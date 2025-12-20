const { errorResponse } = require('../utils/response');

/**
 * Middleware to restrict access based on User Role.
 * Usage: router.get('/admin', verifyToken, checkRole(['SUPER_ADMIN']), controller)
 */
const checkRole = (allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !req.user.role) {
            return errorResponse(res, "Unauthorized Access", 401);
        }

        if (!allowedRoles.includes(req.user.role)) {
            return errorResponse(res, "Forbidden: Insufficient Permissions", 403);
        }

        next();
    };
};

module.exports = checkRole;
