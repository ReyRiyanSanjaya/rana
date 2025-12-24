const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("🔍 Checking Merchant Status...");
    const user = await prisma.user.findUnique({
        where: { email: 'merchant@rana.com' },
        include: { tenant: true }
    });

    if (user) {
        console.log(`User Found: ${user.email}`);
        console.log(`Tenant ID: ${user.tenantId}`);
        console.log(`Plan: ${user.tenant.plan}`);
        console.log(`Subscription Status: ${user.tenant.subscriptionStatus}`);
        console.log(`Trial Ends: ${user.tenant.trialEndsAt}`);
    } else {
        console.log("❌ User merchant@rana.com NOT FOUND");
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
