const express = require('express');
const router = express.Router();
const marketController = require('../controllers/marketController');
const marketOrderController = require('../controllers/marketOrderController');
const systemController = require('../controllers/systemController');

router.get('/nearby', marketController.getNearbyStores);
router.get('/config/payment', systemController.getPaymentInfo);
router.get('/flashsales', marketController.getActiveFlashSales);
router.get('/store/:id/catalog', marketController.getStoreCatalog);
router.post('/order', marketOrderController.createOrder);
router.post('/order/confirm', marketOrderController.confirmPayment);
router.get('/orders', marketOrderController.getOrdersByPhone);

module.exports = router;
