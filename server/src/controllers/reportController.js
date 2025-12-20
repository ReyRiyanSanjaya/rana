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
        // This reads from the PRE-CALCULATED table, avoiding huge JOINs on the fly.
        const summary = await prisma.dailySalesSummary.findFirst({
            where: {
                tenantId,
                storeId: storeId || undefined, // If no storeId, we might need to sum all stores (optional feature)
                date: startOfDay
            }
        });

        // Also get Top 5 Products for widget
        const topProducts = await prisma.productSalesSummary.findMany({
            where: {
                tenantId,
                periodStart: startOfDay,
                periodType: 'DAILY'
            },
            orderBy: {
                revenue: 'desc'
            },
            take: 5,
            include: {
                product: { select: { name: true, sku: true } }
            }
        });

        return successResponse(res, {
            financials: summary || {
                grossSales: 0, netSales: 0, grossProfit: 0, transactionCount: 0
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
                grossSales: true,
                netSales: true,
                cogs: true,
                grossProfit: true,
                totalTax: true,
                totalDiscount: true
            }
        });

        const totals = aggs[0]?._sum || {};

        return successResponse(res, {
            period: { start, end },
            pnl: {
                revenue: totals.netSales || 0,
                cogs: totals.cogs || 0,
                grossProfit: totals.grossProfit || 0,
                margin: totals.netSales > 0 ? ((totals.grossProfit / totals.netSales) * 100).toFixed(2) : 0,
                taxCollected: totals.totalTax || 0,
                discountsGiven: totals.totalDiscount || 0
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
