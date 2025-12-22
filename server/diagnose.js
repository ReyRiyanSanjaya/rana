const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function diagnose() {
    console.log("1. Testing Database Connection...");
    try {
        await prisma.$connect();
        console.log("✅ Database Connected!");
    } catch (e) {
        console.error("❌ Database Connection Failed:", e);
        return;
    }

    console.log("\n2. Testing Dashboard Stats Query...");
    try {
        const start = Date.now();

        const totalStores = await prisma.store.count();
        console.log(`- Stores Count: ${totalStores} (Time: ${Date.now() - start}ms)`);

        const pendingWithdrawals = await prisma.withdrawal.count({ where: { status: 'PENDING' } });
        console.log(`- Pending Withdrawals: ${pendingWithdrawals}`);

        console.log("✅ Dashboard Queries Successful!");

        console.log("\n3. Testing Chart Query...");
        try {
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

            const withdrawals = await prisma.withdrawal.groupBy({
                by: ['createdAt'],
                _sum: { amount: true },
                where: {
                    status: 'APPROVED',
                    createdAt: { gte: sevenDaysAgo }
                },
                orderBy: { createdAt: 'asc' }
            });
            console.log(`✅ Chart Query Successful: ${withdrawals.length} groups`);
        } catch (e) {
            console.error("❌ Chart Query Failed:", e);
        }

    } catch (e) {
        console.error("❌ Dashboard Query Failed:", e);
    } finally {
        await prisma.$disconnect();
    }
}

diagnose();
