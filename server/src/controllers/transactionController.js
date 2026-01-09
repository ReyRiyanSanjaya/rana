const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const AggregationService = require('../services/aggregationService');
const { emitToTenant, emitToAdmin } = require('../socket');

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

        let storeId = transactionData.storeId || req.user.storeId;
        
        // [FIX] Validate storeId exists and belongs to tenant
        if (storeId) {
             const validStore = await prisma.store.findFirst({ 
                where: { id: storeId, tenantId },
                select: { id: true }
            });
            if (!validStore) storeId = null; // Invalid storeId provided
        }

        if (!storeId) {
            const store = await prisma.store.findFirst({ where: { tenantId }, select: { id: true } });
            storeId = store?.id;
        }
        if (!storeId) return errorResponse(res, "No store found for tenant", 404);

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
        // Verify products exist AND belong to the tenant to prevent FK errors or data leaks
        const validProducts = await prisma.product.findMany({
            where: {
                id: { in: productIds },
                tenantId: tenantId // [SECURITY] Compulsory filter
            },
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

        const qtyByProductId = new Map();
        for (const item of prismaItems) {
            const qty = Number(item.quantity || 0);
            if (!qtyByProductId.has(item.productId)) qtyByProductId.set(item.productId, 0);
            qtyByProductId.set(item.productId, qtyByProductId.get(item.productId) + qty);
        }

        const stockChanges = [];
        const newTxn = await prisma.$transaction(async (tx) => {
            const createdTxn = await tx.transaction.create({
                data: {
                    tenantId,
                    storeId,
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

            for (const [productId, qty] of qtyByProductId.entries()) {
                if (!qty) continue;

                const product = await tx.product.findFirst({
                    where: { id: productId, tenantId },
                    select: { id: true, stock: true }
                });
                if (!product) continue;

                const nextProductStock = Math.max(0, Number(product.stock || 0) - qty);
                await tx.product.update({
                    where: { id: product.id },
                    data: { stock: nextProductStock }
                });

                const existingStock = await tx.stock.findUnique({
                    where: { storeId_productId: { storeId, productId } },
                    select: { quantity: true }
                });
                const currentStoreQty = Number(existingStock?.quantity ?? product.stock ?? 0);
                const nextStoreQty = Math.max(0, currentStoreQty - qty);

                await tx.stock.upsert({
                    where: { storeId_productId: { storeId, productId } },
                    update: { quantity: nextStoreQty },
                    create: { storeId, productId, quantity: nextStoreQty }
                });

                await tx.inventoryLog.create({
                    data: {
                        productId,
                        storeId,
                        type: 'OUT',
                        quantity: -qty,
                        reason: 'Sale',
                        createdAt: new Date()
                    }
                });

                stockChanges.push({ productId, stock: nextProductStock, storeStock: nextStoreQty });
            }

            return createdTxn;
        });

        logSync(`Success: ${newTxn.id}`);

        // Async aggregation
        const dateStr = transactionData.occurredAt.split('T')[0];
        AggregationService.processDailyAggregates(tenantId, storeId, dateStr);

        emitToTenant(tenantId, 'transactions:created', { id: newTxn.id, storeId, occurredAt: transactionData.occurredAt });
        if (stockChanges.length) emitToTenant(tenantId, 'inventory:changed', { storeId, changes: stockChanges });

        return successResponse(res, { id: newTxn.id, status: 'SYNCED' }, "Sync successful");

    } catch (error) {
        // [FIX] Handle Race Condition (Unique Constraint)
        if (error.code === 'P2002') {
            const targets = error.meta?.target || [];
            if (Array.isArray(targets) && targets.includes('tenantId') && targets.includes('offlineId')) {
                 logSync(`Already Synced (Race Condition)`);
                 // Fetch the existing one to return success
                 // We need tenantId and offlineId here. 
                 // Assuming they are valid from req.
                 try {
                     const tenantId = req.user.tenantId;
                     const offlineId = req.body.offlineId;
                     const existing = await prisma.transaction.findUnique({
                        where: { tenantId_offlineId: { tenantId, offlineId } }
                     });
                     if (existing) {
                         return successResponse(res, { id: existing.id, status: 'ALREADY_SYNCED' }, "Transaction already exists");
                     }
                 } catch (innerError) {
                     // Fallback to error response if something else fails
                 }
            }
        }

        logSync(`ERROR: ${error.message} \nStack: ${error.stack}`);
        console.error(error); // Keep console log
        return errorResponse(res, "Sync failed", 500, error);
    }
};

const getTransactionHistory = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { limit = 100, startDate, endDate } = req.query;

        const where = { tenantId };
        if (startDate && endDate) {
            where.occurredAt = {
                gte: new Date(startDate),
                lte: new Date(endDate)
            };
        }

        const transactions = await prisma.transaction.findMany({
            where,
            include: {
                transactionItems: {
                    include: {
                        product: { select: { basePrice: true, name: true } }
                    }
                }
            },
            orderBy: { occurredAt: 'desc' },
            take: Number(limit)
        });

        const data = transactions.map(t => ({
            id: t.id,
            offlineId: t.offlineId,
            tenantId: t.tenantId,
            storeId: t.storeId,
            cashierId: t.cashierId,
            totalAmount: t.totalAmount,
            paymentMethod: t.paymentMethod,
            status: t.orderStatus, // Map orderStatus to status
            occurredAt: t.occurredAt,
            createdAt: t.createdAt,
            items: t.transactionItems.map(ti => ({
                productId: ti.productId,
                quantity: ti.quantity,
                price: ti.price,
                costPrice: ti.product?.basePrice ?? 0,
                name: ti.product?.name
            }))
        }));

        successResponse(res, data);
    } catch (error) {
        console.error("History Error:", error);
        errorResponse(res, "Failed to fetch history", 500, error);
    }
};

module.exports = {
    syncTransaction,
    getTransactionHistory
};
