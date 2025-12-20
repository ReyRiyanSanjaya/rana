const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const crypto = require('crypto'); // [NEW]

// BUYER: Create Order
const createOrder = async (req, res) => {
    try {
        const { storeId, items, customerName, customerPhone, deliveryAddress, fulfillmentType } = req.body;
        // items: [{ productId, quantity, price }]

        if (!storeId || !items || items.length === 0) {
            return errorResponse(res, "Invalid Order Data", 400);
        }

        // Get Store to find TenantId
        const store = await prisma.store.findUnique({ where: { id: storeId } });
        if (!store) return errorResponse(res, "Store not found", 404);

        const totalAmount = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);

        // [NEW] Generate Pickup Code
        let pickupCode = null;
        if (fulfillmentType === 'PICKUP') {
            pickupCode = crypto.randomBytes(3).toString('hex').toUpperCase(); // 6 Chars
        }

        const result = await prisma.transaction.create({
            data: {
                id: `ORD-${Date.now()}`,
                tenantId: store.tenantId,
                storeId: storeId,
                totalAmount: totalAmount,
                paymentMethod: 'ONLINE_SIMULATION', // Mocking Online Payment
                amountPaid: totalAmount,
                change: 0,
                source: 'MARKET',
                orderStatus: 'PENDING',
                paymentStatus: 'UNPAID', // [UPDATED] Real Flow
                fulfillmentType: fulfillmentType || 'DELIVERY',
                pickupCode: pickupCode,
                customerName,
                customerPhone,
                deliveryAddress,
                occurredAt: new Date(),
                transactionItems: {
                    create: items.map(i => ({
                        productId: i.productId,
                        quantity: i.quantity,
                        price: i.price
                    }))
                }
            },
            include: { transactionItems: true }
        });

        return successResponse(res, result, "Order Placed - Waiting for Payment");
    } catch (error) {
        console.error(error);
        return errorResponse(res, "Order Failed", 500);
    }
};

// [NEW] Confirm Payment (Buyer Uploads Proof)
const confirmPayment = async (req, res) => {
    try {
        const { orderId, proofUrl } = req.body;

        // In a real app, 'proofUrl' would be the result of a file upload
        // Here we simulate it or accept a string

        const order = await prisma.transaction.update({
            where: { id: orderId },
            data: {
                paymentStatus: 'PAID', // Auto-verify for MVP, or set 'WAITING_VERIFICATION' if Admin Panel exists
                paymentProof: proofUrl || 'manual_confirm',
                paidAt: new Date()
            }
        });

        // Trigger Notification to Merchant here if needed

        return successResponse(res, order, "Payment Confirmed");
    } catch (error) {
        return errorResponse(res, "Confirmation Failed", 500, error);
    }
};

// BUYER: Get My History
const getOrdersByPhone = async (req, res) => {
    const { phone } = req.query;
    try {
        const orders = await prisma.transaction.findMany({
            where: { customerPhone: phone, source: 'MARKET' },
            include: { store: { select: { name: true } } },
            orderBy: { occurredAt: 'desc' }
        });
        return successResponse(res, orders);
    } catch (error) {
        return errorResponse(res, "Fetch Error", 500);
    }
};

module.exports = { createOrder, getOrdersByPhone, confirmPayment };
