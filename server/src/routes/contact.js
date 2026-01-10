const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contact');

router.post('/messages', contactController.createMessage);

module.exports = router;
