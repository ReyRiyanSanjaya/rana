const express = require('express');
const router = express.Router();
const blogController = require('../controllers/blogController');
const verifyToken = require('../middleware/auth'); // Optional for admin routes

// Public Routes
router.get('/', blogController.getPublicPosts);
router.get('/:slug', blogController.getPostBySlug);

// Admin Routes (Protected)
// Note: In refined architecture we might put these under /admin/blog, 
// but here we can just use middleware on specific methods or assume strict route usage.
// Better practice: separate or use middleware here.
router.get('/admin/all', verifyToken, blogController.getAllPostsAdmin);
router.post('/admin', verifyToken, blogController.createPost);
router.put('/admin/:id', verifyToken, blogController.updatePost);
router.delete('/admin/:id', verifyToken, blogController.deletePost);

module.exports = router;
