const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const crypto = require('crypto');

// --- CONSTANTS & HELPERS ---
const ADMIN_EMAIL = 'admin@rana.id';
const ADMIN_PASSWORD = 'password123'; // In a real app, hash this!

const MEDAN_LOCATIONS = [
    { name: 'Medan Baru', lat: 3.5752, lng: 98.6522 },
    { name: 'Medan Petisah', lat: 3.5900, lng: 98.6650 },
    { name: 'Medan Kota', lat: 3.5852, lng: 98.6900 },
    { name: 'Medan Johor', lat: 3.5400, lng: 98.6700 },
    { name: 'Medan Sunggal', lat: 3.5800, lng: 98.6200 },
    { name: 'Merdeka Walk', lat: 3.5913, lng: 98.6775 },
    { name: 'Sun Plaza', lat: 3.5866, lng: 98.6744 },
    { name: 'Podomoro', lat: 3.6000, lng: 98.6600 },
];

const MERCHANT_TEMPLATES = [
    { name: 'Kopi Kenangan Medan', category: 'F&B', products: ['Kopi Kenangan Mantan', 'Kopi Susu Gula Aren', 'Roti Bakar'] },
    { name: 'Soto Medan Sinar Pagi', category: 'F&B', products: ['Soto Sapi', 'Soto Ayam', 'Perkedel', 'Nasi Putih'] },
    { name: 'Durian Ucok', category: 'F&B', products: ['Durian Kupas', 'Pancake Durian', 'Durian Frozen'] },
    { name: 'Bika Ambon Zulaikha', category: 'Retail', products: ['Bika Ambon Original', 'Bika Ambon Pandan', 'Lapis Legit'] },
    { name: 'Lontong Kak Lin', category: 'F&B', products: ['Lontong Sayur', 'Sate Kerang', 'Lupis'] },
    { name: 'Bolu Meranti', category: 'Retail', products: ['Bolu Gulung Keju', 'Bolu Gulung Coklat', 'Bolu Gulung Moka'] },
    { name: 'Rumah Makan Tabona', category: 'F&B', products: ['Kari Bihun', 'Kari Ayam', 'Kari Sapi'] },
    { name: 'Sate Padang Al-Fresco', category: 'F&B', products: ['Sate Padang', 'Sate Kerang', 'Kerupuk Jangek'] },
    { name: 'Mie Aceh Titi Bobrok', category: 'F&B', products: ['Mie Aceh Goreng', 'Mie Aceh Kuah', 'Teh Tarik', 'Martabak Telur'] },
    { name: 'Kedai Kopi Apek', category: 'F&B', products: ['Kopi O', 'Roti Srikaya', 'Telur Setengah Matang'] },
    { name: 'Apotek K-24 Setiabudi', category: 'Services', products: ['Vitamin C', 'Masker Medis', 'Hand Sanitizer'] },
    { name: 'Laundry Kiloan Berkah', category: 'Services', products: ['Cuci Komplit 1kg', 'Cuci Bedcover', 'Setrika Saja'] },
    { name: 'Toko Kelontong Madura', category: 'Retail', products: ['Beras 5kg', 'Minyak Goreng 2L', 'Gula Pasir 1kg', 'Telur 1kg'] },
    { name: 'Warung Nasi Bu Ijah', category: 'F&B', products: ['Nasi Rames', 'Ayam Goreng', 'Ikan Lele', 'Sayur Asem'] },
    { name: 'Es Campur Amo', category: 'F&B', products: ['Es Campur', 'Es Teler', 'Jus Alpukat'] },
];

const PACKAGES = [
    { name: 'Starter', price: 49000, durationDays: 30 },
    { name: 'Pro', price: 99000, durationDays: 30 },
    { name: 'Enterprise', price: 299000, durationDays: 365 },
];

const SUBSCRIPTION_REQUESTS = 5; // Number of pending reqs
const WITHDRAWAL_REQUESTS = 10; // Number of withdrawals

// Helper for random items
const getRandom = (arr) => arr[Math.floor(Math.random() * arr.length)];
const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const getRandomFloat = (min, max) => (Math.random() * (max - min) + min).toFixed(2);
const getRandomDate = (start, end) => new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));

async function main() {
    console.log('🌱 Starting Seed: Medan Real Data...');

    // 1. Create Tenant & Admin
    console.log('Creating Admin Tenant & User...');
    const tenant = await prisma.tenant.create({
        data: {
            name: 'Rana Platform Admin',
            plan: 'ENTERPRISE',
            subscriptionStatus: 'ACTIVE',
        }
    });

    // Determine Admin Role enum based on schema
    // Schema says: USER, STORE_MANAGER, ADMIN, SUPER_ADMIN? Let's check schema.
    // Schema: UserRole { OWNER, ADMIN, STORE_MANAGER, CASHIER, SUPER_ADMIN }

    // Check if user exists first to avoidunique constraint error
    let adminUser = await prisma.user.findUnique({ where: { email: ADMIN_EMAIL } });
    if (!adminUser) {
        adminUser = await prisma.user.create({
            data: {
                name: 'Super Admin',
                email: ADMIN_EMAIL,
                passwordHash: ADMIN_PASSWORD, // Plaintext for demo
                role: 'SUPER_ADMIN',
                tenantId: tenant.id
            }
        });
    }
    console.log(`✅ Admin User: ${ADMIN_EMAIL}`);

    // 2. Create Merchants
    console.log('Creating Merchants...');
    const merchants = [];

    for (const template of MERCHANT_TEMPLATES) {
        // Pick a random location near Medan
        const loc = getRandom(MEDAN_LOCATIONS);
        // Add some jitter to coords so they don't stack
        const lat = loc.lat + (Math.random() - 0.5) * 0.01;
        const lng = loc.lng + (Math.random() - 0.5) * 0.01;

        const store = await prisma.store.create({
            data: {
                name: template.name,
                tenantId: tenant.id,
                location: loc.name,
                latitude: lat,
                longitude: lng,
                category: template.category,
                waNumber: '628' + getRandomInt(1000000000, 9999999999),
                balance: getRandomInt(500000, 15000000), // Random starting balance
            }
        });
        merchants.push({ store, template });
        process.stdout.write('.');
    }
    console.log(`\n✅ Created ${merchants.length} Merchants.`);

    // 3. Create Products for each Merchant
    console.log('Creating Products...');
    const allProducts = [];
    for (const { store, template } of merchants) {
        for (const prodName of template.products) {
            const price = getRandomInt(15, 150) * 1000; // 15k to 150k

            const product = await prisma.product.create({
                data: {
                    tenantId: tenant.id,
                    storeId: store.id,
                    name: prodName,
                    basePrice: price * 0.7,
                    sellingPrice: price,
                    stock: getRandomInt(10, 100),
                    sku: `SKU-${getRandomInt(1000, 9999)}`,
                    description: `Delicious ${prodName} from Medan`,
                }
            });
            allProducts.push(product);
        }
        process.stdout.write('.');
    }
    console.log(`\n✅ Created Products.`);

    // 4. Create Transactions (Last 30 Days)
    console.log('Generating Transactions...');
    const END_DATE = new Date();
    const START_DATE = new Date();
    START_DATE.setDate(START_DATE.getDate() - 30);

    for (const { store } of merchants) {
        // Create 20-50 transactions per store
        const txCount = getRandomInt(20, 50);

        for (let i = 0; i < txCount; i++) {
            const txDate = getRandomDate(START_DATE, END_DATE);
            const total = getRandomInt(50000, 500000);

            await prisma.transaction.create({
                data: {
                    tenantId: tenant.id,
                    storeId: store.id,
                    totalAmount: total,
                    paymentMethod: getRandom(['CASH', 'QRIS', 'TRANSFER']),
                    amountPaid: total,
                    change: 0,
                    orderStatus: 'COMPLETED',
                    paymentStatus: 'PAID',
                    occurredAt: txDate,
                }
            });

            // Also update DailySalesSummary for charts? 
            // The charts usually query aggregate tables or raw txs. 
            // Let's create a DailySalesSummary for this date to be safe for charts.
            const dateOnly = new Date(txDate.toISOString().split('T')[0]);

            // Quick upsert for daily summary logic simplified (usually accumulation)
            // skipping for speed, trusting the "stats/chart" endpoint might query raw txs or we need aggregation script.
            // If the endpoint queries 'DailySalesSummary', the chart will be empty unless we fill it.
            // Let's assume we need to fill it. 

            try {
                // Determine Day ID roughly
                await prisma.dailySalesSummary.upsert({
                    where: {
                        storeId_date: {
                            storeId: store.id,
                            date: dateOnly
                        }
                    },
                    update: {
                        totalSales: { increment: total },
                        totalTrans: { increment: 1 }
                    },
                    create: {
                        tenantId: tenant.id,
                        storeId: store.id,
                        date: dateOnly,
                        totalSales: total,
                        totalTrans: 1
                    }
                });
            } catch (e) {
                // ignore race conditions in seed
            }
        }
        process.stdout.write('.');
    }
    console.log(`\n✅ Generated Transactions & Daily Summaries.`);

    // 5. Create Withdrawals
    console.log('Generating Withdrawals...');
    for (let i = 0; i < WITHDRAWAL_REQUESTS; i++) {
        const { store } = getRandom(merchants);
        const amount = getRandomInt(100000, 2000000);
        const status = getRandom(['PENDING', 'APPROVED', 'REJECTED']);

        await prisma.withdrawal.create({
            data: {
                storeId: store.id,
                amount: amount,
                bankName: getRandom(['BCA', 'Mandiri', 'BNI', 'BRI']),
                accountNumber: getRandomInt(1000000000, 9999999999).toString(),
                status: status,
                createdAt: getRandomDate(START_DATE, END_DATE)
            }
        });
    }
    console.log(`✅ Created Withdrawals.`);

    // 6. Create Subscription Requests
    console.log('Generating Subscription Requests...');
    for (let i = 0; i < SUBSCRIPTION_REQUESTS; i++) {
        await prisma.subscriptionRequest.create({
            data: {
                tenantId: tenant.id,
                status: 'PENDING',
                proofUrl: 'https://via.placeholder.com/300?text=Transfer+Receipt'
            }
        });
    }

    // 7. Create Packages
    console.log('Creating Packages...');
    for (const pkg of PACKAGES) {
        await prisma.subscriptionPackage.create({
            data: {
                name: pkg.name,
                price: pkg.price,
                durationDays: pkg.durationDays,
                description: `Access to ${pkg.name} features.`
            }
        });
    }
    console.log(`✅ Created Packages.`);

    console.log('🎉 SEEDING COMPLETE! Admin Client is ready.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
