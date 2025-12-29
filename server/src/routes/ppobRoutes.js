const express = require('express');
const router = express.Router();
const ppobController = require('../controllers/ppobController');
const verifyToken = require('../middleware/auth');

router.post('/webhook/digiflazz', ppobController.digiflazzWebhook);

router.use(verifyToken);

router.get('/products', ppobController.getProducts);
router.post('/inquiry', ppobController.checkBill);
router.post('/transaction', ppobController.purchaseProduct); // [NEW]
router.get('/status/:refId', ppobController.checkStatus);

module.exports = router;
