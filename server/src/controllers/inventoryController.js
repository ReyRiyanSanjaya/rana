const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const { emitToTenant } = require('../socket');

// Get Inventory Logs for a Product
const getInventoryLogs = async (req, res) => {
    try {
        const { productId } = req.params;
        const { tenantId } = req.user;

        // Verify Product Ownership
        const product = await prisma.product.findUnique({ where: { id: productId } });
        if (!product) return errorResponse(res, "Product not found", 404);
        if (product.tenantId !== tenantId) return errorResponse(res, "Unauthorized", 403);

        const logs = await prisma.inventoryLog.findMany({
            where: { productId },
            orderBy: { createdAt: 'desc' },
            take: 50 // Limit history
        });

        return successResponse(res, logs, "Inventory Logs");
    } catch (error) {
        return errorResponse(res, "Failed to fetch logs", 500, error);
    }
};

// Adjust Stock (Manual)
const adjustStock = async (req, res) => {
    try {
        const { productId, quantity, type, reason } = req.body;
        const { tenantId } = req.user;

        if (!productId || !quantity || !type) {
            return errorResponse(res, "Missing fields", 400);
        }

        // Verify Product Ownership
        const targetProduct = await prisma.product.findUnique({ where: { id: productId } });
        if (!targetProduct) return errorResponse(res, "Product not found", 404);
        if (targetProduct.tenantId !== tenantId) return errorResponse(res, "Unauthorized", 403);

        let storeId = req.user.storeId;
        if (!storeId) {
            const store = await prisma.store.findFirst({ where: { tenantId }, select: { id: true } });
            storeId = store?.id;
        }
        if (!storeId) return errorResponse(res, "No store found for tenant", 404);

        const qty = parseInt(quantity);
        let change = 0;

        if (type === 'IN') change = qty;
        else if (type === 'OUT') change = -qty;
        else if (type === 'ADJUSTMENT') change = qty; // Allow passing negative for adjustment

        const result = await prisma.$transaction(async (tx) => {
            const currentProduct = await tx.product.findFirst({
                where: { id: productId, tenantId },
                select: { stock: true }
            });
            const nextProductStock = Math.max(0, Number(currentProduct?.stock || 0) + change);

            const product = await tx.product.update({
                where: { id: productId },
                data: { stock: nextProductStock },
                select: { id: true, stock: true }
            });

            const existingStock = await tx.stock.findUnique({
                where: { storeId_productId: { storeId, productId } },
                select: { quantity: true }
            });
            const currentStoreQty = Number(existingStock?.quantity ?? currentProduct?.stock ?? 0);
            const nextStoreQty = Math.max(0, currentStoreQty + change);

            await tx.stock.upsert({
                where: { storeId_productId: { storeId, productId } },
                update: { quantity: nextStoreQty },
                create: { storeId, productId, quantity: nextStoreQty }
            });

            // 2. Create Log
            const log = await tx.inventoryLog.create({
                data: {
                    productId,
                    type,
                    quantity: change,
                    storeId,
                    reason: reason || 'Manual Adjustment'
                }
            });

            return { product, log, storeStock: nextStoreQty };
        });

        emitToTenant(tenantId, 'inventory:changed', { storeId, changes: [{ productId, stock: result.product.stock, storeStock: result.storeStock }] });
        return successResponse(res, result, "Stock Adjusted Successfully");

    } catch (error) {
        return errorResponse(res, "Adjustment Failed", 500, error);
    }
};

module.exports = {
    getInventoryLogs,
    adjustStock
};
