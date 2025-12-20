const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const crypto = require('crypto');

const MERCHANTS = [
    {
        name: 'Kopi Senja',
        type: 'FNB',
        owner: 'Budi Santoso',
        email: 'kopisenja@demo.com',
        phone: '081211112222',
        address: 'Jl. Senopati No. 10, Jakarta Selatan',
        categories: ['Coffee', 'Non-Coffee', 'Pastry', 'Main Course'],
        products: [
            { name: 'Kopi Susu Senja', price: 25000, cat: 'Coffee' },
            { name: 'Americano', price: 22000, cat: 'Coffee' },
            { name: 'Latte', price: 28000, cat: 'Coffee' },
            { name: 'Matcha Latte', price: 30000, cat: 'Non-Coffee' },
            { name: 'Chocolate Ice', price: 28000, cat: 'Non-Coffee' },
            { name: 'Croissant Butter', price: 18000, cat: 'Pastry' },
            { name: 'Almond Croissant', price: 25000, cat: 'Pastry' },
            { name: 'Nasi Goreng Kampung', price: 35000, cat: 'Main Course' },
            { name: 'Spaghetti Bolognese', price: 40000, cat: 'Main Course' },
        ]
    },
    {
        name: 'Toko Kelontong Berkah',
        type: 'RETAIL',
        owner: 'Siti Aminah',
        email: 'berkah@demo.com',
        phone: '081233334444',
        address: 'Jl. Kebon Jeruk No. 5, Jakarta Barat',
        categories: ['Sembako', 'Snack', 'Minuman', 'Household'],
        products: [
            { name: 'Beras Pandan Wangi 5kg', price: 65000, cat: 'Sembako' },
            { name: 'Telur Ayam 1kg', price: 28000, cat: 'Sembako' },
            { name: 'Minyak Goreng 2L', price: 35000, cat: 'Sembako' },
            { name: 'Indomie Goreng', price: 3500, cat: 'Snack' },
            { name: 'Chitato Sapi Panggang', price: 12000, cat: 'Snack' },
            { name: 'Aqua 600ml', price: 4000, cat: 'Minuman' },
            { name: 'Teh Pucuk Harum', price: 5000, cat: 'Minuman' },
            { name: 'Sabun Lifebuoy', price: 5000, cat: 'Household' },
            { name: 'Sunlight 750ml', price: 18000, cat: 'Household' },
        ]
    },
    {
        name: 'Clean & Fresh Laundry',
        type: 'SERVICE',
        owner: 'Rudi Hartono',
        email: 'laundry@demo.com',
        phone: '081255556666',
        address: 'Jl. Tebet Raya No. 15, Jakarta Selatan',
        categories: ['Kiloan', 'Satuan', 'Dry Clean'],
        products: [
            { name: 'Cuci Gosok Kiloan (Next Day)', price: 8000, cat: 'Kiloan' },
            { name: 'Cuci Kering Kiloan', price: 6000, cat: 'Kiloan' },
            { name: 'Cuci Gosok Express (4 Jam)', price: 12000, cat: 'Kiloan' },
            { name: 'Cuci Sprei', price: 15000, cat: 'Satuan' },
            { name: 'Cuci Selimut', price: 20000, cat: 'Satuan' },
            { name: 'Cuci Boneka Besar', price: 25000, cat: 'Satuan' },
            { name: 'Jas / Blazer', price: 35000, cat: 'Dry Clean' },
            { name: 'Gaun Pesta', price: 50000, cat: 'Dry Clean' },
        ]
    },
    {
        name: 'Burger Bangor',
        type: 'FNB',
        owner: 'Denny Sumargo',
        email: 'burger@demo.com',
        phone: '081277778888',
        address: 'Jl. Kemang Raya No. 88, Jakarta Selatan',
        categories: ['Burger', 'Sides', 'Drinks'],
        products: [
            { name: 'Juragan Cheese', price: 25000, cat: 'Burger' },
            { name: 'Ningrat Cheese', price: 35000, cat: 'Burger' },
            { name: 'Sultan Cheese', price: 45000, cat: 'Burger' },
            { name: 'French Fries', price: 15000, cat: 'Sides' },
            { name: 'Onion Rings', price: 18000, cat: 'Sides' },
            { name: 'Cola', price: 10000, cat: 'Drinks' },
            { name: 'Lemon Tea', price: 12000, cat: 'Drinks' },
        ]
    },
    {
        name: 'Apotek Sehat',
        type: 'RETAIL',
        owner: 'Dr. Boyke',
        email: 'apotek@demo.com',
        phone: '081299990000',
        address: 'Jl. Kesehatan No. 1, Jakarta Pusat',
        categories: ['Obat Bebas', 'Vitamin', 'Alat Kesehatan'],
        products: [
            { name: 'Panadol Extra', price: 12000, cat: 'Obat Bebas' },
            { name: 'Paracetamol', price: 5000, cat: 'Obat Bebas' },
            { name: 'Bodrex', price: 4000, cat: 'Obat Bebas' },
            { name: 'Vitamin C 1000mg', price: 1500, cat: 'Vitamin' },
            { name: 'Imboost Force', price: 45000, cat: 'Vitamin' },
            { name: 'Masker Medis 5pcs', price: 10000, cat: 'Alat Kesehatan' },
            { name: 'Hand Sanitizer 100ml', price: 15000, cat: 'Alat Kesehatan' },
        ]
    }
];

// Helper to get random item from array
const random = (arr) => arr[Math.floor(Math.random() * arr.length)];
// Helper for random number
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
// Helper for random date in last 30 days
const randomDate = (start, end) => {
    return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
};

async function main() {
    console.log("🌱 Starting EXTENSIVE Seeding...");

    for (const m of MERCHANTS) {
        console.log(`\nProcessing Merchant: ${m.name}...`);

        // 1. Check if user email exists to avoid dupes
        const existingUser = await prisma.user.findUnique({ where: { email: m.email } });
        if (existingUser) {
            console.log(`   ⚠️ Merchant ${m.name} already exists. Skipping.`);
            continue;
        }

        // 2. Create Tenant
        const tenant = await prisma.tenant.create({
            data: {
                name: m.name,
                plan: 'PREMIUM', // Give them premium for demo
                subscriptionStatus: 'ACTIVE',
                trialEndsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            }
        });

        // 3. Create Store
        const store = await prisma.store.create({
            data: {
                tenantId: tenant.id,
                name: m.name,
                location: m.address,
                waNumber: m.phone
            }
        });

        // 4. Create Owner
        const user = await prisma.user.create({
            data: {
                tenantId: tenant.id,
                storeId: store.id,
                name: m.owner,
                email: m.email,
                passwordHash: '$2b$10$EpIx.i.d.5.6.7.8.9.0.e', // Default password (hash of 123456 maybe? or standard dummy)
                role: 'OWNER'
            }
        });

        // 5. Create Categories
        const catMap = {};
        for (const catName of m.categories) {
            const c = await prisma.category.create({
                data: {
                    name: catName,
                    tenantId: tenant.id
                }
            });
            catMap[catName] = c.id;
        }

        // 6. Create Products
        const createdProducts = [];
        for (const p of m.products) {
            const product = await prisma.product.create({
                data: {
                    tenantId: tenant.id,
                    storeId: store.id,
                    name: p.name,
                    basePrice: p.price * 0.7, // 30% margin avg
                    sellingPrice: p.price,
                    stock: randomInt(10, 100), // Random stock
                    minStock: 10,
                    sku: `${m.name.substring(0, 3).toUpperCase()}-${randomInt(100, 999)}`,
                    categoryId: catMap[p.cat],
                    description: `Description for ${p.name}`
                }
            });
            createdProducts.push(product);
        }

        // 7. Create Random Transactions (Last 30 Days)
        const numTrans = randomInt(20, 50); // 20-50 transactions per merchant
        console.log(`   + Generating ${numTrans} dummy transactions...`);

        const startDate = new Date();
        startDate.setDate(startDate.getDate() - 30);
        const endDate = new Date();

        for (let i = 0; i < numTrans; i++) {
            const numItems = randomInt(1, 4);
            const selectedProducts = [];
            let total = 0;
            let itemsToCreate = [];

            for (let j = 0; j < numItems; j++) {
                const prod = random(createdProducts);
                const qty = randomInt(1, 3);
                total += prod.sellingPrice * qty;
                itemsToCreate.push({
                    productId: prod.id,
                    quantity: qty,
                    price: prod.sellingPrice
                });
            }

            const tDate = randomDate(startDate, endDate);

            await prisma.transaction.create({
                data: {
                    id: crypto.randomUUID(), // Manually generate ID to be safe
                    tenantId: tenant.id,
                    storeId: store.id,
                    totalAmount: total,
                    paymentMethod: random(['CASH', 'QRIS', 'T_PAY']),
                    amountPaid: total,
                    change: 0,
                    orderStatus: 'COMPLETED',
                    paymentStatus: 'PAID',
                    fulfillmentType: random(['DINE_IN', 'PICKUP']),
                    occurredAt: tDate,

                    transactionItems: {
                        create: itemsToCreate
                    }
                }
            });
        }
        console.log(`   ✅ Done with ${m.name}`);
    }

    console.log("\n✅ ALL SEEDING COMPLETED!");
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
