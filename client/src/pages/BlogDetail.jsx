import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { getBlogPostBySlug } from '../services/api';
import Navbar from '../components/Navbar';

const BlogDetail = () => {
    const { slug } = useParams();
    const [post, setPost] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const load = async () => {
            try {
                const data = await getBlogPostBySlug(slug);
                setPost(data);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        load();
    }, [slug]);

    if (loading) return <div className="min-h-screen grid place-items-center">Loading...</div>;
    if (!post) return <div className="min-h-screen grid place-items-center">Post not found</div>;

    return (
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] text-slate-200">
            <Navbar />

            <article className="max-w-4xl mx-auto px-4 py-12">
                <div className="text-center mb-12">
                    <div className="flex justify-center gap-2 mb-6">
                        {post.tags?.map(tag => (
                            <span key={tag} className="px-3 py-1 bg-white/10 border border-white/10 text-indigo-300 rounded-full text-sm font-medium">
                                {tag}
                            </span>
                        ))}
                    </div>
                    <h1 className="text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
                        {post.title}
                    </h1>
                    <div className="text-slate-400">
                        Oleh <span className="text-slate-200 font-medium">{post.author}</span> • {new Date(post.publishedAt || post.createdAt).toLocaleDateString()}
                    </div>
                </div>

                {post.imageUrl && (
                    <img
                        src={post.imageUrl}
                        alt={post.title}
                        className="w-full h-[400px] object-cover rounded-3xl mb-12 shadow-[0_20px_50px_rgba(79,70,229,0.2)]"
                    />
                )}

                <div
                    className="mx-auto text-slate-200 leading-relaxed"
                    dangerouslySetInnerHTML={{ __html: post.content }}
                />
            </article>

            <div className="py-12 text-center">
                <Link to="/blog" className="inline-block px-8 py-3 bg-white/5 border border-white/10 rounded-lg font-medium text-slate-200 hover:bg-white/10 transition">
                    &larr; Kembali ke Daftar
                </Link>
            </div>
        </div>
    );
};

export default BlogDetail;
