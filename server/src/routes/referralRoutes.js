const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referralController');
const verifyToken = require('../middleware/auth');

router.use(verifyToken);
router.get('/me', referralController.getMyReferralInfo);
router.get('/me/referrals', referralController.getMyReferrals);

module.exports = router;

