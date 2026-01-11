const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt'); // [NEW]
const crypto = require('crypto');
const { successResponse, errorResponse } = require('../utils/response');
const { emitPublic } = require('../socket');
const https = require('https');
const Contact = require('../models/contact');

const normalizePhone = (value) => {
    let digits = (value || '').toString().replace(/[^\d]/g, '');
    if (!digits) return '';
    if (digits.startsWith('0')) digits = `62${digits.slice(1)}`;
    if (digits.startsWith('8')) digits = `62${digits}`;
    if (digits.startsWith('620')) digits = `62${digits.slice(3)}`;
    return digits;
};

const isLikelyPhoneNumber = (value) => {
    const digits = normalizePhone(value);
    if (!digits) return false;
    if (!digits.startsWith('62')) return false;
    if (digits.length < 10 || digits.length > 15) return false;
    return true;
};

const buildPhoneCandidates = (rawValue) => {
    const raw = (rawValue || '').toString().trim();
    const normalized = normalizePhone(raw);
    const candidates = new Set();
    if (raw) candidates.add(raw);
    if (normalized) {
        candidates.add(normalized);
        candidates.add(`+${normalized}`);
        if (normalized.startsWith('62')) candidates.add(`0${normalized.slice(2)}`);
    }
    return Array.from(candidates);
};

const getUrlText = (url, { timeoutMs = 5000, maxBytes = 64 * 1024, redirectsLeft = 5 } = {}) => {
    return new Promise((resolve, reject) => {
        const req = https.get(
            url,
            { headers: { 'user-agent': 'RanaPOS/1.0' } },
            (res) => {
                const statusCode = res.statusCode || 0;
                const location = res.headers.location;
                if ([301, 302, 303, 307, 308].includes(statusCode) && location && redirectsLeft > 0) {
                    res.resume();
                    const nextUrl = new URL(location, url).toString();
                    getUrlText(nextUrl, { timeoutMs, maxBytes, redirectsLeft: redirectsLeft - 1 })
                        .then(resolve)
                        .catch(reject);
                    return;
                }

                let size = 0;
                const chunks = [];

                res.on('data', (chunk) => {
                    size += chunk.length;
                    if (size > maxBytes) {
                        req.destroy(new Error('Response too large'));
                        return;
                    }
                    chunks.push(chunk);
                });

                res.on('end', () => {
                    resolve({
                        statusCode,
                        body: Buffer.concat(chunks).toString('utf8'),
                        finalUrl: url
                    });
                });
            }
        );

        req.on('error', reject);
        req.setTimeout(timeoutMs, () => req.destroy(new Error('Request timeout')));
    });
};

const verifyWhatsAppNumberWithoutOtp = async (value) => {
    const digits = normalizePhone(value);
    if (!digits) return false;
    try {
        const { statusCode, body } = await getUrlText(`https://wa.me/${digits}`, { timeoutMs: 5000 });
        if (!statusCode || statusCode >= 400) return false;
        const text = (body || '').toLowerCase();
        const invalidMarkers = [
            'phone number shared via url is invalid',
            'shared via url is invalid',
            'invalid phone number',
            'nomor telepon yang dibagikan'
        ];
        if (invalidMarkers.some((m) => text.includes(m))) return false;
        return true;
    } catch (_) {
        return false;
    }
};

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

        const feeValSetting = await prisma.systemSettings.findUnique({ where: { key: 'MERCHANT_SERVICE_FEE' } });
        const feeTypeSetting = await prisma.systemSettings.findUnique({ where: { key: 'MERCHANT_SERVICE_FEE_TYPE' } });
        const percentFallbackSetting = await prisma.systemSettings.findUnique({ where: { key: 'PLATFORM_FEE_PERCENTAGE' } });
        const minCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'MERCHANT_FEE_CAP_MIN' } });
        const maxCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'MERCHANT_FEE_CAP_MAX' } });
        const amount = Number(withdrawal.amount) || 0;
        const feeVal = feeValSetting ? parseFloat(feeValSetting.value) || 0 : 0;
        const feeType = feeTypeSetting ? String(feeTypeSetting.value) : undefined;
        let feeAmount = 0;
        if (feeType === 'PERCENT') {
            feeAmount = (amount * feeVal) / 100;
        } else if (feeType === 'FLAT') {
            feeAmount = feeVal;
        } else {
            const feePercent = percentFallbackSetting ? parseFloat(percentFallbackSetting.value) || 0 : 0;
            feeAmount = (amount * feePercent) / 100;
        }
        const minCap = minCapSetting ? parseFloat(minCapSetting.value) : undefined;
        const maxCap = maxCapSetting ? parseFloat(maxCapSetting.value) : undefined;
        if (minCap !== undefined && feeAmount < minCap) feeAmount = minCap;
        if (maxCap !== undefined && feeAmount > maxCap) feeAmount = maxCap;
        if (!Number.isFinite(feeAmount)) feeAmount = 0;
        const netAmount = amount - feeAmount;

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

const getReferralPrograms = async (req, res) => {
    try {
        const programs = await prisma.referralProgram.findMany({
            orderBy: { createdAt: 'desc' }
        });
        return successResponse(res, programs);
    } catch (error) {
        return errorResponse(res, "Failed to fetch referral programs", 500, error);
    }
};

const getReferrals = async (req, res) => {
    try {
        const { programId, referrerTenantId, refereeTenantId, status } = req.query;
        const where = {};
        if (programId) where.programId = programId;
        if (referrerTenantId) where.referrerTenantId = referrerTenantId;
        if (refereeTenantId) where.refereeTenantId = refereeTenantId;
        if (status) where.status = status;

        const referrals = await prisma.referral.findMany({
            where,
            include: {
                program: true,
                referrer: { select: { id: true, name: true } },
                referee: { select: { id: true, name: true } },
                rewards: true
            },
            orderBy: { createdAt: 'desc' }
        });

        const mapped = referrals.map((r) => ({
            id: r.id,
            createdAt: r.createdAt,
            status: r.status,
            program: {
                id: r.program.id,
                name: r.program.name,
                code: r.program.code
            },
            referrer: r.referrer ? { id: r.referrer.id, name: r.referrer.name } : null,
            referee: r.referee ? { id: r.referee.id, name: r.referee.name } : null,
            rewards: r.rewards.map((rw) => ({
                id: rw.id,
                level: rw.level,
                amount: rw.amount,
                currency: rw.currency,
                status: rw.status,
                releasedAt: rw.releasedAt
            }))
        }));

        return successResponse(res, mapped);
    } catch (error) {
        return errorResponse(res, "Failed to fetch referrals", 500, error);
    }
};

const getReferralRewards = async (req, res) => {
    try {
        const { status, beneficiaryTenantId, programId } = req.query;
        const where = {};
        if (status) where.status = status;
        if (beneficiaryTenantId) where.beneficiaryTenantId = beneficiaryTenantId;
        if (programId) {
            where.referral = { programId };
        }

        const rewards = await prisma.referralReward.findMany({
            where,
            include: {
                referral: {
                    include: {
                        program: true,
                        referrer: { select: { id: true, name: true } },
                        referee: { select: { id: true, name: true } }
                    }
                },
                beneficiaryTenant: { select: { id: true, name: true } }
            },
            orderBy: { createdAt: 'desc' }
        });

        const mapped = rewards.map((rw) => ({
            id: rw.id,
            createdAt: rw.createdAt,
            level: rw.level,
            amount: rw.amount,
            currency: rw.currency,
            status: rw.status,
            holdUntil: rw.holdUntil,
            releasedAt: rw.releasedAt,
            referral: {
                id: rw.referral.id,
                status: rw.referral.status,
                program: {
                    id: rw.referral.program.id,
                    name: rw.referral.program.name,
                    code: rw.referral.program.code
                },
                referrer: rw.referral.referrer
                    ? { id: rw.referral.referrer.id, name: rw.referral.referrer.name }
                    : null,
                referee: rw.referral.referee
                    ? { id: rw.referral.referee.id, name: rw.referral.referee.name }
                    : null
            },
            beneficiary: rw.beneficiaryTenant
                ? { id: rw.beneficiaryTenant.id, name: rw.beneficiaryTenant.name }
                : null
        }));

        return successResponse(res, mapped);
    } catch (error) {
        return errorResponse(res, "Failed to fetch referral rewards", 500, error);
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
            const packed = Buffer.concat([iv, tag, ciphertext]);
            return `enc:v1:${packed.toString('base64')}`;
        };

        const valueToStore = encryptIfNeeded(key, value);
        if (valueToStore === null) {
            // Value is being unset or is a placeholder, so we don't update
            const existing = await prisma.systemSettings.findUnique({ where: { key } });
            return successResponse(res, existing, "Setting unchanged");
        }

        const updatedSetting = await prisma.systemSettings.upsert({
            where: { key },
            update: { value: valueToStore, description },
            create: { key, value: valueToStore, description }
        });

        return successResponse(res, updatedSetting, "Setting updated");
    } catch (error) {
        return errorResponse(res, "Failed to update setting", 500, error);
    }
};

const getMessages = async (req, res) => {
  try {
    const messages = await Contact.find().sort({ createdAt: -1 });
    return successResponse(res, messages);
  } catch (error) {
    return errorResponse(res, 'Gagal mengambil pesan', 500, error);
  }
};

module.exports = {
  getWithdrawals,
  approveWithdrawal,
  getTopUps,
  approveTopUp,
  rejectTopUp,
  getAnnouncements,
  createAnnouncement,
  deleteAnnouncement,
  rejectWithdrawal,
  getSettings,
  updateSettings,
  getReferralPrograms,
  getReferrals,
  getReferralRewards,
  getMessages,
  // New placeholders
  getDashboardStats: async (req, res) => successResponse(res, {}, "Not implemented"),
  getBusinessAnalytics: async (req, res) => successResponse(res, {}, "Not implemented"),
  getPackages: async (req, res) => successResponse(res, [], "Not implemented"),
  createPackage: async (req, res) => successResponse(res, {}, "Not implemented"),
  updatePackage: async (req, res) => successResponse(res, {}, "Not implemented"),
  deletePackage: async (req, res) => successResponse(res, {}, "Not implemented"),
  getMerchants: async (req, res) => successResponse(res, [], "Not implemented"),
  createMerchant: async (req, res) => successResponse(res, {}, "Not implemented"),
  deleteMerchant: async (req, res) => successResponse(res, {}, "Not implemented"),
  updateMerchantSubscription: async (req, res) => successResponse(res, {}, "Not implemented"),
  updateMerchant: async (req, res) => successResponse(res, {}, "Not implemented"),
  getMerchantDetail: async (req, res) => successResponse(res, {}, "Not implemented"),
  adjustMerchantWallet: async (req, res) => successResponse(res, {}, "Not implemented"),
  sendNotification: async (req, res) => successResponse(res, {}, "Not implemented"),
  exportMerchants: async (req, res) => successResponse(res, {}, "Not implemented"),
  getMerchantProducts: async (req, res) => successResponse(res, [], "Not implemented"),
  createMerchantProduct: async (req, res) => successResponse(res, {}, "Not implemented"),
  updateMerchantProduct: async (req, res) => successResponse(res, {}, "Not implemented"),
  deleteMerchantProduct: async (req, res) => successResponse(res, {}, "Not implemented"),
  getSubscriptionRequests: async (req, res) => successResponse(res, [], "Not implemented"),
  approveSubscriptionRequest: async (req, res) => successResponse(res, {}, "Not implemented"),
  rejectSubscriptionRequest: async (req, res) => successResponse(res, {}, "Not implemented"),
  exportWithdrawals: async (req, res) => successResponse(res, {}, "Not implemented"),
  getAppMenus: async (req, res) => successResponse(res, [], "Not implemented"),
  createAppMenu: async (req, res) => successResponse(res, {}, "Not implemented"),
  updateAppMenu: async (req, res) => successResponse(res, {}, "Not implemented"),
  deleteAppMenu: async (req, res) => successResponse(res, {}, "Not implemented"),
  getAppMenuMaintenance: async (req, res) => successResponse(res, {}, "Not implemented"),
  updateAppMenuMaintenance: async (req, res) => successResponse(res, {}, "Not implemented"),
  resetUserPassword: async (req, res) => successResponse(res, {}, "Not implemented"),
  getAdminUsers: async (req, res) => successResponse(res, [], "Not implemented"),
  createAdminUser: async (req, res) => successResponse(res, {}, "Not implemented"),
  deleteAdminUser: async (req, res) => successResponse(res, {}, "Not implemented"),
  getPlatformSubscription: async (req, res) => successResponse(res, {}, "Not implemented"),
  exportDashboardData: async (req, res) => successResponse(res, {}, "Not implemented"),
  getAuditLogs: async (req, res) => successResponse(res, [], "Not implemented"),
  globalSearch: async (req, res) => successResponse(res, [], "Not implemented"),
  getAllTransactions: async (req, res) => successResponse(res, [], "Not implemented"),
  exportTransactions: async (req, res) => successResponse(res, {}, "Not implemented"),
  getFlashSales: async (req, res) => successResponse(res, [], "Not implemented"),
  updateFlashSaleStatus: async (req, res) => successResponse(res, {}, "Not implemented"),
};
