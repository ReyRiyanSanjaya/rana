const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const crypto = require('crypto');

async function main() {
    const email = 'berkah@demo.com';
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
        console.log("❌ User berkah@demo.com not found!");
        return;
    }

    console.log(`🌱 Seeding data for ${user.name} (${email})...`);

    const tenantId = user.tenantId;
    const store = await prisma.store.findFirst({ where: { tenantId } });
    if (!store) { console.log("❌ Store not found"); return; }

    // 1. Add Extra Products (Retail Focus)
    const newProducts = [
        { name: 'Kecap Bango 500ml', price: 22000, cat: 'Sembako', stock: 50 },
        { name: 'Gula Pasir 1kg', price: 16000, cat: 'Sembako', stock: 100 },
        { name: 'Tepung Segitiga Biru', price: 14000, cat: 'Sembako', stock: 40 },
        { name: 'Rokok Sampoerna Mild', price: 32000, cat: 'Rokok', stock: 200 },
        { name: 'Rokok Surya 16', price: 30000, cat: 'Rokok', stock: 200 },
        { name: 'Korek Api Tokai', price: 3000, cat: 'Rokok', stock: 500 },
        { name: 'Shampoo Pantene', price: 25000, cat: 'Household', stock: 30 },
        { name: 'Pasta Gigi Pepsodent', price: 12000, cat: 'Household', stock: 50 },
        { name: 'Sabun Mandi Dettol', price: 8000, cat: 'Household', stock: 50 },
        { name: 'Deterjen Rinso 800g', price: 28000, cat: 'Household', stock: 40 },
    ];

    const catMap = {};
    // Ensure categories exist
    for (const p of newProducts) {
        if (!catMap[p.cat]) {
            let c = await prisma.category.findFirst({ where: { tenantId, name: p.cat } });
            if (!c) {
                c = await prisma.category.create({ data: { tenantId, name: p.cat } });
                console.log(`   + Created Category: ${p.cat}`);
            }
            catMap[p.cat] = c.id;
        }
    }

    // Create Products
    for (const p of newProducts) {
        // Check if product exists to avoid duplicates
        let prod = await prisma.product.findFirst({ where: { tenantId, name: p.name } });
        if (!prod) {
            prod = await prisma.product.create({
                data: {
                    tenantId,
                    storeId: store.id,
                    name: p.name,
                    basePrice: p.price * 0.85,
                    sellingPrice: p.price,
                    stock: p.stock,
                    categoryId: catMap[p.cat],
                    sku: `BRK-${Math.floor(Math.random() * 10000)}`,
                    description: `Stok ${p.name} untuk Toko Berkah`
                }
            });
            console.log(`   + Created Product: ${p.name}`);
        }
    }

    // Fetch all products (old + new) to mix in transactions
    const allProds = await prisma.product.findMany({ where: { tenantId } });

    // 2. Add Transactions (High Intensity for Last 7 Days)
    console.log("   + Generating 50 new transactions...");
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);
    const endDate = new Date();

    for (let i = 0; i < 50; i++) {
        const tDate = new Date(startDate.getTime() + Math.random() * (endDate.getTime() - startDate.getTime()));

        // Random items
        const itemCount = Math.floor(Math.random() * 5) + 1;
        let total = 0;
        const items = [];

        for (let j = 0; j < itemCount; j++) {
            const p = allProds[Math.floor(Math.random() * allProds.length)];
            const qty = Math.floor(Math.random() * 3) + 1;
            total += p.sellingPrice * qty;
            items.push({
                productId: p.id,
                quantity: qty,
                price: p.sellingPrice
            });
        }

        await prisma.transaction.create({
            data: {
                id: crypto.randomUUID(),
                tenantId,
                storeId: store.id,
                totalAmount: total,
                paymentMethod: 'CASH',
                amountPaid: total,
                change: 0,
                orderStatus: 'COMPLETED',
                paymentStatus: 'PAID',
                fulfillmentType: 'PICKUP',
                occurredAt: tDate,
                transactionItems: {
                    create: items
                }
            }
        });
    }
    console.log("✅ Seed for Berkah Complete!");
}

main().finally(() => prisma.$disconnect());
