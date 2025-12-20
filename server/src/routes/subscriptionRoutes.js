const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');

// Public route (no auth needed to view prices usually, but let's keep it consistent)
router.get('/packages', subscriptionController.getPackages);

module.exports = router;
