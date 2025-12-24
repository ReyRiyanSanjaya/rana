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

        // 3. Create Platform Revenue Log if fee exists
        if (feeAmount > 0) {
            await prisma.platformRevenue.create({
                data: {
                    amount: feeAmount,
                    source: 'WITHDRAWAL_FEE',
                    description: `Fee from Withdrawal #${withdrawal.id.substring(0, 8)}`,
                    referenceId: withdrawal.id
                }
            });
        }

        const updated = await prisma.withdrawal.update({
            where: { id },
            data: {
                status: 'APPROVED',
                updatedAt: new Date(),
                fee: feeAmount,
                netAmount: netAmount
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
                            name: true
                        }
                    },
                    users: {
                        where: { role: 'OWNER' },
                        take: 1,
                        select: { email: true, name: true }
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

// [NEW] Get Subscription Requests
const getSubscriptionRequests = async (req, res) => {
    try {
        const requests = await prisma.subscriptionRequest.findMany({
            where: { status: 'PENDING' },
            include: {
                tenant: {
                    select: { name: true, plan: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, requests);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch subscription requests", 500);
    }
};

// [NEW] Approve Subscription Request
const approveSubscriptionRequest = async (req, res) => {
    try {
        const { id } = req.params;

        // Transaction: Update Request -> Update Tenant Plan
        const result = await prisma.$transaction(async (tx) => {
            const request = await tx.subscriptionRequest.findUnique({ where: { id } });
            if (!request) throw new Error("Request not found");
            if (request.status !== 'PENDING') throw new Error("Request already processed");

            // 1. Update Request
            const updatedRequest = await tx.subscriptionRequest.update({
                where: { id },
                data: { status: 'APPROVED' }
            });

            // 2. Update Tenant to PREMIUM
            await tx.tenant.update({
                where: { id: request.tenantId },
                data: {
                    plan: 'PREMIUM',
                    subscriptionStatus: 'ACTIVE',
                }
            });

            // 3. Log Revenue (Assuming Premium is 399000 for now, or fetch from Package)
            // Ideally we should find the package price. 
            // For MVP let's assume standard Premium price.
            await tx.platformRevenue.create({
                data: {
                    amount: 399000,
                    source: 'SUBSCRIPTION',
                    description: `Subscription Upgrade - Tenant ${request.tenantId.substring(0, 8)}`,
                    referenceId: request.id
                }
            });

            return updatedRequest;
        });

        successResponse(res, result, "Subscription Approved");
    } catch (error) {
        console.error(error);
        errorResponse(res, error.message || "Failed to approve subscription", 500);
    }
};

// [NEW] Reject Subscription Request
const rejectSubscriptionRequest = async (req, res) => {
    try {
        const { id } = req.params;
        const updated = await prisma.subscriptionRequest.update({
            where: { id },
            data: { status: 'REJECTED' }
        });
        successResponse(res, updated, "Subscription Rejected");
    } catch (error) {
        errorResponse(res, "Failed to reject subscription", 500);
    }
};

// [NEW] Get Advanced Analytics
const getBusinessAnalytics = async (req, res) => {
    try {
        // 1. Total Revenue
        const totalRevenueResult = await prisma.platformRevenue.aggregate({
            _sum: { amount: true }
        });
        const totalRevenue = totalRevenueResult._sum.amount || 0;

        // 2. Revenue by Source
        const revenueBySource = await prisma.platformRevenue.groupBy({
            by: ['source'],
            _sum: { amount: true }
        });

        // 3. Monthly Revenue (Last 6 Months)
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
        sixMonthsAgo.setDate(1); // Start of month

        const revenueLogs = await prisma.platformRevenue.findMany({
            where: { createdAt: { gte: sixMonthsAgo } },
            orderBy: { createdAt: 'asc' }
        });

        // Aggregate by Month-Year in JS
        const monthlyRevenue = {};
        // Initialize keys
        for (let i = 0; i < 6; i++) {
            const d = new Date(sixMonthsAgo);
            d.setMonth(d.getMonth() + i);
            const key = d.toLocaleString('default', { month: 'short', year: '2-digit' }); // Jan 24
            monthlyRevenue[key] = 0;
        }

        revenueLogs.forEach(log => {
            const key = log.createdAt.toLocaleString('default', { month: 'short', year: '2-digit' });
            if (monthlyRevenue[key] !== undefined) {
                monthlyRevenue[key] += log.amount;
            }
        });

        // Convert to array for Recharts
        const revenueChart = Object.keys(monthlyRevenue).map(key => ({
            name: key,
            revenue: monthlyRevenue[key]
        }));

        // 4. Merchant Growth (New Tenants per month)
        // Similar logic for Tenants
        const tenants = await prisma.tenant.findMany({
            where: { createdAt: { gte: sixMonthsAgo } }
        });
        const monthlyGrowth = {};
        // Initialize keys
        for (let i = 0; i < 6; i++) {
            const d = new Date(sixMonthsAgo);
            d.setMonth(d.getMonth() + i);
            const key = d.toLocaleString('default', { month: 'short', year: '2-digit' });
            monthlyGrowth[key] = 0;
        }
        tenants.forEach(t => {
            const key = t.createdAt.toLocaleString('default', { month: 'short', year: '2-digit' });
            if (monthlyGrowth[key] !== undefined) {
                monthlyGrowth[key] += 1;
            }
        });
        const growthChart = Object.keys(monthlyGrowth).map(key => ({
            name: key,
            count: monthlyGrowth[key]
        }));

        // 5. Active Subscribers
        const activeSubscribers = await prisma.tenant.count({
            where: { plan: { not: 'FREE' }, subscriptionStatus: 'ACTIVE' }
        });

        // [NEW] 6. Metrics: ARPU (Average Revenue Per User/Tenant)
        const totalTenants = await prisma.tenant.count();
        const arpu = totalTenants > 0 ? (totalRevenue / totalTenants) : 0;

        // [NEW] 7. Churn (Cancelled / Total)
        const cancelledTenants = await prisma.tenant.count({
            where: { subscriptionStatus: 'CANCELLED' }
        });
        const churnRate = totalTenants > 0 ? ((cancelledTenants / totalTenants) * 100).toFixed(1) : 0;

        // [NEW] 8. Top Merchants by Transaction Volume
        const topMerchantsResult = await prisma.transaction.groupBy({
            by: ['storeId'],
            _sum: { totalAmount: true },
            orderBy: {
                _sum: { totalAmount: 'desc' }
            },
            take: 5
        });

        // Enrich with Store Names
        const topMerchants = [];
        for (const tm of topMerchantsResult) {
            const store = await prisma.store.findUnique({
                where: { id: tm.storeId },
                select: { name: true, tenant: { select: { name: true } } }
            });
            if (store) {
                topMerchants.push({
                    name: store.name, // or store.tenant.name
                    volume: tm._sum.totalAmount
                });
            }
        }

        // [NEW] 9. Merchant Distribution by Location
        const locationStats = await prisma.store.groupBy({
            by: ['location'],
            _count: { id: true },
            where: {
                location: { not: null }
            },
            orderBy: {
                _count: { id: 'desc' }
            },
            take: 10
        });

        const merchantByLocation = locationStats.map(stat => ({
            name: stat.location,
            count: stat._count.id
        }));

        successResponse(res, {
            totalRevenue,
            revenueBySource,
            revenueChart,
            growthChart,
            activeSubscribers,
            arpu,
            churnRate,
            topMerchants,
            merchantByLocation
        });

    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch analytics", 500);
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
    deleteMerchant,
    getSubscriptionRequests,
    approveSubscriptionRequest,
    rejectSubscriptionRequest,
    getBusinessAnalytics // Exported
};
