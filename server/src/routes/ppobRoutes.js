const express = require('express');
const router = express.Router();
const ppobController = require('../controllers/ppobController');
const verifyToken = require('../middleware/auth');

// All PPOB/Digital Product routes require authentication
router.use(verifyToken);

router.get('/products', ppobController.getProducts);
router.post('/inquiry', ppobController.checkBill);
router.post('/transaction', ppobController.purchaseProduct); // [NEW]

module.exports = router;
