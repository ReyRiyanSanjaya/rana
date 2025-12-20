const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt');

async function main() {
    console.log("🔒 Fixing Passwords...");

    // Create a real hash for '123456'
    // Cost factor 10 is standard
    const hashedPassword = await bcrypt.hash('123456', 10);

    console.log(`Generated Hash for '123456': ${hashedPassword}`);

    // Update ALL users to have this password
    const result = await prisma.user.updateMany({
        data: {
            passwordHash: hashedPassword
        }
    });

    console.log(`✅ Updated ${result.count} users to password '123456'`);
}

main()
    .catch(e => console.error(e))
    .finally(async () => await prisma.$disconnect());
