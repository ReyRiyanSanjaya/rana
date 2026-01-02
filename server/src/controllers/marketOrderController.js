const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const crypto = require('crypto');
const { emitToTenant } = require('../socket');

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

        // Apply Flash Sale Pricing if applicable
        const now = new Date();
        const activeSales = await prisma.flashSale.findMany({
            where: {
                storeId,
                status: { in: ['APPROVED', 'ACTIVE'] },
                startAt: { lte: now },
                endAt: { gte: now }
            },
            include: { items: true }
        });
        const saleMap = new Map();
        for (const sale of activeSales) {
            for (const si of sale.items) {
                saleMap.set(si.productId, { price: si.salePrice, maxQtyPerOrder: si.maxQtyPerOrder || 0 });
            }
        }
        // Recalculate item prices with flash sale
        let recomputedItems = [];
        for (const i of items) {
            const sale = saleMap.get(i.productId);
            if (sale) {
                if (sale.maxQtyPerOrder > 0 && i.quantity > sale.maxQtyPerOrder) {
                    return errorResponse(res, "Quantity exceeds flash sale limit", 400);
                }
                recomputedItems.push({ ...i, price: sale.price });
            } else {
                recomputedItems.push(i);
            }
        }

        // Get Fee Settings
        const subtotal = recomputedItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
        const feeSetting = await prisma.systemSettings.findUnique({ where: { key: 'BUYER_SERVICE_FEE' } });
        const feeTypeSetting = await prisma.systemSettings.findUnique({ where: { key: 'BUYER_SERVICE_FEE_TYPE' } });
        const minCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'BUYER_FEE_CAP_MIN' } });
        const maxCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'BUYER_FEE_CAP_MAX' } });
        const feeVal = feeSetting ? parseFloat(feeSetting.value) : 0;
        const feeType = feeTypeSetting ? String(feeTypeSetting.value) : 'FLAT';
        let buyerFee = 0;
        if (feeType === 'PERCENT') {
            buyerFee = (subtotal * feeVal) / 100;
        } else {
            buyerFee = feeVal;
        }
        const minCap = minCapSetting ? parseFloat(minCapSetting.value) : undefined;
        const maxCap = maxCapSetting ? parseFloat(maxCapSetting.value) : undefined;
        if (minCap !== undefined && buyerFee < minCap) buyerFee = minCap;
        if (maxCap !== undefined && buyerFee > maxCap) buyerFee = maxCap;
        const totalAmount = subtotal + buyerFee;

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
                buyerFee: buyerFee, // [NEW]
                platformFee: buyerFee, // [NEW] Initially just buyer fee, merchant fee deducted later
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
                    create: recomputedItems.map(i => ({
                        productId: i.productId,
                        quantity: i.quantity,
                        price: i.price
                    }))
                }
            },
            include: { transactionItems: true }
        });

        try {
            emitToTenant(store.tenantId, 'orders:updated', result);
        } catch (e) {
            console.error('Socket emit failed', e);
        }

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

        if (order.platformFee && order.platformFee > 0) {
            await prisma.platformRevenue.create({
                data: {
                    amount: order.platformFee,
                    source: 'OTHER',
                    description: `Transaction Fee (Buyer) - ${order.id}`,
                    referenceId: order.id
                }
            });
        }

        try {
            emitToTenant(order.tenantId, 'orders:updated', order);
        } catch (e) {
            console.error('Socket emit failed', e);
        }

        try {
            await prisma.notification.create({
                data: {
                    tenantId: order.tenantId,
                    title: 'Pembayaran pesanan marketplace dikonfirmasi',
                    body: `Order ${order.id} telah dibayar oleh pelanggan`
                }
            });
        } catch (e) {
            console.error('Create notification failed', e);
        }

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
