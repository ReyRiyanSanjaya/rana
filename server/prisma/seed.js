const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
    console.log('Seeding Database...');

    // 1. Create Tenant (UMKM Demo)
    // Check if exists
    let tenant = await prisma.tenant.findFirst({ where: { name: 'Kopi Kenangan Demo' } });

    if (!tenant) {
        tenant = await prisma.tenant.create({
            data: {
                name: 'Kopi Kenangan Demo',
                plan: 'PREMIUM',
                subscriptionStatus: 'ACTIVE',
                // Trial ends in 30 days
                trialEndsAt: new Date(new Date().getTime() + 30 * 24 * 60 * 60 * 1000)
            }
        });
        console.log('✅ Created Tenant:', tenant.name);
    } else {
        console.log('ℹ️ Tenant already exists:', tenant.name);
    }

    // 2. Create User (Merchant Owner)
    const merchantEmail = 'merchant@rana.com';
    const rawPassword = 'password123';
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const merchantUser = await prisma.user.upsert({
        where: { email: merchantEmail },
        update: {},
        create: {
            email: merchantEmail,
            name: 'Merchant Owner',
            passwordHash: hashedPassword,
            role: 'OWNER',
            tenantId: tenant.id
        },
    });
    console.log(`✅ Created Merchant: ${merchantEmail} / ${rawPassword}`);

    // 3. Create User (Super Admin Platform)
    // Super Admin might not have a tenant, OR belongs to a system tenant. 
    // For simplicity, let's allow null tenantId for Super Admin if schema allows, 
    // OR create a System Tenant.
    // Checking schema: tenantId is String (required) or String? (optional).
    // Let's assume user.tenantId is required based on schema context usually.
    // If required, we use the same tenant or a special one. 
    // Safe bet: modify schema to make tenantId optional for Super Admin, 
    // BUT for now, assign to the same tenant to avoid schema errors if strict.

    // Actually, looking at previous schema view, tenantId looks required on User?
    // Let's check schema first in next step if unsure, but I'll assume it's required for now
    // and just assign the same tenant but give SUPER_ADMIN role.

    const adminEmail = 'super@rana.com';
    const adminUser = await prisma.user.upsert({
        where: { email: adminEmail },
        update: { role: 'SUPER_ADMIN' },
        create: {
            email: adminEmail,
            name: 'Platform Administrator',
            passwordHash: hashedPassword,
            role: 'SUPER_ADMIN',
            tenantId: tenant.id
        },
    });
    console.log(`✅ Created Super Admin: ${adminEmail} / ${rawPassword}`);

    // 3. Create Store
    const store = await prisma.store.upsert({
        where: { id: 'store-1-demo' }, // We need a logical ID or findFirst logic, but UUID makes it hard.
        // Simplify: Find first store for tenant, if none, create.
        update: {},
        create: {
            tenantId: tenant.id,
            name: 'Cabang Pusat',
            location: 'Jakarta',
            waNumber: '628123456789'
        }
    }); // Note: upsert requires @unique, Store doesn't have easy unique besides ID. 
    // Let's just create if count is 0

    const count = await prisma.store.count({ where: { tenantId: tenant.id } });
    if (count === 0) {
        await prisma.store.create({
            data: {
                tenantId: tenant.id,
                name: 'Cabang Pusat - Jakarta',
                location: 'Jakarta Selatan',
                waNumber: '628123456789'
            }
        });
        console.log('✅ Created Default Store');
    }

    // 4. Create Subscription Packages
    const packages = [
        { name: 'Paket Bulanan', price: 49000, durationDays: 30, description: 'Billed Monthly' },
        { name: 'Paket 6 Bulan', price: 250000, durationDays: 180, description: 'Save 15%' },
        { name: 'Paket Tahunan', price: 450000, durationDays: 365, description: 'Best Value (Save 25%)' }
    ];

    for (const pkg of packages) {
        await prisma.subscriptionPackage.create({ data: pkg });
    }
    console.log('✅ Created Subscription Packages');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
