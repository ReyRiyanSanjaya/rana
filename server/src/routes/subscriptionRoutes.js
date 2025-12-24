const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');

const authenticateToken = require('../middleware/auth');

router.get('/packages', subscriptionController.getPackages);
router.get('/status', authenticateToken, subscriptionController.getStatus);
router.post('/request', authenticateToken, subscriptionController.createRequest);
router.get('/requests', subscriptionController.getAllRequests); // Admin only (add middleware later)
router.post('/requests/:id/approve', subscriptionController.approveRequest); // Admin only

module.exports = router;
