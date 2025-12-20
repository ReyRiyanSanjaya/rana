const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// Get Withdrawals with filtering
const getWithdrawals = async (req, res) => {
    try {
        const { status } = req.query; // PENDING, APPROVED, REJECTED
        const whereClause = status ? { status } : {};

        const withdrawals = await prisma.withdrawal.findMany({
            where: whereClause,
            include: {
                store: {
                    select: {
                        name: true,
                        tenant: {
                            select: { name: true }
                        }
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return successResponse(res, withdrawals);
    } catch (error) {
        return errorResponse(res, "Failed to fetch withdrawals", 500, error);
    }
};

// Approve Withdrawal including proof
const approveWithdrawal = async (req, res) => {
    try {
        const { id } = req.params;
        const { proofImage } = req.body; // Optional: URL to transfer proof

        const withdrawal = await prisma.withdrawal.findUnique({ where: { id } });
        if (!withdrawal) return errorResponse(res, "Withdrawal not found", 404);
        if (withdrawal.status !== 'PENDING') return errorResponse(res, "Withdrawal already processed", 400);

        // 1. Get Platform Fee %
        const feeSetting = await prisma.systemSettings.findUnique({ where: { key: 'PLATFORM_FEE_PERCENTAGE' } });
        const feePercent = feeSetting ? parseFloat(feeSetting.value) : 0;

        // 2. Calculate Fee
        const feeAmount = (withdrawal.amount * feePercent) / 100;
        const netAmount = withdrawal.amount - feeAmount;

        const updated = await prisma.withdrawal.update({
            where: { id },
            data: {
                status: 'APPROVED',
                updatedAt: new Date(),
                fee: feeAmount,
                netAmount: netAmount
                // In a real app we might save proofImage somewhere
            }
        });

        return successResponse(res, updated, "Withdrawal Approved");
    } catch (error) {
        return errorResponse(res, "Failed to approve withdrawal", 500, error);
    }
};

// ... existing code ...

// [NEW] Announcement Management
const getAnnouncements = async (req, res) => {
    try {
        const announcements = await prisma.announcement.findMany({
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, announcements);
    } catch (error) {
        errorResponse(res, "Failed to fetch announcements", 500);
    }
};

const createAnnouncement = async (req, res) => {
    try {
        const { title, content } = req.body;
        const newAnnouncement = await prisma.announcement.create({
            data: { title, content, isActive: true }
        });
        successResponse(res, newAnnouncement, "Announcement created");
    } catch (error) {
        errorResponse(res, "Failed to create announcement", 500);
    }
};

const deleteAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.announcement.delete({ where: { id } });
        successResponse(res, null, "Announcement deleted");
    } catch (error) {
        errorResponse(res, "Failed to delete announcement", 500);
    }
};

// Reject Withdrawal
const rejectWithdrawal = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        return await prisma.$transaction(async (tx) => {
            const withdrawal = await tx.withdrawal.findUnique({ where: { id } });
            if (!withdrawal) throw new Error("Withdrawal not found");
            if (withdrawal.status !== 'PENDING') throw new Error("Withdrawal already processed");

            // 1. Update status
            const updated = await tx.withdrawal.update({
                where: { id },
                data: {
                    status: 'REJECTED',
                    updatedAt: new Date()
                    // possibly failedReason: reason (if schema allows, otherwise just audit or console)
                }
            });

            // 2. Refund Balance to Store
            await tx.store.update({
                where: { id: withdrawal.storeId },
                data: {
                    balance: { increment: withdrawal.amount }
                }
            });

            return updated;
        })
            .then(result => successResponse(res, result, "Withdrawal Rejected and Funds Returned"))
            .catch(err => errorResponse(res, err.message || "Failed to reject", 400));

    } catch (error) {
        return errorResponse(res, "System Error during rejection", 500, error);
    }
};

// Get Global Settings
const getSettings = async (req, res) => {
    try {
        const settings = await prisma.systemSettings.findMany();
        const settingsMap = {};
        settings.forEach(s => settingsMap[s.key] = s.value);
        return successResponse(res, settingsMap);
    } catch (error) {
        return errorResponse(res, "Failed to fetch settings", 500, error);
    }
};

// Update Global Settings
const updateSettings = async (req, res) => {
    try {
        const { key, value, description } = req.body;

        const setting = await prisma.systemSettings.upsert({
            where: { key },
            update: { value, description },
            create: { key, value, description }
        });

        return successResponse(res, setting, "Setting Updated");
    } catch (error) {
        return errorResponse(res, "Failed to update setting", 500, error);
    }
};

// [NEW] Get Dashboard Stats
const getDashboardStats = async (req, res) => {
    try {
        const totalStores = await prisma.store.count();

        const totalPayoutsResult = await prisma.withdrawal.aggregate({
            _sum: { amount: true },
            where: { status: 'APPROVED' }
        });
        const totalPayouts = totalPayoutsResult._sum.amount || 0;

        const pendingWithdrawals = await prisma.withdrawal.count({
            where: { status: 'PENDING' }
        });

        const recentWithdrawals = await prisma.withdrawal.findMany({
            take: 5,
            orderBy: { createdAt: 'desc' },
            include: {
                store: {
                    include: { tenant: true } // Include tenant name
                }
            }
        });

        successResponse(res, {
            totalStores,
            totalPayouts,
            pendingWithdrawals,
            recentWithdrawals
        });
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch dashboard stats", 500);
    };

    // [NEW] Subscription Package Management
    const getPackages = async (req, res) => {
        try {
            const packages = await prisma.subscriptionPackage.findMany({
                where: { isActive: true },
                orderBy: { price: 'asc' }
            });
            successResponse(res, packages);
        } catch (error) {
            errorResponse(res, "Failed to fetch packages", 500);
        }
    };

    const createPackage = async (req, res) => {
        try {
            const { name, price, durationDays, description } = req.body;
            const newPackage = await prisma.subscriptionPackage.create({
                data: { name, price: parseFloat(price), durationDays: parseInt(durationDays), description }
            });
            successResponse(res, newPackage, "Package created");
        } catch (error) {
            errorResponse(res, "Failed to create package", 500);
        }
    };

    const deletePackage = async (req, res) => {
        try {
            const { id } = req.params;
            await prisma.subscriptionPackage.update({
                where: { id },
                data: { isActive: false } // Soft delete
            });
            successResponse(res, null, "Package deleted");
        } catch (error) {
            errorResponse(res, "Failed to delete package", 500);
        }
    };

    // [NEW] Get Payout Chart Data (Last 7 Days)
    const getPayoutChart = async (req, res) => {
        try {
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

            const withdrawals = await prisma.withdrawal.groupBy({
                by: ['createdAt'],
                _sum: { amount: true },
                where: {
                    status: 'APPROVED',
                    createdAt: { gte: sevenDaysAgo }
                },
                orderBy: { createdAt: 'asc' }
            });

            // Format data for Recharts (group by date string)
            const chartData = [];
            for (let i = 6; i >= 0; i--) {
                const d = new Date();
                d.setDate(d.getDate() - i);
                const dateStr = d.toISOString().split('T')[0];

                // Find existing data or default to 0
                // Note: Prisma groupBy on DateTime might return specific timestamps. 
                // Better to raw query or JS process. JS process for simplicity here with small data.
                chartData.push({ date: dateStr, amount: 0 });
            }

            // We re-query properly or just doing raw aggregation might be better, 
            // but for simplicity let's fetch APPROVED recently and map in JS.
            const recentApproved = await prisma.withdrawal.findMany({
                where: {
                    status: 'APPROVED',
                    createdAt: { gte: sevenDaysAgo }
                },
                select: { createdAt: true, amount: true }
            });

            recentApproved.forEach(w => {
                const dateStr = new Date(w.createdAt).toISOString().split('T')[0];
                const entry = chartData.find(d => d.date === dateStr);
                if (entry) entry.amount += w.amount;
            });

            successResponse(res, chartData);
        } catch (error) {
            console.error(error);
            errorResponse(res, "Failed to fetch chart data", 500);
        }
    };

    // [NEW] Get Merchants List
    const getMerchants = async (req, res) => {
        try {
            const merchants = await prisma.store.findMany({
                include: {
                    tenant: {
                        select: {
                            name: true,
                            email: true,
                        }
                    }
                },
                orderBy: { createdAt: 'desc' }
            });
            successResponse(res, merchants);
        } catch (error) {
            console.error(error);
            errorResponse(res, "Failed to fetch merchants", 500);
        }
    };

    // [NEW] Export Withdrawals (Returns all data for CSV)
    const exportWithdrawals = async (req, res) => {
        try {
            const withdrawals = await prisma.withdrawal.findMany({
                include: {
                    store: {
                        select: { name: true, tenant: { select: { name: true } } }
                    }
                },
                orderBy: { createdAt: 'desc' }
            });
            successResponse(res, withdrawals);
        } catch (error) {
            console.error(error);
            errorResponse(res, "Failed to export data", 500);
        }
    };

    module.exports = {
        getWithdrawals,
        approveWithdrawal,
        rejectWithdrawal,
    }
};

// [NEW] Subscription Package Management
const getPackages = async (req, res) => {
    try {
        const packages = await prisma.subscriptionPackage.findMany({
            where: { isActive: true },
            orderBy: { price: 'asc' }
        });
        successResponse(res, packages);
    } catch (error) {
        errorResponse(res, "Failed to fetch packages", 500);
    }
};

const createPackage = async (req, res) => {
    try {
        const { name, price, durationDays, description } = req.body;
        const newPackage = await prisma.subscriptionPackage.create({
            data: { name, price: parseFloat(price), durationDays: parseInt(durationDays), description }
        });
        successResponse(res, newPackage, "Package created");
    } catch (error) {
        errorResponse(res, "Failed to create package", 500);
    }
};

const deletePackage = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.subscriptionPackage.update({
            where: { id },
            data: { isActive: false } // Soft delete
        });
        successResponse(res, null, "Package deleted");
    } catch (error) {
        errorResponse(res, "Failed to delete package", 500);
    }
};

// [NEW] Get Payout Chart Data (Last 7 Days)
const getPayoutChart = async (req, res) => {
    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const withdrawals = await prisma.withdrawal.groupBy({
            by: ['createdAt'],
            _sum: { amount: true },
            where: {
                status: 'APPROVED',
                createdAt: { gte: sevenDaysAgo }
            },
            orderBy: { createdAt: 'asc' }
        });

        // Format data for Recharts (group by date string)
        const chartData = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dateStr = d.toISOString().split('T')[0];

            // Find existing data or default to 0
            // Note: Prisma groupBy on DateTime might return specific timestamps. 
            // Better to raw query or JS process. JS process for simplicity here with small data.
            chartData.push({ date: dateStr, amount: 0 });
        }

        // We re-query properly or just doing raw aggregation might be better, 
        // but for simplicity let's fetch APPROVED recently and map in JS.
        const recentApproved = await prisma.withdrawal.findMany({
            where: {
                status: 'APPROVED',
                createdAt: { gte: sevenDaysAgo }
            },
            select: { createdAt: true, amount: true }
        });

        recentApproved.forEach(w => {
            const dateStr = new Date(w.createdAt).toISOString().split('T')[0];
            const entry = chartData.find(d => d.date === dateStr);
            if (entry) entry.amount += w.amount;
        });

        successResponse(res, chartData);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch chart data", 500);
    }
};

// [NEW] Get Merchants List
const getMerchants = async (req, res) => {
    try {
        const merchants = await prisma.store.findMany({
            include: {
                tenant: {
                    select: {
                        name: true,
                        email: true,
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, merchants);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch merchants", 500);
    }
};

// [NEW] Export Withdrawals (Returns all data for CSV)
const exportWithdrawals = async (req, res) => {
    try {
        const withdrawals = await prisma.withdrawal.findMany({
            include: {
                store: {
                    select: { name: true, tenant: { select: { name: true } } }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, withdrawals);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to export data", 500);
    }
};

// [NEW] Create Merchant (Tenant + User + Store)
const createMerchant = async (req, res) => {
    try {
        const { businessName, ownerName, email, password, phone, address } = req.body;

        // Validation
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) return errorResponse(res, "Email already registered", 400);

        // Transactional Creation
        const result = await prisma.$transaction(async (tx) => {
            // 1. Create Tenant
            const tenant = await tx.tenant.create({
                data: {
                    name: businessName,
                    plan: 'FREE', // Default plan
                    subscriptionStatus: 'TRIAL',
                    trialEndsAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // 14 Days Trial
                }
            });

            // 2. Create Store
            const store = await tx.store.create({
                data: {
                    tenantId: tenant.id,
                    name: businessName, // Default store name same as business (can change later)
                    location: address,
                    waNumber: phone
                }
            });

            // 3. Create Owner User
            // Ideally hash password here with bcrypt
            // For now assuming plain text/simple hash or client sends simple. 
            // NOTE: In production use bcrypt.hash(password, 10)
            const newUser = await tx.user.create({
                data: {
                    tenantId: tenant.id,
                    storeId: store.id,
                    name: ownerName,
                    email,
                    passwordHash: password, // TODO: Hash this!
                    role: 'OWNER'
                }
            });

            return { tenant, store, user: newUser };
        });

        successResponse(res, result, "Merchant created successfully");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to create merchant", 500, error);
    }
};

// [NEW] Delete Merchant (Soft Delete Tenant)
const deleteMerchant = async (req, res) => {
    try {
        const { id } = req.params; // Expecting Tenant ID? Or Store ID? 
        // Let's assume ID passed is Store ID for better UI flow, but we want to ban Tenant?
        // Usually list shows Stores. Let's assume Store ID.

        const store = await prisma.store.findUnique({ where: { id } });
        if (!store) return errorResponse(res, "Store not found", 404);

        // Soft delete Logic? 
        // Actually, let's just delete the Store logic or deactivate User?
        // Implementation: Deactivate Tenant subscription
        await prisma.tenant.update({
            where: { id: store.tenantId },
            data: { subscriptionStatus: 'CANCELLED' }
        });

        successResponse(res, null, "Merchant deactivated (Subscription Cancelled)");
    } catch (error) {
        errorResponse(res, "Failed to deactivate merchant", 500);
    }
};

module.exports = {
    getWithdrawals,
    approveWithdrawal,
    rejectWithdrawal,
    getSettings,
    updateSettings,
    getDashboardStats,
    getMerchants,
    exportWithdrawals,
    getPayoutChart,
    getPackages,
    createPackage,
    deletePackage,
    getAnnouncements,
    createAnnouncement,
    deleteAnnouncement,
    createMerchant,
    deleteMerchant
};
