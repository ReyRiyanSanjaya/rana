const express = require('express');
const router = express.Router();
const merchantOrderController = require('../controllers/merchantOrderController');
const verifyToken = require('../middleware/auth');

router.use(verifyToken);
router.get('/', merchantOrderController.getIncomingOrders);
router.put('/status', merchantOrderController.updateOrderStatus);
router.post('/scan', merchantOrderController.scanQrOrder); // [NEW]

module.exports = router;
