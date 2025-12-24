const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
    console.log("🌱 Seeding Merchant Demo User...");

    const email = 'merchant@rana.com';
    const password = 'password123';
    const businessName = 'Tokoku (Demo)';

    // 1. Check if user exists
    let user = await prisma.user.findUnique({ where: { email } });

    if (user) {
        console.log("⚠️ User already exists. Resetting subscription status...");

        // Find Tenant
        const tenant = await prisma.tenant.findUnique({ where: { id: user.tenantId } });
        if (tenant) {
            await prisma.tenant.update({
                where: { id: tenant.id },
                data: {
                    plan: 'FREE',
                    subscriptionStatus: 'EXPIRED', // Force expired to show subscription flow
                    trialEndsAt: new Date(new Date().setDate(new Date().getDate() - 1)) // Ended yesterday
                }
            });
            console.log("✅ Tenant subscription reset to EXPIRED.");
        }
    } else {
        console.log("🆕 Creating new Merchant User...");

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create Tenant
        const tenant = await prisma.tenant.create({
            data: {
                name: businessName,
                plan: 'FREE',
                subscriptionStatus: 'EXPIRED', // Starting as expired demo
                trialEndsAt: new Date(new Date().setDate(new Date().getDate() - 1))
            }
        });

        // Create Store
        const store = await prisma.store.create({
            data: {
                name: businessName,
                location: 'Jl. Demo No. 123',
                waNumber: '081234567890',
                tenantId: tenant.id
            }
        });

        // Create User
        user = await prisma.user.create({
            data: {
                email,
                name: 'Merchant Demo',
                passwordHash: hashedPassword,
                role: 'OWNER',
                tenantId: tenant.id,
                storeId: store.id
            }
        });

        console.log(`✅ User Created: ${email} / ${password}`);
    }

    console.log("🎉 Seeding Complete!");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
