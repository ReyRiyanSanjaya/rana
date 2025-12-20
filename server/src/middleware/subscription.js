const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { errorResponse } = require('../utils/response');

/**
 * Middleware to check if Tenant has active subscription or valid trial.
 * Blocks Write Access if expired.
 */
const checkSubscription = async (req, res, next) => {
    try {
        const { tenantId } = req.user;

        // 1. Fetch Tenant Status
        const tenant = await prisma.tenant.findUnique({
            where: { id: tenantId }
        });

        if (!tenant) return errorResponse(res, "Tenant not found", 404);

        // 2. Check if exempt (e.g. LIFETIME/Owner) or already Active
        if (tenant.subscriptionStatus === 'ACTIVE') {
            return next();
        }

        // 3. Check Trial
        const now = new Date();
        const trialEnd = new Date(tenant.trialEndsAt || tenant.createdAt); // Fallback to createdAt if null

        // If trialEndsAt is null, maybe give them 7 days from CreatedAt default? 
        // Logic: if trialEndsAt is null, calculate it.
        let efficientTrialEnd = tenant.trialEndsAt;
        if (!efficientTrialEnd) {
            efficientTrialEnd = new Date(tenant.createdAt);
            efficientTrialEnd.setDate(efficientTrialEnd.getDate() + 7);
        }

        if (now > efficientTrialEnd) {
            // EXPIRED

            // Allow GET (Read-only access to see data)
            if (req.method === 'GET') {
                return next();
            }

            // Block POST/PUT/DELETE
            return res.status(402).json({
                success: false,
                message: "Subscription Expired. Please upgrade to continue.",
                code: "SUBSCRIPTION_EXPIRED"
            });
        }

        next();

    } catch (error) {
        console.error("Sub Check Error:", error);
        return errorResponse(res, "Subscription Check Failed", 500);
    }
};

module.exports = checkSubscription;
