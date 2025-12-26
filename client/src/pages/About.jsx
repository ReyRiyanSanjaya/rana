import React, { useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { gsap } from 'gsap';

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
        <div className="min-h-screen bg-[#e0e5ec] font-sans text-gray-700">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-5xl mx-auto">
                <div ref={containerRef} className="bg-[#e0e5ec] rounded-[3rem] p-10 md:p-20 shadow-[20px_20px_60px_#bebebe,-20px_-20px_60px_#ffffff]">
                    <h1 className="text-4xl md:text-6xl font-bold text-[#303346] mb-10 text-center">About Us</h1>

                    <div
                        className="prose prose-lg prose-indigo mx-auto text-gray-600 leading-loose"
                        dangerouslySetInnerHTML={{ __html: cmsContent.CMS_ABOUT_US || '<p>Loading about us content...</p>' }}
                    />

                    {/* Team Section Placeholder */}
                    <div className="mt-20">
                        <h2 className="text-3xl font-bold text-[#303346] mb-10 text-center">Our Mission</h2>
                        <div ref={missionRef} className="grid md:grid-cols-2 gap-10">
                            <div className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[inset_8px_8px_16px_#bebebe,inset_-8px_-8px_16px_#ffffff] hover:scale-[1.02] transition-transform duration-300">
                                <h3 className="text-xl font-bold mb-4 text-primary">Vision</h3>
                                <p>To be the world's most trusted partner for MSMEs, empowering them with technology that feels human.</p>
                            </div>
                            <div className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[inset_8px_8px_16px_#bebebe,inset_-8px_-8px_16px_#ffffff] hover:scale-[1.02] transition-transform duration-300">
                                <h3 className="text-xl font-bold mb-4 text-primary">Mission</h3>
                                <p>Delivering intuitive, beautiful, and powerful tools that simplify commerce and unlock potential.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default About;
