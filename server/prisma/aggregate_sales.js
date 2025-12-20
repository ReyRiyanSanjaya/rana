const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("🔄 Starting Sales Aggregation...");

    // 1. Get all transactions
    const transactions = await prisma.transaction.findMany({
        where: { orderStatus: 'COMPLETED' }
    });

    console.log(`Found ${transactions.length} transactions to aggregate.`);

    const summaryMap = {}; // Key: "storeId_dateStr" -> { totalSales, count }

    for (const t of transactions) {
        // Use occurredAt or createdAt
        const dateObj = new Date(t.occurredAt || t.createdAt);
        const dateStr = dateObj.toISOString().split('T')[0]; // YYYY-MM-DD
        const key = `${t.tenantId}_${t.storeId}_${dateStr}`;

        if (!summaryMap[key]) {
            summaryMap[key] = {
                tenantId: t.tenantId,
                storeId: t.storeId,
                date: new Date(dateStr),
                totalSales: 0,
                totalTrans: 0
            };
        }

        summaryMap[key].totalSales += t.totalAmount;
        summaryMap[key].totalTrans += 1;
    }

    console.log(`Aggregating into ${Object.keys(summaryMap).length} daily records...`);

    for (const key in summaryMap) {
        const data = summaryMap[key];

        // Upsert summary
        const existing = await prisma.dailySalesSummary.findFirst({
            where: {
                storeId: data.storeId,
                date: data.date
            }
        });

        if (existing) {
            await prisma.dailySalesSummary.update({
                where: { id: existing.id },
                data: {
                    totalSales: data.totalSales,
                    totalTrans: data.totalTrans
                }
            });
        } else {
            await prisma.dailySalesSummary.create({
                data: {
                    tenantId: data.tenantId,
                    storeId: data.storeId,
                    date: data.date,
                    totalSales: data.totalSales,
                    totalTrans: data.totalTrans
                }
            });
        }
    }

    // 2. Product Sales Aggregation
    console.log("Aggregating Product Sales...");
    const productMap = {}; // "productId_date" -> { qty, revenue }

    // Refetch with items
    const transWithItems = await prisma.transaction.findMany({
        where: { orderStatus: 'COMPLETED' },
        include: { transactionItems: true }
    });

    for (const t of transWithItems) {
        const dateObj = new Date(t.occurredAt || t.createdAt);
        const dateStr = dateObj.toISOString().split('T')[0];

        for (const item of t.transactionItems) {
            const key = `${item.productId}_${dateStr}`;
            if (!productMap[key]) {
                productMap[key] = {
                    tenantId: t.tenantId,
                    storeId: t.storeId, // Schema doesn't have storeId on ProductSalesSummary but has tenantId
                    productId: item.productId,
                    date: new Date(dateStr),
                    quantity: 0,
                    revenue: 0
                };
            }
            productMap[key].quantity += item.quantity;
            productMap[key].revenue += (item.price * item.quantity);
        }
    }

    for (const key in productMap) {
        const data = productMap[key];
        // Upsert Product Summary
        // Schema check: model ProductSalesSummary { id, tenantId, productId, date, quantitySold, totalRevenue }
        // Unique missing? Let's check schema. findFirst is safer.
        const existing = await prisma.productSalesSummary.findFirst({
            where: {
                productId: data.productId,
                date: data.date
            }
        });

        if (existing) {
            await prisma.productSalesSummary.update({
                where: { id: existing.id },
                data: {
                    quantitySold: data.quantity,
                    totalRevenue: data.revenue
                }
            });
        } else {
            await prisma.productSalesSummary.create({
                data: {
                    tenantId: data.tenantId,
                    productId: data.productId,
                    date: data.date,
                    quantitySold: data.quantity,
                    totalRevenue: data.revenue
                }
            });
        }
    }

    console.log("✅ Aggregation Complete!");
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
