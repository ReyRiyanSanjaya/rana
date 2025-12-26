const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// GET Payment Info (Public)
const getPaymentInfo = async (req, res) => {
    try {
        const qris = await prisma.systemSettings.findUnique({
            where: { key: 'PLATFORM_QRIS_URL' }
        });

        const bank = await prisma.systemSettings.findUnique({
            where: { key: 'PLATFORM_BANK_INFO' }
        });

        return successResponse(res, {
            qrisUrl: qris?.value || 'https://placehold.co/400x400/png?text=QRIS+Rana',
            bankInfo: bank?.value || 'BCA 1234567890 a.n Rana Platform'
        });
    } catch (error) {
        return errorResponse(res, "Failed to fetch payment info", 500);
    }
};

// UPDATE Payment Info (Admin)
const updatePaymentInfo = async (req, res) => {
    try {
        const { qrisUrl, bankInfo } = req.body;

        if (qrisUrl) {
            await prisma.systemSettings.upsert({
                where: { key: 'PLATFORM_QRIS_URL' },
                update: { value: qrisUrl },
                create: { key: 'PLATFORM_QRIS_URL', value: qrisUrl, description: 'Main QRIS' }
            });
        }

        if (bankInfo) {
            await prisma.systemSettings.upsert({
                where: { key: 'PLATFORM_BANK_INFO' },
                update: { value: bankInfo },
                create: { key: 'PLATFORM_BANK_INFO', value: bankInfo, description: 'Bank Transfer Info' }
            });
        }

        return successResponse(res, null, "Payment Info Updated");
    } catch (error) {
        return errorResponse(res, "Update Failed", 500, error);
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
            where: { isActive: true },
            orderBy: { createdAt: 'desc' }
        });
        successResponse(res, announcements);
    } catch (error) {
        errorResponse(res, "Failed to fetch announcements", 500);
    }
};

// [NEW] Get Notifications (Public/System but requires Tenant Context via Header/Query?)
// Actually mobile app probably sends tenantId in header or we infer from context.
// For now let's assume query or header 'x-tenant-id'.
const getNotifications = async (req, res) => {
    try {
        const tenantId = req.headers['x-tenant-id'];
        if (!tenantId) return successResponse(res, []); // Silent fail if no context

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

module.exports = { getPaymentInfo, updatePaymentInfo, getActiveAnnouncements, getAppMenus, getNotifications, getPublicSettings };
