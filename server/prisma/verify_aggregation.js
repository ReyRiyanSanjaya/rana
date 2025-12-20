const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("--- VERIFYING AGGREGATION ---");
    const summaries = await prisma.dailySalesSummary.count();
    const productSummaries = await prisma.productSalesSummary.count();

    console.log(`Daily Sales Summaries: ${summaries}`);
    console.log(`Product Sales Summaries: ${productSummaries}`);

    if (summaries > 0) {
        const sample = await prisma.dailySalesSummary.findFirst({ include: { tenant: true } });
        console.log(`Sample Summary: ${sample.date.toISOString().split('T')[0]} - Sales: ${sample.totalSales} (Tenant: ${sample.tenant.name})`);
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
