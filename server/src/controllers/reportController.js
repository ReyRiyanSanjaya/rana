const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

/**
 * Get Dashboard Summary
 * /reports/dashboard?storeId=...&date=...
 */
const getDashboardStats = async (req, res) => {
    try {
        const { tenantId } = req.user; // From Auth Middleware
        const { storeId, date } = req.query; // YYYY-MM-DD

        if (!date) return errorResponse(res, "Date is required", 400);

        const startOfDay = new Date(`${date}T00:00:00.000Z`);

        // Fetch Daily Summary
        let summary;

        if (storeId) {
            // Specific Store
            summary = await prisma.dailySalesSummary.findFirst({
                where: {
                    tenantId,
                    storeId,
                    date: startOfDay
                }
            });
        } else {
            // Global (All Stores) - Aggregate
            const agg = await prisma.dailySalesSummary.aggregate({
                where: {
                    tenantId,
                    date: startOfDay
                },
                _sum: {
                    totalSales: true,
                    totalTrans: true
                }
            });

            // Map aggregation result to match expected summary object structure
            if (agg._sum.totalSales !== null) {
                summary = {
                    totalSales: agg._sum.totalSales,
                    totalTrans: agg._sum.totalTrans,
                    // Add other fields if schema has them and they were summed
                };
            }
        }

        // Also get Top 5 Products for widget
        // [FIX] Ensure we filter by storeId if provided, otherwise global
        const topProductWhere = {
            tenantId,
            date: startOfDay
        };
        // Note: productSalesSummary currently does not seem to support storeId based on aggregationService.
        // If it did, we would add: if (storeId) topProductWhere.storeId = storeId;

        const topSummaries = await prisma.productSalesSummary.findMany({
            where: topProductWhere,
            orderBy: {
                totalRevenue: 'desc'
            },
            take: 5
        });

        // Manually fetch product details since relation is missing in schema
        const productIds = topSummaries.map(s => s.productId);
        const products = await prisma.product.findMany({
            where: { id: { in: productIds } },
            select: { id: true, name: true, sku: true }
        });

        const productMap = new Map(products.map(p => [p.id, p]));

        const topProducts = topSummaries.map(s => ({
            ...s,
            product: productMap.get(s.productId) || { name: 'Unknown', sku: '-' }
        }));

        // Fallback: jika daily summary tidak ada, agregasi langsung transaksi untuk hari tersebut
        if (!summary) {
            const txnAgg = await prisma.transaction.aggregate({
                where: {
                    tenantId,
                    orderStatus: 'COMPLETED',
                    storeId: storeId || undefined,
                    occurredAt: {
                        gte: startOfDay,
                        lte: new Date(`${date}T23:59:59.999Z`)
                    }
                },
                _sum: { totalAmount: true },
                _count: { _all: true }
            });
            summary = {
                totalSales: Number(txnAgg._sum.totalAmount) || 0,
                totalTrans: Number(txnAgg._count._all) || 0
            };
        }

        return successResponse(res, {
            financials: summary || {
                totalSales: 0, totalTrans: 0 // Match the keys we actually use (totalSales found in aggregation)
            },
            topProducts
        });

    } catch (error) {
        return errorResponse(res, "Failed to fetch dashboard stats", 500, error);
    }
};

/**
 * Get Profit & Loss Report
 * /reports/profit-loss?startDate=...&endDate=...
 */
const getProfitLoss = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { startDate, endDate, storeId } = req.query;

        if (!startDate || !endDate) {
            return errorResponse(res, "startDate dan endDate wajib diisi", 400);
        }

        const start = new Date(`${startDate}T00:00:00.000Z`);
        const end = new Date(`${endDate}T23:59:59.999Z`);

        // Aggregate the Aggregates: Summing up DailySalesSummaries
        const aggs = await prisma.dailySalesSummary.groupBy({
            by: ['tenantId'],
            where: {
                tenantId,
                storeId: storeId || undefined,
                date: {
                    gte: start,
                    lte: end
                }
            },
            _sum: {
                totalSales: true,
                totalTrans: true
            }
        });

        // Fetch Expenses (CashflowLog)
        const expenses = await prisma.cashflowLog.groupBy({
            by: ['category'],
            where: {
                tenantId,
                storeId: storeId || undefined,
                type: 'CASH_OUT',
                category: {
                    in: ['EXPENSE_OPERATIONAL', 'EXPENSE_PURCHASE', 'EXPENSE_PETTY', 'OTHER']
                },
                occurredAt: {
                    gte: start,
                    lte: end
                }
            },
            _sum: {
                amount: true
            }
        });

        const totals = aggs[0]?._sum || {};

        // Process Expenses
        const expenseMap = {};
        let totalExpenses = 0;
        expenses.forEach(e => {
            const amt = Number(e._sum.amount);
            expenseMap[e.category] = amt;
            totalExpenses += amt;
        });

        // Fallback: jika DailySalesSummary kosong, agregasi langsung dari transaksi
        let revenue = totals.totalSales || 0;
        let transCount = totals.totalTrans || 0;
        if (!revenue && !transCount) {
            const txnAgg = await prisma.transaction.aggregate({
                where: {
                    tenantId,
                    orderStatus: 'COMPLETED',
                    storeId: storeId || undefined,
                    occurredAt: {
                        gte: start,
                        lte: end
                    }
                },
                _sum: { totalAmount: true },
                _count: { _all: true }
            });
            revenue = Number(txnAgg._sum.totalAmount) || 0;
            transCount = Number(txnAgg._count._all) || 0;
        }

        const cogs = 0; // Not available in DailySalesSummary
        const grossProfit = revenue - cogs;
        const netProfit = grossProfit - totalExpenses;

        return successResponse(res, {
            period: { start, end },
            pnl: {
                revenue,
                cogs,
                grossProfit,
                margin: revenue > 0 ? ((grossProfit / revenue) * 100).toFixed(2) : 0,
                taxCollected: 0,
                discountsGiven: 0,
                totalExpenses,
                netProfit,
                expenseBreakdown: expenseMap
            }
        });

    } catch (error) {
        return errorResponse(res, "Failed to fetch P&L", 500, error);
    }
};

/**
 * Get Inventory Intelligence (Slow Moving / Stock Aging)
 * /reports/inventory-aging
 */
const getInventoryIntelligence = async (req, res) => {
    // This would query the Stock table and potential LastSold dates
    // For MVP, simply return low stock items
    try {
        const { tenantId } = req.user;

        const lowStock = await prisma.product.findMany({
            where: {
                tenantId,
                trackStock: true,
                stocks: {
                    some: {
                        quantity: { lte: 5 } // Threshold
                    }
                }
            },
            include: {
                stocks: true
            },
            take: 20
        });

        return successResponse(res, {
            alerts: {
                lowStockCount: lowStock.length,
                items: lowStock
            }
        });

    } catch (error) {
        return errorResponse(res, "Failed inventory report", 500, error);
    }
}

const getAnalytics = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { startDate, endDate, storeId } = req.query;
        if (!startDate || !endDate) {
            return errorResponse(res, "startDate dan endDate wajib diisi", 400);
        }
        const start = new Date(`${startDate}T00:00:00.000Z`);
        const end = new Date(`${endDate}T23:59:59.999Z`);

        const transactions = await prisma.transaction.findMany({
            where: {
                tenantId,
                orderStatus: 'COMPLETED',
                storeId: storeId || undefined,
                occurredAt: { gte: start, lte: end }
            },
            include: {
                transactionItems: {
                    include: {
                        product: {
                            select: { id: true, name: true, sku: true, category: { select: { name: true } } }
                        }
                    }
                }
            },
            orderBy: { occurredAt: 'asc' }
        });

        let revenue = 0;
        const totalTransactions = transactions.length;
        const trendMap = new Map();
        const paymentMap = {};

        const productStats = new Map();
        const categoryMap = {};

        for (const t of transactions) {
            revenue += Number(t.totalAmount) || 0;
            const d = new Date(t.occurredAt);
            d.setHours(0, 0, 0, 0);
            const key = d.toISOString().split('T')[0];
            trendMap.set(key, (trendMap.get(key) || 0) + (Number(t.totalAmount) || 0));
            const pm = t.paymentMethod || 'UNKNOWN';
            paymentMap[pm] = (paymentMap[pm] || 0) + (Number(t.totalAmount) || 0);
            for (const it of t.transactionItems) {
                const pid = it.productId;
                const prev = productStats.get(pid) || { revenue: 0, quantity: 0, product: it.product };
                prev.revenue += Number(it.price) * it.quantity;
                prev.quantity += it.quantity;
                productStats.set(pid, prev);
                const catName = it.product?.category?.name || 'Unknown';
                categoryMap[catName] = (categoryMap[catName] || 0) + (Number(it.price) * it.quantity);
            }
        }

        const expenses = await prisma.cashflowLog.groupBy({
            by: ['category'],
            where: {
                tenantId,
                storeId: storeId || undefined,
                type: 'CASH_OUT',
                occurredAt: { gte: start, lte: end }
            },
            _sum: { amount: true }
        });
        const expenseBreakdown = {};
        let totalExpenses = 0;
        for (const e of expenses) {
            const amt = Number(e._sum.amount) || 0;
            expenseBreakdown[e.category] = amt;
            totalExpenses += amt;
        }

        const expenseTrendLogs = await prisma.cashflowLog.findMany({
            where: {
                tenantId,
                storeId: storeId || undefined,
                type: 'CASH_OUT',
                occurredAt: { gte: start, lte: end }
            },
            select: { occurredAt: true, amount: true },
            orderBy: { occurredAt: 'asc' }
        });
        const expenseTrendMap = new Map();
        for (const l of expenseTrendLogs) {
            const d = new Date(l.occurredAt);
            d.setHours(0, 0, 0, 0);
            const key = d.toISOString().split('T')[0];
            expenseTrendMap.set(key, (expenseTrendMap.get(key) || 0) + Number(l.amount));
        }

        const trend = [];
        const allDates = new Set([...trendMap.keys(), ...expenseTrendMap.keys()]);
        for (const dateKey of Array.from(allDates).sort()) {
            trend.push({
                date: dateKey,
                sales: trendMap.get(dateKey) || 0,
                expenses: expenseTrendMap.get(dateKey) || 0
            });
        }

        const topProducts = Array.from(productStats.values())
            .sort((a, b) => b.revenue - a.revenue)
            .slice(0, 5);
        const categorySales = Object.entries(categoryMap).map(([category, revenue]) => ({ category, revenue }));
        const paymentMethods = Object.entries(paymentMap).map(([method, total]) => ({ method, total }));

        const averageOrderValue = totalTransactions > 0 ? revenue / totalTransactions : 0;
        const netProfit = revenue - totalExpenses;

        const lowStocks = await prisma.stock.findMany({
            where: {
                quantity: { lte: 5 },
                store: { tenantId }
            },
            include: { product: { select: { id: true, name: true, sku: true } } },
            take: 20
        });

        return successResponse(res, {
            summary: {
                revenue,
                totalExpenses,
                netProfit,
                totalTransactions,
                averageOrderValue
            },
            trend,
            topProducts,
            categorySales,
            paymentMethods,
            expenses: expenseBreakdown,
            lowStock: lowStocks
        });
    } catch (error) {
        return errorResponse(res, "Failed to fetch analytics", 500, error);
    }
};

module.exports = {
    getDashboardStats,
    getProfitLoss,
    getInventoryIntelligence,
    getAnalytics
};
