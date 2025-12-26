const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

// Public: Get all published posts
const getPublicPosts = async (req, res) => {
    try {
        const { search, tag, page = 1, limit = 10 } = req.query;
        const skip = (page - 1) * limit;

        const where = {
            status: 'PUBLISHED',
            ...(search && {
                OR: [
                    { title: { contains: search, mode: 'insensitive' } },
                    { content: { contains: search, mode: 'insensitive' } }
                ]
            }),
            ...(tag && { tags: { has: tag } })
        };

        const [posts, total] = await prisma.$transaction([
            prisma.blogPost.findMany({
                where,
                skip: parseInt(skip),
                take: parseInt(limit),
                orderBy: { publishedAt: 'desc' },
                select: {
                    id: true,
                    title: true,
                    slug: true,
                    summary: true,
                    imageUrl: true,
                    author: true,
                    tags: true,
                    publishedAt: true,
                    createdAt: true
                    // Exclude content for list view to save bandwidth
                }
            }),
            prisma.blogPost.count({ where })
        ]);

        return successResponse(res, {
            posts,
            meta: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        return errorResponse(res, 'Failed to fetch posts', 500, error);
    }
};

// Public: Get single post by slug
const getPostBySlug = async (req, res) => {
    try {
        const { slug } = req.params;
        const post = await prisma.blogPost.findUnique({
            where: { slug }
        });

        if (!post || post.status !== 'PUBLISHED') {
            return errorResponse(res, 'Post not found', 404);
        }

        return successResponse(res, post);
    } catch (error) {
        return errorResponse(res, 'Failed to fetch post', 500, error);
    }
};

// Admin: Get all posts (including drafts)
const getAllPostsAdmin = async (req, res) => {
    try {
        const posts = await prisma.blogPost.findMany({
            orderBy: { createdAt: 'desc' }
        });
        return successResponse(res, posts);
    } catch (error) {
        return errorResponse(res, 'Failed to fetch admin posts', 500, error);
    }
};

// Admin: Create Post
const createPost = async (req, res) => {
    try {
        const { title, content, summary, imageUrl, author, tags, status, slug } = req.body;

        // Auto-generate slug if not provided
        let finalSlug = slug || title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');

        // Ensure uniqueness
        const existing = await prisma.blogPost.findUnique({ where: { slug: finalSlug } });
        if (existing) {
            finalSlug = `${finalSlug}-${Date.now()}`;
        }

        const post = await prisma.blogPost.create({
            data: {
                title,
                content,
                summary,
                imageUrl,
                author: author || 'Admin',
                tags: tags || [],
                status: status || 'DRAFT',
                slug: finalSlug,
                publishedAt: status === 'PUBLISHED' ? new Date() : null
            }
        });

        return successResponse(res, post, 'Post created successfully');
    } catch (error) {
        return errorResponse(res, 'Failed to create post', 500, error);
    }
};

// Admin: Update Post
const updatePost = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, content, summary, imageUrl, author, tags, status, slug } = req.body;

        const data = {
            title, content, summary, imageUrl, author, tags, status, slug
        };

        if (status === 'PUBLISHED') {
            // If checking existing, we might valid if it was already published to not overwrite date?
            // For now, simple logic: update publishedAt if switching to PUBLISHED
            data.publishedAt = new Date();
            // Ideally check if it was already published to keep original date
        }

        const post = await prisma.blogPost.update({
            where: { id },
            data
        });

        return successResponse(res, post, 'Post updated successfully');
    } catch (error) {
        return errorResponse(res, 'Failed to update post', 500, error);
    }
};

// Admin: Delete Post
const deletePost = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.blogPost.delete({ where: { id } });
        return successResponse(res, null, 'Post deleted successfully');
    } catch (error) {
        return errorResponse(res, 'Failed to delete post', 500, error);
    }
};

module.exports = {
    getPublicPosts,
    getPostBySlug,
    getAllPostsAdmin,
    createPost,
    updatePost,
    deletePost
};
