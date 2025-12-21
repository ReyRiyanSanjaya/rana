const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding Real Data for merchant@rana.com...');

    // 1. Get Tenant and Store
    const tenant = await prisma.tenant.findFirst({ where: { name: 'Kopi Kenangan Demo' } });
    if (!tenant) {
        console.error('❌ Tenant "Kopi Kenangan Demo" not found. Run "npx prisma db seed" first.');
        return;
    }

    const store = await prisma.store.findFirst({ where: { tenantId: tenant.id } });
    if (!store) {
        console.error('❌ Default Store not found.');
        return;
    }

    // 2. Create Categories
    const categoriesData = [
        { name: 'Kopi Kekinian' },
        { name: 'Non-Coffee' },
        { name: 'Makanan Berat' },
        { name: 'Camilan' },
        { name: 'Minuman Botol' }
    ];

    const categories = {};
    for (const cat of categoriesData) {
        const c = await prisma.category.create({
            data: {
                tenantId: tenant.id,
                name: cat.name
            }
        });
        categories[cat.name] = c.id;
        console.log(`✅ Category: ${cat.name}`);
    }

    // 3. Create Products
    const productsData = [
        { name: 'Kopi Kenangan Mantan', price: 18000, cost: 8000, stock: 100, cat: 'Kopi Kekinian' },
        { name: 'Kopi Susu Gula Aren', price: 22000, cost: 9000, stock: 80, cat: 'Kopi Kekinian' },
        { name: 'Americano', price: 15000, cost: 5000, stock: 50, cat: 'Kopi Kekinian' },
        { name: 'Hazelnut Latte', price: 24000, cost: 10000, stock: 60, cat: 'Kopi Kekinian' },
        
        { name: 'Chocolate Shake', price: 20000, cost: 8000, stock: 40, cat: 'Non-Coffee' },
        { name: 'Matcha Latte', price: 25000, cost: 11000, stock: 45, cat: 'Non-Coffee' },
        { name: 'Thai Tea', price: 18000, cost: 7000, stock: 70, cat: 'Non-Coffee' },
        
        { name: 'Nasi Goreng Spesial', price: 35000, cost: 15000, stock: 20, cat: 'Makanan Berat' },
        { name: 'Mie Goreng Telur', price: 25000, cost: 10000, stock: 25, cat: 'Makanan Berat' },
        { name: 'Ayam Geprek Sambal Matah', price: 30000, cost: 14000, stock: 30, cat: 'Makanan Berat' },
        
        { name: 'Roti Bakar Coklat Keju', price: 15000, cost: 6000, stock: 15, cat: 'Camilan' },
        { name: 'Kentang Goreng', price: 12000, cost: 5000, stock: 50, cat: 'Camilan' },
        { name: 'Pisang Goreng Madu', price: 14000, cost: 5000, stock: 20, cat: 'Camilan' },
        
        { name: 'Air Mineral 600ml', price: 5000, cost: 2000, stock: 100, cat: 'Minuman Botol' },
        { name: 'Teh Botol Sosro', price: 7000, cost: 3500, stock: 80, cat: 'Minuman Botol' }
    ];

    const products = [];

    for (const p of productsData) {
        const product = await prisma.product.create({
            data: {
                tenantId: tenant.id,
                storeId: store.id,
                categoryId: categories[p.cat],
                name: p.name,
                description: `Deskripsi lezat untuk ${p.name}`,
                basePrice: p.cost,
                sellingPrice: p.price,
                stock: p.stock,
                sku: `SKU-${Math.floor(Math.random() * 10000)}`,
                isActive: true
            }
        });
        
        // Also create Stock record
        await prisma.stock.create({
            data: {
                storeId: store.id,
                productId: product.id,
                quantity: p.stock
            }
        });

        products.push(product);
        console.log(`✅ Product: ${p.name}`);
    }

    // 4. Create Fake Transactions (Past 7 Days)
    console.log('⏳ Generating Sales History...');
    const paymentMethods = ['CASH', 'QRIS', 'TRANSFER'];
    
    for (let i = 0; i < 50; i++) {
        const randomProduct = products[Math.floor(Math.random() * products.length)];
        const qty = Math.floor(Math.random() * 3) + 1;
        const total = randomProduct.sellingPrice * qty;
        
        // Random date within last 7 days
        const date = new Date();
        date.setDate(date.getDate() - Math.floor(Math.random() * 7));
        date.setHours(Math.floor(Math.random() * 14) + 8); // 08:00 - 22:00

        const txn = await prisma.transaction.create({
            data: {
                tenantId: tenant.id,
                storeId: store.id,
                totalAmount: total,
                paymentMethod: paymentMethods[Math.floor(Math.random() * paymentMethods.length)],
                amountPaid: total,
                change: 0,
                orderStatus: 'COMPLETED',
                paymentStatus: 'PAID',
                fulfillmentType: 'DINE_IN',
                occurredAt: date,
                
                transactionItems: {
                    create: {
                         productId: randomProduct.id,
                         quantity: qty,
                         price: randomProduct.sellingPrice
                    }
                },
                
                // Update DailySalesSummary
            }
        });
        
        // Simplification: We rely on triggers or manual summary updates? 
        // Schema has DailySalesSummary. Let's update it manually for graph to show up.
        const dateKey = new Date(date.toDateString()); // Strip time
        
        const summary = await prisma.dailySalesSummary.findUnique({
             where: {
                 storeId_date: {
                     storeId: store.id,
                     date: dateKey
                 }
             }
        });

        if (summary) {
            await prisma.dailySalesSummary.update({
                where: { id: summary.id },
                data: {
                    totalSales: { increment: total },
                    totalTrans: { increment: 1 }
                }
            });
        } else {
            await prisma.dailySalesSummary.create({
                data: {
                    tenantId: tenant.id,
                    storeId: store.id,
                    date: dateKey,
                    totalSales: total,
                    totalTrans: 1
                }
            });
        }
    }
    console.log('✅ Created 50 Fake Transactions');

    // 5. Create some Expenses (Cashflow)
    await prisma.cashflowLog.create({
        data: {
            tenantId: tenant.id,
            storeId: store.id,
            amount: 500000,
            type: 'CASH_OUT',
            category: 'EXPENSE_PURCHASE',
            description: 'Belanja Bahan Baku Pasar',
            occurredAt: new Date()
        }
    });

    await prisma.cashflowLog.create({
         data: {
             tenantId: tenant.id,
             storeId: store.id,
             amount: 150000,
             type: 'CASH_OUT',
             category: 'EXPENSE_OPERATIONAL',
             description: 'Bayar Listrik Token',
             occurredAt: new Date(new Date().setDate(new Date().getDate() - 2))
         }
     });
     console.log('✅ Created Cashflow Logs');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
