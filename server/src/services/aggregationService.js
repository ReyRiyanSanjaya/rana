const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * aggregationService.js
 * 
 * CORE LOGIC for "Sync-Based" Architecture.
 * This service takes completed transactions and updates the 'Reporting Tables'.
 * It ensures that heavy math (Gross Profit, COGS) is done ONCE during sync,
 * not every time a user loads the dashboard.
 */

const AggregationService = {
    /**
     * Process a batch of synced transactions to update daily summaries.
     * This should be called after a Sync batch is committed.
     */
    async processDailyAggregates(tenantId, storeId, date) {
        console.log(`[Aggregation] Processing for ${tenantId} - ${storeId} on ${date}`);

        // 1. Fetch all RECONCILED transactions for this Store+Date
        // We look for transactions that happened on this 'local date'
        // Note: In production you need timezone awareness. 
        // Here we assume 'date' is YYYY-MM-DD string.

        // Convert YYYY-MM-DD to ISO start/end
        const startOfDay = new Date(`${date}T00:00:00.000Z`);
        const endOfDay = new Date(`${date}T23:59:59.999Z`);

        const transactions = await prisma.transaction.findMany({
            where: {
                tenantId,
                storeId,
                status: { in: ['SYNCED', 'RECONCILED'] },
                occurredAt: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            },
            include: {
                items: true
            }
        });

        if (transactions.length === 0) {
            console.log(`[Aggregation] No transactions found for ${date}`);
            return;
        }

        // 2. Compute Aggregates in Memory first
        let grossSales = 0;
        let netSales = 0; // gross - tax - discount? Depending on accounting rules.
        let totalTax = 0;
        let totalDiscount = 0;
        let totalCOGS = 0;
        let grossProfit = 0;

        for (const txn of transactions) {
            // Decimal handling: Parse float for calculation (JS limitation), 
            // but in real enterprise system use a BigInt or Decimal library.
            // Prisma returns Decimals as strings or specialized objects. 
            // We'll coerce to Number for this MVP logic (beware floating point).

            const tTotal = Number(txn.total);
            const tSub = Number(txn.subtotal);
            const tTax = Number(txn.tax);
            const tDisc = Number(txn.discount);

            grossSales += tSub; // Usually subtotal is Gross Sales (Price * Qty)
            netSales += tTotal; // Final amount paid
            totalTax += tTax;
            totalDiscount += tDisc;

            // Calculate COGS and Profit from items
            // (Profit is stored on Transaction, but we can re-sum to be safe)
            let txnCost = 0;
            for (const item of txn.items) {
                txnCost += (Number(item.unitCost) * item.quantity);
            }
            totalCOGS += txnCost;
        }

        grossProfit = netSales - totalCOGS - totalTax; // Simple P&L formula: Sales - Cost - Tax (if tax is excluded)
        // Refined Formula: 
        // Gross Revenue (Total Paid) - Tax - COGS = Gross Profit
        // OR: Subtotal (Pre-tax) - COGS = Gross Profit

        // We'll use: NetSales (Total) - Tax - COGS
        grossProfit = (netSales - totalTax) - totalCOGS;

        // 3. Upsert into DailySalesSummary
        // We use upsert to create or overwrite the record for this day
        await prisma.dailySalesSummary.upsert({
            where: {
                storeId_date: {
                    storeId,
                    date: startOfDay // Prisma expects Date object
                }
            },
            update: {
                grossSales,
                netSales,
                totalTax,
                totalDiscount,
                cogs: totalCOGS,
                grossProfit,
                transactionCount: transactions.length
            },
            create: {
                tenantId,
                storeId,
                date: startOfDay,
                grossSales,
                netSales,
                totalTax,
                totalDiscount,
                cogs: totalCOGS,
                grossProfit,
                transactionCount: transactions.length
            }
        });

        console.log(`[Aggregation] Updated DailySalesSummary: Profit ${grossProfit}`);

        // 4. Update Product Aggregates (Top Selling)
        await this.processProductAggregates(tenantId, transactions);
    },

    async processProductAggregates(tenantId, transactions) {
        // Map of productId -> { revenue, quantity, profit }
        const productStats = {};

        for (const txn of transactions) {
            for (const item of txn.items) {
                if (!productStats[item.productId]) {
                    productStats[item.productId] = { revenue: 0, quantity: 0, profit: 0 };
                }

                const revenue = Number(item.subtotal); // usually price * qty
                const cost = Number(item.unitCost) * item.quantity;
                const profit = revenue - cost;

                productStats[item.productId].revenue += revenue;
                productStats[item.productId].quantity += item.quantity;
                productStats[item.productId].profit += profit;
            }
        }

        // Upsert each product stat
        // Using current date as periodStart for DAILY stats
        // We'll just grab the date from the first transaction for simplicity of this batch
        const dateRef = new Date(transactions[0].occurredAt);
        dateRef.setHours(0, 0, 0, 0);

        for (const [productId, stats] of Object.entries(productStats)) {
            // Find existing to increment? 
            // Or overwrite based on "re-calculating the whole day"?
            // The safest for idempotent sync is to Re-calculate the whole day's total from scratch 
            // (like step 1 does), but for product stats, fetching generic day sums is heavier.
            // For MVP, we will simpler: Just overwrite stats for this day. 
            // WARNING: This assumes 'transactions' passed here IS ALL transactions for the day.
            // If we are doing incremental sync, we need to Fetch-And-Add.

            // Let's do Fetch-And-Add logic roughly via Upsert? 
            // Prisma upsert update takes exact values, not "increment".
            // Better approach: We should have 'DailySalesSummary' be the single source of truth for "Day".
            // For Product stats, let's keep it simple: 
            // We will increment if we can, or just overwrite if we assume 'transactions' is the delta.
            // Actually, 'processDailyAggregates' fetched ALL txns for the day. 
            // So 'transactions' IS the full set. We can overwrite.

            await prisma.productSalesSummary.upsert({
                where: {
                    // We need a composite unique key for (productId, periodStart, periodType) in Schema
                    // Schema currently only has ID. We need to find first.
                    // Let's rely on `findFirst` then update/create.
                    id: "temp_unknown" // Hack: logic below handles this better
                },
                // PRISMA NOTE: We need a unique constraint to clean upsert. 
                // We'll simulate upsert with code for now since schema might need an @@unique
                create: {
                    tenantId,
                    productId,
                    periodStart: dateRef,
                    periodType: 'DAILY',
                    quantitySold: stats.quantity,
                    revenue: stats.revenue,
                    profit: stats.profit
                },
                update: {
                    quantitySold: stats.quantity,
                    revenue: stats.revenue,
                    profit: stats.profit
                }
            }).catch(async (e) => {
                // Fallback manual checks if unique constraint isn't perfect in schema yet
                const existing = await prisma.productSalesSummary.findFirst({
                    where: {
                        tenantId,
                        productId,
                        periodStart: dateRef,
                        periodType: 'DAILY'
                    }
                });
                if (existing) {
                    await prisma.productSalesSummary.update({
                        where: { id: existing.id },
                        data: {
                            quantitySold: stats.quantity,
                            revenue: stats.revenue,
                            profit: stats.profit
                        }
                    })
                } else {
                    await prisma.productSalesSummary.create({
                        data: {
                            tenantId,
                            productId,
                            periodStart: dateRef,
                            periodType: 'DAILY',
                            quantitySold: stats.quantity,
                            revenue: stats.revenue,
                            profit: stats.profit
                        }
                    })
                }
            });
        }
    }
};

module.exports = AggregationService;
