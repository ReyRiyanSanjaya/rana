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
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] text-slate-200">
            <Navbar />
            <div className="max-w-7xl mx-auto px-4 py-12">
                <h1 className="text-4xl font-bold text-white mb-8">Update & Berita Terbaru</h1>

                {loading ? (
                    <div className="text-center">Loading...</div>
                ) : (
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                        {posts.map(post => (
                            <Link to={`/blog/${post.slug}`} key={post.id} className="group">
                                <article className="bg-white/5 border border-white/10 rounded-2xl transition overflow-hidden h-full flex flex-col hover:-translate-y-1 duration-300">
                                    {post.imageUrl && (
                                        <img
                                            src={post.imageUrl}
                                            alt={post.title}
                                            className="w-full h-48 object-cover group-hover:scale-105 transition duration-500"
                                        />
                                    )}
                                    <div className="p-6 flex-1 flex flex-col">
                                        <div className="flex items-center text-sm text-slate-400 mb-3">
                                            <span className="px-2 py-0.5 bg-white/10 border border-white/10 rounded-full">{post.tags?.[0] || 'News'}</span>
                                            <span className="mx-2">•</span>
                                            <span>{new Date(post.publishedAt || post.createdAt).toLocaleDateString()}</span>
                                        </div>
                                        <h2 className="text-xl font-bold text-white mb-2 group-hover:text-indigo-300 transition">
                                            {post.title}
                                        </h2>
                                        <p className="text-slate-300 line-clamp-3 mb-4 flex-1">
                                            {post.summary}
                                        </p>
                                        <div className="flex items-center text-indigo-300 font-medium">
                                            Baca Selengkapnya &rarr;
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
