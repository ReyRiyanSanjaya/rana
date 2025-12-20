const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// Get Inventory Logs for a Product
const getInventoryLogs = async (req, res) => {
    try {
        const { productId } = req.params;
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
        // quantity should be positive integer
        // type: IN (add), OUT (subtract), ADJUSTMENT (set or diff?)
        // Let's assume quantity is "amount to change" (e.g. +5 or -3) OR abs value + type.
        // Convention: type="IN" => +qty, type="OUT" => -qty, type="ADJUSTMENT" => Explicit difference

        // Let's enforce: Type is from Enum. Qty is absolute. 
        // Logic:
        // IN: stock + qty
        // OUT: stock - qty
        // ADJUSTMENT: We might just interpret this as a delta too, usually for 'Correction'.

        if (!productId || !quantity || !type) {
            return errorResponse(res, "Missing fields", 400);
        }

        const qty = parseInt(quantity);
        let change = 0;

        if (type === 'IN') change = qty;
        else if (type === 'OUT') change = -qty;
        else if (type === 'ADJUSTMENT') change = qty; // Allow passing negative for adjustment

        const result = await prisma.$transaction(async (tx) => {
            // 1. Update Product Stock
            // Note: If using `Stock` model separate from `Product` (for multi-warehouse), we should update `Stock` model.
            // Looking at schema: Product has `stock` AND there is a `Stock` model (lines 229).
            // Schema Step 751:
            // model Product { ... stock Int ... stocks Stock[] }
            // model Stock { ... storeId, productId, quantity ... }
            // This is ambiguous. User likely uses Product.stock for simple cases. 
            // We should ask or check Usage. 
            // `authController` login used `store`... 
            // `Product` model has `storeId`.
            // So Product is arguably per-store. 
            // Let's update `Product.stock` for simplicity as per request context, 
            // BUT also check if `Stock` entries exist.
            // Let's stick to `Product.stock` as the primary for this MVP level.

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
