const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');

router.post('/request', subscriptionController.createRequest);
router.get('/requests', subscriptionController.getAllRequests); // Admin only (add middleware later)
router.post('/requests/:id/approve', subscriptionController.approveRequest); // Admin only

module.exports = router;
