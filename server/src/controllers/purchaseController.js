const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

const createPurchase = async (req, res) => {
    try {
        const { tenantId, role } = req.user; // From JWT
        // In multi-store, we should get storeId from body or user context
        // For now defaulting to first store of tenant if not provided
        let { storeId, supplierName, items } = req.body;
        // items: [{ productId, quantity, costPrice }]

        if (!storeId) {
            const store = await prisma.store.findFirst({ where: { tenantId } });
            if (!store) return errorResponse(res, "No store found", 404);
            storeId = store.id;
        }

        // 1. Handle Supplier (Find or Create)
        let supplier;
        if (supplierName) {
            supplier = await prisma.supplier.findFirst({
                where: { tenantId, name: { equals: supplierName, mode: 'insensitive' } }
            });
            if (!supplier) {
                supplier = await prisma.supplier.create({
                    data: { tenantId, name: supplierName }
                });
            }
        }

        // 2. Calculate Total
        const totalAmount = items.reduce((sum, item) => sum + (item.costPrice * item.quantity), 0);

        // 3. Transaction: Record Purchase + Update Stock + Update Product Cost (Moving Average?)
        // For simplicity MVP: Update Product Cost to latest Purchase Price
        const result = await prisma.$transaction(async (tx) => {
            // A. Create Purchase Record
            const purchase = await tx.purchase.create({
                data: {
                    tenantId,
                    storeId,
                    supplierId: supplier?.id,
                    totalAmount,
                    items: {
                        create: items.map(i => ({
                            productId: i.productId,
                            quantity: i.quantity,
                            costPrice: i.costPrice
                        }))
                    }
                }
            });

            // B. Update Products (Stock & Cost)
            for (const item of items) {
                // Update Product Master Cost
                // Logic: Optional, some prefer weighted average. 
                // We will just update 'costPrice' to Reflect LATEST value for future sales margin calc.
                await tx.product.updateMany({
                    where: { id: item.productId, tenantId },
                    data: { costPrice: item.costPrice }
                });

                // Note: Stock Quantity in 'Product' table isn't tracked directly in my schema?
                // Wait, checking Schema... 
                // My schema has 'Stock' model separated or implicit?
                // Let's check Schema... 'stock Stock[]' in Store.

                // Upsert Stock Record
                const existingStock = await tx.stock.findFirst({
                    where: { storeId, productId: item.productId }
                });

                if (existingStock) {
                    await tx.stock.update({
                        where: { id: existingStock.id },
                        data: { quantity: { increment: item.quantity } }
                    });
                } else {
                    await tx.stock.create({
                        data: {
                            storeId,
                            productId: item.productId,
                            quantity: item.quantity,
                            lowStockThreshold: 5
                        }
                    });
                }
            }

            // C. Record Cashflow Log (Money Out)
            await tx.cashflowLog.create({
                data: {
                    tenantId,
                    storeId,
                    amount: totalAmount,
                    type: 'CASH_OUT',
                    category: 'EXPENSE_PURCHASE',
                    description: `Purchase from ${supplierName || 'Unknown'}`,
                    occurredAt: new Date()
                }
            });

            return purchase;
        });

        return successResponse(res, result, "Purchase Recorded");

    } catch (error) {
        console.error(error);
        return errorResponse(res, "Failed to record purchase", 500);
    }
};

module.exports = { createPurchase };
