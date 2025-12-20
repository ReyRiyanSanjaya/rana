const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// MERCHANT: Get Incoming Orders
const getIncomingOrders = async (req, res) => {
    try {
        const { storeId } = req.user;
        const orders = await prisma.transaction.findMany({
            where: {
                storeId: storeId,
                source: 'MARKET',
                // orderStatus: { in: ['PENDING', 'ACCEPTED', 'READY'] }
            },
            include: { transactionItems: { include: { product: true } } },
            orderBy: { occurredAt: 'desc' }
        });
        return successResponse(res, orders);
    } catch (error) {
        return errorResponse(res, "Fetch Error", 500);
    }
};

// MERCHANT: Update Status
const updateOrderStatus = async (req, res) => {
    try {
        const { orderId, status } = req.body;
        const order = await prisma.transaction.update({
            where: { id: orderId },
            data: { orderStatus: status }
        });
        return successResponse(res, order, `Order ${status}`);
    } catch (error) {
        return errorResponse(res, "Update Error", 500);
    }
};

// [NEW] Scan QR & Complete Order
const scanQrOrder = async (req, res) => {
    try {
        const { storeId } = req.user;
        const { pickupCode } = req.body;

        const result = await prisma.$transaction(async (tx) => {
            // 1. Find Order
            const order = await tx.transaction.findFirst({
                where: { pickupCode: pickupCode, storeId: storeId }
            });

            if (!order) throw new Error("Order Not Found or Invalid Code");
            if (order.orderStatus === 'COMPLETED') throw new Error("Order Already Completed");
            // if (order.paymentStatus !== 'PAID') throw new Error("Order Not Paid");

            // 2. Mark Completed
            const updatedOrder = await tx.transaction.update({
                where: { id: order.id },
                data: { orderStatus: 'COMPLETED' }
            });

            // 3. Credit Balance
            await tx.store.update({
                where: { id: storeId },
                data: { balance: { increment: order.totalAmount } }
            });

            return updatedOrder;
        });

        return successResponse(res, result, "Order Verified & Balance Credited");

    } catch (error) {
        console.error("Scan Error", error);
        return errorResponse(res, error.message || "Scan Failed", 400);
    }
};

module.exports = { getIncomingOrders, updateOrderStatus, scanQrOrder };
