const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt'); // [NEW]
const crypto = require('crypto');
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

// [NEW] Get TopUps with filtering
const getTopUps = async (req, res) => {
    try {
        const { status } = req.query; // PENDING, APPROVED, REJECTED
        const whereClause = status ? { status } : {};

        const topups = await prisma.topUpRequest.findMany({
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

        return successResponse(res, topups);
    } catch (error) {
        return errorResponse(res, "Failed to fetch top-ups", 500, error);
    }
};

// [NEW] Approve TopUp
const approveTopUp = async (req, res) => {
    try {
        const { id } = req.params;

        return await prisma.$transaction(async (tx) => {
            const topup = await tx.topUpRequest.findUnique({
                where: { id },
                include: { store: true } // [FIX] Include store to access tenantId
            });
            if (!topup) throw new Error("TopUp request not found");
            if (topup.status !== 'PENDING') throw new Error("TopUp already processed");

            // 1. Update Status
            const updated = await tx.topUpRequest.update({
                where: { id },
                data: {
                    status: 'APPROVED',
                    updatedAt: new Date()
                }
            });

            // 2. Add Balance to Store
            await tx.store.update({
                where: { id: topup.storeId },
                data: {
                    balance: { increment: topup.amount }
                }
            });

            // 3. Create Cashflow Log
            await tx.cashflowLog.create({
                data: {
                    tenantId: topup.store.tenantId, // [FIX] Get from store relation
                    storeId: topup.storeId,
                    amount: topup.amount,
                    type: 'CASH_IN',
                    category: 'TOPUP', // [FIX] Enum matches schema (TOPUP)
                    description: `Top Up Approved #${topup.id.substring(0, 8)}`,
                    occurredAt: new Date()
                }
            });

            return updated;
        })
            .then(result => successResponse(res, result, "Top Up Approved"))
            .catch(err => errorResponse(res, err.message || "Failed to approve", 400));

    } catch (error) {
        return errorResponse(res, "Failed to approve top-up", 500, error);
    }
};

// [NEW] Reject TopUp
const rejectTopUp = async (req, res) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;

        const updated = await prisma.topUpRequest.update({
            where: { id },
            data: {
                status: 'REJECTED',
                updatedAt: new Date()
            }
        });

        // Optional: Notify user about rejection reason

        return successResponse(res, updated, "Top Up Rejected");
    } catch (error) {
        return errorResponse(res, "Failed to reject top-up", 500, error);
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
        const SENSITIVE_SETTING_KEYS = new Set(['DIGIFLAZZ_API_KEY', 'DIGIFLAZZ_WEBHOOK_SECRET']);
        const deriveAesKey = (secret) =>
            crypto.createHash('sha256').update(String(secret || '')).digest();

        const decryptIfNeeded = (value) => {
            const raw = (value || '').toString();
            if (!raw) return '';
            if (!raw.startsWith('enc:v1:')) return raw;

            try {
                const secret =
                    process.env.SETTINGS_ENCRYPTION_KEY ||
                    process.env.JWT_SECRET ||
                    'super_secret_key_change_in_prod';
                const key = deriveAesKey(secret);

                const packed = Buffer.from(raw.slice('enc:v1:'.length), 'base64');
                if (packed.length < 12 + 16) return '';

                const iv = packed.subarray(0, 12);
                const tag = packed.subarray(12, 28);
                const ciphertext = packed.subarray(28);

                const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
                decipher.setAuthTag(tag);
                const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
                return plaintext.toString('utf8');
            } catch {
                return '';
            }
        };

        const maskSecret = (secret) => {
            const s = (secret || '').toString();
            if (!s) return '';
            const tail = s.slice(-4);
            return `****${tail}`;
        };

        const settings = await prisma.systemSettings.findMany();
        const settingsMap = {};
        settings.forEach(s => {
            if (SENSITIVE_SETTING_KEYS.has(s.key)) {
                const isSet = Boolean(s.value && s.value.toString().trim());
                settingsMap[`${s.key}_IS_SET`] = isSet ? 'true' : 'false';
                settingsMap[s.key] = isSet ? maskSecret(decryptIfNeeded(s.value)) : '';
                return;
            }
            settingsMap[s.key] = s.value;
        });
        return successResponse(res, settingsMap);
    } catch (error) {
        return errorResponse(res, "Failed to fetch settings", 500, error);
    }
};

// Update Global Settings
const updateSettings = async (req, res) => {
    try {
        const { key, value, description } = req.body;
        const SENSITIVE_SETTING_KEYS = new Set(['DIGIFLAZZ_API_KEY', 'DIGIFLAZZ_WEBHOOK_SECRET']);
        const deriveAesKey = (secret) =>
            crypto.createHash('sha256').update(String(secret || '')).digest();

        const encryptIfNeeded = (k, v) => {
            if (!SENSITIVE_SETTING_KEYS.has(k)) return String(v ?? '');
            const incoming = String(v ?? '');
            if (!incoming.trim() || incoming.includes('*')) return null;

            const secret =
                process.env.SETTINGS_ENCRYPTION_KEY ||
                process.env.JWT_SECRET ||
                'super_secret_key_change_in_prod';
            const aesKey = deriveAesKey(secret);
            const iv = crypto.randomBytes(12);
            const cipher = crypto.createCipheriv('aes-256-gcm', aesKey, iv);
            const ciphertext = Buffer.concat([cipher.update(incoming, 'utf8'), cipher.final()]);
            const tag = cipher.getAuthTag();
            const packed = Buffer.concat([iv, tag, ciphertext]).toString('base64');
            return `enc:v1:${packed}`;
        };

        const maybeEncryptedValue = encryptIfNeeded(key, value);
        if (maybeEncryptedValue === null) {
            const existing = await prisma.systemSettings.findUnique({ where: { key } });
            return successResponse(res, existing, "Setting Updated");
        }

        const setting = await prisma.systemSettings.upsert({
            where: { key },
            update: { value: maybeEncryptedValue, description },
            create: { key, value: maybeEncryptedValue, description }
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
                        plan: true,
                        subscriptionStatus: true,
                        trialEndsAt: true,
                        subscriptionEndsAt: true // [NEW] Include subscription expiry
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

// [NEW] Get Merchant Detail (Comprehensive)
const getMerchantDetail = async (req, res) => {
    try {
        const { id } = req.params; // Store ID
        const store = await prisma.store.findUnique({
            where: { id },
            include: {
                tenant: {
                    include: {
                        users: { select: { id: true, name: true, email: true, role: true } },
                        // subscriptions: true, // REMOVED: Field does not exist, using fields on Tenant
                    }
                },
                _count: {
                    select: { transactions: true, stock: true }
                }
            }
        });

        if (!store) return errorResponse(res, "Merchant not found", 404);

        // Fetch recent wallet history
        const walletHistory = await prisma.cashflowLog.findMany({
            where: { storeId: id },
            orderBy: { occurredAt: 'desc' },
            take: 10
        });

        // Calculate Stats (e.g. Total GMV) - optimized with aggregate
        const stats = await prisma.transaction.aggregate({
            where: { storeId: id },
            _sum: { totalAmount: true }
        });

        const detail = {
            ...store,
            walletHistory,
            totalGmv: stats._sum.totalAmount || 0,
            subscription: {
                plan: store.tenant.plan,
                status: store.tenant.subscriptionStatus,
                trialEndsAt: store.tenant.trialEndsAt
            }
        };

        successResponse(res, detail);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch merchant details", 500);
    }
};

// [NEW] Adjust Merchant Wallet
const adjustMerchantWallet = async (req, res) => {
    try {
        const { storeId } = req.params;
        const { type, amount, reason } = req.body; // type: 'CREDIT' or 'DEBIT'
        const numericAmount = parseFloat(amount);

        if (isNaN(numericAmount) || numericAmount <= 0) return errorResponse(res, "Invalid amount", 400);

        await prisma.$transaction(async (tx) => {
            const store = await tx.store.findUnique({ where: { id: storeId } });
            if (!store) throw new Error("Store not found");

            let newBalance = store.balance;
            if (type === 'CREDIT') {
                newBalance += numericAmount;
            } else {
                newBalance -= numericAmount;
            }

            await tx.store.update({
                where: { id: storeId },
                data: { balance: newBalance }
            });

            await tx.cashflowLog.create({
                data: {
                    tenantId: store.tenantId,
                    storeId: store.id,
                    amount: numericAmount,
                    type: type === 'CREDIT' ? 'CASH_IN' : 'CASH_OUT',
                    category: 'ADJUSTMENT',
                    description: `Admin Adjustment: ${reason}`,
                    occurredAt: new Date()
                }
            });

            // [INTEGRATION] Auto-send Notification
            await tx.notification.create({
                data: {
                    tenantId: store.tenantId,
                    title: type === 'CREDIT' ? 'Saldo Diterima' : 'Penyesuaian Saldo',
                    body: `Wallet Anda telah di-${type === 'CREDIT' ? 'kredit' : 'debit'} sebesar Rp ${numericAmount.toLocaleString()}. Alasan: ${reason}`
                }
            });
        });

        successResponse(res, null, "Wallet adjusted successfully");

    } catch (error) {
        console.error(error);
        errorResponse(res, error.message || "Failed to adjust wallet", 500);
    }
};

// [NEW] Send Notification to Merchant
const sendNotification = async (req, res) => {
    try {
        const { tenantId } = req.params;
        const { title, body } = req.body;

        await prisma.notification.create({
            data: {
                tenantId,
                title,
                body
            }
        });

        // In real world: Trigger FCM / Socket here

        successResponse(res, null, "Notification sent");
    } catch (error) {
        errorResponse(res, "Failed to send notification", 500);
    }
};

// [UPDATED] Update Merchant Subscription - plan is now optional (using packages instead)
const updateMerchantSubscription = async (req, res) => {
    try {
        const { tenantId } = req.params;
        const { subscriptionStatus, subscriptionEndsAt } = req.body;

        // Build update data
        const updateData = {
            subscriptionStatus
        };

        // Set subscription end date if provided
        if (subscriptionEndsAt) {
            updateData.subscriptionEndsAt = new Date(subscriptionEndsAt);
        }

        const tenant = await prisma.tenant.update({
            where: { id: tenantId },
            data: updateData
        });

        successResponse(res, tenant, "Subscription updated");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to update subscription", 500);
    }
};

// [NEW] Get Merchant Products
const getMerchantProducts = async (req, res) => {
    try {
        const { storeId } = req.params;
        const products = await prisma.product.findMany({
            where: { storeId, isActive: true },
            include: { category: true },
            orderBy: { name: 'asc' }
        });
        successResponse(res, products);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch products", 500);
    }
};

// [NEW] Create Merchant Product
const createMerchantProduct = async (req, res) => {
    try {
        const { storeId } = req.params;
        const { name, basePrice, sellingPrice, stock, categoryId, description, imageUrl } = req.body;

        const store = await prisma.store.findUnique({ where: { id: storeId } });
        if (!store) return errorResponse(res, "Store not found", 404);

        const product = await prisma.product.create({
            data: {
                tenantId: store.tenantId,
                storeId: store.id,
                name,
                basePrice: parseFloat(basePrice) || 0,
                sellingPrice: parseFloat(sellingPrice) || 0,
                stock: parseInt(stock) || 0,
                categoryId: categoryId || undefined,
                description,
                imageUrl,
                isActive: true
            }
        });

        // Log Initial Stock
        if (stock > 0) {
            await prisma.inventoryLog.create({
                data: {
                    productId: product.id,
                    storeId: store.id,
                    type: 'IN',
                    quantity: parseInt(stock),
                    reason: 'Initial Admin Creation',
                    createdAt: new Date()
                }
            });
        }

        successResponse(res, product, "Product created");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to create product", 500);
    }
};

// [NEW] Update Merchant Product
const updateMerchantProduct = async (req, res) => {
    try {
        const { productId } = req.params;
        const { name, basePrice, sellingPrice, stock, categoryId, description, imageUrl } = req.body;

        const product = await prisma.product.update({
            where: { id: productId },
            data: {
                name,
                basePrice: basePrice ? parseFloat(basePrice) : undefined,
                sellingPrice: sellingPrice ? parseFloat(sellingPrice) : undefined,
                stock: stock ? parseInt(stock) : undefined,
                categoryId: categoryId || undefined,
                description,
                imageUrl
            }
        });
        successResponse(res, product, "Product updated");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to update product", 500);
    }
};

// [NEW] Delete Merchant Product
const deleteMerchantProduct = async (req, res) => {
    try {
        const { productId } = req.params;
        await prisma.product.update({
            where: { id: productId },
            data: { isActive: false }
        });
        successResponse(res, null, "Product deleted");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to delete product", 500);
    }
};

// [NEW] Get Subscription Requests
const getSubscriptionRequests = async (req, res) => {
    try {
        const requests = await prisma.subscriptionRequest.findMany({
            where: { status: 'PENDING' },
            include: {
                tenant: {
                    select: {
                        name: true,
                        plan: true,
                        users: {
                            where: { role: 'OWNER' },
                            select: { email: true },
                            take: 1
                        }
                    }
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

// [NEW] App Menu Management
const getAppMenus = async (req, res) => {
    try {
        const menus = await prisma.appMenu.findMany({
            orderBy: { order: 'asc' }
        });
        successResponse(res, menus);
    } catch (error) {
        errorResponse(res, "Failed to fetch menus", 500);
    }
};

const createAppMenu = async (req, res) => {
    try {
        const { key, label, icon, route, order } = req.body;
        const menu = await prisma.appMenu.create({
            data: {
                key,
                label,
                icon,
                route,
                order: parseInt(order) || 0,
                isActive: true
            }
        });
        successResponse(res, menu, "Menu created");
    } catch (error) {
        console.error(error);
        if (error.code === 'P2002') return errorResponse(res, "Menu key already exists", 400);
        errorResponse(res, "Failed to create menu", 500);
    }
};

const updateAppMenu = async (req, res) => {
    try {
        const { id } = req.params;
        const { key, label, icon, route, isActive, order } = req.body;

        const menu = await prisma.appMenu.update({
            where: { id },
            data: {
                key,
                label,
                icon,
                route,
                isActive: isActive !== undefined ? isActive : undefined,
                order: order !== undefined ? parseInt(order) : undefined
            }
        });
        successResponse(res, menu, "Menu updated");
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to update menu", 500);
    }
};

const deleteAppMenu = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.appMenu.delete({ where: { id } });
        successResponse(res, null, "Menu deleted");
    } catch (error) {
        errorResponse(res, "Failed to delete menu", 500);
    }
};

// [NEW] Reset User Password
const resetUserPassword = async (req, res) => {
    try {
        const { id } = req.params;
        const { password } = req.body;

        if (!password || password.length < 6) return errorResponse(res, "Password must be at least 6 characters", 400);

        const hashedPassword = await bcrypt.hash(password, 10);

        await prisma.user.update({
            where: { id },
            data: { passwordHash: hashedPassword }
        });

        await logAudit('SYSTEM', req.user?.id, 'RESET_PASSWORD', 'User', id, { updatedBy: req.user?.id });

        successResponse(res, null, "Password reset successfully");
    } catch (error) {
        errorResponse(res, "Failed to reset password", 500);
    }
};

// [NEW] Get All Transactions
const getAllTransactions = async (req, res) => {
    try {
        const { page = 1, limit = 20, storeId, startDate, endDate, area, category, paymentStatus, paymentMethod } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const where = {};
        if (storeId) where.storeId = storeId;
        if (paymentStatus) where.paymentStatus = paymentStatus;
        if (paymentMethod) where.paymentMethod = paymentMethod;

        if (startDate && endDate) {
            where.occurredAt = {
                gte: new Date(startDate),
                lte: new Date(endDate)
            };
        }

        // Filter by Store fields (Area/Location, Category)
        if (area || category) {
            where.store = {
                ...(area && { location: { contains: area, mode: 'insensitive' } }),
                ...(category && { category: { equals: category, mode: 'insensitive' } })
            };
        }

        const [transactions, total] = await Promise.all([
            prisma.transaction.findMany({
                where,
                include: {
                    store: { select: { name: true, location: true, category: true } },
                    tenant: { select: { name: true } }
                },
                skip,
                take: parseInt(limit),
                orderBy: { occurredAt: 'desc' }
            }),
            prisma.transaction.count({ where })
        ]);

        successResponse(res, { transactions, total, page: parseInt(page), totalPages: Math.ceil(total / parseInt(limit)) });
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to fetch transactions", 500);
    }
};

// [NEW] Export Transactions
const exportTransactions = async (req, res) => {
    try {
        const { storeId, startDate, endDate, area, category, paymentStatus, paymentMethod } = req.query;

        const where = {};
        if (storeId) where.storeId = storeId;
        if (paymentStatus) where.paymentStatus = paymentStatus;
        if (paymentMethod) where.paymentMethod = paymentMethod;

        if (startDate && endDate) {
            where.occurredAt = {
                gte: new Date(startDate),
                lte: new Date(endDate)
            };
        }

        // Filter by Store fields
        if (area || category) {
            where.store = {
                ...(area && { location: { contains: area, mode: 'insensitive' } }),
                ...(category && { category: { equals: category, mode: 'insensitive' } })
            };
        }

        const transactions = await prisma.transaction.findMany({
            where,
            include: {
                store: { select: { name: true, location: true, category: true } },
                tenant: { select: { name: true } },
                user: { select: { name: true } } // Cashier
            },
            orderBy: { occurredAt: 'desc' }
        });

        successResponse(res, transactions);
    } catch (error) {
        console.error(error);
        errorResponse(res, "Failed to export transactions", 500);
    }
};



module.exports = {
    getWithdrawals,
    approveWithdrawal,
    rejectWithdrawal,
    getDashboardStats,
    getPayoutChart,
    getMerchants,
    createMerchant,
    deleteMerchant,
    getMerchantProducts,
    createMerchantProduct,
    updateMerchantProduct,
    deleteMerchantProduct,
    getPackages,
    createPackage,
    deletePackage,
    getSubscriptionRequests,
    approveSubscriptionRequest,
    rejectSubscriptionRequest,
    getBusinessAnalytics,
    getSettings,
    updateSettings,
    exportWithdrawals,
    updateMerchantSubscription, // [NEW]
    getAnnouncements,
    createAnnouncement,
    deleteAnnouncement,
    getAppMenus,
    createAppMenu,
    updateAppMenu,
    deleteAppMenu,
    getMerchantDetail, // [NEW]
    adjustMerchantWallet, // [NEW]
    sendNotification, // [NEW]
    resetUserPassword,
    getTopUps,
    approveTopUp,
    rejectTopUp,
    getAllTransactions, // [NEW]
    exportTransactions, // [NEW]

    // [NEW] Get Admin Users
    getAdminUsers: async (req, res) => {
        try {
            const admins = await prisma.user.findMany({
                where: { role: 'SUPER_ADMIN' },
                orderBy: { createdAt: 'desc' },
                select: { id: true, name: true, email: true, createdAt: true, role: true }
            });
            successResponse(res, admins, "Admin users retrieved");
        } catch (error) {
            errorResponse(res, "Failed to fetch admins", 500);
        }
    },

    // [NEW] Create Admin User
    createAdminUser: async (req, res) => {
        try {
            const { name, email, password } = req.body;
            if (!email || !password || password.length < 6) return errorResponse(res, "Invalid input", 400);

            const hashedPassword = await bcrypt.hash(password, 10);

            // We need a tenant for the user. Usually Super Admins belong to a 'System' tenant or we pick the first available. 
            // valid way: check if existing admin has tenantId, reuse it. Or find any tenant (hacky). 
            // Better: find a Tenant with name 'Rana Platform', if not create one.
            let tenant = await prisma.tenant.findFirst({ where: { name: 'Rana Platform' } });
            if (!tenant) {
                tenant = await prisma.tenant.create({ data: { name: 'Rana Platform', plan: 'ENTERPRISE', subscriptionStatus: 'ACTIVE' } });
            }

            const admin = await prisma.user.create({
                data: {
                    name,
                    email,
                    passwordHash: hashedPassword,
                    role: 'SUPER_ADMIN',
                    tenantId: tenant.id
                }
            });

            await logAudit(tenant.id, req.user?.id, 'CREATE_ADMIN', 'User', admin.id, { email });

            successResponse(res, { id: admin.id, email: admin.email }, "Admin created successfully");
        } catch (error) {
            console.error(error);
            if (error.code === 'P2002') return errorResponse(res, "Email already exists", 400);
            errorResponse(res, "Failed to create admin", 500);
        }
    },

    // [NEW] Delete Admin User
    deleteAdminUser: async (req, res) => {
        try {
            const { id } = req.params;
            const currentUserId = req.user.id; // From verifyToken middleware
            if (id === currentUserId) return errorResponse(res, "Cannot delete yourself", 403);

            await prisma.user.delete({ where: { id } });
            await logAudit('SYSTEM', req.user?.id, 'DELETE_ADMIN', 'User', id, {});
            successResponse(res, null, "Admin deleted");
        } catch (error) {
            errorResponse(res, "Failed to delete admin", 500);
        }
    },

    // [NEW] Get Platform Subscription (Billing)
    getPlatformSubscription: async (req, res) => {
        try {
            // Static for now, as requested.
            const data = {
                plan: "Enterprise",
                status: "ACTIVE",
                features: ["Unlimited Merchants", "Advanced Analytics", "Priority Support", "White-label Options"],
                nextBillingDate: "Lifetime Access",
                paymentMethod: "Corporate Billing"
            };
            successResponse(res, data, "Billing info retrieved");
        } catch (error) {
            errorResponse(res, "Failed to fetch billing", 500);
        }
    },

    // [NEW] Export Dashboard Data
    exportDashboardData: async (req, res) => {
        try {
            // Aggregate high level stats
            const [merchants, transactions] = await Promise.all([
                prisma.tenant.findMany({ select: { id: true, name: true, plan: true, createdAt: true, subscriptionStatus: true } }),
                prisma.transaction.findMany({
                    take: 1000,
                    orderBy: { occurredAt: 'desc' },
                    include: { store: { select: { name: true } } }
                })
            ]);

            // Simplified CSV generation
            const merchantCsv = merchants.map(m => `${m.name},${m.plan},${m.subscriptionStatus},${m.createdAt.toISOString()}`).join('\n');
            const data = {
                merchants: merchants,
                recentTransactions: transactions,
                generatedAt: new Date()
            };

            successResponse(res, data, "Export data ready");
        } catch (error) {
            errorResponse(res, "Failed to export data", 500);
        }
    },

    // [NEW] Get Audit Logs
    getAuditLogs: async (req, res) => {
        try {
            const logs = await prisma.auditLog.findMany({
                orderBy: { occurredAt: 'desc' },
                take: 100
            });
            successResponse(res, logs, "Audit logs retrieved");
        } catch (error) {
            errorResponse(res, "Failed to fetch audit logs", 500);
        }
    },

    // [NEW] Global Search
    globalSearch: async (req, res) => {
        try {
            const { q } = req.query;
            if (!q || q.length < 3) return successResponse(res, { merchants: [], users: [], products: [] }, "Query too short");

            const [merchants, users, products] = await Promise.all([
                prisma.tenant.findMany({
                    where: { name: { contains: q, mode: 'insensitive' } },
                    take: 5,
                    select: { id: true, name: true, plan: true }
                }),
                prisma.user.findMany({
                    where: { OR: [{ name: { contains: q, mode: 'insensitive' } }, { email: { contains: q, mode: 'insensitive' } }] },
                    take: 5,
                    select: { id: true, name: true, email: true, role: true }
                }),
                prisma.product.findMany({
                    where: { name: { contains: q, mode: 'insensitive' } },
                    take: 5,
                    select: { id: true, name: true, sellingPrice: true }
                })
            ]);

            successResponse(res, { merchants, users, products }, "Search results");
        } catch (error) {
            errorResponse(res, "Search failed", 500);
        }
    }
};

// [HELPER] Internal Audit Logger
const logAudit = async (tenantId, userId, action, entity, entityId, details) => {
    try {
        await prisma.auditLog.create({
            data: {
                tenantId: tenantId || 'SYSTEM',
                userId: userId,
                action: action,
                entity: entity,
                entityId: entityId,
                newValue: JSON.stringify(details)
            }
        });
    } catch (e) {
        console.error("Audit Log Error:", e);
    }
};

// Exporting logAudit for use in other controllers if needed (though mostly internal here)
module.exports.logAudit = logAudit;
