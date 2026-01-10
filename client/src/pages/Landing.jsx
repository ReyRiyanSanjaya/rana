import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Canvas } from '@react-three/fiber';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { motion } from 'framer-motion';
import { ArrowRight, Box, TrendingUp, Users, Smartphone, ShieldCheck, Zap, BarChart3, PieChart, LineChart, Sparkles, Activity, Layers } from 'lucide-react';
import Experience from '../components/3d/Experience';
import Navbar from '../components/Navbar';
import LiveDashboardPreview from '../components/LiveDashboardPreview';
import useCms from '../hooks/useCms';

gsap.registerPlugin(ScrollTrigger);

const GrowthSimulator = () => {
    const [monthlySales, setMonthlySales] = useState(50000000);
    const [growthRate, setGrowthRate] = useState(20);

    const projectedSales = monthlySales * (1 + growthRate / 100);
    const annualExtra = (projectedSales - monthlySales) * 12;

    return (
        <div className="bg-white/5 border border-white/10 rounded-3xl p-8 backdrop-blur-md">
            <div className="mb-8">
                <h3 className="text-2xl font-bold text-white mb-2">Simulasi Pertumbuhan Bisnis</h3>
                <p className="text-slate-400">Lihat potensi kenaikan omzet Anda dengan teknologi AI Rana.</p>
            </div>

            <div className="space-y-6 mb-8">
                <div>
                    <div className="flex justify-between text-slate-300 mb-2">
                        <span>Omzet Bulanan Saat Ini</span>
                        <span className="font-mono text-indigo-400">Rp {monthlySales.toLocaleString('id-ID')}</span>
                    </div>
                    <input 
                        type="range" 
                        min="10000000" 
                        max="500000000" 
                        step="1000000" 
                        value={monthlySales} 
                        onChange={(e) => setMonthlySales(Number(e.target.value))}
                        className="w-full h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-indigo-500"
                    />
                </div>
                <div>
                    <div className="flex justify-between text-slate-300 mb-2">
                        <span>Optimasi AI (Efisiensi & Stok)</span>
                        <span className="font-mono text-green-400">+{growthRate}%</span>
                    </div>
                    <div className="w-full bg-slate-700 h-2 rounded-lg overflow-hidden">
                        <div className="bg-gradient-to-r from-indigo-500 to-green-400 h-full transition-all duration-500" style={{ width: `${growthRate}%` }}></div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
                <div className="bg-indigo-600/20 border border-indigo-500/30 p-4 rounded-xl">
                    <div className="text-slate-400 text-sm mb-1">Proyeksi Bulan Depan</div>
                    <div className="text-2xl font-bold text-white">Rp {projectedSales.toLocaleString('id-ID')}</div>
                </div>
                <div className="bg-green-600/20 border border-green-500/30 p-4 rounded-xl">
                    <div className="text-slate-400 text-sm mb-1">Potensi Tambahan / Tahun</div>
                    <div className="text-2xl font-bold text-green-400">+Rp {annualExtra.toLocaleString('id-ID')}</div>
                </div>
            </div>
        </div>
    );
};

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

            {/* Live Dashboard Preview Section */}
            <section className="relative z-20 -mt-20 mb-32 px-4">
                <motion.div 
                    initial={{ opacity: 0, y: 100 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8 }}
                    className="max-w-6xl mx-auto"
                >
                    <LiveDashboardPreview />
                </motion.div>
            </section>

            {/* WhatsApp-Style Features Section */}
            <section className="relative z-10 py-12 px-4 overflow-hidden">
                <div className="absolute top-0 right-0 w-1/2 h-full pointer-events-none translate-x-1/2" />

                <div className="max-w-7xl mx-auto space-y-32">

                    {/* Feature 1: Efficiency (Image Left) */}
                    <div ref={coreValuesRef} className="flex flex-col md:flex-row items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2 order-2 md:order-1">
                             <motion.div 
                                whileHover={{ scale: 1.02, rotate: -1 }}
                                className="relative rounded-3xl overflow-hidden p-1 bg-gradient-to-br from-indigo-500/30 to-violet-500/30 backdrop-blur-md"
                            >
                                <div className="bg-[#0f172a] rounded-[22px] overflow-hidden">
                                    <div className="h-64 md:h-80 bg-gradient-to-br from-indigo-900/50 to-slate-900 flex items-center justify-center relative overflow-hidden group">
                                        <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-20"></div>
                                        <Zap size={80} className="text-yellow-400 drop-shadow-[0_0_15px_rgba(250,204,21,0.5)] group-hover:scale-110 transition-transform duration-500" />
                                        
                                        {/* Floating Elements */}
                                        <motion.div 
                                            animate={{ y: [0, -10, 0] }}
                                            transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                                            className="absolute top-10 right-10 bg-white/10 backdrop-blur-md border border-white/20 p-3 rounded-xl"
                                        >
                                            <Activity className="text-green-400" size={24} />
                                        </motion.div>
                                    </div>
                                </div>
                            </motion.div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6 order-1 md:order-2">
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 text-xs font-bold uppercase tracking-wider">
                                <Zap size={14} />
                                <span>Lightning Fast</span>
                            </div>
                            <h2 className="text-4xl md:text-5xl font-bold text-white leading-tight">
                                Manajemen secepat <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-cyan-300">Kecepatan Pikiran</span>
                            </h2>
                            <p className="text-xl text-slate-300 leading-relaxed">
                                Tidak ada lagi loading lama. Arsitektur kami dirancang untuk performa instan, memastikan setiap transaksi dan laporan tersaji dalam milidetik.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-slate-200 font-bold text-lg hover:text-indigo-400 transition-colors gap-2 group">
                                Pelajari efisiensi <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 2: Mobile First (Image Right) */}
                    <div className="flex flex-col md:flex-row-reverse items-center gap-10 md:gap-20">
                        <div className="w-full md:w-1/2">
                             <motion.div 
                                whileHover={{ scale: 1.02, rotate: 1 }}
                                className="relative rounded-3xl overflow-hidden p-1 bg-gradient-to-br from-violet-500/30 to-pink-500/30 backdrop-blur-md"
                            >
                                <div className="bg-[#0f172a] rounded-[22px] overflow-hidden">
                                    <div className="h-64 md:h-80 bg-gradient-to-bl from-violet-900/50 to-slate-900 flex items-center justify-center relative overflow-hidden group">
                                        <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-20"></div>
                                        <Smartphone size={80} className="text-pink-400 drop-shadow-[0_0_15px_rgba(236,72,153,0.5)] group-hover:scale-110 transition-transform duration-500" />
                                         
                                         {/* Floating Elements */}
                                        <motion.div 
                                            animate={{ y: [0, -15, 0] }}
                                            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut", delay: 1 }}
                                            className="absolute bottom-10 left-10 bg-white/10 backdrop-blur-md border border-white/20 p-3 rounded-xl"
                                        >
                                            <Layers className="text-violet-400" size={24} />
                                        </motion.div>
                                    </div>
                                </div>
                            </motion.div>
                        </div>
                        <div className="w-full md:w-1/2 text-left space-y-6">
                            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-pink-500/10 border border-pink-500/20 text-pink-400 text-xs font-bold uppercase tracking-wider">
                                <Smartphone size={14} />
                                <span>Mobile First</span>
                            </div>
                            <h2 className="text-4xl md:text-5xl font-bold text-white leading-tight">
                                Bisnis dalam <br />
                                <span className="text-slate-200">Genggaman Anda</span>
                            </h2>
                            <p className="text-xl text-slate-300 leading-relaxed">
                                Kontrol penuh dari mana saja. Aplikasi mobile Rana memberikan kekuatan desktop dalam format yang ringkas dan intuitif.
                            </p>
                            <Link to="/features" className="inline-flex items-center text-slate-200 font-bold text-lg hover:text-pink-400 transition-colors gap-2 group">
                                Jelajahi fitur mobile <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
                            </Link>
                        </div>
                    </div>

                    {/* Feature 3: Security & Growth (Core Values) */}
                    <div className="text-center max-w-6xl mx-auto pt-20">
                        <div className="inline-block mb-4 px-4 py-1.5 rounded-full border border-slate-700 bg-slate-800/50 backdrop-blur text-slate-300 text-sm font-medium">
                            Our Core Values
                        </div>
                        <h2 className="text-3xl md:text-5xl font-bold text-white mb-16">Fondasi Kesuksesan Bisnis Modern</h2>
                        <div className="grid md:grid-cols-3 gap-6 text-left">
                            {(cmsContent.CMS_CORE_VALUES && cmsContent.CMS_CORE_VALUES.length > 0) ? (
                                cmsContent.CMS_CORE_VALUES.map((val, idx) => (
                                    <motion.div 
                                        key={idx} 
                                        whileHover={{ y: -10 }}
                                        className="p-8 bg-[#1e293b]/40 border border-slate-700/50 rounded-3xl hover:bg-[#1e293b]/60 hover:border-indigo-500/30 transition-all duration-300 group"
                                    >
                                        <div className="w-14 h-14 rounded-2xl bg-indigo-500/10 flex items-center justify-center mb-6 group-hover:bg-indigo-500/20 transition-colors">
                                            <TrendingUp size={28} className="text-indigo-400" />
                                        </div>
                                        <h3 className="text-xl font-bold text-white mb-3 group-hover:text-indigo-300 transition-colors">{val.title}</h3>
                                        <p className="text-slate-400 leading-relaxed">{val.desc}</p>
                                    </motion.div>
                                ))
                            ) : (
                                <>
                                    <motion.div 
                                        whileHover={{ y: -10 }}
                                        className="p-8 bg-[#1e293b]/40 border border-slate-700/50 rounded-3xl hover:bg-[#1e293b]/60 hover:border-indigo-500/30 transition-all duration-300 group"
                                    >
                                        <div className="w-14 h-14 rounded-2xl bg-blue-500/10 flex items-center justify-center mb-6 group-hover:bg-blue-500/20 transition-colors">
                                            <ShieldCheck size={28} className="text-blue-400" />
                                        </div>
                                        <h3 className="text-xl font-bold text-white mb-3 group-hover:text-blue-300 transition-colors">Keamanan Terjamin</h3>
                                        <p className="text-slate-400 leading-relaxed">Data bisnis Anda adalah aset paling berharga. Kami melindunginya dengan enkripsi tingkat lanjut dan backup otomatis.</p>
                                    </motion.div>

                                    <motion.div 
                                        whileHover={{ y: -10 }}
                                        className="p-8 bg-[#1e293b]/40 border border-slate-700/50 rounded-3xl hover:bg-[#1e293b]/60 hover:border-emerald-500/30 transition-all duration-300 group"
                                    >
                                        <div className="w-14 h-14 rounded-2xl bg-emerald-500/10 flex items-center justify-center mb-6 group-hover:bg-emerald-500/20 transition-colors">
                                            <TrendingUp size={28} className="text-emerald-400" />
                                        </div>
                                        <h3 className="text-xl font-bold text-white mb-3 group-hover:text-emerald-300 transition-colors">Pertumbuhan Berkelanjutan</h3>
                                        <p className="text-slate-400 leading-relaxed">Sistem yang tumbuh bersama Anda. Dari satu gerai kecil hingga waralaba nasional, Rana siap menskalakan bisnis Anda.</p>
                                    </motion.div>

                                    <motion.div 
                                        whileHover={{ y: -10 }}
                                        className="p-8 bg-[#1e293b]/40 border border-slate-700/50 rounded-3xl hover:bg-[#1e293b]/60 hover:border-violet-500/30 transition-all duration-300 group"
                                    >
                                        <div className="w-14 h-14 rounded-2xl bg-violet-500/10 flex items-center justify-center mb-6 group-hover:bg-violet-500/20 transition-colors">
                                            <Users size={28} className="text-violet-400" />
                                        </div>
                                        <h3 className="text-xl font-bold text-white mb-3 group-hover:text-violet-300 transition-colors">Customer Centric</h3>
                                        <p className="text-slate-400 leading-relaxed">Fitur CRM yang mendalam membantu Anda memahami dan melayani pelanggan dengan lebih personal dan efektif.</p>
                                    </motion.div>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            </section>

            {/* AI Growth Section */}
            <section className="relative z-10 py-32 px-4 bg-white/5">
                <div className="max-w-7xl mx-auto">
                    <div className="flex flex-col lg:flex-row items-center gap-16">
                        <div className="w-full lg:w-1/2 space-y-8">
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-300 text-sm font-semibold">
                                <Sparkles size={16} />
                                <span>Teknologi Rana Intelligence™</span>
                            </div>
                            <h2 className="text-4xl md:text-5xl font-bold text-white leading-tight">
                                Kembangkan Bisnis dengan <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">Kecerdasan Buatan</span>
                            </h2>
                            <p className="text-xl text-slate-300 leading-relaxed">
                                Jangan hanya mencatat transaksi. Rana menganalisis pola penjualan, memprediksi tren, dan memberikan saran actionable untuk meningkatkan profitabilitas bisnis Anda secara otomatis.
                            </p>
                            
                            <div className="space-y-4">
                                {[
                                    { icon: BarChart3, title: 'Prediksi Penjualan', desc: 'Forecast omzet harian dengan akurasi tinggi.' },
                                    { icon: PieChart, title: 'Analisis Pelanggan', desc: 'Pahami preferensi dan kebiasaan belanja pelanggan.' },
                                    { icon: Zap, title: 'Restock Pintar', desc: 'Notifikasi otomatis saat stok menipis berdasarkan tren.' }
                                ].map((item, idx) => (
                                    <div key={idx} className="flex items-start gap-4 p-4 rounded-xl hover:bg-white/5 transition-colors">
                                        <div className="bg-indigo-600/20 p-3 rounded-lg text-indigo-400">
                                            <item.icon size={24} />
                                        </div>
                                        <div>
                                            <h4 className="text-lg font-bold text-white">{item.title}</h4>
                                            <p className="text-slate-400 text-sm">{item.desc}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                        
                        <div className="w-full lg:w-1/2">
                            <GrowthSimulator />
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
