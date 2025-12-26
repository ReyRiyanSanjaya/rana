const express = require('express');
const router = express.Router();
const controller = require('../controllers/merchantTicketController');
const verifyToken = require('../middleware/auth');

router.use(verifyToken); // All routes require login

router.get('/', controller.getMyTickets);
router.post('/', controller.createTicket);
router.get('/:id', controller.getTicketDetail);
router.post('/:id/reply', controller.replyTicket);

module.exports = router;
