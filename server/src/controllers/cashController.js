const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const WhatsAppService = require('../services/whatsappService');

// --- Cash Management ---

const recordExpense = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { storeId, amount, category, description, date } = req.body;

        const expense = await prisma.cashflowLog.create({
            data: {
                tenantId,
                storeId,
                amount,
                type: 'CASH_OUT',
                category: category || 'EXPENSE_OPERATIONAL',
                description,
                occurredAt: new Date(date || new Date())
            }
        });

        return successResponse(res, expense, "Expense recorded");
    } catch (error) {
        return errorResponse(res, "Failed to record expense", 500, error);
    }
};

const recordDebt = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { storeId, borrowerName, amount, notes, date } = req.body;

        const debt = await prisma.debtRecord.create({
            data: {
                tenantId,
                storeId,
                borrowerName,
                amount,
                notes,
                status: 'UNPAID',
                createdAt: new Date(date || new Date())
            }
        });

        return successResponse(res, debt, "Debt recorded");
    } catch (error) {
        return errorResponse(res, "Failed to record debt", 500, error);
    }
};

// --- WhatsApp Triggers ---

const triggerDailyReport = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { storeId, date } = req.body; // YYYY-MM-DD

        // 1. Get Store Settings for WA Number
        const store = await prisma.store.findUnique({
            where: { id: storeId }
        });

        if (!store || !store.waNumber) {
            return errorResponse(res, "Store WA number not configured", 400);
        }

        // 2. Generate Report
        const text = await WhatsAppService.generateDailyReport(tenantId, storeId, date);

        // 3. Send
        await WhatsAppService.sendWhatsApp(store.waNumber, text);

        return successResponse(res, { sent: true, text }, "Report sent to WA");

    } catch (error) {
        return errorResponse(res, "Failed to send WA report", 500, error);
    }
};

module.exports = {
    recordExpense,
    recordDebt,
    triggerDailyReport
};
