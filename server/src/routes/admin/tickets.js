const express = require('express');
const router = express.Router();
const TicketController = require('../../controllers/admin/TicketController');

// Should use authentication middleware here in real app
// router.use(verifyToken);
// router.use(verifyAdmin);

router.get('/', TicketController.getTickets);
router.get('/:id', TicketController.getTicketDetail);
router.post('/:id/reply', TicketController.replyTicket);
router.put('/:id/status', TicketController.updateStatus);

module.exports = router;
