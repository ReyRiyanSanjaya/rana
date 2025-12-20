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

module.exports = { getPaymentInfo, updatePaymentInfo, getActiveAnnouncements };
