const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// GET Payment Info (Public)
const getPaymentInfo = async (req, res) => {
    try {
        const qris = await prisma.systemSettings.findUnique({
            where: { key: 'PLATFORM_QRIS_URL' }
        });

        const bankSetting = await prisma.systemSettings.findUnique({
            where: { key: 'PLATFORM_BANK_INFO' }
        });

        let bankInfo = bankSetting?.value ? bankSetting.value.trim() : '';

        if (!bankInfo) {
            const bankSettings = await prisma.systemSettings.findMany({
                where: {
                    key: {
                        in: ['BANK_NAME', 'BANK_ACCOUNT_NUMBER', 'BANK_ACCOUNT_NAME']
                    }
                }
            });

            const bankMap = {};
            bankSettings.forEach((s) => {
                bankMap[s.key] = (s.value || '').trim();
            });

            const parts = [];
            if (bankMap.BANK_NAME) parts.push(bankMap.BANK_NAME);
            if (bankMap.BANK_ACCOUNT_NUMBER) parts.push(bankMap.BANK_ACCOUNT_NUMBER);
            if (bankMap.BANK_ACCOUNT_NAME) parts.push(`a.n ${bankMap.BANK_ACCOUNT_NAME}`);

            bankInfo = parts.join(' ').trim();
        }

        return successResponse(res, {
            qrisUrl: qris?.value || 'https://placehold.co/400x400/png?text=QRIS+Rana',
            bankInfo
        });
    } catch (error) {
        return errorResponse(res, "Failed to fetch payment info", 500);
    }
};

// UPDATE Payment Info (Admin)
const updatePaymentInfo = async (req, res) => {
    try {
        const { qrisUrl, bankInfo } = req.body;
        const { id: userId, tenantId } = req.user || {};
        const { logAudit } = require('./adminController');

        if (qrisUrl) {
            await prisma.systemSettings.upsert({
                where: { key: 'PLATFORM_QRIS_URL' },
                update: { value: qrisUrl },
                create: { key: 'PLATFORM_QRIS_URL', value: qrisUrl, description: 'Main QRIS' }
            });
            if (logAudit) {
                await logAudit(tenantId || 'SYSTEM', userId, 'UPDATE_SETTING', 'SystemSettings', 'PLATFORM_QRIS_URL', { value: qrisUrl });
            }
        }

        if (bankInfo) {
            await prisma.systemSettings.upsert({
                where: { key: 'PLATFORM_BANK_INFO' },
                update: { value: bankInfo },
                create: { key: 'PLATFORM_BANK_INFO', value: bankInfo, description: 'Bank Transfer Info' }
            });
            if (logAudit) {
                await logAudit(tenantId || 'SYSTEM', userId, 'UPDATE_SETTING', 'SystemSettings', 'PLATFORM_BANK_INFO', { value: bankInfo });
            }
        }

        return successResponse(res, null, "Payment Info Updated");
    } catch (error) {
        return errorResponse(res, "Update Failed", 500, error);
    }
};

// GET Fee Settings (Admin)
const getFeeSettings = async (req, res) => {
    try {
        const keys = ['BUYER_SERVICE_FEE', 'MERCHANT_SERVICE_FEE', 'WHOLESALE_SERVICE_FEE'];
        const settings = await prisma.systemSettings.findMany({
            where: { key: { in: keys } }
        });
        
        const feeMap = {
            buyerFee: '0',
            merchantFee: '0',
            wholesaleFee: '0'
        };

        settings.forEach(s => {
            if (s.key === 'BUYER_SERVICE_FEE') feeMap.buyerFee = s.value;
            if (s.key === 'MERCHANT_SERVICE_FEE') feeMap.merchantFee = s.value;
            if (s.key === 'WHOLESALE_SERVICE_FEE') feeMap.wholesaleFee = s.value;
        });

        return successResponse(res, feeMap);
    } catch (error) {
        return errorResponse(res, "Failed to fetch fee settings", 500, error);
    }
};

// UPDATE Fee Settings (Admin)
const updateFeeSettings = async (req, res) => {
    try {
        const { buyerFee, merchantFee, wholesaleFee } = req.body;
        const { id: userId, tenantId } = req.user || {};
        const { logAudit } = require('./adminController');

        const updates = [];
        if (buyerFee !== undefined) updates.push({ key: 'BUYER_SERVICE_FEE', value: String(buyerFee), description: 'Fee charged to Buyer' });
        if (merchantFee !== undefined) updates.push({ key: 'MERCHANT_SERVICE_FEE', value: String(merchantFee), description: 'Fee deducted from Merchant' });
        if (wholesaleFee !== undefined) updates.push({ key: 'WHOLESALE_SERVICE_FEE', value: String(wholesaleFee), description: 'Fee on Wholesale Orders' });

        for (const update of updates) {
            await prisma.systemSettings.upsert({
                where: { key: update.key },
                update: { value: update.value },
                create: update
            });
            if (logAudit) {
                await logAudit(tenantId || 'SYSTEM', userId, 'UPDATE_SETTING', 'SystemSettings', update.key, { value: update.value });
            }
        }

        return successResponse(res, null, "Fee Settings Updated");
    } catch (error) {
        return errorResponse(res, "Failed to update fee settings", 500, error);
    }
};

const getAppMenus = async (req, res) => {
    try {
        const menus = await prisma.appMenu.findMany({
            where: { isActive: true },
            orderBy: { order: 'asc' }
        });
        successResponse(res, menus);
    } catch (error) {
        errorResponse(res, "Failed to fetch app menus", 500);
    }
};

const getActiveAnnouncements = async (req, res) => {
    try {
        const announcements = await prisma.announcement.findMany({
            where: { 
                isActive: true,
                target: 'ALL' 
            },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, announcements);
    } catch (error) {
        errorResponse(res, "Failed to fetch announcements", 500);
    }
};

const getMyAnnouncements = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const tenant = await prisma.tenant.findUnique({ where: { id: tenantId } });
        
        if (!tenant) return successResponse(res, []);

        const announcements = await prisma.announcement.findMany({
            where: {
                isActive: true,
                OR: [
                    { target: 'ALL' },
                    { target: 'PLAN', targetValue: tenant.plan },
                    { target: 'STATUS', targetValue: tenant.subscriptionStatus }
                ]
            },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, announcements);
    } catch (error) {
        errorResponse(res, "Failed to fetch announcements", 500);
    }
};

const getNotifications = async (req, res) => {
    try {
        const { tenantId } = req.user; // Extracted from verifyToken middleware

        if (!tenantId) return successResponse(res, []);

        const notifications = await prisma.notification.findMany({
            where: { tenantId },
            orderBy: { createdAt: 'desc' },
            take: 20
        });
        successResponse(res, notifications);
    } catch (error) {
        errorResponse(res, "Failed to fetch notifications", 500);
    }
};

const markAllNotificationsRead = async (req, res) => {
    try {
        const { tenantId } = req.user;
        if (!tenantId) return successResponse(res, null, "No tenant");

        await prisma.notification.updateMany({
            where: { tenantId, isRead: false },
            data: { isRead: true }
        });

        successResponse(res, null, "Notifications marked as read");
    } catch (error) {
        errorResponse(res, "Failed to mark notifications as read", 500);
    }
};

const getPublicSettings = async (req, res) => {
    try {
        const settings = await prisma.systemSettings.findMany({
            where: {
                key: { startsWith: 'CMS_' }
            }
        });
        const settingsMap = {};
        settings.forEach(s => settingsMap[s.key] = s.value);
        successResponse(res, settingsMap);
    } catch (error) {
        errorResponse(res, "Failed to fetch public settings", 500);
    }
};

const getAppConfig = async (req, res) => {
    try {
        const settings = await prisma.systemSettings.findMany({
            where: {
                key: {
                    in: [
                        'BUYER_SERVICE_FEE',
                        'BUYER_SERVICE_FEE_TYPE',
                        'BUYER_FEE_CAP_MIN',
                        'BUYER_FEE_CAP_MAX',
                        'PLATFORM_BANK_INFO',
                        'BANK_NAME',
                        'BANK_ACCOUNT_NUMBER',
                        'BANK_ACCOUNT_NAME'
                    ]
                }
            }
        });
        
        const config = {
            buyerServiceFee: 0,
            buyerServiceFeeType: 'FLAT',
            buyerFeeCapMin: null,
            buyerFeeCapMax: null,
            bankInfo: {}
        };

        const bankMap = {};

        settings.forEach(s => {
            if (s.key === 'BUYER_SERVICE_FEE') config.buyerServiceFee = parseInt(s.value) || 0;
            if (s.key === 'BUYER_SERVICE_FEE_TYPE') config.buyerServiceFeeType = s.value || 'FLAT';
            if (s.key === 'BUYER_FEE_CAP_MIN') {
                const v = parseFloat(s.value);
                if (!Number.isNaN(v)) config.buyerFeeCapMin = v;
            }
            if (s.key === 'BUYER_FEE_CAP_MAX') {
                const v = parseFloat(s.value);
                if (!Number.isNaN(v)) config.buyerFeeCapMax = v;
            }
            if (['PLATFORM_BANK_INFO', 'BANK_NAME', 'BANK_ACCOUNT_NUMBER', 'BANK_ACCOUNT_NAME'].includes(s.key)) {
                bankMap[s.key] = s.value;
            }
        });

        // Construct Bank Info
        if (bankMap.PLATFORM_BANK_INFO) {
            config.bankInfo.text = bankMap.PLATFORM_BANK_INFO;
        } else {
             const parts = [];
            if (bankMap.BANK_NAME) parts.push(bankMap.BANK_NAME);
            if (bankMap.BANK_ACCOUNT_NUMBER) parts.push(bankMap.BANK_ACCOUNT_NUMBER);
            if (bankMap.BANK_ACCOUNT_NAME) parts.push(`a.n ${bankMap.BANK_ACCOUNT_NAME}`);
            config.bankInfo.text = parts.join(' ').trim();
        }

        successResponse(res, config);
    } catch (error) {
        errorResponse(res, "Failed to fetch app config", 500, error);
    }
};

const getAllAnnouncements = async (req, res) => {
    try {
        const announcements = await prisma.announcement.findMany({
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, announcements);
    } catch (error) {
        errorResponse(res, "Failed to fetch all announcements", 500);
    }
};

const createAnnouncement = async (req, res) => {
    try {
        const { title, content, isActive, target, targetValue } = req.body;
        const announcement = await prisma.announcement.create({
            data: {
                title,
                content,
                isActive: isActive ?? true,
                target: target || 'ALL',
                targetValue: targetValue || null
            }
        });
        successResponse(res, announcement, "Announcement Created");
    } catch (error) {
        errorResponse(res, "Failed to create announcement", 500, error);
    }
};

const updateAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, content, isActive, target, targetValue } = req.body;
        const announcement = await prisma.announcement.update({
            where: { id },
            data: { 
                title, 
                content, 
                isActive,
                target,
                targetValue
            }
        });
        successResponse(res, announcement, "Announcement Updated");
    } catch (error) {
        errorResponse(res, "Failed to update announcement", 500, error);
    }
};

const deleteAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.announcement.delete({ where: { id } });
        successResponse(res, null, "Announcement Deleted");
    } catch (error) {
        errorResponse(res, "Failed to delete announcement", 500, error);
    }
};

module.exports = {
    getPaymentInfo,
    updatePaymentInfo,
    getFeeSettings,
    updateFeeSettings,
    getActiveAnnouncements,
    getMyAnnouncements,
    getAllAnnouncements, // Admin
    createAnnouncement, // Admin
    updateAnnouncement, // Admin
    deleteAnnouncement, // Admin
    getAppMenus,
    getNotifications,
    markAllNotificationsRead,
    getPublicSettings,
    getAppConfig
};
