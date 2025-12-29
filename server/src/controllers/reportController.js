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

        const start = new Date(startDate);
        const end = new Date(endDate);

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

        const revenue = totals.totalSales || 0;
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

module.exports = {
    getDashboardStats,
    getProfitLoss,
    getInventoryIntelligence
};
