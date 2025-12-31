const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    const blankResult = await prisma.store.updateMany({
        where: { waNumber: '' },
        data: { waNumber: null }
    });
    if (blankResult.count) {
        console.log(`Cleared blank waNumber: ${blankResult.count}`);
    }

    const dupGroups = await prisma.store.groupBy({
        by: ['waNumber'],
        where: { waNumber: { not: null } },
        _count: { waNumber: true },
        having: { waNumber: { _count: { gt: 1 } } }
    });

    console.log(`Duplicate groups: ${dupGroups.length}`);

    let cleared = 0;
    for (const g of dupGroups) {
        const waNumber = g.waNumber;
        if (!waNumber) continue;

        const stores = await prisma.store.findMany({
            where: { waNumber },
            select: { id: true, createdAt: true, tenantId: true, name: true },
            orderBy: { createdAt: 'asc' }
        });

        if (stores.length <= 1) continue;

        const keep = stores[0];
        const toClear = stores.slice(1);

        const res = await prisma.store.updateMany({
            where: { id: { in: toClear.map((s) => s.id) } },
            data: { waNumber: null }
        });

        cleared += res.count;
        console.log(
            `waNumber=${waNumber} keep=${keep.id} cleared=${res.count} (${toClear.map((s) => s.id).join(',')})`
        );
    }

    console.log(`Total cleared duplicates: ${cleared}`);
}

main()
    .catch((e) => {
        console.error(e);
        process.exitCode = 1;
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
