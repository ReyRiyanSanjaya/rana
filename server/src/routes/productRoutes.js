const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const verifyToken = require('../middleware/auth');
router.use(verifyToken);

router.get('/', productController.getProducts);
router.post('/', productController.createProduct);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);
router.post('/:id/apply-discount', productController.applyDiscount); // [NEW]
router.post('/:id/revert-price', productController.revertPrice);     // [NEW]

module.exports = router;
