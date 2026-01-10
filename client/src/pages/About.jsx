import React, { useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { motion, useScroll, useTransform } from 'framer-motion';
import { Canvas } from '@react-three/fiber';
import { Users, TrendingUp, Globe, Award, Target, Zap, Shield, Heart, MapPin, ArrowUpRight } from 'lucide-react';
import NetworkGlobe from '../components/3d/NetworkGlobe';
import MerchantGrowthMap from '../components/MerchantGrowthMap';

const StatItem = ({ label, value, delay }) => (
    <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay }}
        viewport={{ once: true }}
        className="text-center"
    >
        <div className="text-4xl md:text-5xl font-bold text-white mb-2 tracking-tight">{value}</div>
        <div className="text-sm text-slate-400 uppercase tracking-widest font-medium">{label}</div>
    </motion.div>
);

const About = () => {
    const { cmsContent } = useCms();
    const containerRef = useRef(null);
    
    // Parallax effect for the hero text
    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start start", "end start"]
    });
    const y = useTransform(scrollYProgress, [0, 1], ["0%", "50%"]);
    const opacity = useTransform(scrollYProgress, [0, 0.5], [1, 0]);

    return (
        <div className="min-h-screen bg-[#0a0b0f] font-sans text-slate-200 overflow-hidden">
            <Navbar />
            
            {/* 3D Background Layer */}
            <div className="fixed inset-0 z-0 pointer-events-none opacity-40">
                <Canvas camera={{ position: [0, 0, 4], fov: 45 }}>
                    <ambientLight intensity={0.5} />
                    <NetworkGlobe />
                </Canvas>
            </div>
            
            {/* Hero Section */}
            <section ref={containerRef} className="relative z-10 h-screen flex items-center justify-center px-4">
                <motion.div 
                    style={{ y, opacity }}
                    className="max-w-5xl mx-auto text-center"
                >
                    <motion.div 
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 1 }}
                        className="inline-block px-4 py-2 mb-8 rounded-full bg-indigo-500/10 border border-indigo-500/20 backdrop-blur-md text-indigo-300 font-semibold text-sm tracking-wide uppercase"
                    >
                        Pioneering The Future
                    </motion.div>
                    <h1 className="text-6xl md:text-8xl font-black text-white mb-8 tracking-tighter leading-[1.1]">
                        We Build for the <br />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 via-violet-400 to-cyan-300">
                            Bold & Ambitious
                        </span>
                    </h1>
                    <p className="text-xl md:text-2xl text-slate-300 max-w-3xl mx-auto leading-relaxed font-light">
                        Rana bukan sekadar aplikasi POS. Kami adalah ekosistem teknologi yang memberdayakan jutaan UMKM untuk bersaing di era digital.
                    </p>
                </motion.div>

                {/* Scroll Indicator */}
                <motion.div 
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1, y: [0, 10, 0] }}
                    transition={{ delay: 2, duration: 2, repeat: Infinity }}
                    className="absolute bottom-10 left-1/2 -translate-x-1/2 text-slate-500 flex flex-col items-center gap-2"
                >
                    <span className="text-xs uppercase tracking-widest">Explore Our World</span>
                    <div className="w-px h-12 bg-gradient-to-b from-indigo-500 to-transparent"></div>
                </motion.div>
            </section>

            {/* Live Operations Center Section */}
            <section className="relative z-10 py-32 px-4 bg-gradient-to-b from-[#0a0b0f] via-[#0f172a] to-[#0a0b0f]">
                <div className="max-w-7xl mx-auto">
                    <div className="grid lg:grid-cols-2 gap-20 items-center">
                        <div>
                            <div className="flex items-center gap-3 mb-6">
                                <span className="relative flex h-3 w-3">
                                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                  <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                                </span>
                                <span className="text-green-400 font-mono text-sm tracking-wider uppercase">Live Operations Center</span>
                            </div>
                            <h2 className="text-4xl md:text-5xl font-bold text-white mb-8 leading-tight">
                                Melihat Pertumbuhan <br/>
                                <span className="text-indigo-400">Secara Real-time</span>
                            </h2>
                            <p className="text-lg text-slate-300 mb-10 leading-relaxed">
                                Teknologi kami memproses jutaan transaksi setiap hari, menghubungkan pedagang dari Sabang sampai Merauke dalam satu jaringan saraf digital yang cerdas.
                            </p>
                            
                            <div className="grid grid-cols-2 gap-8">
                                <div className="p-6 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-sm">
                                    <Globe className="text-indigo-400 mb-4" size={32} />
                                    <div className="text-3xl font-bold text-white mb-1">34</div>
                                    <div className="text-sm text-slate-400">Provinsi Terjangkau</div>
                                </div>
                                <div className="p-6 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-sm">
                                    <Target className="text-pink-400 mb-4" size={32} />
                                    <div className="text-3xl font-bold text-white mb-1">99.9%</div>
                                    <div className="text-sm text-slate-400">Uptime Server</div>
                                </div>
                            </div>
                        </div>
                        
                        <div className="relative">
                            <div className="absolute -inset-1 bg-gradient-to-r from-indigo-500 to-violet-500 rounded-[2rem] blur opacity-30"></div>
                            <MerchantGrowthMap />
                        </div>
                    </div>
                </div>
            </section>

            {/* Impact Stats */}
            <section className="relative z-10 py-20 border-y border-white/5 bg-white/[0.02]">
                <div className="max-w-7xl mx-auto px-4">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-10 md:gap-4">
                        <StatItem label="Active Merchants" value="50K+" delay={0.1} />
                        <StatItem label="Daily Transactions" value="1.2M" delay={0.2} />
                        <StatItem label="Cities Covered" value="120+" delay={0.3} />
                        <StatItem label="Growth YoY" value="300%" delay={0.4} />
                    </div>
                </div>
            </section>

            {/* Mission & Vision - Glass Cards */}
            <section className="relative z-10 py-32 px-4">
                <div className="max-w-7xl mx-auto">
                    <motion.div 
                        initial={{ opacity: 0, y: 50 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-center mb-20"
                    >
                        <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">Driven by Purpose</h2>
                        <p className="text-xl text-slate-400 max-w-3xl mx-auto">
                            Kami percaya bahwa teknologi canggih seharusnya tidak hanya milik perusahaan besar. 
                            Misi kami adalah mendemokratisasi akses ke alat bisnis kelas enterprise.
                        </p>
                    </motion.div>

                    <div className="grid md:grid-cols-3 gap-8">
                        {[
                            { 
                                icon: Zap, 
                                title: "Inovasi Tanpa Henti", 
                                desc: "Kami terus mendorong batas apa yang mungkin dilakukan oleh aplikasi web, menghadirkan kecepatan native ke dalam browser.",
                                color: "text-yellow-400",
                                bg: "bg-yellow-400/10",
                                border: "border-yellow-400/20"
                            },
                            { 
                                icon: Heart, 
                                title: "Obsesi Pelanggan", 
                                desc: "Setiap fitur yang kami bangun dimulai dari masalah nyata yang dihadapi pengguna kami. Empati adalah kode sumber kami.",
                                color: "text-pink-400",
                                bg: "bg-pink-400/10",
                                border: "border-pink-400/20"
                            },
                            { 
                                icon: Shield, 
                                title: "Integritas & Keamanan", 
                                desc: "Kepercayaan adalah mata uang kami. Kami menjaga data bisnis Anda dengan standar keamanan perbankan tertinggi.",
                                color: "text-cyan-400",
                                bg: "bg-cyan-400/10",
                                border: "border-cyan-400/20"
                            }
                        ].map((item, idx) => (
                            <motion.div
                                key={idx}
                                initial={{ opacity: 0, y: 30 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                transition={{ delay: idx * 0.2 }}
                                viewport={{ once: true }}
                                whileHover={{ y: -10 }}
                                className={`p-10 rounded-3xl bg-white/5 border ${item.border} backdrop-blur-md hover:bg-white/10 transition-all duration-300 group`}
                            >
                                <div className={`w-14 h-14 rounded-2xl ${item.bg} flex items-center justify-center mb-8 group-hover:scale-110 transition-transform`}>
                                    <item.icon size={28} className={item.color} />
                                </div>
                                <h3 className="text-2xl font-bold text-white mb-4">{item.title}</h3>
                                <p className="text-slate-400 leading-relaxed">{item.desc}</p>
                            </motion.div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Our Story / CMS Content */}
            <section className="relative z-10 py-32 px-4 bg-[#0f172a]">
                <div className="max-w-4xl mx-auto">
                    <div className="flex items-center gap-4 mb-12">
                        <div className="h-px flex-1 bg-gradient-to-r from-transparent to-slate-700"></div>
                        <h2 className="text-3xl font-bold text-white uppercase tracking-widest">Our Story</h2>
                        <div className="h-px flex-1 bg-gradient-to-l from-transparent to-slate-700"></div>
                    </div>
                    
                    <div 
                        className="prose prose-lg prose-invert mx-auto text-slate-300 leading-loose"
                        dangerouslySetInnerHTML={{ 
                            __html: cmsContent.CMS_ABOUT_US || `
                                <p>Perjalanan Rana dimulai dari sebuah kedai kopi kecil di Jakarta. Kami melihat betapa sulitnya pemilik usaha mengelola inventaris, karyawan, dan laporan keuangan secara manual.</p>
                                <p>Apa yang dimulai sebagai solusi sederhana untuk satu toko, kini telah berkembang menjadi platform yang melayani ribuan bisnis di seluruh Indonesia. Kami menggabungkan desain yang indah dengan rekayasa perangkat lunak yang kuat untuk menciptakan pengalaman yang tak tertandingi.</p>
                                <p>Hari ini, Rana didukung oleh tim insinyur, desainer, dan ahli strategi produk kelas dunia yang bekerja tanpa lelah untuk satu tujuan: <strong>Membantu bisnis Anda tumbuh.</strong></p>
                            ` 
                        }} 
                    />
                </div>
            </section>

            {/* CTA Section */}
            <section className="relative z-10 py-32 px-4 overflow-hidden">
                <div className="absolute inset-0 bg-indigo-900/20"></div>
                <div className="absolute -top-40 -right-40 w-[600px] h-[600px] bg-indigo-600/30 rounded-full blur-[100px]"></div>
                <div className="absolute -bottom-40 -left-40 w-[600px] h-[600px] bg-violet-600/30 rounded-full blur-[100px]"></div>
                
                <div className="relative max-w-5xl mx-auto text-center">
                    <h2 className="text-5xl md:text-7xl font-black text-white mb-10 tracking-tight">
                        Siap Bergabung dengan <br/> Revolusi Retail?
                    </h2>
                    <p className="text-xl text-indigo-200 mb-12 max-w-2xl mx-auto">
                        Jadilah bagian dari komunitas pedagang modern yang tumbuh bersama Rana. Mulai perjalanan sukses Anda hari ini.
                    </p>
                    <motion.button 
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        className="px-10 py-5 bg-white text-indigo-900 rounded-full font-bold text-lg shadow-[0_20px_50px_rgba(255,255,255,0.2)] hover:shadow-[0_30px_60px_rgba(255,255,255,0.3)] transition-all flex items-center gap-3 mx-auto"
                    >
                        Mulai Gratis Sekarang <ArrowUpRight size={24} />
                    </motion.button>
                </div>
            </section>
        </div>
    );
};

export default About;