const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// List Products (Active Only)
const getProducts = async (req, res) => {
    try {
        const { storeId } = req.user; // Assuming user attached to store, or request query?
        // Let's use user's storeId if available, or query param for flexibility
        // For Owner, they might have multiple stores.

        // Simplified: Fetch all products for the tenant or specific store
        const products = await prisma.product.findMany({
            where: {
                isActive: true,
                // storeId: ... ? If we want to filter by store. Let's list all for now or filter by tenant.
                // tenantId: req.user.tenantId
            },
            include: { category: true },
            orderBy: { name: 'asc' }
        });

        return successResponse(res, products, "Products retrieved successfully");
    } catch (error) {
        return errorResponse(res, "Failed to fetch products", 500, error);
    }
};

// Create Product
const createProduct = async (req, res) => {
    try {
        const { name, sku, basePrice, sellingPrice, stock, minStock, categoryId, category, description } = req.body;

        // Dynamic fetch for demo purposes since auth might be off
        let tenant = await prisma.tenant.findFirst({ where: { name: 'Demo Tenant' } });
        if (!tenant) {
            // [FIX] Self-healing: Create Demo Tenant if missing
            console.log("Demo Tenant missing. Creating...");
            tenant = await prisma.tenant.create({
                data: { name: 'Demo Tenant', plan: 'FREE', subscriptionStatus: 'ACTIVE' }
            });
        }

        // Find demo store
        let demoStore = await prisma.store.findFirst({ where: { tenantId: tenant.id } });
        if (!demoStore) {
            // [FIX] Self-healing: Create Demo Store if missing
            console.log("Demo Store missing. Creating...");
            demoStore = await prisma.store.create({
                data: { tenantId: tenant.id, name: 'Main Store', balance: 0 }
            });
        }

        // [FIX] Handle Category String (Find or Create)
        let finalCategoryId = categoryId;
        if (!finalCategoryId && category) {
            let cat = await prisma.category.findFirst({
                where: { tenantId: tenant.id, name: category }
            });
            if (!cat) {
                cat = await prisma.category.create({
                    data: {
                        tenantId: tenant.id,
                        name: category
                    }
                });
            }
            finalCategoryId = cat.id;
        }

        const product = await prisma.product.create({
            data: {
                name,
                sku,
                basePrice: isNaN(parseFloat(basePrice)) ? 0 : parseFloat(basePrice),
                sellingPrice: isNaN(parseFloat(sellingPrice)) ? 0 : parseFloat(sellingPrice),
                stock: isNaN(parseInt(stock)) ? 0 : parseInt(stock),
                minStock: isNaN(parseInt(minStock)) ? 0 : parseInt(minStock),
                category: finalCategoryId ? { connect: { id: finalCategoryId } } : undefined,
                description,
                tenant: { connect: { id: tenant.id } },
                storeId: demoStore ? demoStore.id : undefined
            }
        });

        // Log Initial Stock
        if (stock > 0) {
            await prisma.inventoryLog.create({
                data: {
                    productId: product.id,
                    type: 'IN',
                    quantity: parseInt(stock),
                    reason: 'Initial Creation',
                    createdAt: new Date()
                }
            });
        }

        return successResponse(res, product, "Product created successfully", 201);
    } catch (error) {
        console.error("Create Product Error:", error); // Log error for debugging
        return errorResponse(res, "Failed to create product", 500, error);
    }
};

// Update Product
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, sku, basePrice, sellingPrice, minStock, categoryId, category, description } = req.body;

        // [FIX] Handle Category String (Find or Create) - Need Tenant ID.
        // Assuming we can get tenant from the existing product if not in req.user
        let finalCategoryId = categoryId;

        if (!finalCategoryId && category) {
            const existingProduct = await prisma.product.findUnique({ where: { id }, select: { tenantId: true } });
            if (existingProduct) {
                let cat = await prisma.category.findFirst({
                    where: { tenantId: existingProduct.tenantId, name: category }
                });
                if (!cat) {
                    cat = await prisma.category.create({
                        data: {
                            tenantId: existingProduct.tenantId,
                            name: category
                        }
                    });
                }
                finalCategoryId = cat.id;
            }
        }

        const product = await prisma.product.update({
            where: { id },
            data: {
                name,
                sku,
                basePrice: basePrice ? parseFloat(basePrice) : undefined,
                sellingPrice: sellingPrice ? parseFloat(sellingPrice) : undefined,
                minStock: minStock ? parseInt(minStock) : undefined,
                categoryId: finalCategoryId || undefined,
                description
            }
        });

        return successResponse(res, product, "Product updated successfully");
    } catch (error) {
        console.error("Update Product Error:", error);
        return errorResponse(res, "Failed to update product", 500, error);
    }
};

// Delete Product (Soft Delete)
const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.product.update({
            where: { id },
            data: { isActive: false }
        });
        return successResponse(res, null, "Product deleted successfully");
    } catch (error) {
        return errorResponse(res, "Failed to delete product", 500, error);
    }
};

module.exports = {
    getProducts,
    createProduct,
    updateProduct,
    deleteProduct
};
