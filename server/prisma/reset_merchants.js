const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const emails = ['kopisenja@demo.com', 'berkah@demo.com', 'laundry@demo.com'];

    console.log("Cleaning up incomplete merchants...");

    for (const email of emails) {
        const user = await prisma.user.findUnique({ where: { email } });
        if (user) {
            console.log(`Deleting data for ${email}...`);
            // We need to delete Tenant, which should cascade or we delete manually.
            // Let's rely on Tenant deletion if possible, or delete Store/User first.

            // Delete Transactions first
            await prisma.transaction.deleteMany({ where: { tenantId: user.tenantId } });

            // Delete Products
            await prisma.product.deleteMany({ where: { tenantId: user.tenantId } });

            // Delete Categories
            await prisma.category.deleteMany({ where: { tenantId: user.tenantId } });

            // Delete User
            await prisma.user.delete({ where: { id: user.id } });

            // Delete Store
            await prisma.store.deleteMany({ where: { tenantId: user.tenantId } });

            // Delete Tenant
            await prisma.tenant.delete({ where: { id: user.tenantId } });

            console.log(`Deleted ${email} data.`);
        }
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
