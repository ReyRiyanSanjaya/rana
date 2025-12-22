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
router.post('/categories', controller.createCategory);
router.put('/orders/:id/status', controller.updateOrderStatus);

module.exports = router;
