const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const verifyToken = require('../middleware/auth');
const checkSubscription = require('../middleware/subscription');

// Secure all routes
router.use(verifyToken);
router.use(checkSubscription);

// Reporting Endpoints
router.get('/dashboard', reportController.getDashboardStats);
router.get('/profit-loss', reportController.getProfitLoss);
router.get('/inventory', reportController.getInventoryIntelligence);
router.post('/expenses', require('../controllers/cashController').recordExpense);

module.exports = router;
