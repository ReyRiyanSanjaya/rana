const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const DIGITAL_PRODUCTS = [
    // Pulsa Telkomsel
    { sku: 'P5', name: 'Telkomsel 5.000', price: 5250, sellingPrice: 7000, category: 'pulsa', brand: 'Telkomsel', isPromo: false },
    { sku: 'P10', name: 'Telkomsel 10.000', price: 10200, sellingPrice: 12000, category: 'pulsa', brand: 'Telkomsel', isPromo: false },
    { sku: 'P25', name: 'Telkomsel 25.000', price: 24900, sellingPrice: 27000, category: 'pulsa', brand: 'Telkomsel', isPromo: true },
    { sku: 'P50', name: 'Telkomsel 50.000', price: 49500, sellingPrice: 52000, category: 'pulsa', brand: 'Telkomsel', isPromo: true },
    { sku: 'P100', name: 'Telkomsel 100.000', price: 98500, sellingPrice: 102000, category: 'pulsa', brand: 'Telkomsel', isPromo: false },

    // Pulsa Indosat
    { sku: 'I5', name: 'Indosat 5.000', price: 5800, sellingPrice: 7500, category: 'pulsa', brand: 'Indosat', isPromo: false },
    { sku: 'I10', name: 'Indosat 10.000', price: 10800, sellingPrice: 13000, category: 'pulsa', brand: 'Indosat', isPromo: false },

    // PLN
    { sku: 'PLN20', name: 'Token PLN 20.000', price: 20500, sellingPrice: 23000, category: 'pln', brand: 'PLN', isPromo: false },
    { sku: 'PLN50', name: 'Token PLN 50.000', price: 50500, sellingPrice: 53000, category: 'pln', brand: 'PLN', isPromo: false },
    { sku: 'PLN100', name: 'Token PLN 100.000', price: 100500, sellingPrice: 103000, category: 'pln', brand: 'PLN', isPromo: false },
    { sku: 'PLN200', name: 'Token PLN 200.000', price: 200500, sellingPrice: 203000, category: 'pln', brand: 'PLN', isPromo: false },

    // Games
    { sku: 'FF70', name: 'Free Fire 70 Diamonds', price: 9500, sellingPrice: 11000, category: 'game', brand: 'Free Fire', isPromo: true },
    { sku: 'FF140', name: 'Free Fire 140 Diamonds', price: 19000, sellingPrice: 22000, category: 'game', brand: 'Free Fire', isPromo: false },
    { sku: 'ML86', name: 'Mobile Legends 86 Diamonds', price: 22000, sellingPrice: 25000, category: 'game', brand: 'Mobile Legends', isPromo: false },
];

async function main() {
    console.log('Seeding Digital Products...');

    for (const product of DIGITAL_PRODUCTS) {
        await prisma.digitalProduct.upsert({
            where: { sku: product.sku },
            update: product,
            create: product,
        });
    }

    console.log('Seeding completed.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
