import React, { useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { Mail, Phone, MapPin, Send } from 'lucide-react';
import { gsap } from 'gsap';

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
        <div className="min-h-screen bg-[#e0e5ec] font-sans text-gray-700">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-6xl mx-auto">
                <div ref={headerRef} className="text-center mb-16">
                    <h1 className="text-4xl md:text-6xl font-bold text-[#303346] mb-4">Get in Touch</h1>
                    <p className="text-xl text-gray-500">We'd love to hear from you.</p>
                </div>

                <div className="grid md:grid-cols-2 gap-10">
                    {/* Contact Info */}
                    <div ref={infoRef} className="space-y-8">
                        <div className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[8px_8px_16px_#bebebe,-8px_-8px_16px_#ffffff] flex items-center gap-6 hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-[#e0e5ec] shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] flex items-center justify-center text-primary">
                                <Mail size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-[#303346]">Email</h3>
                                <p className="text-gray-500">{cmsContent.CMS_CONTACT_EMAIL || 'support@rana.com'}</p>
                            </div>
                        </div>

                        <div className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[8px_8px_16px_#bebebe,-8px_-8px_16px_#ffffff] flex items-center gap-6 hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-[#e0e5ec] shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] flex items-center justify-center text-primary">
                                <Phone size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-[#303346]">Phone</h3>
                                <p className="text-gray-500">{cmsContent.CMS_CONTACT_PHONE || '+62 812 0000 0000'}</p>
                            </div>
                        </div>

                        <div className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[8px_8px_16px_#bebebe,-8px_-8px_16px_#ffffff] flex items-center gap-6 hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-shadow duration-300">
                            <div className="w-12 h-12 rounded-full bg-[#e0e5ec] shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] flex items-center justify-center text-primary">
                                <MapPin size={24} />
                            </div>
                            <div>
                                <h3 className="font-bold text-[#303346]">Headquarters</h3>
                                <p className="text-gray-500">Jakarta, Indonesia</p>
                            </div>
                        </div>
                    </div>

                    {/* Contact Form */}
                    <form ref={formRef} className="bg-[#e0e5ec] p-10 rounded-3xl shadow-[8px_8px_16px_#bebebe,-8px_-8px_16px_#ffffff]">
                        <div className="space-y-6">
                            <div>
                                <label className="block text-sm font-bold text-gray-500 mb-2 uppercase tracking-wide">Name</label>
                                <input type="text" className="w-full bg-[#e0e5ec] border-none rounded-xl p-4 shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] focus:outline-none focus:ring-2 focus:ring-primary/50" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-500 mb-2 uppercase tracking-wide">Email</label>
                                <input type="email" className="w-full bg-[#e0e5ec] border-none rounded-xl p-4 shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] focus:outline-none focus:ring-2 focus:ring-primary/50" />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-gray-500 mb-2 uppercase tracking-wide">Message</label>
                                <textarea rows="4" className="w-full bg-[#e0e5ec] border-none rounded-xl p-4 shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] focus:outline-none focus:ring-2 focus:ring-primary/50"></textarea>
                            </div>
                            <button type="button" className="w-full py-4 bg-primary text-white font-bold rounded-xl shadow-lg hover:bg-rose-700 transition duration-300 flex items-center justify-center gap-2">
                                Send Message <Send size={18} />
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Contact;
