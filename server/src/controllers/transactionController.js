const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const AggregationService = require('../services/aggregationService');

/**
 * Handle incoming sync batches from offline clients
 */
const fs = require('fs');
const path = require('path');

const logSync = (msg) => {
    const logPath = path.join(__dirname, '../../sync_debug.log');
    const time = new Date().toISOString();
    fs.appendFileSync(logPath, `[${time}] ${msg}\n`);
};

const syncTransaction = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const transactionData = req.body;

        logSync(`Receiving Sync: ${JSON.stringify(transactionData)}`);

        // Validate structure
        if (!transactionData.offlineId || !transactionData.items) {
            logSync('Invalid Data');
            return errorResponse(res, "Invalid transaction data", 400);
        }

        // 1. Idempotency Check
        const existing = await prisma.transaction.findUnique({
            where: {
                tenantId_offlineId: {
                    tenantId,
                    offlineId: transactionData.offlineId
                }
            }
        });

        if (existing) {
            logSync(`Already Synced: ${existing.id}`);
            return successResponse(res, { id: existing.id, status: 'ALREADY_SYNCED' }, "Transaction already exists");
        }

        const productIds = transactionData.items.map(i => i.productId);
        // Verify products exist to prevent FK errors
        const validProducts = await prisma.product.findMany({
            where: { id: { in: productIds } },
            select: { id: true, sellingPrice: true, basePrice: true }
        });
        const validProductMap = new Map(validProducts.map(p => [p.id, p]));

        // Filter items to only valid products (or handle error)
        // For now, let's log if mismatch
        if (validProducts.length !== productIds.length) {
            const foundIds = validProducts.map(p => p.id);
            const missing = productIds.filter(id => !foundIds.includes(id));
            logSync(`Missing Products in DB: ${missing.join(', ')}`);
            // We can return error to client so they know to sync products first
            // OR we can skip these items (bad for integrity)
            // Let's FAIL to force downstream sync
            return errorResponse(res, "Product Mismatch - Please Update Products on Device", 400);
        }

        const prismaItems = transactionData.items.map(item => {
            const prod = validProductMap.get(item.productId);
            return {
                productId: item.productId,
                quantity: item.quantity,
                price: Number(item.price || prod?.sellingPrice || 0)
            };
        });

        const newTxn = await prisma.transaction.create({
            data: {
                tenantId,
                storeId: transactionData.storeId,
                cashierId: req.user.userId || transactionData.cashierId,
                offlineId: transactionData.offlineId,
                occurredAt: new Date(transactionData.occurredAt),
                orderStatus: 'COMPLETED',
                paymentStatus: 'PAID',
                paymentMethod: transactionData.paymentMethod || 'CASH',
                totalAmount: Number(transactionData.totalAmount),
                amountPaid: Number(transactionData.totalAmount),
                change: 0,
                transactionItems: {
                    create: prismaItems
                }
            }
        });

        logSync(`Success: ${newTxn.id}`);

        // Async aggregation
        const dateStr = transactionData.occurredAt.split('T')[0];
        AggregationService.processDailyAggregates(tenantId, transactionData.storeId, dateStr);

        return successResponse(res, { id: newTxn.id, status: 'SYNCED' }, "Sync successful");

    } catch (error) {
        logSync(`ERROR: ${error.message} \nStack: ${error.stack}`);
        console.error(error); // Keep console log
        return errorResponse(res, "Sync failed", 500, error);
    }
};

module.exports = {
    syncTransaction
};
