const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Seeding Revenue Data...');

    // Clear old logs if testing?
    // await prisma.platformRevenue.deleteMany({});

    const revenueSources = ['SUBSCRIPTION', 'WITHDRAWAL_FEE'];
    const descriptions = {
        'SUBSCRIPTION': 'Monthly Subscription Premium',
        'WITHDRAWAL_FEE': 'Withdrawal Fee'
    };
    const amounts = {
        'SUBSCRIPTION': 399000,
        'WITHDRAWAL_FEE': 5000
    };

    const monthsBack = 6;
    const now = new Date();

    for (let i = 0; i < monthsBack; i++) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 15);

        // Random number of transactions per month
        const count = Math.floor(Math.random() * 10) + 5;

        for (let j = 0; j < count; j++) {
            const source = revenueSources[Math.floor(Math.random() * revenueSources.length)];
            const amount = source === 'WITHDRAWAL_FEE' ? (Math.random() * 10000 + 2000) : amounts[source];

            await prisma.platformRevenue.create({
                data: {
                    amount: Math.round(amount),
                    source: source,
                    description: descriptions[source],
                    createdAt: date
                }
            });
        }
        console.log(`Seeded ${count} logs for month offset -${i}`);
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
