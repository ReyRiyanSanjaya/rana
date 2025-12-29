import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { Canvas } from '@react-three/fiber';
import gsap from 'gsap';
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
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] text-slate-200 font-sans selection:bg-indigo-400/30">
            <Navbar />

            {/* 3D Background */}
            <div className="fixed inset-0 z-0 pointer-events-none opacity-25">
                <Canvas camera={{ position: [0, 0, 8], fov: 45 }}>
                    <Experience />
                </Canvas>
            </div>
            <div className="fixed inset-0 z-0 pointer-events-none">
                <div className="absolute -top-40 -left-40 w-[600px] h-[600px] bg-gradient-to-br from-indigo-600/30 to-violet-600/20 rounded-full blur-3xl" />
                <div className="absolute -bottom-40 -right-40 w-[500px] h-[500px] bg-gradient-to-tr from-cyan-500/20 to-indigo-500/20 rounded-full blur-3xl" />
            </div>

            {/* Hero Section */}
            <header className="relative z-10 min-h-screen flex items-center justify-center pt-20 px-4">
                <div ref={headerRef} className="max-w-4xl mx-auto text-center">
                    <div className="inline-block px-4 py-2 mb-6 rounded-full bg-white/5 border border-white/10 backdrop-blur-md text-indigo-300 font-semibold text-sm tracking-wide uppercase">
                        The Future of Retail Management
                    </div>
                    <h1 className="text-5xl md:text-7xl font-black mb-8 tracking-tight leading-tight text-white">
                        Naikkan Level Bisnis Anda <br />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 via-violet-400 to-cyan-300">
                            Tanpa Batas
                        </span>
                    </h1>
                    <p className="text-xl md:text-2xl text-slate-300 mb-10 max-w-2xl mx-auto leading-relaxed">
                        Perpaduan desain modern dan teknologi kuat. Kelola penjualan, stok, dan pertumbuhan dengan presisi yang elegan.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-6 justify-center">
                        <Link to="/login" className="px-8 py-4 rounded-xl font-bold text-lg transition-all duration-300 flex items-center justify-center gap-2 group bg-gradient-to-r from-indigo-600 to-violet-600 text-white shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)] hover:-translate-y-0.5">
                            Mulai
                            <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                        </Link>
                        <Link to="/blog" className="px-8 py-4 rounded-xl font-bold text-lg transition-all duration-300 bg-white/5 border border-white/10 text-slate-200 hover:bg-white/10">
                            Jelajahi Insight
                        </Link>
                    </div>
                </div>
            </header>

            {/* WhatsApp-Style Features Section */}
            <section className="relative z-10 py-32 px-4 overflow-hidden">
                <div className="absolute top-0 right-0 w-1/2 h-full pointer-events-none translate-x-1/2" />

                <div className="max-w-7xl mx-auto space-y-32">

                    {/* Feature 1: Efficiency (Image Left) */}
                    <div ref={coreValuesRef} className="flex flex-col md:flex-row items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2">
                            <div className="relative rounded-3xl overflow-hidden p-4 group hover:scale-[1.02] transition-transform duration-500 bg-white/5 border border-white/10 backdrop-blur-md shadow-[0_20px_50px_rgba(79,70,229,0.15)]">
                                <img
                                    src="/dashboard_red_theme.png"
                                    alt="Rana Dashboard"
                                    className="w-full h-auto rounded-2xl shadow-inner"
                                />
                            </div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6">
                            <h2 className="text-4xl md:text-5xl font-bold text-white leading-tight">
                                Manajemen secepat <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-cyan-300">Cahaya</span>
                            </h2>
                            <p className="text-xl text-slate-300 leading-relaxed">
                                Proses super cepat di setiap titik, dari pencarian stok hingga pembayaran akhir, memastikan pelanggan selalu puas.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-slate-200 font-bold text-lg hover:underline decoration-2 underline-offset-4 decoration-indigo-400 gap-2 group">
                                Pelajari efisiensi <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 2: Mobile First (Image Right) */}
                    <div className="flex flex-col md:flex-row-reverse items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2">
                            <div className="relative rounded-3xl overflow-hidden p-4 group hover:scale-[1.02] transition-transform duration-500 bg-white/5 border border-white/10 backdrop-blur-md shadow-[0_20px_50px_rgba(15,23,42,0.35)]">
                                <img
                                    src="/mobile_pos_red_theme.png"
                                    alt="Mobile POS"
                                    className="w-full h-auto rounded-2xl shadow-inner"
                                />
                            </div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6">
                            <h2 className="text-4xl md:text-5xl font-bold text-white leading-tight">
                                Mobile, <br />
                                <span className="text-slate-200">Selalu Terhubung</span>
                            </h2>
                            <p className="text-xl text-slate-300 leading-relaxed">
                                Kendalikan bisnis dari genggaman. Desain mobile-first tanpa kompromi pada daya dan fungsionalitas.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-slate-200 font-bold text-lg hover:underline decoration-2 underline-offset-4 decoration-indigo-400 gap-2 group">
                                Jelajahi fitur mobile <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 3: Security & Growth (Text Center or Grid) */}
                    <div className="text-center max-w-4xl mx-auto pt-20">
                        <h2 className="text-3xl md:text-4xl font-bold text-white mb-12">Dibangun di atas Kepercayaan & Inovasi</h2>
                        <div className="grid md:grid-cols-3 gap-8 text-left">
                            {(cmsContent.CMS_CORE_VALUES && cmsContent.CMS_CORE_VALUES.length > 0) ? (
                                cmsContent.CMS_CORE_VALUES.map((val, idx) => (
                                    <div key={idx} className="p-8 bg-white/5 border border-white/10 rounded-3xl transition-colors duration-300">
                                        <TrendingUp size={40} className="text-indigo-400 mb-6" />
                                        <h3 className="text-xl font-bold text-white mb-3">{val.title}</h3>
                                        <p className="text-slate-300">{val.desc}</p>
                                    </div>
                                ))
                            ) : (
                                <>
                                    <div className="p-8 bg-white/5 border border-white/10 rounded-3xl transition-colors duration-300">
                                        <ShieldCheck size={40} className="text-indigo-400 mb-6" />
                                        <h3 className="text-xl font-bold text-white mb-3">Keamanan Enterprise</h3>
                                        <p className="text-slate-300">Enkripsi kelas bank yang melindungi data Anda 24/7.</p>
                                    </div>
                                    <div className="p-8 bg-white/5 border border-white/10 rounded-3xl transition-colors duration-300">
                                        <TrendingUp size={40} className="text-indigo-400 mb-6" />
                                        <h3 className="text-xl font-bold text-white mb-3">Pertumbuhan Tanpa Batas</h3>
                                        <p className="text-slate-300">Skalabilitas mulus dari satu gerai hingga ribuan.</p>
                                    </div>
                                    <div className="p-8 bg-white/5 border border-white/10 rounded-3xl transition-colors duration-300">
                                        <Users size={40} className="text-indigo-400 mb-6" />
                                        <h3 className="text-xl font-bold text-white mb-3">Fokus Pelanggan</h3>
                                        <p className="text-slate-300">Alat yang dirancang untuk hubungan jangka panjang.</p>
                                    </div>
                                </>
                            )}
                        </div>
                    </div>

                </div>
            </section>

            {/* Download Section */}
            <section className="relative z-10 py-32 px-4 text-white">
                <div ref={downloadRef} className="max-w-5xl mx-auto text-center">
                    <h2 className="text-4xl md:text-6xl font-black mb-8">
                        Siap Bertransformasi?
                    </h2>
                    <p className="text-xl text-slate-300 mb-12 max-w-2xl mx-auto">
                        Bergabung dengan ribuan merchant yang membentuk masa depan retail. Unduh aplikasinya sekarang.
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

            <footer className="py-12 text-center text-slate-400 text-sm relative z-10 border-t border-white/10">
                <p>&copy; {new Date().getFullYear()} Rana POS. All rights reserved.</p>
            </footer>
        </div>
    );
};

export default Landing;
