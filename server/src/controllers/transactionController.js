const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const AggregationService = require('../services/aggregationService');

/**
 * Handle incoming sync batches from offline clients
 */
const syncTransaction = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const transactionData = req.body; // Expecting single transaction object or array? SyncManager sends 1 by 1 currently.

        // Validate structure
        if (!transactionData.offlineId || !transactionData.items) {
            return errorResponse(res, "Invalid transaction data", 400);
        }

        console.log(`[Sync] Receiving txn ${transactionData.offlineId}`);

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
            return successResponse(res, { id: existing.id, status: 'ALREADY_SYNCED' }, "Transaction already exists");
        }

        // 2. Insert Transaction
        // We need to map the raw JSON to Prisma create input
        // Note: 'items' in body might need mapping

        // Calculate Profit for this specific transaction (Simulated COGS lookup if not provided)
        // In a real app, we look up Product Cost from DB. 
        // For this MVP, assuming client sends snapshot or we accept 0 for now.
        // Let's look up product costs to be accurate?
        // Optimization: Fetch all products in this txn

        const productIds = transactionData.items.map(i => i.productId);
        const products = await prisma.product.findMany({
            where: { id: { in: productIds }, tenantId }
        });
        const productMap = new Map(products.map(p => [p.id, p]));

        let totalVals = { sub, tax, disc, total, profit } = { sub: 0, tax: 0, disc: 0, total: 0, profit: 0 };

        // Map items
        const prismaItems = transactionData.items.map(item => {
            const prod = productMap.get(item.productId);
            const cost = prod ? Number(prod.costPrice) : 0;
            const price = Number(item.price || prod?.sellingPrice || 0);

            return {
                productId: item.productId,
                quantity: item.qty,
                unitCost: cost,
                unitPrice: price,
                subtotal: price * item.qty
            };
        });

        // Create Txn
        const newTxn = await prisma.transaction.create({
            data: {
                tenantId,
                storeId: transactionData.storeId,
                cashierId: req.user.userId, // Or from body
                offlineId: transactionData.offlineId,
                occurredAt: new Date(transactionData.occurredAt),
                status: 'SYNCED',
                paymentMethod: 'CASH', // Default for now

                subtotal: transactionData.total, // Trust client or recalc
                tax: 0,
                discount: 0,
                total: transactionData.total,
                profit: 0, // Will be updated by AggregationService or calculated here?
                // AggregationService calculates Daily Summary.
                // We should set individual profit here too.

                items: {
                    create: prismaItems
                }
            }
        });

        // 3. Trigger Aggregation (Blocking or Async?)
        // For "Realtime-ish" feel, we await it.
        const dateStr = transactionData.occurredAt.split('T')[0];
        await AggregationService.processDailyAggregates(tenantId, transactionData.storeId, dateStr);

        return successResponse(res, { id: newTxn.id, status: 'SYNCED' }, "Sync successful");

    } catch (error) {
        return errorResponse(res, "Sync failed", 500, error);
    }
};

module.exports = {
    syncTransaction
};
