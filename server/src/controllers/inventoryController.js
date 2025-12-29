const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

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

        const qty = parseInt(quantity);
        let change = 0;

        if (type === 'IN') change = qty;
        else if (type === 'OUT') change = -qty;
        else if (type === 'ADJUSTMENT') change = qty; // Allow passing negative for adjustment

        const result = await prisma.$transaction(async (tx) => {
            const product = await tx.product.update({
                where: { id: productId },
                data: {
                    stock: { increment: change }
                }
            });

            // 2. Create Log
            const log = await tx.inventoryLog.create({
                data: {
                    productId,
                    type,
                    quantity: change,
                    reason: reason || 'Manual Adjustment'
                }
            });

            return { product, log };
        });

        return successResponse(res, result, "Stock Adjusted Successfully");

    } catch (error) {
        return errorResponse(res, "Adjustment Failed", 500, error);
    }
};

module.exports = {
    getInventoryLogs,
    adjustStock
};
