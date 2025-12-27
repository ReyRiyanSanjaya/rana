const express = require('express');
const router = express.Router();
const systemController = require('../controllers/systemController');

// Public System Info
router.get('/payment-info', systemController.getPaymentInfo);
router.get('/announcements', systemController.getActiveAnnouncements);
router.get('/app-menus', systemController.getAppMenus);

// Protected System Info
const verifyToken = require('../middleware/auth');
router.get('/notifications', verifyToken, systemController.getNotifications); 

// Public Settings for CMP/Content
router.get('/cms-content', systemController.getPublicSettings);

module.exports = router;
