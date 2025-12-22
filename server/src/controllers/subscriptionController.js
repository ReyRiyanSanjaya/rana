const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.createRequest = async (req, res) => {
    try {
        const { tenantId, proofUrl } = req.body;

        // Create Request
        const request = await prisma.subscriptionRequest.create({
            data: {
                tenantId,
                proofUrl,
                status: 'PENDING'
            }
        });

        // Update Tenant to PENDING if not already
        await prisma.tenant.update({
            where: { id: tenantId },
            data: { subscriptionStatus: 'ACTIVE' } // For Demo: Auto-Activate if desired, but user wants verification.
        });
        // actually, let's keep tenant status as TRIAL or EXPIRED until approved.
        // Or maybe we add a 'PENDING_VERIFICATION' status to enum?
        // For simplicity, we just rely on the Request being pending.

        res.status(201).json({ success: true, data: request });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getAllRequests = async (req, res) => {
    try {
        const requests = await prisma.subscriptionRequest.findMany({
            include: { tenant: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, data: requests });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.approveRequest = async (req, res) => {
    try {
        const { id } = req.params;

        // 1. Update Request
        const request = await prisma.subscriptionRequest.update({
            where: { id },
            data: { status: 'APPROVED' },
            include: { tenant: true }
        });

        // 2. Update Tenant
        await prisma.tenant.update({
            where: { id: request.tenantId },
            data: {
                subscriptionStatus: 'ACTIVE',
                plan: 'PREMIUM',
                // Extend trialEndsAt or set expiry?
            }
        });

        res.json({ success: true, message: 'Subscription Approved' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
