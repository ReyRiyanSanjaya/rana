const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("🌱 Starting Seeding Demo Data...");

    // 1. Find or Create Demo Store
    let store = await prisma.store.findFirst({ where: { name: 'Demo Coffee Shop' } });

    // 1b. Find or Create Demo Tenant (Ensure this runs regardless of store existence)
    let tenant = await prisma.tenant.findFirst({ where: { name: 'Demo Tenant' } });
    if (!tenant) {
        tenant = await prisma.tenant.create({
            data: {
                name: 'Demo Tenant',
                plan: 'PREMIUM',
                subscriptionStatus: 'ACTIVE'
            }
        });
        console.log("✅ Created Demo Tenant");
    }

    if (!store) {
        // Need an owner first
        let owner = await prisma.user.findFirst({ where: { role: 'OWNER' } });
        if (!owner) {
            // Create demo owner if none exists
            owner = await prisma.user.create({
                data: {
                    email: 'demo@owner.com',
                    passwordHash: '$2b$10$EpIx.i.d.5.6.7.8.9.0.e', // dummy
                    name: 'Demo Owner',
                    role: 'OWNER'
                }
            });
        }

        // Create tenant first if it doesn't exist (We already ensured tenant exists above)

        // Check User's relation for storeId? or Store's relation for users?
        // Schema has `users User[]`. It doesn't seem to have `userId` on Store directly.
        // But User has `storeId`.
        // User: `store Store? @relation(fields: [storeId], references: [id])`
        // Store: `users User[]`
        // So we Create Store, then update User to have this storeId.

        store = await prisma.store.create({
            data: {
                name: 'Demo Coffee Shop',
                location: '123 Jalan Demo', // Fixed from address
                waNumber: '08123456789', // Fixed from phone
                tenant: { connect: { id: tenant.id } }
            }
        });
        console.log("✅ Created Demo Store");

        // Connect User to Store
        await prisma.user.update({
            where: { id: owner.id },
            data: { storeId: store.id }
        });

    } else {
        console.log("✅ Using existing Demo Store:", store.name);
        // ensure it has tenant connected if not
        if (!store.tenantId) {
            await prisma.store.update({
                where: { id: store.id },
                data: { tenantId: tenant.id }
            });
        }
    }

    // 2. Create Categories
    const categories = ['Beverage', 'Food', 'Beans', 'Merchandise'];
    const catMap = {};

    for (const cat of categories) {
        let c = await prisma.category.findFirst({ where: { name: cat } });
        if (!c) {
            c = await prisma.category.create({
                data: {
                    name: cat,
                    tenant: { connect: { id: tenant.id } }
                }
            });
        }
        catMap[cat] = c.id;
    }

    // 3. Create Products (Top Selling & Slow Moving)
    const productsData = [
        // High Sales (Top Selling)
        { name: 'Kopi Susu Gula Aren', price: 18000, stock: 45, minStock: 10, category: 'Beverage', sku: 'BV-001' },
        { name: 'Caramel Macchiato', price: 28000, stock: 32, minStock: 10, category: 'Beverage', sku: 'BV-002' },
        { name: 'Croissant Butter', price: 15000, stock: 12, minStock: 15, category: 'Food', sku: 'FD-001' }, // Low Stock

        // Slow Moving (Old creation date, No recent sales)
        { name: 'Green Tea Powder 500g', price: 85000, stock: 5, minStock: 2, category: 'Beans', sku: 'MTAR-01' },
        { name: 'French Press Manual', price: 150000, stock: 8, minStock: 2, category: 'Merchandise', sku: 'EQ-001' },

        // Normal
        { name: 'Espresso', price: 12000, stock: 100, minStock: 20, category: 'Beverage', sku: 'BV-003' },
    ];

    for (const p of productsData) {
        const input = {
            name: p.name,
            basePrice: p.price * 0.7, // Estimate base price
            sellingPrice: p.price,
            stock: p.stock,
            minStock: p.minStock,
            sku: p.sku,
            categoryId: catMap[p.category],
            storeId: store.id,
            tenantId: tenant.id // Direct connect via ID is fine if field exists, but let's check schema
            // Schema has tenantId String. So this works.
        };

        const existing = await prisma.product.findFirst({ where: { sku: p.sku } });
        if (!existing) {
            await prisma.product.create({ data: input });
            console.log(`+ Created Product: ${p.name}`);
        } else {
            await prisma.product.update({
                where: { id: existing.id },
                data: { stock: p.stock } // Reset stock for demo
            });
            console.log(`~ Updated Product: ${p.name}`);
        }
    }

    // 4. Simulate Sales (Transactions) to drive "Top Selling"
    // We need to fetch products again to get IDs
    const allProducts = await prisma.product.findMany({ where: { storeId: store.id } });
    const productMap = {};
    allProducts.forEach(p => productMap[p.sku] = p);

    // Create a transaction for "Kopi Susu" (Massive sales)
    const kopi = productMap['BV-001'];
    if (kopi) {
        await prisma.transaction.create({
            data: {
                tenantId: tenant.id,
                storeId: store.id,
                totalAmount: kopi.sellingPrice * 50,
                paymentMethod: 'CASH',
                amountPaid: kopi.sellingPrice * 50,
                change: 0,
                orderStatus: 'COMPLETED',
                paymentStatus: 'PAID',
                fulfillmentType: 'DINE_IN',
                createdAt: new Date(), // Today
                items: {
                    create: {
                        productId: kopi.id,
                        quantity: 50,
                        price: kopi.sellingPrice
                    }
                }
            }
        });
        console.log("💰 Simulated 50 sales for Kopi Susu");
    }

    // Create sales for Caramel Macchiato
    const caramel = productMap['BV-002'];
    if (caramel) {
        await prisma.transaction.create({
            data: {
                tenantId: tenant.id,
                storeId: store.id,
                totalAmount: caramel.sellingPrice * 30,
                paymentMethod: 'QRIS',
                amountPaid: caramel.sellingPrice * 30,
                change: 0,
                orderStatus: 'COMPLETED',
                paymentStatus: 'PAID',
                fulfillmentType: 'PICKUP',
                createdAt: new Date(),
                items: {
                    create: {
                        productId: caramel.id,
                        quantity: 30,
                        price: caramel.sellingPrice
                    }
                }
            }
        });
        console.log("💰 Simulated 30 sales for Caramel Macchiato");
    }

    // 5. Create Inventory Logs
    for (const p of allProducts) {
        await prisma.inventoryLog.create({
            data: {
                productId: p.id,
                type: 'IN',
                quantity: p.stock,
                reason: 'Initial Stock Import',
                createdAt: new Date(new Date().setDate(new Date().getDate() - 30)) // 30 days ago
            }
        });
    }

    console.log("✅ Seeding Complete!");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
