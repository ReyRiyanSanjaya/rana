const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log("🔍 Testing getMerchants query...");
    try {
        const merchants = await prisma.store.findMany({
            include: {
                tenant: {
                    select: {
                        name: true
                    }
                },
                users: { // Does Store have users relation?
                    where: { role: 'OWNER' },
                    take: 1,
                    select: { email: true, name: true }
                }
            },
            take: 5
        });

        console.log("✅ Query Successful!");
        console.log(JSON.stringify(merchants, null, 2));
    } catch (e) {
        console.error("❌ Query Failed:", e);
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
