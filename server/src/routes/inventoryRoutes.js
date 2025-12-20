const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');
const verifyToken = require('../middleware/auth');
const checkRole = require('../middleware/role');

// All routes required authentication
router.use(verifyToken);

// Get Logs for a product
router.get('/:productId/logs', inventoryController.getInventoryLogs);

// Adjust Stock (Store Manager or Owner)
router.post('/adjust', checkRole(['OWNER', 'STORE_MANAGER']), inventoryController.adjustStock);

module.exports = router;
