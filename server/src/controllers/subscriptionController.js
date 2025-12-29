const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Create subscription request with selected package
exports.createRequest = async (req, res) => {
    try {
        const { proofUrl, packageId } = req.body; // [UPDATED] Include packageId
        const tenantId = req.user.tenantId;

        // Validate package exists if provided
        if (packageId) {
            const pkg = await prisma.subscriptionPackage.findUnique({ where: { id: packageId } });
            if (!pkg || !pkg.isActive) {
                return res.status(400).json({ success: false, error: 'Invalid package selected' });
            }
        }

        // Create Request with package reference
        const request = await prisma.subscriptionRequest.create({
            data: {
                tenantId,
                packageId, // [NEW] Link to selected package
                proofUrl,
                status: 'PENDING'
            },
            include: { package: true } // Include package info in response
        });

        res.status(201).json({ success: true, data: request });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getAllRequests = async (req, res) => {
    try {
        const { tenantId, role } = req.user;
        const whereClause = {};

        // If not ADMIN (or similar role), restrict to own tenant
        if (role !== 'ADMIN') {
            whereClause.tenantId = tenantId;
        }

        const requests = await prisma.subscriptionRequest.findMany({
            where: whereClause,
            include: {
                tenant: true,
                package: true // [NEW] Include package info
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, data: requests });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Approve request and set subscription duration based on package
exports.approveRequest = async (req, res) => {
    try {
        const { id } = req.params;

        // 1. Update Request and include package info
        const request = await prisma.subscriptionRequest.update({
            where: { id },
            data: { status: 'APPROVED' },
            include: {
                tenant: true,
                package: true // [NEW] Include package for duration
            }
        });

        // 2. Calculate subscription end date based on package duration
        const durationDays = request.package?.durationDays || 30; // Default 30 days
        const subscriptionEndsAt = new Date();
        subscriptionEndsAt.setDate(subscriptionEndsAt.getDate() + durationDays);

        // 3. Update Tenant with subscription expiry
        await prisma.tenant.update({
            where: { id: request.tenantId },
            data: {
                subscriptionStatus: 'ACTIVE',
                plan: 'PREMIUM',
                subscriptionEndsAt // [NEW] Set expiry based on package
            }
        });

        // 4. Create Platform Revenue log for the subscription
        if (request.package) {
            await prisma.platformRevenue.create({
                data: {
                    amount: request.package.price,
                    source: 'SUBSCRIPTION',
                    description: `Subscription: ${request.package.name} - ${request.tenant.name}`,
                    referenceId: request.id
                }
            });
        }

        res.json({
            success: true,
            message: 'Subscription Approved',
            data: {
                packageName: request.package?.name,
                durationDays,
                subscriptionEndsAt
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// [UPDATED] Get packages from database instead of hardcoded data
exports.getPackages = async (req, res) => {
    try {
        const packages = await prisma.subscriptionPackage.findMany({
            where: { isActive: true },
            orderBy: { price: 'asc' }
        });

        // Transform to include benefits array from description
        const transformedPackages = packages.map(pkg => ({
            ...pkg,
            benefits: pkg.description ? pkg.description.split('\n').filter(b => b.trim()) : [],
            interval: pkg.durationDays <= 31 ? 'month' : (pkg.durationDays <= 366 ? 'year' : 'custom')
        }));

        res.json({ success: true, data: transformedPackages });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Get subscription status including expiry date
exports.getStatus = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const tenant = await prisma.tenant.findUnique({
            where: { id: tenantId },
            select: {
                subscriptionStatus: true,
                plan: true,
                trialEndsAt: true,
                subscriptionEndsAt: true // [NEW] Include subscription expiry
            }
        });

        if (!tenant) return res.status(404).json({ success: false, message: 'Tenant not found' });

        // Calculate days remaining
        let daysRemaining = null;
        if (tenant.subscriptionStatus === 'ACTIVE' && tenant.subscriptionEndsAt) {
            daysRemaining = Math.ceil((new Date(tenant.subscriptionEndsAt) - new Date()) / (1000 * 60 * 60 * 24));
        } else if (tenant.subscriptionStatus === 'TRIAL' && tenant.trialEndsAt) {
            daysRemaining = Math.ceil((new Date(tenant.trialEndsAt) - new Date()) / (1000 * 60 * 60 * 24));
        }

        res.json({
            success: true,
            data: {
                ...tenant,
                daysRemaining
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
