const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// =======================
// PRODUCT MANAGEMENT
// =======================

// Get all active wholesale products (For Mobile App)
const getProducts = async (req, res) => {
    try {
        const { category, search } = req.query;

        const products = await prisma.wholesaleProduct.findMany({
            where: {
                isActive: true,
                categoryId: category && category !== 'Semua' ? category : undefined,
                name: search ? { contains: search, mode: 'insensitive' } : undefined
            },
            include: { category: true },
            orderBy: { name: 'asc' }
        });
        return successResponse(res, products, "Wholesale products retrieved");
    } catch (error) {
        return errorResponse(res, "Failed to fetch wholesale products", 500, error);
    }
};

// Create Product (Admin)
const createProduct = async (req, res) => {
    try {
        const { name, categoryId, price, stock, supplierName, imageUrl, description } = req.body;

        const product = await prisma.wholesaleProduct.create({
            data: {
                name,
                categoryId,
                price: parseFloat(price),
                stock: parseInt(stock),
                supplierName,
                imageUrl,
                description
            }
        });
        return successResponse(res, product, "Product created", 201);
    } catch (error) {
        return errorResponse(res, "Failed to create wholesale product", 500, error);
    }
};

// =======================
// ORDER MANAGEMENT
// =======================

// Create Order (Merchant buys items)
const createOrder = async (req, res) => {
    try {
        const { tenantId, items, paymentMethod, shippingAddress, shippingCost } = req.body;
        // items: [{ productId, quantity, price }]

        // Calculate total
        const totalAmount = items.reduce((sum, item) => sum + (item.price * item.quantity), 0) + (shippingCost || 0);

        const result = await prisma.$transaction(async (tx) => {
            // Create Order
            const order = await tx.wholesaleOrder.create({
                data: {
                    tenantId, // Which merchant is buying
                    totalAmount,
                    status: 'PENDING',
                    paymentMethod,
                    shippingAddress,
                    shippingCost: parseFloat(shippingCost || 0),
                    items: {
                        create: items.map(i => ({
                            productId: i.productId,
                            quantity: i.quantity,
                            price: i.price
                        }))
                    }
                }
            });

            // Decrease Stock (Optional: usually reserved first, but let's deduct now)
            for (const item of items) {
                await tx.wholesaleProduct.update({
                    where: { id: item.productId },
                    data: { stock: { decrement: item.quantity }, soldCount: { increment: item.quantity } }
                });
            }

            return order;
        });

        return successResponse(res, result, "Order created successfully", 201);
    } catch (error) {
        return errorResponse(res, "Failed to place order", 500, error);
    }
};

// Get Orders (Admin or Merchant)
const getOrders = async (req, res) => {
    try {
        const { tenantId, status } = req.query; // If tenantId provided, filter by it (Merchant View). Else Admin view.

        const orders = await prisma.wholesaleOrder.findMany({
            where: {
                tenantId: tenantId || undefined,
                status: status || undefined
            },
            include: {
                items: { include: { product: true } },
                tenant: { select: { name: true } } // Show who bought it
            },
            orderBy: { createdAt: 'desc' }
        });

        return successResponse(res, orders, "Orders retrieved");
    } catch (error) {
        return errorResponse(res, "Failed to fetch orders", 500, error);
    }
};

// Update Order Status (Admin)
const updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // PAID, SHIPPED, etc.

        const order = await prisma.wholesaleOrder.update({
            where: { id },
            data: { status }
        });

        // TODO: Notification logic here

        return successResponse(res, order, "Order status updated");
    } catch (error) {
        return errorResponse(res, "Failed to update order", 500, error);
    }
};

const getCategories = async (req, res) => {
    try {
        const cats = await prisma.wholesaleCategory.findMany({ where: { isActive: true } });
        return successResponse(res, cats, "Categories retrieved");
    } catch (error) {
        return errorResponse(res, "Failed fetch categories", 500, error);
    }
};

// Admin: Create Category
const createCategory = async (req, res) => {
    try {
        const { name } = req.body;
        const cat = await prisma.wholesaleCategory.create({ data: { name } });
        return successResponse(res, cat, "Category created", 201);
    } catch (error) {
        return errorResponse(res, "Failed create category", 500, error);
    }
}

module.exports = {
    getProducts,
    createProduct,
    createOrder,
    getOrders,
    updateOrderStatus,
    getCategories,
    createCategory
};
