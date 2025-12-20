const express = require('express');
const router = express.Router();
const purchaseController = require('../controllers/purchaseController');
const verifyToken = require('../middleware/auth');
const checkSubscription = require('../middleware/subscription');

router.use(verifyToken);
router.use(checkSubscription);

router.post('/', purchaseController.createPurchase);

module.exports = router;
