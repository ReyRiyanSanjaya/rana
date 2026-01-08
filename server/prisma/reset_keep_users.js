const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("🔥 STARTING PARTIAL RESET (Resetting Data, Keeping Users)...");

    const argvEmails = process.argv.slice(2).map(e => e.toLowerCase());
    const envAdmin = (process.env.ADMIN_EMAIL || '').toLowerCase();
    const KEEP_EMAILS = argvEmails.length > 0
        ? argvEmails
        : [envAdmin].filter(Boolean).length > 0
            ? [envAdmin]
            : ['merchant@rana.com', 'super@rana.com'];

    // 1. Identify Users/Tenants to KEEP
    const keepUsers = await prisma.user.findMany({
        where: { email: { in: KEEP_EMAILS } },
        include: { tenant: true } // Need tenant ID
    });

    const keepUserIds = keepUsers.map(u => u.id);
    const keepTenantIds = keepUsers.map(u => u.tenantId).filter(id => id != null);

    // Also need to keep Stores belonging to these tenants
    const keepStores = await prisma.store.findMany({
        where: { tenantId: { in: keepTenantIds } }
    });
    const keepStoreIds = keepStores.map(s => s.id);

    console.log(`ℹ️ Preserving Users: ${keepUserIds.length}`);
    console.log(`ℹ️ Preserving Tenants: ${keepTenantIds.length}`);
    console.log(`ℹ️ Preserving Stores: ${keepStoreIds.length}`);

    // 2. Delete Dependent Data (Transactions, etc.)
    // We wipe ALL functional data for EVERYONE

    console.log("Deleting Transactions...");
    await prisma.transactionItem.deleteMany({});
    await prisma.transaction.deleteMany({});

    console.log("Deleting Inventory/Products...");
    await prisma.stock.deleteMany({});
    await prisma.inventoryLog.deleteMany({});
    // Fix: Clear Product Sales Summary first
    await prisma.productSalesSummary.deleteMany({});
    // Fix: Clear Favorites/Reviews before Products
    await prisma.favorite.deleteMany({});
    await prisma.review.deleteMany({});
    // Fix: Clear Flash Sales before Products
    await prisma.flashSaleItem.deleteMany({});
    await prisma.flashSale.deleteMany({});
    await prisma.product.deleteMany({});
    await prisma.category.deleteMany({});

    console.log("Deleting Cashflow/Analytics...");
    await prisma.cashflowLog.deleteMany({});
    // Fix: Clear DailySalesSummary first
    await prisma.dailySalesSummary.deleteMany({});
    await prisma.platformRevenue.deleteMany({});

    console.log("Deleting Customers/Suppliers...");
    await prisma.customer.deleteMany({});
    await prisma.debtRecord.deleteMany({}); // Fix: Debt Records
    await prisma.purchaseItem.deleteMany({});
    await prisma.purchase.deleteMany({});
    await prisma.supplier.deleteMany({});

    console.log("Deleting Support/Tickets...");
    await prisma.ticketMessage.deleteMany({});
    await prisma.supportTicket.deleteMany({});
    await prisma.notification.deleteMany({}); // Fix: Notifications

    console.log("Deleting Subscription Requests/Orders...");
    await prisma.subscriptionRequest.deleteMany({});
    await prisma.wholesaleOrderItem.deleteMany({});
    await prisma.wholesaleOrder.deleteMany({});
    await prisma.ppobTransaction.deleteMany({}); // Fix: Digital product transactions

    console.log("Deleting Wallet Data...");
    await prisma.withdrawal.deleteMany({}); // Fix: Withdrawals
    await prisma.topUpRequest.deleteMany({}); // Fix: TopUps
    await prisma.walletTransfer.deleteMany({}); // Fix: Transfers

    // 3. Delete NON-KEPT Users/Tenants/Stores
    console.log("Deleting Non-Essential Accounts...");

    // Fix: Clear Referral program data before tenants
    await prisma.referralReward.deleteMany({});
    await prisma.referral.deleteMany({});
    await prisma.referralCode.deleteMany({});
    await prisma.referralProgram.deleteMany({});

    await prisma.loginHistory.deleteMany({
        where: { userId: { notIn: keepUserIds } }
    });

    await prisma.user.deleteMany({
        where: { id: { notIn: keepUserIds } }
    });

    await prisma.store.deleteMany({
        where: { id: { notIn: keepStoreIds } } // Stores of kept tenants are kept
    });

    await prisma.tenant.deleteMany({
        where: { id: { notIn: keepTenantIds } }
    });

    // 4. Reset Balance/Data for KEPT tenants

    await prisma.store.updateMany({
        where: { id: { in: keepStoreIds } },
        data: { balance: 0 }
    });

    console.log("✅ Database Reset Complete (Users Preserved).");
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => await prisma.$disconnect());
