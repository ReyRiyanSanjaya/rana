const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Seeding App Menus...');

    const menus = [
        { key: 'POS', label: 'Kasir', icon: 'POS', route: '/pos', order: 1 },
        { key: 'PRODUCT', label: 'Produk', icon: 'PRODUCT', route: '/products', order: 2 },
        { key: 'REPORT', label: 'Laporan', icon: 'REPORT', route: '/reports', order: 3 },
        { key: 'KULAKAN', label: 'Kulakan', icon: 'KULAKAN', route: '/kulakan', order: 4 },
        { key: 'ADS', label: 'Iklan', icon: 'ADS', route: '/marketing', order: 5 },
        { key: 'SUPPORT', label: 'Bantuan', icon: 'SUPPORT', route: '/support', order: 6 },
        { key: 'SETTINGS', label: 'Setting', icon: 'SETTINGS', route: '/settings', order: 7 },
        { key: 'PPOB', label: 'PPOB', icon: 'PPOB', route: '/ppob', order: 8 },
    ];

    for (const menu of menus) {
        await prisma.appMenu.upsert({
            where: { key: menu.key },
            update: {
                label: menu.label,
                route: menu.route,
                order: menu.order,
                icon: menu.icon,
                isActive: true
            },
            create: {
                key: menu.key,
                label: menu.label,
                icon: menu.icon,
                route: menu.route,
                order: menu.order,
                isActive: true
            }
        });
    }

    console.log(`✅ Seeded ${menus.length} menu items.`);
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
