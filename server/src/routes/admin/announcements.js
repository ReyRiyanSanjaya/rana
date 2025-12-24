const express = require('express');
const router = express.Router();
const AnnouncementController = require('../../controllers/admin/AnnouncementController');

router.get('/', AnnouncementController.getAnnouncements);
router.post('/', AnnouncementController.createAnnouncement);
router.delete('/:id', AnnouncementController.deleteAnnouncement);
router.put('/:id/active', AnnouncementController.toggleActive);

module.exports = router;
