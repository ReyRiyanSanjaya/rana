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

// =======================
// COUPON MANAGEMENT
// =======================

// Create Coupon (Admin)
const createCoupon = async (req, res) => {
    try {
        const { code, type, value, minOrder, maxDiscount, startDate, endDate, isActive } = req.body;

        // Check uniqueness
        const exist = await prisma.wholesaleCoupon.findUnique({ where: { code } });
        if (exist) return errorResponse(res, "Coupon code already exists", 400);

        const coupon = await prisma.wholesaleCoupon.create({
            data: {
                code, type,
                value: parseFloat(value),
                minOrder: parseFloat(minOrder || 0),
                maxDiscount: maxDiscount ? parseFloat(maxDiscount) : null,
                startDate: startDate ? new Date(startDate) : null,
                endDate: endDate ? new Date(endDate) : null,
                isActive: isActive ?? true
            }
        });
        return successResponse(res, coupon, "Coupon created", 201);
    } catch (error) {
        return errorResponse(res, "Failed to create coupon", 500, error);
    }
};

// Get Coupons (Admin)
const getCoupons = async (req, res) => {
    try {
        const coupons = await prisma.wholesaleCoupon.findMany({ orderBy: { createdAt: 'desc' } });
        return successResponse(res, coupons, "Coupons retrieved");
    } catch (error) {
        return errorResponse(res, "Failed to fetch coupons", 500, error);
    }
};

// Toggle Coupon Status (Admin)
const toggleCoupon = async (req, res) => {
    try {
        const { id } = req.params;
        const { isActive } = req.body;
        const coupon = await prisma.wholesaleCoupon.update({
            where: { id },
            data: { isActive }
        });
        return successResponse(res, coupon, "Coupon updated");
    } catch (error) {
        return errorResponse(res, "Failed update coupon", 500, error);
    }
};

// Delete Coupon (Admin)
const deleteCoupon = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.wholesaleCoupon.delete({ where: { id } });
        return successResponse(res, null, "Coupon deleted");
    } catch (error) {
        return errorResponse(res, "Failed delete coupon", 500, error);
    }
}

// Validate Coupon (Mobile/API)
const validateCoupon = async (req, res) => {
    try {
        const { code, totalAmount } = req.body;
        const coupon = await prisma.wholesaleCoupon.findUnique({ where: { code } });

        if (!coupon) return errorResponse(res, "Invalid coupon code", 404);
        if (!coupon.isActive) return errorResponse(res, "Coupon is inactive", 400);

        const now = new Date();
        if (coupon.startDate && now < coupon.startDate) return errorResponse(res, "Coupon not yet started", 400);
        if (coupon.endDate && now > coupon.endDate) return errorResponse(res, "Coupon expired", 400);

        if (totalAmount < coupon.minOrder) return errorResponse(res, `Minimum order Rp ${coupon.minOrder.toLocaleString()}`, 400);

        // Calculate Discount
        let discount = 0;
        if (coupon.type === 'FIXED') {
            discount = coupon.value;
        } else if (coupon.type === 'PERCENTAGE') {
            discount = (totalAmount * coupon.value) / 100;
            if (coupon.maxDiscount && discount > coupon.maxDiscount) {
                discount = coupon.maxDiscount;
            }
        } else if (coupon.type === 'FREE_SHIPPING') {
            // For simplicity, we just return the coupon type. The exact shipping deduction happens in order creation or frontend logic.
            // But usually validate returns the potential discount value.
            discount = 0; // Handled as shipping deduction
        }

        return successResponse(res, { coupon, discount }, "Coupon is valid");
    } catch (error) {
        return errorResponse(res, "Validation failed", 500, error);
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
        const { tenantId } = req.user; // [SECURE] Trust token
        const { items, paymentMethod, shippingAddress, shippingCost, couponCode } = req.body;
        // items: [{ productId, quantity, price }]

        // Calculate subtotal
        let subtotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
        let finalShippingCost = parseFloat(shippingCost || 0);
        let discountAmount = 0;

        // Apply Coupon if present
        if (couponCode) {
            const coupon = await prisma.wholesaleCoupon.findUnique({ where: { code: couponCode } });
            if (coupon && coupon.isActive) {
                // Basic validation again just in case
                if (subtotal >= coupon.minOrder) {
                    if (coupon.type === 'FIXED') {
                        discountAmount = coupon.value;
                    } else if (coupon.type === 'PERCENTAGE') {
                        discountAmount = (subtotal * coupon.value) / 100;
                        if (coupon.maxDiscount && discountAmount > coupon.maxDiscount) discountAmount = coupon.maxDiscount;
                    } else if (coupon.type === 'FREE_SHIPPING') {
                        discountAmount = finalShippingCost; // Discount covers shipping
                    }
                }
            }
        }

        // Get Service Fee
        const feeSetting = await prisma.systemSettings.findUnique({ where: { key: 'WHOLESALE_SERVICE_FEE' } });
        const feeTypeSetting = await prisma.systemSettings.findUnique({ where: { key: 'WHOLESALE_SERVICE_FEE_TYPE' } });
        const minCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'WHOLESALE_FEE_CAP_MIN' } });
        const maxCapSetting = await prisma.systemSettings.findUnique({ where: { key: 'WHOLESALE_FEE_CAP_MAX' } });
        const feeVal = feeSetting ? parseFloat(feeSetting.value) : 0;
        const feeType = feeTypeSetting ? String(feeTypeSetting.value) : 'FLAT';
        let serviceFee = 0;
        if (feeType === 'PERCENT') {
            serviceFee = (subtotal * feeVal) / 100;
        } else {
            serviceFee = feeVal;
        }
        const minCap = minCapSetting ? parseFloat(minCapSetting.value) : undefined;
        const maxCap = maxCapSetting ? parseFloat(maxCapSetting.value) : undefined;
        if (minCap !== undefined && serviceFee < minCap) serviceFee = minCap;
        if (maxCap !== undefined && serviceFee > maxCap) serviceFee = maxCap;

        const totalAmount = subtotal + finalShippingCost + serviceFee - discountAmount;

        const result = await prisma.$transaction(async (tx) => {
            // Create Order
            const order = await tx.wholesaleOrder.create({
                data: {
                    tenantId, // Which merchant is buying
                    totalAmount: totalAmount > 0 ? totalAmount : 0,
                    serviceFee: serviceFee, // [NEW]
                    status: 'PENDING',
                    paymentMethod,
                    shippingAddress,
                    shippingCost: finalShippingCost,
                    couponCode,
                    discountAmount,
                    items: {
                        create: items.map(i => ({
                            productId: i.productId,
                            quantity: i.quantity,
                            price: i.price
                        }))
                    }
                }
            });

            // Decrease Stock
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
        const { role, tenantId: userTenantId } = req.user;
        const { status, tenantId } = req.query;

        const where = {
            status: status || undefined
        };

        // [SECURE] If not Admin, force own tenant
        if (role !== 'ADMIN') {
            where.tenantId = userTenantId;
        } else if (tenantId) {
            // Admin filtering by specific tenant
            where.tenantId = tenantId;
        }

        const orders = await prisma.wholesaleOrder.findMany({
            where,
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
        const { status, pickupCode } = req.body;

        // Validate status against enum
        const validStatuses = ['PENDING', 'PAID', 'PROCESSED', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
        if (!validStatuses.includes(status)) {
            return errorResponse(res, `Invalid status. Allowed: ${validStatuses.join(', ')}`, 400);
        }

        const order = await prisma.wholesaleOrder.update({
            where: { id },
            data: { status, pickupCode: pickupCode !== undefined ? pickupCode : undefined }
        });

        if (status === 'PAID' && order.serviceFee && order.serviceFee > 0) {
            await prisma.platformRevenue.create({
                data: {
                    amount: order.serviceFee,
                    source: 'OTHER',
                    description: `Wholesale Service Fee - ${order.id}`,
                    referenceId: order.id
                }
            });
        }

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

// Update Product (Admin)
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, categoryId, price, stock, supplierName, imageUrl, description, isActive } = req.body;

        const product = await prisma.wholesaleProduct.update({
            where: { id },
            data: {
                name,
                categoryId,
                price: price ? parseFloat(price) : undefined,
                stock: stock ? parseInt(stock) : undefined,
                supplierName,
                imageUrl,
                description,
                isActive: isActive !== undefined ? isActive : undefined
            }
        });
        return successResponse(res, product, "Product updated");
    } catch (error) {
        return errorResponse(res, "Failed to update wholesale product", 500, error);
    }
};

// Limit Product Deletion (Admin)
const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.wholesaleProduct.delete({ where: { id } });
        return successResponse(res, null, "Product deleted");
    } catch (error) {
        return errorResponse(res, "Failed to delete wholesale product", 500, error);
    }
};

// Update Category (Admin)
const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, isActive } = req.body;
        const cat = await prisma.wholesaleCategory.update({
            where: { id },
            data: {
                name,
                isActive: isActive !== undefined ? isActive : undefined
            }
        });
        return successResponse(res, cat, "Category updated");
    } catch (error) {
        return errorResponse(res, "Failed to update category", 500, error);
    }
};

// Delete Category (Admin)
const deleteCategory = async (req, res) => {
    try {
        const { id } = req.params;
        // Check if has products
        const count = await prisma.wholesaleProduct.count({ where: { categoryId: id } });
        if (count > 0) {
            return errorResponse(res, "Cannot delete category with existing products", 400);
        }

        await prisma.wholesaleCategory.delete({ where: { id } });
        return successResponse(res, null, "Category deleted");
    } catch (error) {
        return errorResponse(res, "Failed to delete category", 500, error);
    }
};

// Upload Proof
const uploadProof = async (req, res) => {
    try {
        if (!req.file) return errorResponse(res, "No file uploaded", 400);
        // Assuming public/uploads is served statically
        const url = `/uploads/proofs/${req.file.filename}`;
        const { orderId } = req.body || {};
        if (orderId) {
            try {
                await prisma.wholesaleOrder.update({
                    where: { id: orderId },
                    data: { proofUrl: url }
                });
            } catch (_) {}
        }
        return successResponse(res, { url }, "Proof uploaded");
    } catch (error) {
        return errorResponse(res, "Upload failed", 500, error);
    }
};

// Scan Order (Merchant receives goods)
const scanOrder = async (req, res) => {
    try {
        const { pickupCode } = req.body;
        // Find by ID or PickupCode
        const order = await prisma.wholesaleOrder.findFirst({
            where: {
                OR: [
                    { id: pickupCode },
                    { pickupCode: pickupCode }
                ]
            }
        });

        if (!order) return errorResponse(res, "Order not found", 404);

        if (order.status !== 'SHIPPED') {
            return errorResponse(res, `Order cannot be received. Status: ${order.status}`, 400);
        }

        const updated = await prisma.wholesaleOrder.update({
            where: { id: order.id },
            data: { status: 'DELIVERED' }
        });

        return successResponse(res, updated, "Order received successfully");
    } catch (error) {
        return errorResponse(res, "Scan failed", 500, error);
    }
};

module.exports = {
    uploadProof,
    scanOrder, // [NEW]
    getProducts,
    createProduct,
    createOrder,
    getOrders,
    updateOrderStatus,
    getCategories,
    createCategory,
    updateProduct,
    deleteProduct,
    updateCategory,
    deleteCategory,
    createCoupon,
    getCoupons,
    toggleCoupon,
    deleteCoupon,
    validateCoupon,

    // Banner Management
    createBanner: async (req, res) => {
        try {
            const { title, imageUrl, description, isActive } = req.body;
            const banner = await prisma.wholesaleBanner.create({
                data: { title, imageUrl, description, isActive: isActive ?? true }
            });
            return successResponse(res, banner, "Banner created", 201);
        } catch (error) {
            return errorResponse(res, "Failed to create banner", 500, error);
        }
    },

    getBanners: async (req, res) => {
        try {
            const banners = await prisma.wholesaleBanner.findMany({
                where: { isActive: true },
                orderBy: { createdAt: 'desc' }
            });
            return successResponse(res, banners, "Banners retrieved");
        } catch (error) {
            return errorResponse(res, "Failed to fetch banners", 500, error);
        }
    },

    deleteBanner: async (req, res) => {
        try {
            const { id } = req.params;
            await prisma.wholesaleBanner.delete({ where: { id } });
            return successResponse(res, null, "Banner deleted");
        } catch (error) {
            return errorResponse(res, "Failed to delete banner", 500, error);
        }
    },

    // [NEW] Update Banner
    updateBanner: async (req, res) => {
        try {
            const { id } = req.params;
            const { title, imageUrl, description, isActive } = req.body;
            const banner = await prisma.wholesaleBanner.update({
                where: { id },
                data: {
                    title, imageUrl, description,
                    isActive: isActive !== undefined ? isActive : undefined
                }
            });
            return successResponse(res, banner, "Banner updated");
        } catch (error) {
            return errorResponse(res, "Failed to update banner", 500, error);
        }
    },

    // [NEW] Update Coupon
    updateCoupon: async (req, res) => {
        try {
            const { id } = req.params;
            const { code, type, value, minOrder, maxDiscount, startDate, endDate, isActive } = req.body;

            const coupon = await prisma.wholesaleCoupon.update({
                where: { id },
                data: {
                    code, type,
                    value: value ? parseFloat(value) : undefined,
                    minOrder: minOrder !== undefined ? parseFloat(minOrder) : undefined,
                    maxDiscount: maxDiscount !== undefined ? parseFloat(maxDiscount) : undefined,
                    startDate: startDate ? new Date(startDate) : undefined,
                    endDate: endDate ? new Date(endDate) : undefined,
                    isActive: isActive !== undefined ? isActive : undefined
                }
            });
            return successResponse(res, coupon, "Coupon updated");
        } catch (error) {
            return errorResponse(res, "Failed to update coupon", 500, error);
        }
    }
};
