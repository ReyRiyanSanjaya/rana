import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getBlogPosts } from '../services/api';
import Navbar from '../components/Navbar'; // Assuming exists or I will create basic one if fails

const BlogList = () => {
    const [posts, setPosts] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            try {
                const data = await getBlogPosts();
                setPosts(data.posts);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, []);

    return (
        <div className="min-h-screen bg-gray-50">
            <Navbar />
            <div className="max-w-7xl mx-auto px-4 py-12">
                <h1 className="text-4xl font-bold text-gray-900 mb-8">Latest Updates & News</h1>

                {loading ? (
                    <div className="text-center">Loading...</div>
                ) : (
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                        {posts.map(post => (
                            <Link to={`/blog/${post.slug}`} key={post.id} className="group">
                                <article className="bg-white rounded-2xl shadow-sm hover:shadow-md transition overflow-hidden h-full flex flex-col">
                                    {post.imageUrl && (
                                        <img
                                            src={post.imageUrl}
                                            alt={post.title}
                                            className="w-full h-48 object-cover group-hover:scale-105 transition duration-500"
                                        />
                                    )}
                                    <div className="p-6 flex-1 flex flex-col">
                                        <div className="flex items-center text-sm text-gray-500 mb-3">
                                            <span>{post.tags?.[0] || 'News'}</span>
                                            <span className="mx-2">•</span>
                                            <span>{new Date(post.publishedAt || post.createdAt).toLocaleDateString()}</span>
                                        </div>
                                        <h2 className="text-xl font-bold text-gray-900 mb-2 group-hover:text-primary transition">
                                            {post.title}
                                        </h2>
                                        <p className="text-gray-600 line-clamp-3 mb-4 flex-1">
                                            {post.summary}
                                        </p>
                                        <div className="flex items-center text-primary font-medium">
                                            Read More &rarr;
                                        </div>
                                    </div>
                                </article>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default BlogList;
