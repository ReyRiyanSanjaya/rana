import React, { useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import gsap from 'gsap';

const About = () => {
    const { cmsContent } = useCms();
    const containerRef = useRef(null);
    const missionRef = useRef(null);

    useEffect(() => {
        const tl = gsap.timeline();
        tl.fromTo(containerRef.current, { y: 30, opacity: 0 }, { y: 0, opacity: 1, duration: 0.8, ease: 'power3.out' })
            .fromTo(missionRef.current.children,
                { y: 30, opacity: 0 },
                { y: 0, opacity: 1, stagger: 0.2, duration: 0.6, ease: 'back.out(1.5)' },
                '-=0.4'
            );
    }, []);

    return (
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] font-sans text-slate-200">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-5xl mx-auto">
                <div ref={containerRef} className="bg-white/5 border border-white/10 rounded-[3rem] p-10 md:p-20 backdrop-blur-md">
                    <h1 className="text-4xl md:text-6xl font-bold text-white mb-10 text-center">Tentang Kami</h1>

                    <div
                        className="prose prose-lg prose-indigo mx-auto text-slate-300 leading-loose"
                        dangerouslySetInnerHTML={{ __html: cmsContent.CMS_ABOUT_US || '<p>Loading about us content...</p>' }}
                    />

                    {/* Team Section Placeholder */}
                    <div className="mt-20">
                        <h2 className="text-3xl font-bold text-white mb-10 text-center">Misi Kami</h2>
                        <div ref={missionRef} className="grid md:grid-cols-2 gap-10">
                            <div className="bg-white/5 border border-white/10 p-8 rounded-3xl hover:scale-[1.02] transition-transform duration-300">
                                <h3 className="text-xl font-bold mb-4 text-indigo-300">Visi</h3>
                                <p className="text-slate-300">Menjadi mitra paling tepercaya bagi UMKM, memberdayakan dengan teknologi yang terasa manusiawi.</p>
                            </div>
                            <div className="bg-white/5 border border-white/10 p-8 rounded-3xl hover:scale-[1.02] transition-transform duration-300">
                                <h3 className="text-xl font-bold mb-4 text-indigo-300">Misi</h3>
                                <p className="text-slate-300">Menyediakan alat yang intuitif, indah, dan kuat untuk menyederhanakan perdagangan dan membuka potensi.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default About;
