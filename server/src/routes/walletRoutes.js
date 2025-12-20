const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const verifyToken = require('../middleware/auth');

router.use(verifyToken);
router.get('/', walletController.getWalletData);
router.post('/withdraw', walletController.requestWithdrawal);

module.exports = router;
