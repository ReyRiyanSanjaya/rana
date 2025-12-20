const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("--- DATABASE COUNTS ---");
    const tenants = await prisma.tenant.count();
    const stores = await prisma.store.count();
    const users = await prisma.user.count();
    const products = await prisma.product.count();
    const transactions = await prisma.transaction.count();

    console.log(`Tenants: ${tenants}`);
    console.log(`Stores: ${stores}`);
    console.log(`Users: ${users}`);
    console.log(`Products: ${products}`);
    console.log(`Transactions: ${transactions}`);

    console.log("\n--- MERCHANTS LIST ---");
    const allStores = await prisma.store.findMany({
        include: { tenant: true }
    });
    allStores.forEach(s => console.log(`- [${s.id}] Store: ${s.name} (Tenant: ${s.tenant?.name})`));

    console.log("\n--- SUPER ADMINS ---");
    const admins = await prisma.user.findMany({ where: { role: 'SUPER_ADMIN' } });
    admins.forEach(a => console.log(`- ${a.email} (${a.name})`));
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
