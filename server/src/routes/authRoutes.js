const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

const verifyToken = require('../middleware/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', verifyToken, authController.getProfile);
router.put('/me', verifyToken, authController.updateUserProfile);
router.put('/store', verifyToken, authController.updateStoreProfile); // [NEW]

module.exports = router;
