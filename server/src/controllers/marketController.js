const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// Haversine Formula (Earth Radius = 6371 km)
// We will use Raw SQL for performance if dataset grows, 
// but for MVP Prisma.raw or JS filter is fine. 
// Let's use Prisma $queryRaw for efficiency.

const getNearbyStores = async (req, res) => {
    try {
        const { lat, long, radius = 5 } = req.query; // Radius in km

        if (!lat || !long) {
            return errorResponse(res, "Latitude and Longitude required", 400);
        }

        const userLat = parseFloat(lat);
        const userLong = parseFloat(long);

        // Raw SQL for Distance Calculation (Postgres)
        // Note: Prisma returns BigInt for some counts, handled by JSON.stringify usually.
        // We select stores and distance
        const stores = await prisma.$queryRaw`
            SELECT id, name, address, "category", "latitude", "longitude",
            (
                6371 * acos(
                    cos(radians(${userLat})) * cos(radians("latitude")) *
                    cos(radians("longitude") - radians(${userLong})) +
                    sin(radians(${userLat})) * sin(radians("latitude"))
                )
            ) AS distance
            FROM "Store"
            WHERE "latitude" IS NOT NULL AND "longitude" IS NOT NULL
            AND (
                6371 * acos(
                    cos(radians(${userLat})) * cos(radians("latitude")) *
                    cos(radians("longitude") - radians(${userLong})) +
                    sin(radians(${userLat})) * sin(radians("latitude"))
                )
            ) < ${parseFloat(radius)}
            ORDER BY distance ASC
            LIMIT 20;
        `;

        // Fetch products for these stores (Top 3 per store for display)
        // This is a "N+1" problem potential, but for 20 stores it's acceptable.
        // We will map it in JS.
        const result = [];
        for (const store of stores) {
            const products = await prisma.product.findMany({
                where: { storeId: store.id, isDeleted: false },
                take: 3,
                select: { id: true, name: true, sellingPrice: true }
            });
            result.push({
                ...store,
                distance: store.distance, // Ensure it's passed
                products
            });
        }

        return successResponse(res, result);

    } catch (error) {
        console.error("Nearby Error:", error);
        return errorResponse(res, "Failed to fetch nearby stores", 500, error);
    }
};

module.exports = { getNearbyStores };
