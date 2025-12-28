const express = require('express');
const router = express.Router();
const systemController = require('../../controllers/systemController');

router.get('/', systemController.getAllAnnouncements);
router.post('/', systemController.createAnnouncement);
router.delete('/:id', systemController.deleteAnnouncement);
router.put('/:id', systemController.updateAnnouncement); // Changed from toggleActive to general update

module.exports = router;
