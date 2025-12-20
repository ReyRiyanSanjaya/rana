const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// Get Balance & Withdrawal History
const getWalletData = async (req, res) => {
    try {
        const { storeId } = req.user;

        const store = await prisma.store.findUnique({
            where: { id: storeId },
            select: { balance: true }
        });

        const withdrawals = await prisma.withdrawal.findMany({
            where: { storeId: storeId },
            orderBy: { createdAt: 'desc' }
        });

        return successResponse(res, { balance: store.balance, withdrawals });
    } catch (error) {
        return errorResponse(res, "Failed to fetch wallet data", 500, error);
    }
};

// Request Withdrawal
const requestWithdrawal = async (req, res) => {
    try {
        const { storeId } = req.user;
        const { amount, bankName, accountNumber } = req.body;

        const numericAmount = parseFloat(amount);

        const result = await prisma.$transaction(async (tx) => {
            // 1. Check Balance
            const store = await tx.store.findUnique({ where: { id: storeId } });
            if (store.balance < numericAmount) {
                throw new Error("Insufficient Balance");
            }

            // 2. Deduct Balance Immediately (Hold funds)
            await tx.store.update({
                where: { id: storeId },
                data: { balance: { decrement: numericAmount } }
            });

            // 3. Create Request
            const wd = await tx.withdrawal.create({
                data: {
                    storeId,
                    amount: numericAmount,
                    bankName,
                    accountNumber,
                    status: 'PENDING'
                }
            });

            return wd;
        });

        return successResponse(res, result, "Withdrawal Requested");

    } catch (error) {
        return errorResponse(res, error.message || "Withdrawal Failed", 400);
    }
};

module.exports = { getWalletData, requestWithdrawal };
