const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const { emitToTenant } = require('../socket');
const fs = require('fs');
const path = require('path');

const saveProductImage = (base64String, tenantId, productId) => {
    try {
        if (!base64String) return null;

        const matches = base64String.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
        if (!matches || matches.length !== 3) return null;

        const mimeType = matches[1];
        if (!mimeType.startsWith('image/')) return null;

        const buffer = Buffer.from(matches[2], 'base64');
        const ext = mimeType.split('/')[1] || 'jpg';
        const safeExt = ext.replace(/[^a-z0-9]/gi, '').toLowerCase() || 'jpg';
        const fileName = `product_${productId || 'new'}_${Date.now()}.${safeExt}`;

        const uploadDir = path.join(__dirname, '../../uploads/products', tenantId);
        if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

        fs.writeFileSync(path.join(uploadDir, fileName), buffer);
        return `/uploads/products/${tenantId}/${fileName}`;
    } catch (e) {
        console.error("Save Product Image Error:", e);
        return null;
    }
};

// List Products (Active Only)
const getProducts = async (req, res) => {
    try {
        const { tenantId, storeId } = req.user;

        const products = await prisma.product.findMany({
            where: {
                isActive: true,
                tenantId: tenantId
                // Optional: Filter by storeId if needed, but usually tenant-wide products are fine for owner
                // storeId: storeId 
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
        const { name, sku, basePrice, sellingPrice, stock, minStock, categoryId, category, description, imageBase64 } = req.body;
        const { tenantId, storeId } = req.user;

        if (!tenantId) return errorResponse(res, "Unauthorized: No Tenant ID", 401);

        // [FIX] Handle Category String (Find or Create)
        let finalCategoryId = categoryId;
        if (!finalCategoryId && category) {
            let cat = await prisma.category.findFirst({
                where: { tenantId: tenantId, name: category }
            });
            if (!cat) {
                cat = await prisma.category.create({
                    data: {
                        tenantId: tenantId,
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
                tenant: { connect: { id: tenantId } },
                storeId: storeId // Associate with the creator's store
            }
        });

        if (imageBase64) {
            const imageUrl = saveProductImage(imageBase64, tenantId, product.id);
            if (imageUrl) {
                await prisma.product.update({
                    where: { id: product.id },
                    data: { imageUrl }
                });
                product.imageUrl = imageUrl;
            }
        }

        // Log Initial Stock
        if (stock > 0) {
            await prisma.inventoryLog.create({
                data: {
                    productId: product.id,
                    storeId: storeId,
                    type: 'IN',
                    quantity: parseInt(stock),
                    reason: 'Initial Creation',
                    createdAt: new Date()
                }
            });

            // Also create Stock record
            if (storeId) {
                await prisma.stock.create({
                    data: {
                        storeId: storeId,
                        productId: product.id,
                        quantity: parseInt(stock)
                    }
                });
            }
        }

        emitToTenant(tenantId, 'products:changed', { type: 'CREATED', id: product.id });
        emitToTenant(tenantId, 'inventory:changed', { storeId, changes: [{ productId: product.id, stock: product.stock }] });
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
        const { name, sku, basePrice, sellingPrice, minStock, categoryId, category, description, imageBase64 } = req.body;
        const { tenantId } = req.user;

        // Verify Ownership
        const existingProduct = await prisma.product.findUnique({ where: { id } });
        if (!existingProduct) return errorResponse(res, "Product not found", 404);
        if (existingProduct.tenantId !== tenantId) return errorResponse(res, "Unauthorized Access", 403);

        // [FIX] Handle Category String (Find or Create)
        let finalCategoryId = categoryId;

        if (!finalCategoryId && category) {
            let cat = await prisma.category.findFirst({
                where: { tenantId: tenantId, name: category }
            });
            if (!cat) {
                cat = await prisma.category.create({
                    data: {
                        tenantId: tenantId,
                        name: category
                    }
                });
            }
            finalCategoryId = cat.id;
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

        if (imageBase64) {
            const imageUrl = saveProductImage(imageBase64, tenantId, product.id);
            if (imageUrl) {
                const updatedWithImage = await prisma.product.update({
                    where: { id: product.id },
                    data: { imageUrl }
                });
                emitToTenant(tenantId, 'products:changed', { type: 'UPDATED', id: product.id });
                return successResponse(res, updatedWithImage, "Product updated successfully");
            }
        }

        emitToTenant(tenantId, 'products:changed', { type: 'UPDATED', id: product.id });
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
        const { tenantId } = req.user;

        // Verify Ownership
        const existingProduct = await prisma.product.findUnique({ where: { id } });
        if (!existingProduct) return errorResponse(res, "Product not found", 404);
        if (existingProduct.tenantId !== tenantId) return errorResponse(res, "Unauthorized Access", 403);

        const product = await prisma.product.update({
            where: { id },
            data: {
                isActive: false,
                // deletedAt field not in schema shown previously, relying on isActive=false
                // deletedAt: new Date() 
            }
        });

        emitToTenant(tenantId, 'products:changed', { type: 'DELETED', id });
        return successResponse(res, null, "Product deleted successfully");
    } catch (error) {
        return errorResponse(res, "Failed to delete product", 500, error);
    }
};

// [NEW] Marketing: Apply Discount/Flash Sale
const applyDiscount = async (req, res) => {
    try {
        const { id } = req.params;
        const { discountPercentage, newPrice, promoType, label } = req.body;

        const product = await prisma.product.findUnique({ where: { id } });
        if (!product) return errorResponse(res, "Product not found", 404);

        const { tenantId } = req.user;
        if (product.tenantId !== tenantId) return errorResponse(res, "Unauthorized Access", 403);

        // Store original price if not already set
        let basePrice = product.originalPrice ? product.originalPrice : product.sellingPrice;

        let finalSellingPrice;

        // Support both old (discountPercentage) and new (newPrice) format
        if (newPrice !== undefined && newPrice !== null) {
            // New format: direct price
            finalSellingPrice = parseFloat(newPrice);
        } else if (discountPercentage !== undefined && discountPercentage !== null) {
            // Old format: calculate from percentage
            const discountAmount = (basePrice * discountPercentage) / 100;
            finalSellingPrice = basePrice - discountAmount;
        } else {
            return errorResponse(res, "Please provide newPrice or discountPercentage", 400);
        }

        // Generate promo label based on type
        const promoLabel = label || (promoType === 'flashsale' ? '⚡ Flash Sale' : '🔥 Promo Special');

        const updated = await prisma.product.update({
            where: { id },
            data: {
                originalPrice: basePrice, // Ensure base is saved
                sellingPrice: finalSellingPrice,
                discountLabel: promoLabel
            }
        });

        return successResponse(res, updated, `${promoType === 'flashsale' ? 'Flash Sale' : 'Discount'} applied. New price: ${finalSellingPrice}`);

    } catch (error) {
        return errorResponse(res, "Failed to apply discount", 500, error);
    }
};

// [NEW] Marketing: Revert Price
const revertPrice = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await prisma.product.findUnique({ where: { id } });

        if (!product || !product.originalPrice) {
            return errorResponse(res, "No discount to revert or product not found", 400);
        }

        const { tenantId } = req.user;
        if (product.tenantId !== tenantId) return errorResponse(res, "Unauthorized Access", 403);

        const updated = await prisma.product.update({
            where: { id },
            data: {
                sellingPrice: product.originalPrice,
                originalPrice: null, // Clear it
                discountLabel: null
            }
        });

        return successResponse(res, updated, "Price reverted to normal");

    } catch (error) {
        return errorResponse(res, "Failed to revert price", 500, error);
    }
};

module.exports = {
    getProducts,
    createProduct,
    updateProduct,
    deleteProduct,
    applyDiscount,
    revertPrice
};
