const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function verify() {
    const email = 'merchant@rana.com';
    const password = 'password123';

    console.log(`Checking user: ${email}`);
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
        console.log("❌ User NOT FOUND");
        return;
    }
    console.log("✅ User FOUND:", user.id, user.role);
    console.log("Stored Hash:", user.passwordHash);

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (valid) {
        console.log("✅ Password MATCHES");
    } else {
        console.log("❌ Password DOES NOT MATCH");
        // Debug: what if we hash it now?
        const newHash = await bcrypt.hash(password, 10);
        console.log("Expected Hash for 'password123':", newHash);
    }
}

verify()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
