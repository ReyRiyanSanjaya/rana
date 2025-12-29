import React, { useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { Mail, Phone, MapPin, Send } from 'lucide-react';
import gsap from 'gsap';

const Contact = () => {
    const { cmsContent } = useCms();
    const headerRef = useRef(null);
    const formRef = useRef(null);
    const infoRef = useRef(null);

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
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] font-sans text-slate-200">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-6xl mx-auto">
                <div ref={headerRef} className="text-center mb-16">
                    <h1 className="text-4xl md:text-6xl font-bold text-white mb-4">Hubungi Kami</h1>
                    <p className="text-xl text-slate-300">Kami siap mendengar Anda.</p>
                </div>

                <div className="grid md:grid-cols-2 gap-10">
                    {/* Contact Info */}
                    <div ref={infoRef} className="space-y-8">
                        <div className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <Mail size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Email</h3>
                                <p className="text-slate-300">{cmsContent.CMS_CONTACT_EMAIL || 'support@rana.com'}</p>
                            </div>
                        </div>

                        <div className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <Phone size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Telepon</h3>
                                <p className="text-slate-300">{cmsContent.CMS_CONTACT_PHONE || '+62 812 0000 0000'}</p>
                            </div>
                        </div>

                        <div className="bg-white/5 border border-white/10 p-8 rounded-3xl flex items-center gap-6 transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400">
                                <MapPin size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-white">Kantor Pusat</h3>
                                <p className="text-slate-300">Jakarta, Indonesia</p>
                            </div>
                        </div>
                    </div>

                    {/* Contact Form */}
                    <form ref={formRef} className="bg-white/5 border border-white/10 p-10 rounded-3xl">
                        <div className="space-y-6">
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Nama</label>
                                <input type="text" className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="Nama Anda" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Email</label>
                                <input type="email" className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="email@domain.com" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-slate-300 mb-2 uppercase tracking-wide">Pesan</label>
                                <textarea rows="4" className="w-full bg-white/10 border border-white/10 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 text-white placeholder:text-slate-400" placeholder="Tulis pesan Anda"></textarea>
                            </div>
                            <button type="button" className="w-full py-4 bg-gradient-to-r from-indigo-600 to-violet-600 text-white font-bold rounded-xl shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)] transition duration-300 flex items-center justify-center gap-2">
                                Kirim Pesan <Send size={18} />
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Contact;
