const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const verifyToken = require('../middleware/auth');
const checkRole = require('../middleware/role');

// All routes require SUPER_ADMIN
router.use(verifyToken);
router.use(checkRole(['SUPER_ADMIN']));

// Get Dashboard Stats
router.get('/stats', adminController.getDashboardStats);
router.get('/stats/chart', adminController.getPayoutChart);

// Subscription Packages
router.get('/packages', adminController.getPackages);
router.post('/packages', adminController.createPackage);
router.delete('/packages/:id', adminController.deletePackage);

// Announcements
router.get('/announcements', adminController.getAnnouncements);
router.post('/announcements', adminController.createAnnouncement);
router.delete('/announcements/:id', adminController.deleteAnnouncement);

// Merchant Management
router.get('/merchants', adminController.getMerchants);
router.post('/merchants', adminController.createMerchant);
router.delete('/merchants/:id', adminController.deleteMerchant);

// Reports
router.get('/withdrawals/export', adminController.exportWithdrawals);

// Withdrawal Management
router.get('/withdrawals', adminController.getWithdrawals);
router.put('/withdrawals/:id/approve', adminController.approveWithdrawal);
router.put('/withdrawals/:id/reject', adminController.rejectWithdrawal);

// System Settings
router.get('/settings', adminController.getSettings);
router.post('/settings', adminController.updateSettings);

module.exports = router;
