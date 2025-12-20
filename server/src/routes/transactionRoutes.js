const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const verifyToken = require('../middleware/auth');

// Secure
router.use(verifyToken);
router.use(require('../middleware/subscription')); // Block Sync if expired

router.post('/sync', transactionController.syncTransaction);

module.exports = router;
