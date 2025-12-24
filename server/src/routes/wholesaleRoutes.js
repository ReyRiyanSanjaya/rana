const express = require('express');
const router = express.Router();
const controller = require('../controllers/wholesaleController');

// Public / Merchant
router.get('/products', controller.getProducts);
router.get('/categories', controller.getCategories);
router.post('/orders', controller.createOrder);
router.get('/orders', controller.getOrders); // Can filter by tenantId query

// Admin (Should have auth middleware in real production)
router.post('/products', controller.createProduct);
router.put('/products/:id', controller.updateProduct);
router.delete('/products/:id', controller.deleteProduct);
router.post('/categories', controller.createCategory);
router.put('/categories/:id', controller.updateCategory);
router.delete('/categories/:id', controller.deleteCategory);
router.put('/orders/:id/status', controller.updateOrderStatus);

// Coupon Routes (Admin)
router.get('/coupons', controller.getCoupons);
router.post('/coupons', controller.createCoupon);
router.patch('/coupons/:id', controller.toggleCoupon);
router.delete('/coupons/:id', controller.deleteCoupon);
router.post('/validate-coupon', controller.validateCoupon); // Public/Mobile

// Banner Routes
router.post('/wholesale/banners', controller.createBanner);
router.get('/wholesale/banners', controller.getBanners);
router.delete('/wholesale/banners/:id', controller.deleteBanner);

module.exports = router;
