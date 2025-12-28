import React, { useState, useEffect } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import { Edit, Trash2, Plus, X, Eye } from 'lucide-react';
import ReactQuill from 'react-quill-new';
import 'react-quill-new/dist/quill.snow.css';

// Quill Editor Modules Configuration
const quillModules = {
    toolbar: [
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        [{ 'font': [] }],
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'list': 'ordered' }, { 'list': 'bullet' }],
        [{ 'indent': '-1' }, { 'indent': '+1' }],
        [{ 'align': [] }],
        ['blockquote', 'code-block'],
        ['link', 'image', 'video'],
        ['clean']
    ],
};

const quillFormats = [
    'header', 'font', 'bold', 'italic', 'underline', 'strike',
    'color', 'background', 'list', 'indent', 'align',
    'blockquote', 'code-block', 'link', 'image', 'video'
];

const BlogManager = () => {
    const [posts, setPosts] = useState([]);
    const [open, setOpen] = useState(false);
    const [editingPost, setEditingPost] = useState(null);
    const [loading, setLoading] = useState(false);

    // Form State
    const [formData, setFormData] = useState({
        title: '',
        slug: '',
        summary: '',
        content: '',
        imageUrl: '',
        author: 'Admin',
        tags: '',
        status: 'DRAFT'
    });

    useEffect(() => {
        fetchPosts();
    }, []);

    const fetchPosts = async () => {
        setLoading(true);
        try {
            const res = await api.get('/blog/admin/all');
            setPosts(res.data.data);
        } catch (err) {
            console.error("Failed to fetch posts", err);
        } finally {
            setLoading(false);
        }
    };

    const handleOpen = (post = null) => {
        if (post) {
            setEditingPost(post);
            setFormData({
                title: post.title,
                slug: post.slug,
                summary: post.summary || '',
                content: post.content,
                imageUrl: post.imageUrl || '',
                author: post.author || 'Admin',
                // Check if tags is array or string if server returns something else
                tags: Array.isArray(post.tags) ? post.tags.join(', ') : (post.tags || ''),
                status: post.status
            });
        } else {
            setEditingPost(null);
            setFormData({
                title: '',
                slug: '',
                summary: '',
                content: '',
                imageUrl: '',
                author: 'Admin',
                tags: '',
                status: 'DRAFT'
            });
        }
        setOpen(true);
    };

    const handleClose = () => setOpen(false);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const payload = {
                ...formData,
                tags: formData.tags.split(',').map(t => t.trim()).filter(t => t)
            };

            if (editingPost) {
                await api.put(`/blog/admin/${editingPost.id}`, payload);
            } else {
                await api.post('/blog/admin', payload);
            }
            fetchPosts();
            handleClose();
        } catch (err) {
            alert('Failed to save post: ' + (err.response?.data?.message || err.message));
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure you want to delete this post?')) return;
        try {
            await api.delete(`/blog/admin/${id}`);
            fetchPosts();
        } catch (err) {
            alert('Failed to delete');
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Blog Manager</h1>
                    <p className="text-slate-500 mt-1">Create and manage content for your blog.</p>
                </div>
                <Button
                    onClick={() => handleOpen()}
                    icon={Plus}
                >
                    New Post
                </Button>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Title</Th>
                            <Th>Author</Th>
                            <Th>Status</Th>
                            <Th>Published</Th>
                            <Th className="text-right">Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">Loading posts...</Td>
                            </Tr>
                        ) : posts.length === 0 ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">No posts found.</Td>
                            </Tr>
                        ) : (
                            posts.map((post) => (
                                <Tr key={post.id}>
                                    <Td>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-slate-900">{post.title}</span>
                                            <span className="text-xs text-slate-500">/{post.slug}</span>
                                        </div>
                                    </Td>
                                    <Td>{post.author}</Td>
                                    <Td>
                                        <Badge variant={post.status === 'PUBLISHED' ? 'success' : 'secondary'}>
                                            {post.status}
                                        </Badge>
                                    </Td>
                                    <Td>
                                        {post.publishedAt ? new Date(post.publishedAt).toLocaleDateString() : '-'}
                                    </Td>
                                    <Td className="text-right">
                                        <div className="flex justify-end gap-2">
                                            <Button
                                                size="sm"
                                                variant="secondary"
                                                icon={Edit}
                                                onClick={() => handleOpen(post)}
                                            >
                                                Edit
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                className="text-red-500 border-red-200 hover:bg-red-50"
                                                icon={Trash2}
                                                onClick={() => handleDelete(post.id)}
                                            >
                                                Delete
                                            </Button>
                                        </div>
                                    </Td>
                                </Tr>
                            ))
                        )}
                    </Tbody>
                </Table>
            </Card>

            {/* Modal / Dialog */}
            {open && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[95vh] overflow-y-auto">
                        <style>{`
                            .ql-container { min-height: 250px; font-size: 14px; }
                            .ql-editor { min-height: 250px; }
                            .ql-toolbar { border-top-left-radius: 6px; border-top-right-radius: 6px; }
                            .ql-container { border-bottom-left-radius: 6px; border-bottom-right-radius: 6px; }
                        `}</style>
                        <div className="flex items-center justify-between p-4 border-b border-slate-100">
                            <h2 className="text-lg font-semibold text-slate-900">
                                {editingPost ? 'Edit Post' : 'New Post'}
                            </h2>
                            <button onClick={handleClose} className="text-slate-400 hover:text-slate-600">
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
                                    <input
                                        type="text"
                                        name="title"
                                        value={formData.title}
                                        onChange={handleChange}
                                        required
                                        className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
                                    <select
                                        name="status"
                                        value={formData.status}
                                        onChange={handleChange}
                                        className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    >
                                        <MenuItem value="DRAFT">Draft</MenuItem>
                                        <MenuItem value="PUBLISHED">Published</MenuItem>
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Slug (Optional)</label>
                                <input
                                    type="text"
                                    name="slug"
                                    value={formData.slug}
                                    onChange={handleChange}
                                    placeholder="Auto-generated if empty"
                                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Summary</label>
                                <textarea
                                    name="summary"
                                    value={formData.summary}
                                    onChange={handleChange}
                                    rows="2"
                                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Image URL</label>
                                <input
                                    type="text"
                                    name="imageUrl"
                                    value={formData.imageUrl}
                                    onChange={handleChange}
                                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Tags (comma separated)</label>
                                <input
                                    type="text"
                                    name="tags"
                                    value={formData.tags}
                                    onChange={handleChange}
                                    className="w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-2">Content</label>
                                <div className="border border-slate-300 rounded-md overflow-hidden">
                                    <ReactQuill
                                        theme="snow"
                                        value={formData.content}
                                        onChange={(value) => setFormData({ ...formData, content: value })}
                                        modules={quillModules}
                                        formats={quillFormats}
                                        placeholder="Write your blog content here..."
                                        style={{ minHeight: '300px' }}
                                    />
                                </div>
                            </div>

                            <div className="flex justify-end gap-3 pt-4 border-t border-slate-100 mt-4">
                                <Button type="button" variant="ghost" onClick={handleClose}>Cancel</Button>
                                <Button type="submit">Save Post</Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

// Helper for select
const MenuItem = ({ value, children }) => <option value={value}>{children}</option>;

export default BlogManager;
