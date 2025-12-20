const express = require('express');
const router = express.Router();
const marketController = require('../controllers/marketController');

const marketOrderController = require('../controllers/marketOrderController');

const systemController = require('../controllers/systemController');

// Public Routes
router.get('/nearby', marketController.getNearbyStores);
router.get('/config/payment', systemController.getPaymentInfo); // [NEW]
router.post('/order', marketOrderController.createOrder);
router.post('/order/confirm', marketOrderController.confirmPayment); // [NEW]
router.get('/orders', marketOrderController.getOrdersByPhone);

module.exports = router;
