const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const verifyToken = require('../middleware/auth');

router.use(verifyToken);
router.get('/', walletController.getWalletData);
router.post('/withdraw', walletController.requestWithdrawal);

router.post('/topup', walletController.topUp);
router.post('/transfer', walletController.transfer);
router.post('/transaction', walletController.payTransaction);

module.exports = router;
