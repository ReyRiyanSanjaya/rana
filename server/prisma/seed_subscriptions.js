const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Seeding Subscription Requests...');

    // 1. Create a dummy tenant for the request
    const tenant = await prisma.tenant.create({
        data: {
            name: 'Toko Sejahtera Abadi',
            plan: 'FREE',
            subscriptionStatus: 'TRIAL',
            trialEndsAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
    });

    // 2. Create the request
    const request = await prisma.subscriptionRequest.create({
        data: {
            tenantId: tenant.id,
            status: 'PENDING',
            proofUrl: 'https://placehold.co/600x400/png?text=Transfer+Bukti+BCA', // Dummy proof image
        }
    });

    console.log(`Created Subscription Request for tenant: ${tenant.name}`);

    // 3. Create another one without proof
    const tenant2 = await prisma.tenant.create({
        data: {
            name: 'Warung Bu Dewi',
            plan: 'FREE',
            subscriptionStatus: 'TRIAL',
        }
    });

    await prisma.subscriptionRequest.create({
        data: {
            tenantId: tenant2.id,
            status: 'PENDING',
            // no proof
        }
    });
    console.log(`Created Subscription Request for tenant: ${tenant2.name}`);

}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
