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

            const aggs = await prisma.review.aggregate({
                where: { product: { storeId: store.id } },
                _avg: { rating: true },
                _count: { rating: true }
            });

            result.push({
                ...store,
                distance: store.distance,
                rating: aggs._avg.rating || 0,
                reviewCount: aggs._count.rating || 0,
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
                store: { select: { name: true, location: true, latitude: true, longitude: true } },
                items: {
                    include: { product: { select: { name: true, sellingPrice: true, imageUrl: true, description: true } } }
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
                imageUrl: true,
                bannerUrl: true,
                description: true,
                openingHours: true
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
                originalPrice: true,
                imageUrl: true,
                description: true,
                averageRating: true, 
                reviewCount: true,
                category: { select: { name: true } }
            },
            orderBy: { name: 'asc' },
            take
        });

        // Extract unique categories
        const categories = [...new Set(products
            .map(p => p.category?.name)
            .filter(Boolean))];

        return successResponse(res, { store, products, categories });
    } catch (error) {
        return errorResponse(res, "Failed to fetch store catalog", 500, error);
    }
};

const getStoreReviews = async (req, res) => {
    try {
        const { id } = req.params;
        const { page = 1, limit = 10 } = req.query;

        const reviews = await prisma.review.findMany({
            where: { 
                product: { storeId: id }
            },
            orderBy: { createdAt: 'desc' },
            take: parseInt(limit),
            skip: (parseInt(page) - 1) * parseInt(limit),
            include: {
                product: {
                    select: { name: true, imageUrl: true }
                }
            }
        });
        
        const aggs = await prisma.review.aggregate({
            where: { product: { storeId: id } },
            _avg: { rating: true },
            _count: { rating: true }
        });

        return successResponse(res, {
            reviews,
            stats: {
                averageRating: aggs._avg.rating || 0,
                totalReviews: aggs._count.rating || 0
            }
        });
    } catch (error) {
        return errorResponse(res, "Get store reviews failed", 500, error);
    }
};

const searchGlobal = async (req, res) => {
    try {
        const { q, category, sort, lat, long } = req.query;
        
        const whereClause = {
            isActive: true,
            store: { isActive: true } // Ensure store is active
        };

        if (q) {
            whereClause.name = { contains: q, mode: 'insensitive' };
        }

        // Note: Category in Product is tenant-specific relation, but we can also filter by Store category if needed.
        // For now, let's assume 'category' param refers to Store Category (e.g. Food, Pharmacy)
        if (category && category !== 'Semua') {
            whereClause.store = { 
                ...whereClause.store,
                category: { equals: category, mode: 'insensitive' }
            };
        }

        let orderBy = {};
        if (sort === 'price_asc') orderBy = { sellingPrice: 'asc' };
        else if (sort === 'price_desc') orderBy = { sellingPrice: 'desc' };
        else if (sort === 'rating_desc') orderBy = { averageRating: 'desc' };
        else orderBy = { name: 'asc' };

        const products = await prisma.product.findMany({
            where: whereClause,
            take: 50,
            select: {
                id: true,
                name: true,
                sellingPrice: true,
                imageUrl: true,
                description: true,
                averageRating: true,
                reviewCount: true,
                storeId: true,
                store: {
                    select: {
                        name: true,
                        latitude: true,
                        longitude: true,
                        location: true,
                        category: true
                    }
                }
            },
            orderBy
        });

        // If lat/long provided, calculate distance
        let results = products.map(p => {
            let dist = null;
            if (lat && long && p.store.latitude && p.store.longitude) {
                // Haversine approx
                const R = 6371; 
                const dLat = (p.store.latitude - lat) * Math.PI / 180;
                const dLon = (p.store.longitude - long) * Math.PI / 180;
                const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                        Math.cos(lat * Math.PI / 180) * Math.cos(p.store.latitude * Math.PI / 180) * 
                        Math.sin(dLon/2) * Math.sin(dLon/2);
                const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                dist = R * c;
            }
            return { ...p, distance: dist, category: p.store.category };
        });

        if (sort === 'distance' && lat && long) {
            results.sort((a, b) => (a.distance || 99999) - (b.distance || 99999));
        }

        return successResponse(res, results);
    } catch (error) {
        return errorResponse(res, "Search failed", 500, error);
    }
};

const toggleFavorite = async (req, res) => {
    try {
        const { phone, productId } = req.body;
        if (!phone || !productId) return errorResponse(res, "Phone and Product ID required", 400);

        const existing = await prisma.favorite.findUnique({
            where: { phone_productId: { phone, productId } }
        });

        if (existing) {
            await prisma.favorite.delete({ where: { id: existing.id } });
            return successResponse(res, { isFavorite: false }, "Removed from favorites");
        } else {
            await prisma.favorite.create({
                data: { phone, productId }
            });
            return successResponse(res, { isFavorite: true }, "Added to favorites");
        }
    } catch (error) {
        return errorResponse(res, "Toggle favorite failed", 500, error);
    }
};

const getFavorites = async (req, res) => {
    try {
        const { phone } = req.query;
        if (!phone) return errorResponse(res, "Phone required", 400);

        const favs = await prisma.favorite.findMany({
            where: { phone },
            include: {
                product: {
                    select: {
                        id: true,
                        name: true,
                        sellingPrice: true,
                        imageUrl: true,
                        storeId: true,
                        store: { select: { name: true } }
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return successResponse(res, favs.map(f => f.product));
    } catch (error) {
        return errorResponse(res, "Fetch favorites failed", 500, error);
    }
};

const addReview = async (req, res) => {
    try {
        const { rating, comment, userName } = req.body;
        const productId = req.params.id || req.body.productId;

        if (!productId || !rating) return errorResponse(res, "Product ID and Rating required", 400);

        const review = await prisma.review.create({
            data: { 
                productId, 
                rating: parseInt(rating), 
                comment, 
                userName: userName || 'Pengguna'
            }
        });

        // Update Product Stats
        const aggs = await prisma.review.aggregate({
            where: { productId },
            _avg: { rating: true },
            _count: { rating: true }
        });

        await prisma.product.update({
            where: { id: productId },
            data: { 
                averageRating: aggs._avg.rating || 0,
                reviewCount: aggs._count.rating || 0
            }
        });

        return successResponse(res, review, "Review added");
    } catch (error) {
        return errorResponse(res, "Add review failed", 500, error);
    }
};

const getProductReviews = async (req, res) => {
    try {
        const { id } = req.params;
        const { page = 1, limit = 10, sort = 'newest' } = req.query;
        
        let orderBy = { createdAt: 'desc' };
        if (sort === 'oldest') orderBy = { createdAt: 'asc' };
        if (sort === 'highest') orderBy = { rating: 'desc' };
        if (sort === 'lowest') orderBy = { rating: 'asc' };

        const reviews = await prisma.review.findMany({
            where: { productId: id },
            orderBy,
            take: parseInt(limit),
            skip: (parseInt(page) - 1) * parseInt(limit)
        });

        return successResponse(res, reviews);
    } catch (error) {
        return errorResponse(res, "Fetch reviews failed", 500, error);
    }
};

module.exports = { 
    getNearbyStores, 
    getActiveFlashSales, 
    getStoreCatalog,
    searchGlobal,
    toggleFavorite,
    getFavorites,
    addReview,
    getProductReviews,
    getStoreReviews
};
