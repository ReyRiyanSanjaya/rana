const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const fs = require('fs');
const path = require('path');
const { successResponse, errorResponse } = require('../utils/response');

// Helper: Save Base64 Image
const saveProofImage = (base64String, storeId) => {
    try {
        if (!base64String) return null;

        const matches = base64String.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
        if (!matches || matches.length !== 3) {
            return null;
        }

        const buffer = Buffer.from(matches[2], 'base64');
        const fileName = `proof_${storeId}_${Date.now()}.jpg`;
        const uploadDir = path.join(__dirname, '../../uploads/proofs'); // Ensure this dir exists

        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        fs.writeFileSync(path.join(uploadDir, fileName), buffer);
        return `/uploads/proofs/${fileName}`; // Return relative path for URL
    } catch (e) {
        console.error("Save Image Error:", e);
        return null;
    }
};

// Get Balance & History
const getWalletData = async (req, res) => {
    try {
        let { storeId, tenantId } = req.user;
        if (!storeId && tenantId) {
            const s = await prisma.store.findFirst({ where: { tenantId } });
            if (s) storeId = s.id;
        }
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const store = await prisma.store.findUnique({
            where: { id: storeId },
            select: { balance: true }
        });

        // Fetch Logs instead of just Withdrawals for comprehensive history
        const history = await prisma.cashflowLog.findMany({
            where: { storeId: storeId },
            orderBy: { occurredAt: 'desc' },
            take: 20
        });

        // Also fetch pending withdrawals/topups if needed? 
        // For now, let's mix them or just return what we have.
        // Let's stick to CashflowLog as the "Ledger".
        // But Pending items are NOT in ledger yet.

        const pendingWithdrawals = await prisma.withdrawal.findMany({
            where: { storeId: storeId, status: 'PENDING' }
        });

        const pendingTopUps = await prisma.topUpRequest.findMany({ // [NEW]
            where: { storeId: storeId, status: 'PENDING' }
        });

        return successResponse(res, {
            balance: store.balance,
            history,
            pendingWithdrawals,
            pendingTopUps
        });
    } catch (error) {
        return errorResponse(res, "Failed to fetch wallet data", 500, error);
    }
};

// Request Withdrawal
const requestWithdrawal = async (req, res) => {
    try {
        let { storeId, tenantId } = req.user;
        if (!storeId && tenantId) {
            const s = await prisma.store.findFirst({ where: { tenantId } });
            if (s) storeId = s.id;
        }
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const { amount, bankName, accountNumber } = req.body;
        const numericAmount = parseFloat(amount);

        if (isNaN(numericAmount) || numericAmount <= 0) throw new Error("Invalid amount");

        // Transaction
        await prisma.$transaction(async (tx) => {
            const store = await tx.store.findUnique({ where: { id: storeId } });
            if (store.balance < numericAmount) throw new Error("Insufficient Balance");

            // Deduct (Hold)
            await tx.store.update({
                where: { id: storeId },
                data: { balance: { decrement: numericAmount } }
            });

            // Log
            await tx.cashflowLog.create({
                data: {
                    tenantId: req.user.tenantId,
                    storeId,
                    amount: numericAmount,
                    type: 'CASH_OUT',
                    category: 'WITHDRAWAL',
                    description: `Withdrawal to ${bankName} - ${accountNumber}`,
                    occurredAt: new Date()
                }
            });

            // Create Request
            await tx.withdrawal.create({
                data: {
                    storeId,
                    amount: numericAmount,
                    bankName,
                    accountNumber,
                    status: 'PENDING'
                }
            });
        });

        return successResponse(res, null, "Withdrawal Requested");
    } catch (error) {
        return errorResponse(res, error.message || "Withdrawal Failed", 400);
    }
};

// Top Up Request
const topUp = async (req, res) => {
    try {
        let { storeId, tenantId } = req.user;
        if (!storeId && tenantId) {
            const s = await prisma.store.findFirst({ where: { tenantId } });
            if (s) storeId = s.id;
        }
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const { amount, proofImage } = req.body;
        const numericAmount = parseFloat(amount);

        if (isNaN(numericAmount) || numericAmount <= 0) throw new Error("Invalid amount");
        if (!proofImage) throw new Error("Proof of transfer is required");

        const proofPath = saveProofImage(proofImage, storeId);
        if (!proofPath) throw new Error("Failed to save proof image");

        const request = await prisma.topUpRequest.create({
            data: {
                storeId,
                amount: numericAmount,
                proofUrl: proofPath,
                status: 'PENDING'
            }
        });

        // Note: We DO NOT add balance yet. Admin must approve.

        return successResponse(res, request, "Top Up Requested. Please wait for approval.");
    } catch (error) {
        return errorResponse(res, error.message || "Top Up Failed", 400);
    }
};

// Transfer to another Store
const transfer = async (req, res) => {
    try {
        let { storeId, tenantId } = req.user;
        if (!storeId && tenantId) {
            const s = await prisma.store.findFirst({ where: { tenantId } });
            if (s) storeId = s.id;
        }
        if (!storeId) return errorResponse(res, "Store not found", 404);
        const { targetStoreId, amount, note } = req.body;
        const numericAmount = parseFloat(amount);

        if (isNaN(numericAmount) || numericAmount <= 0) throw new Error("Invalid amount");
        if (storeId === targetStoreId) throw new Error("Cannot transfer to self");

        await prisma.$transaction(async (tx) => {
            // 1. Check Sender Balance
            const sender = await tx.store.findUnique({ where: { id: storeId } });
            if (sender.balance < numericAmount) throw new Error("Insufficient Balance");

            // 2. Check Receiver Exists
            const receiver = await tx.store.findUnique({ where: { id: targetStoreId } });
            if (!receiver) throw new Error("Target store not found");

            // 3. Move Funds
            await tx.store.update({ where: { id: storeId }, data: { balance: { decrement: numericAmount } } });
            await tx.store.update({ where: { id: targetStoreId }, data: { balance: { increment: numericAmount } } });

            // 4. Create Transfer Record
            await tx.walletTransfer.create({
                data: {
                    senderStoreId: storeId,
                    receiverStoreId: targetStoreId,
                    amount: numericAmount,
                    note
                }
            });

            // 5. Logs for Sender
            await tx.cashflowLog.create({
                data: {
                    tenantId,
                    storeId,
                    amount: numericAmount,
                    type: 'CASH_OUT',
                    category: 'TRANSFER',
                    description: `Transfer to ${receiver.name} (${note || ''})`,
                    occurredAt: new Date()
                }
            });

            // 6. Logs for Receiver (Receiver might have different Tenant, handle that?)
            // Assuming same system, we can write to their log.
            await tx.cashflowLog.create({
                data: {
                    tenantId: receiver.tenantId, // Use Receiver's Tenant
                    storeId: targetStoreId,
                    amount: numericAmount,
                    type: 'CASH_IN',
                    category: 'TRANSFER',
                    description: `Transfer from ${sender.name} (${note || ''})`,
                    occurredAt: new Date()
                }
            });
        });

        return successResponse(res, null, "Transfer Successful");

    } catch (error) {
        return errorResponse(res, error.message || "Transfer Failed", 400);
    }
};

// Generic Payment (PPOB, Bills, etc)
const payTransaction = async (req, res) => {
    try {
        let { storeId, tenantId } = req.user;
        if (!storeId && tenantId) {
            const s = await prisma.store.findFirst({ where: { tenantId } });
            if (s) storeId = s.id;
        }
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const { amount, description, category } = req.body;
        const numericAmount = parseFloat(amount);

        if (isNaN(numericAmount) || numericAmount <= 0) throw new Error("Invalid amount");

        await prisma.$transaction(async (tx) => {
            const store = await tx.store.findUnique({ where: { id: storeId } });
            if (store.balance < numericAmount) throw new Error("Insufficient Balance");

            // Deduct
            await tx.store.update({
                where: { id: storeId },
                data: { balance: { decrement: numericAmount } }
            });

            // Map generic/client categories to Prisma Enum
            let dbCategory = 'OTHER';
            const catUpper = (category || 'PURCHASE').toUpperCase();

            if (catUpper === 'PPOB' || catUpper === 'PURCHASE') {
                dbCategory = 'EXPENSE_PURCHASE';
            } else if (['SALES', 'EXPENSE_OPERATIONAL', 'EXPENSE_PETTY', 'DEBT_PAYMENT', 'RECEIVABLE_PAYMENT', 'CAPITAL_IN', 'TOPUP', 'TRANSFER', 'WITHDRAWAL'].includes(catUpper)) {
                dbCategory = catUpper;
            }

            // Log
            await tx.cashflowLog.create({
                data: {
                    tenantId,
                    storeId,
                    amount: numericAmount,
                    type: 'CASH_OUT',
                    category: dbCategory,
                    description: description || 'Payment',
                    occurredAt: new Date()
                }
            });
        });

        return successResponse(res, null, "Transaction Successful");
    } catch (error) {
        return errorResponse(res, error.message || "Transaction Failed", 400);
    }
};

module.exports = { getWalletData, requestWithdrawal, topUp, transfer, payTransaction };
