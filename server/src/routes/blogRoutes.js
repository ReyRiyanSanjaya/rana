const express = require('express');
const router = express.Router();
const blogController = require('../controllers/blogController');
const verifyToken = require('../middleware/auth'); // Optional for admin routes
const multer = require('multer');
const path = require('path');

// Multer Config
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Ensure this directory exists or node will throw. 
        // Ideally we should use fs.mkdirSync or similar if not exists, but 'uploads' is usually safe.
        cb(null, 'uploads/'); 
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'blog-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });


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

// Upload Route
router.post('/upload', verifyToken, upload.single('image'), blogController.uploadImage);

module.exports = router;
