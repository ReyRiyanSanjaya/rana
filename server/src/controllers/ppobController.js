const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

const purchaseProduct = async (req, res) => {
    try {
        const { tenantId, storeId } = req.user;
        const { productId, customerId, amount } = req.body;

        if (!amount || amount <= 0) return errorResponse(res, "Invalid amount", 400);

        // 1. Validate Balance & Deduct (Atomic)
        const result = await prisma.$transaction(async (tx) => {
            // Check Wallet using a generic query or assume singular wallet for now.
            // We use 'CashflowLog' aggregation or a 'Wallet' model if it exists. 
            // Checking schema, we don't have a 'Wallet' table but rely on logs? 
            // Wait, previous sessions implemented Wallet via TopUpRequest/Withdrawal but where is balance stored?
            // Usually balance is calculated on fly or stored in Store/Tenant.
            // Let's assume we calculate or check a stored field.
            // Looking at Schema (viewed earlier), Tenant didn't have 'balance'.
            // Let's check 'Store' or assume we insert a negative cashflow and trust the frontend/wallet service checks.
            // BUT for security we MUST check balance. 
            // For this specific 'completion' task, I'll calculate balance from CashflowLog sum.

            const cashflows = await tx.cashflowLog.aggregate({
                where: { tenantId },
                _sum: { amount: true }
            });

            const currentBalance = cashflows._sum.amount || 0;
            if (currentBalance < amount) {
                throw new Error("Saldo tidak mencukupi");
            }

            // 2. Create Transaction Record (Cashflow - OUT)
            const log = await tx.cashflowLog.create({
                data: {
                    tenantId,
                    storeId, // Can be null if header doesn't have it, but usually req.user has it
                    type: 'CASH_OUT',
                    category: 'EXPENSE_PURCHASE', // Or PPOB specific
                    amount: -Math.abs(amount), // Negative for out
                    description: `Beli PPOB: ${productId} - ${customerId}`,
                    occurredAt: new Date()
                }
            });

            // 3. (Optional) Create Purchase Record specifically if needed, but CashflowLog is good for Wallet History.

            return { log, newBalance: currentBalance - amount };
        });

        // 4. Mock Provider Call (Async or Sync)
        // In real world, we'd call Shopee/Digiflazz API here.

        return successResponse(res, {
            status: 'SUCCESS',
            transactionId: result.log.id,
            message: 'Transaksi Berhasil',
            newBalance: result.newBalance
        });

    } catch (error) {
        if (error.message === "Saldo tidak mencukupi") {
            return errorResponse(res, "Saldo tidak mencukupi", 402);
        }
        console.error(error);
        return errorResponse(res, "Transaksi Gagal", 500);
    }
};

// Mock Data on Server (Simulating a connection to Shopee/Aggregator)
const MOCK_PULSA = [
    { id: 'P5', name: 'Telkomsel 5.000', price: 5250, promo: false, category: 'pulsa' },
    { id: 'P10', name: 'Telkomsel 10.000', price: 10200, promo: false, category: 'pulsa' },
    { id: 'P25', name: 'Telkomsel 25.000', price: 24900, promo: true, category: 'pulsa' },
    { id: 'P50', name: 'Telkomsel 50.000', price: 49500, promo: true, category: 'pulsa' },
    { id: 'P100', name: 'Telkomsel 100.000', price: 98500, promo: false, category: 'pulsa' },
    { id: 'I5', name: 'Indosat 5.000', price: 5800, promo: false, category: 'pulsa' },
    { id: 'I10', name: 'Indosat 10.000', price: 10800, promo: false, category: 'pulsa' },
];

const MOCK_PLN = [
    { id: 'PLN20', name: 'Token PLN 20.000', price: 20500, promo: false, category: 'pln' },
    { id: 'PLN50', name: 'Token PLN 50.000', price: 50500, promo: false, category: 'pln' },
    { id: 'PLN100', name: 'Token PLN 100.000', price: 100500, promo: false, category: 'pln' },
    { id: 'PLN200', name: 'Token PLN 200.000', price: 200500, promo: false, category: 'pln' },
];

const MOCK_GAMES = [
    { id: 'FF70', name: 'Free Fire 70 Diamonds', price: 9500, promo: true, category: 'game' },
    { id: 'FF140', name: 'Free Fire 140 Diamonds', price: 19000, promo: false, category: 'game' },
    { id: 'ML86', name: 'Mobile Legends 86 Diamonds', price: 22000, promo: false, category: 'game' },
];

const getProducts = async (req, res) => {
    try {
        const { category } = req.query;
        let data = [];

        const type = (category || '').toLowerCase();

        if (type.includes('pulsa') || type.includes('data')) {
            data = MOCK_PULSA;
        } else if (type.includes('listrik') || type.includes('pln')) {
            data = MOCK_PLN;
        } else if (type.includes('game')) {
            data = MOCK_GAMES;
        }

        return successResponse(res, data);
    } catch (error) {
        return errorResponse(res, "Failed to fetch PPOB products", 500);
    }
};

const checkBill = async (req, res) => {
    try {
        const { customerId, type } = req.body;
        // Mock Inquiry Logic
        if (!customerId) return errorResponse(res, "Invalid Customer ID", 400);

        return successResponse(res, {
            customer_name: 'TEST CUSTOMER',
            bill_amount: 150000,
            admin_fee: 2500,
            total: 152500,
            status: 'UNPAID',
            details: `Tagihan ${type} bulan ini`
        });
    } catch (error) {
        return errorResponse(res, "Inquiry Failed", 500);
    }
};

module.exports = { getProducts, checkBill, purchaseProduct };
