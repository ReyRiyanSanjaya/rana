const express = require('express');
const router = express.Router();
const systemController = require('../controllers/systemController');

// Public System Info
router.get('/payment-info', systemController.getPaymentInfo);
router.get('/announcements', systemController.getActiveAnnouncements);
router.get('/app-menus', systemController.getAppMenus);
router.get('/notifications', systemController.getNotifications); // [NEW] // [NEW] Mobile App Menu

// Public Announcements
router.get('/announcements', systemController.getActiveAnnouncements);
router.get('/cms-content', systemController.getPublicSettings); // [NEW]

module.exports = router;
