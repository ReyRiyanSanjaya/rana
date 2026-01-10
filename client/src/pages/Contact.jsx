import React, { useEffect, useRef, useState } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { Mail, Phone, MapPin, Send, Loader, CheckCircle, AlertTriangle } from 'lucide-react';
import gsap from 'gsap';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { Canvas, useFrame } from '@react-three/fiber';
import { Points, PointMaterial } from '@react-three/drei';
import * as random from 'maath/random/dist/maath-random.esm';

const Stars = (props) => {
    const ref = useRef();
    const [sphere] = useState(() => random.inSphere(new Float32Array(5000), { radius: 1.2 }));

    useFrame((state, delta) => {
        ref.current.rotation.x -= delta / 10;
        ref.current.rotation.y -= delta / 15;
    });

    return (
        <group rotation={[0, 0, Math.PI / 4]}>
            <Points ref={ref} positions={sphere} stride={3} frustumCulled {...props}>
                <PointMaterial
                    transparent
                    color="#ffffff"
                    size={0.005}
                    sizeAttenuation={true}
                    depthWrite={false}
                />
            </Points>
        </group>
    );
};

const ContactCanvas = () => {
    return (
        <div className="w-full h-full absolute inset-0 z-[-1]">
            <Canvas camera={{ position: [0, 0, 1] }}>
                <Stars />
            </Canvas>
        </div>
    );
};

const Contact = () => {
    const { cmsContent } = useCms();
    const headerRef = useRef(null);
    const formRef = useRef(null);
    const infoRef = useRef(null);

    const [formData, setFormData] = useState({ name: '', email: '', message: '' });
    const [formStatus, setFormStatus] = useState({ status: 'idle', message: '' }); // idle, loading, success, error

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormStatus({ status: 'loading', message: '' });

        try {
            const response = await axios.post('/api/contact/messages', formData);
            setFormStatus({ status: 'success', message: 'Pesan Anda telah terkirim!' });
            setFormData({ name: '', email: '', message: '' });
            setTimeout(() => setFormStatus({ status: 'idle', message: '' }), 5000);
        } catch (error) {
            setFormStatus({ status: 'error', message: 'Terjadi kesalahan. Coba lagi.' });
            setTimeout(() => setFormStatus({ status: 'idle', message: '' }), 5000);
        }
    };

    useEffect(() => {
        const tl = gsap.timeline();
        tl.fromTo(headerRef.current, { y: -30, opacity: 0 }, { y: 0, opacity: 1, duration: 0.8, ease: 'power3.out' })
            .fromTo(infoRef.current.children,
                { x: -50, opacity: 0 },
                { x: 0, opacity: 1, stagger: 0.1, duration: 0.6, ease: 'power2.out' },
                '-=0.4'
            )
            .fromTo(formRef.current,
                { x: 50, opacity: 0 },
                { x: 0, opacity: 1, duration: 0.8, ease: 'power2.out' },
                '-=0.6'
            );
    }, []);

    return (
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] font-sans text-slate-200 relative">
            <ContactCanvas />
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-6xl mx-auto relative z-10">
                <div ref={headerRef} className="text-center mb-16">
                    <h1 className="text-4xl md:text-6xl font-bold text-white mb-4">Hubungi Kami</h1>
                    <p className="text-xl text-slate-300">Kami siap mendengar Anda.</p>
                </div>

                <div className="grid md:grid-cols-2 gap-10">
                    {/* Contact Info */}
                    <div ref={infoRef} className="space-y-8">
                        <motion.div whileHover={{ y: -5, boxShadow: '0 10px 20px rgba(0,0,0,0.2)' }} className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <Mail size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Email</h3>
                                <p className="text-slate-300">{cmsContent.CMS_CONTACT_EMAIL || 'support@rana.com'}</p>
                            </div>
                        </motion.div>

                        <motion.div whileHover={{ y: -5, boxShadow: '0 10px 20px rgba(0,0,0,0.2)' }} className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <Phone size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Telepon</h3>
                                <p className="text-slate-300">{cmsContent.CMS_CONTACT_PHONE || '+62 812 0000 0000'}</p>
                            </div>
                        </motion.div>

                        <motion.div whileHover={{ y: -5, boxShadow: '0 10px 20px rgba(0,0,0,0.2)' }} className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <MapPin size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Kantor Pusat</h3>
                                <p className="text-slate-300">Jakarta, Indonesia</p>
                            </div>
                        </motion.div>
                    </div>

                    {/* Contact Form */}
                    <form ref={formRef} onSubmit={handleSubmit} className="bg-white/5 border border-white/10 p-10 rounded-3xl">
                        <div className="space-y-6">
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Nama</label>
                                <input type="text" name="name" value={formData.name} onChange={handleInputChange} required className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="Nama Anda" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Email</label>
                                <input type="email" name="email" value={formData.email} onChange={handleInputChange} required className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="email@domain.com" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Pesan</label>
                                <textarea rows="4" name="message" value={formData.message} onChange={handleInputChange} required className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="Tulis pesan Anda"></textarea>
                            </div>
                            <div className="relative">
                                <motion.button 
                                    type="submit" 
                                    disabled={formStatus.status === 'loading'}
                                    className="w-full py-4 bg-gradient-to-r from-indigo-600 to-violet-600 text-white font-bold rounded-xl shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)] transition duration-300 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                                    whileHover={{ scale: formStatus.status === 'idle' ? 1.05 : 1 }}
                                    whileTap={{ scale: formStatus.status === 'idle' ? 0.95 : 1 }}
                                >
                                    <AnimatePresence mode="wait">
                                        {formStatus.status === 'loading' && (
                                            <motion.div key="loading" initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 10 }}>
                                                <Loader className="animate-spin" size={18} />
                                            </motion.div>
                                        )}
                                        {formStatus.status === 'idle' && (
                                            <motion.span key="idle" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex items-center justify-center gap-2">
                                                Kirim Pesan <Send size={18} />
                                            </motion.span>
                                        )}
                                        {formStatus.status === 'success' && (
                                            <motion.span key="success" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex items-center justify-center gap-2">
                                                Terkirim! <CheckCircle size={18} />
                                            </motion.span>
                                        )}
                                        {formStatus.status === 'error' && (
                                            <motion.span key="error" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex items-center justify-center gap-2">
                                                Gagal <AlertTriangle size={18} />
                                            </motion.span>
                                        )}
                                    </AnimatePresence>
                                </motion.button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Contact;
