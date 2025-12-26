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
        <div className="min-h-screen bg-white">
            <Navbar />

            <article className="max-w-4xl mx-auto px-4 py-12">
                <div className="text-center mb-12">
                    <div className="flex justify-center gap-2 mb-6">
                        {post.tags?.map(tag => (
                            <span key={tag} className="px-3 py-1 bg-rose-50 text-primary rounded-full text-sm font-medium">
                                {tag}
                            </span>
                        ))}
                    </div>
                    <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6 leading-tight">
                        {post.title}
                    </h1>
                    <div className="text-gray-500">
                        By <span className="text-gray-900 font-medium">{post.author}</span> • {new Date(post.publishedAt || post.createdAt).toLocaleDateString()}
                    </div>
                </div>

                {post.imageUrl && (
                    <img
                        src={post.imageUrl}
                        alt={post.title}
                        className="w-full h-[400px] object-cover rounded-3xl mb-12 shadow-lg"
                    />
                )}

                <div
                    className="prose prose-lg prose-rose mx-auto text-gray-700"
                    dangerouslySetInnerHTML={{ __html: post.content }}
                />
            </article>

            <div className="bg-gray-50 py-12 text-center">
                <Link to="/blog" className="inline-block px-8 py-3 bg-white border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition">
                    &larr; Back to Listings
                </Link>
            </div>
        </div>
    );
};

export default BlogDetail;
