const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

const getPackages = async (req, res) => {
    try {
        const packages = await prisma.subscriptionPackage.findMany({
            where: { isActive: true },
            orderBy: { price: 'asc' }
        });

        // Seed if empty (for demo purposes)
        if (packages.length === 0) {
            const defaultPackages = [
                { name: 'Paket Bulanan', price: 49000, durationDays: 30, description: 'Billed Monthly' },
                { name: 'Paket 6 Bulan', price: 250000, durationDays: 180, description: 'Save 15%' },
                { name: 'Paket Tahunan', price: 450000, durationDays: 365, description: 'Best Value (Save 25%)' }
            ];
            for (const pkg of defaultPackages) {
                await prisma.subscriptionPackage.create({ data: pkg });
            }
            return successResponse(res, defaultPackages, "Packages (Seeded)");
        }

        return successResponse(res, packages, "Subscription Packages");
    } catch (error) {
        return errorResponse(res, "Failed to fetch packages", 500, error);
    }
};

module.exports = {
    getPackages
};
