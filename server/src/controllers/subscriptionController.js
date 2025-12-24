const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.createRequest = async (req, res) => {
    try {
        const { proofUrl } = req.body;
        // const { tenantId } = req.body; 
        // Use authenticated user's tenantId
        const tenantId = req.user.tenantId;

        // Create Request
        const request = await prisma.subscriptionRequest.create({
            data: {
                tenantId,
                proofUrl,
                status: 'PENDING'
            }
        });

        // Update Tenant to PENDING if not already
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
exports.getPackages = (req, res) => {
    // Hardcoded packages for now, or fetch from DB if we had a table
    const packages = [
        {
            id: 'premium_monthly',
            name: 'Rana Premium',
            price: 99000,
            interval: 'month',
            benefits: [
                'Unlimited Produk',
                'Rana AI Smart Insight',
                'Laporan Bisnis Lengkap',
                'Multi-User Access',
                'Prioritas Support (24/7)'
            ],
            color: 'blue'
        },
        // We can add more plans like Yearly in future
    ];
    res.json({ success: true, data: packages });
};

exports.getStatus = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const tenant = await prisma.tenant.findUnique({
            where: { id: tenantId },
            select: { subscriptionStatus: true, plan: true, trialEndsAt: true }
        });

        if (!tenant) return res.status(404).json({ success: false, message: 'Tenant not found' });

        res.json({ success: true, data: tenant });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
