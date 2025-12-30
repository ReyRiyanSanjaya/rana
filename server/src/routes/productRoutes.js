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
// [NEW] Flash Sale Submission (Merchant)
router.post('/flashsales', productController.createFlashSale);
router.get('/flashsales', productController.getMyFlashSales);
router.put('/flashsales/:id', productController.updateFlashSale);
router.delete('/flashsales/:id', productController.deleteFlashSale);
router.put('/flashsales/:id/status', productController.updateFlashSaleStatusForMerchant);
router.post('/flashsales/:id/items', productController.addFlashSaleItem);
router.put('/flashsales/:id/items/:itemId', productController.updateFlashSaleItem);
router.delete('/flashsales/:id/items/:itemId', productController.deleteFlashSaleItem);

module.exports = router;
