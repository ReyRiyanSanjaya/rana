const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

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
            SELECT id, name, "location" AS address, "category", "latitude", "longitude", "imageUrl",
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
                where: { storeId: store.id, isActive: true },
                take: 3,
                select: { id: true, name: true, sellingPrice: true, imageUrl: true, description: true }
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

const getActiveFlashSales = async (req, res) => {
    try {
        const { storeId } = req.query;
        const now = new Date();
        const sales = await prisma.flashSale.findMany({
            where: {
                ...(storeId ? { storeId } : {}),
                status: { in: ['APPROVED', 'ACTIVE'] },
                startAt: { lte: now },
                endAt: { gte: now }
            },
            include: {
                store: { select: { name: true } },
                items: {
                    include: { product: { select: { name: true, sellingPrice: true, imageUrl: true } } }
                }
            },
            orderBy: { startAt: 'asc' }
        });
        return successResponse(res, sales);
    } catch (error) {
        return errorResponse(res, "Failed to fetch flash sales", 500, error);
    }
};

const getStoreCatalog = async (req, res) => {
    try {
        const { id } = req.params;
        if (!id) return errorResponse(res, "Store id required", 400);

        const store = await prisma.store.findUnique({
            where: { id },
            select: {
                id: true,
                name: true,
                location: true,
                category: true,
                latitude: true,
                longitude: true,
                imageUrl: true
            }
        });
        if (!store) return errorResponse(res, "Store not found", 404);

        const { search, limit } = req.query;
        const take = Math.min(parseInt(limit || '60', 10) || 60, 200);

        const products = await prisma.product.findMany({
            where: {
                storeId: id,
                isActive: true,
                ...(search
                    ? {
                          name: {
                              contains: search,
                              mode: 'insensitive'
                          }
                      }
                    : {})
            },
            select: {
                id: true,
                name: true,
                sellingPrice: true,
                imageUrl: true,
                description: true
            },
            orderBy: { name: 'asc' },
            take
        });

        return successResponse(res, { store, products });
    } catch (error) {
        return errorResponse(res, "Failed to fetch store catalog", 500, error);
    }
};

module.exports = { getNearbyStores, getActiveFlashSales, getStoreCatalog };
