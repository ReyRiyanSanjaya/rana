const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding dummy withdrawals...');

  // 1. Find or create a dummy tenant and store
  let tenant = await prisma.tenant.findFirst();
  if (!tenant) {
    tenant = await prisma.tenant.create({
      data: {
        name: 'Demo Tenant',
        plan: 'PREMIUM',
        subscriptionStatus: 'ACTIVE'
      }
    });
    console.log('Created Demo Tenant');
  }

  let store = await prisma.store.findFirst({ where: { tenantId: tenant.id } });
  if (!store) {
    store = await prisma.store.create({
      data: {
        tenantId: tenant.id,
        name: 'Demo Store',
        location: 'Jakarta',
        balance: 5000000
      }
    });
    console.log('Created Demo Store');
  }

  // 2. Create Withdrawals
  // Pending
  await prisma.withdrawal.create({
    data: {
      storeId: store.id,
      amount: 150000,
      bankName: 'BCA',
      accountNumber: '1234567890',
      status: 'PENDING'
    }
  });

  // Approved
  await prisma.withdrawal.create({
    data: {
      storeId: store.id,
      amount: 500000,
      bankName: 'Mandiri',
      accountNumber: '0987654321',
      status: 'APPROVED',
      fee: 5000,
      netAmount: 495000
    }
  });

  // Rejected
  await prisma.withdrawal.create({
    data: {
      storeId: store.id,
      amount: 1000000,
      bankName: 'BRI',
      accountNumber: '1122334455',
      status: 'REJECTED'
    }
  });

  console.log('Seeding completed. Added 3 withdrawals (Pending, Approved, Rejected).');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
