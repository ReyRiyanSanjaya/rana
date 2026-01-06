const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const systemController = require('../controllers/systemController');
const verifyToken = require('../middleware/auth');
const checkRole = require('../middleware/role');

// All routes require SUPER_ADMIN
router.use(verifyToken);
router.use(checkRole(['SUPER_ADMIN']));

// Get Dashboard Stats
router.get('/stats', adminController.getDashboardStats);
router.get('/stats/chart', adminController.getPayoutChart);
router.get('/analytics', adminController.getBusinessAnalytics); // [NEW]

// Subscription Packages
router.get('/packages', adminController.getPackages);
router.post('/packages', adminController.createPackage);
router.put('/packages/:id', adminController.updatePackage);
router.delete('/packages/:id', adminController.deletePackage);

// Tickets & Support
router.use('/tickets', require('./admin/tickets'));

// Announcements
router.use('/announcements', require('./admin/announcements'));

// Merchant Management
router.get('/merchants', adminController.getMerchants);
router.post('/merchants', adminController.createMerchant);
router.delete('/merchants/:id', adminController.deleteMerchant);
router.put('/merchants/:tenantId/subscription', adminController.updateMerchantSubscription);
router.get('/merchants/:id', adminController.getMerchantDetail); // [NEW]
router.post('/merchants/:storeId/wallet/adjust', adminController.adjustMerchantWallet); // [NEW]
router.post('/merchants/:tenantId/notify', adminController.sendNotification); // [NEW]
router.get('/merchants/export', adminController.exportMerchants);

// Merchant Menu Management
router.get('/merchants/:storeId/products', adminController.getMerchantProducts);
router.post('/merchants/:storeId/products', adminController.createMerchantProduct);
router.put('/merchants/:storeId/products/:productId', adminController.updateMerchantProduct);
router.delete('/merchants/:storeId/products/:productId', adminController.deleteMerchantProduct);

// Subscription Requests
router.get('/subscriptions', adminController.getSubscriptionRequests);
router.put('/subscriptions/:id/approve', adminController.approveSubscriptionRequest);
router.put('/subscriptions/:id/reject', adminController.rejectSubscriptionRequest);

// Reports
router.get('/withdrawals/export', adminController.exportWithdrawals);

// Withdrawal Management
router.get('/withdrawals', adminController.getWithdrawals);
router.put('/withdrawals/:id/approve', adminController.approveWithdrawal);
router.put('/withdrawals/:id/reject', adminController.rejectWithdrawal);

// Top-Up Management (Wallet)
router.get('/topups', adminController.getTopUps);
router.put('/topups/:id/approve', adminController.approveTopUp);
router.put('/topups/:id/reject', adminController.rejectTopUp);

// System Settings
router.get('/settings', adminController.getSettings);
router.post('/settings', adminController.updateSettings);
router.get('/settings/fees', systemController.getFeeSettings);
router.post('/settings/fees', systemController.updateFeeSettings);

// App Menu Management
router.get('/app-menus', adminController.getAppMenus);
router.post('/app-menus', adminController.createAppMenu);
router.put('/app-menus/:id', adminController.updateAppMenu);
router.delete('/app-menus/:id', adminController.deleteAppMenu);
router.get('/app-menus/maintenance', adminController.getAppMenuMaintenance);
router.put('/app-menus/:id/maintenance', adminController.updateAppMenuMaintenance);

// User Management
router.put('/users/:id/password', adminController.resetUserPassword);
router.get('/admins', adminController.getAdminUsers); // [NEW]
router.post('/admins', adminController.createAdminUser); // [NEW]
router.delete('/admins/:id', adminController.deleteAdminUser); // [NEW]

// Billing & Export
router.get('/billing/subscription', adminController.getPlatformSubscription); // [NEW]
router.get('/export/dashboard', adminController.exportDashboardData); // [NEW]

// Enterprise Features
router.get('/audit-logs', adminController.getAuditLogs); // [NEW]
router.get('/search', adminController.globalSearch); // [NEW]

// Transaction Management
router.get('/transactions', adminController.getAllTransactions); // [NEW]
router.get('/transactions/export', adminController.exportTransactions); // [NEW]

// Flash Sales Management
router.get('/flashsales', adminController.getFlashSales); // [NEW]
router.put('/flashsales/:id/status', adminController.updateFlashSaleStatus); // [NEW]

// Referral & Rewards Monitoring
router.get('/referral/programs', adminController.getReferralPrograms);
router.get('/referral/referrals', adminController.getReferrals);
router.get('/referral/rewards', adminController.getReferralRewards);

module.exports = router;
