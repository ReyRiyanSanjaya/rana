import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { Canvas } from '@react-three/fiber';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ArrowRight, Box, TrendingUp, Users, Smartphone, ShieldCheck, Zap } from 'lucide-react';
import Experience from '../components/3d/Experience';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms'; // [NEW]

gsap.registerPlugin(ScrollTrigger);

const Landing = () => {
    const { cmsContent } = useCms(); // [NEW]
    const headerRef = useRef(null);
    const coreValuesRef = useRef(null);
    const downloadRef = useRef(null);

    useEffect(() => {
        // Hero Animation
        gsap.fromTo(headerRef.current.children,
            { y: 50, opacity: 0 },
            { y: 0, opacity: 1, stagger: 0.2, duration: 1, ease: 'power3.out', delay: 0.5 }
        );

        // Core Values Animation
        gsap.fromTo(coreValuesRef.current.children,
            { y: 100, opacity: 0 },
            {
                y: 0, opacity: 1, stagger: 0.1, duration: 0.8, ease: 'back.out(1.7)',
                scrollTrigger: {
                    trigger: coreValuesRef.current,
                    start: 'top 80%',
                }
            }
        );

        // Download Section Animation
        gsap.fromTo(downloadRef.current,
            { scale: 0.9, opacity: 0 },
            {
                scale: 1, opacity: 1, duration: 0.8, ease: 'power2.out',
                scrollTrigger: {
                    trigger: downloadRef.current,
                    start: 'top 75%',
                }
            }
        );

    }, []);

    return (
        <div className="min-h-screen bg-[#e0e5ec] text-gray-700 font-sans selection:bg-rose-200">
            <Navbar />

            {/* 3D Background */}
            <div className="fixed inset-0 z-0 pointer-events-none opacity-60">
                <Canvas camera={{ position: [0, 0, 8], fov: 45 }}>
                    <Experience />
                </Canvas>
            </div>

            {/* Hero Section */}
            <header className="relative z-10 min-h-screen flex items-center justify-center pt-20 px-4">
                <div ref={headerRef} className="max-w-4xl mx-auto text-center">
                    <div className="inline-block px-4 py-2 mb-6 rounded-full bg-[#e0e5ec] shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff] text-primary font-semibold text-sm tracking-wide uppercase">
                        The Future of Retail Management
                    </div>
                    <h1 className="text-5xl md:text-7xl font-black mb-8 text-[#303346] tracking-tight leading-tight">
                        Elevate Your Business <br />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-orange-600">
                            Beyond Limits
                        </span>
                    </h1>
                    <p className="text-xl md:text-2xl text-gray-500 mb-10 max-w-2xl mx-auto leading-relaxed">
                        Experience the perfect fusion of aesthetic design and powerful technology. Manage sales, inventory, and growth with effortless precision.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-6 justify-center">
                        <Link to="/login" className="px-8 py-4 bg-[#e0e5ec] rounded-xl text-primary font-bold text-lg shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff] hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-all duration-300 flex items-center justify-center gap-2 group">
                            Get Started
                            <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                        </Link>
                        <Link to="/blog" className="px-8 py-4 bg-[#e0e5ec] rounded-xl text-gray-600 font-bold text-lg shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff] hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-all duration-300">
                            Explore Insights
                        </Link>
                    </div>
                </div>
            </header>

            {/* WhatsApp-Style Features Section */}
            <section className="relative z-10 py-32 px-4 bg-white overflow-hidden">
                {/* Decorative background circle */}
                <div className="absolute top-0 right-0 w-1/2 h-full bg-[#fae8eb] rounded-l-[10rem] opacity-30 pointer-events-none translate-x-1/2" />

                <div className="max-w-7xl mx-auto space-y-32">

                    {/* Feature 1: Efficiency (Image Left) */}
                    <div ref={coreValuesRef} className="flex flex-col md:flex-row items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2">
                            <div className="relative rounded-3xl overflow-hidden shadow-[0_20px_50px_rgba(191,9,47,0.2)] bg-[#fae8eb] p-4 group hover:scale-[1.02] transition-transform duration-500">
                                <img
                                    src="/dashboard_red_theme.png"
                                    alt="Rana Dashboard"
                                    className="w-full h-auto rounded-2xl shadow-inner"
                                />
                            </div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6">
                            <h2 className="text-4xl md:text-5xl font-bold text-[#303346] leading-tight">
                                Management at the <br />
                                <span className="text-primary">Speed of Light</span>
                            </h2>
                            <p className="text-xl text-gray-500 leading-relaxed">
                                Lightning-fast processing ensuring you never keep a customer waiting. Optimized for speed at every touchpoint, from inventory lookups to final checkout.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-primary font-bold text-lg hover:underline decoration-2 underline-offset-4 decoration-primary gap-2 group">
                                Learn about efficiency <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 2: Mobile First (Image Right) */}
                    <div className="flex flex-col md:flex-row-reverse items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2">
                            <div className="relative rounded-3xl overflow-hidden shadow-[0_20px_50px_rgba(15,23,42,0.15)] bg-slate-50 p-4 group hover:scale-[1.02] transition-transform duration-500">
                                <img
                                    src="/mobile_pos_red_theme.png"
                                    alt="Mobile POS"
                                    className="w-full h-auto rounded-2xl shadow-inner"
                                />
                            </div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6">
                            <h2 className="text-4xl md:text-5xl font-bold text-[#303346] leading-tight">
                                Go Mobile, <br />
                                <span className="text-slate-700">Stay Connected</span>
                            </h2>
                            <p className="text-xl text-gray-500 leading-relaxed">
                                Control your empire from the palm of your hand. Whether you are on the floor or on the go, our mobile-first design ensures zero compromises on power or functionality.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-slate-700 font-bold text-lg hover:underline decoration-2 underline-offset-4 decoration-slate-900 gap-2 group">
                                Explore mobile features <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 3: Security & Growth (Text Center or Grid) */}
                    <div className="text-center max-w-4xl mx-auto pt-20">
                        <h2 className="text-3xl md:text-4xl font-bold text-[#303346] mb-12">Built on Trust & Innovation</h2>
                        <div className="grid md:grid-cols-3 gap-8 text-left">
                            {(cmsContent.CMS_CORE_VALUES && cmsContent.CMS_CORE_VALUES.length > 0) ? (
                                cmsContent.CMS_CORE_VALUES.map((val, idx) => (
                                    <div key={idx} className="p-8 bg-gray-50 rounded-3xl hover:bg-[#fae8eb] transition-colors duration-300">
                                        <TrendingUp size={40} className="text-primary mb-6" />
                                        <h3 className="text-xl font-bold text-[#303346] mb-3">{val.title}</h3>
                                        <p className="text-gray-500">{val.desc}</p>
                                    </div>
                                ))
                            ) : (
                                <>
                                    <div className="p-8 bg-gray-50 rounded-3xl hover:bg-[#fae8eb] transition-colors duration-300">
                                        <ShieldCheck size={40} className="text-primary mb-6" />
                                        <h3 className="text-xl font-bold text-[#303346] mb-3">Enterprise Security</h3>
                                        <p className="text-gray-500">Bank-grade encryption protecting your data 24/7.</p>
                                    </div>
                                    <div className="p-8 bg-gray-50 rounded-3xl hover:bg-[#fae8eb] transition-colors duration-300">
                                        <TrendingUp size={40} className="text-primary mb-6" />
                                        <h3 className="text-xl font-bold text-[#303346] mb-3">Limitless Growth</h3>
                                        <p className="text-gray-500">Scales effortlessly from one store to one thousand.</p>
                                    </div>
                                    <div className="p-8 bg-gray-50 rounded-3xl hover:bg-[#fae8eb] transition-colors duration-300">
                                        <Users size={40} className="text-primary mb-6" />
                                        <h3 className="text-xl font-bold text-[#303346] mb-3">Customer Focus</h3>
                                        <p className="text-gray-500">Tools designed to build lasting relationships.</p>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>

                </div>
            </section>

            {/* Download Section */}
            <section className="relative z-10 py-32 px-4 bg-[#303346] text-white">
                <div ref={downloadRef} className="max-w-5xl mx-auto text-center">
                    <h2 className="text-4xl md:text-6xl font-black mb-8">
                        Ready to Transform?
                    </h2>
                    <p className="text-xl text-gray-300 mb-12 max-w-2xl mx-auto">
                        Join thousands of merchants who are reshaping the future of retail. Download the app today.
                    </p>
                    <div className="flex flex-col sm:flex-row justify-center gap-6">
                        <button className="px-8 py-4 bg-white rounded-2xl text-[#303346] font-bold flex items-center justify-center gap-4 hover:bg-gray-100 transition-all duration-300 transform hover:-translate-y-1">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Play Store" className="h-8" />
                            <span className="text-left">
                                <small className="block text-xs text-gray-500">GET IT ON</small>
                                Google Play
                            </span>
                        </button>
                        <button className="px-8 py-4 bg-white rounded-2xl text-[#303346] font-bold flex items-center justify-center gap-4 hover:bg-gray-100 transition-all duration-300 transform hover:-translate-y-1">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" className="h-8" />
                            <span className="text-left">
                                <small className="block text-xs text-gray-500">Download on the</small>
                                App Store
                            </span>
                        </button>
                    </div>
                </div>
            </section>

            <footer className="py-12 text-center text-gray-400 text-sm relative z-10 bg-[#303346] border-t border-gray-700">
                <p>&copy; {new Date().getFullYear()} Rana POS. All rights reserved.</p>
            </footer>
        </div>
    );
};

export default Landing;
