import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { gsap } from 'gsap';

const Navbar = () => {
    const navRef = useRef(null);
    const logoRef = useRef(null);
    const linksRef = useRef(null);
    const actionsRef = useRef(null);
    const [isScrolled, setIsScrolled] = useState(false);
    const location = useLocation();

    // Scroll Effect
    useEffect(() => {
        const handleScroll = () => {
            if (window.scrollY > 20) {
                setIsScrolled(true);
            } else {
                setIsScrolled(false);
            }
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    // Entrance Animation
    useEffect(() => {
        const tl = gsap.timeline();

        tl.fromTo(navRef.current,
            { y: -100, opacity: 0 },
            { y: 0, opacity: 1, duration: 0.8, ease: 'power3.out' }
        )
            .fromTo([logoRef.current, linksRef.current.children, actionsRef.current.children],
                { y: -20, opacity: 0 },
                { y: 0, opacity: 1, stagger: 0.1, duration: 0.5, ease: 'back.out(1.7)' },
                '-=0.4'
            );

    }, []);

    // Hover Animation Helper
    const handleHover = (e, isEnter) => {
        gsap.to(e.target, {
            scale: isEnter ? 1.05 : 1,
            color: isEnter ? '#BF092F' : '#4B5563', // Primary Red vs Gray-600
            duration: 0.2,
            ease: 'power1.out'
        });

        // Underline animation logic could be added here if we used a span ref
    };

    return (
        <nav
            ref={navRef}
            className={`fixed top-0 w-full z-50 transition-all duration-500 ease-in-out border-b ${isScrolled
                    ? 'bg-white/90 backdrop-blur-xl h-16 shadow-[0_4px_30px_rgba(0,0,0,0.03)] border-gray-100'
                    : 'bg-transparent h-24 border-transparent'
                }`}
        >
            <div className="max-w-7xl mx-auto px-6 h-full flex items-center justify-between">

                {/* Logo */}
                <Link to="/" ref={logoRef} className="flex items-center gap-3 group">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-xl shadow-lg transition-all duration-500 ${isScrolled ? 'bg-primary rotate-0' : 'bg-gradient-to-br from-primary to-rose-400 rotate-0'
                        } group-hover:rotate-12`}>
                        R
                    </div>
                    <span className={`text-2xl font-black tracking-tight transition-colors duration-300 ${isScrolled ? 'text-slate-900' : 'text-slate-900' // Keeping dark for visibility on light bg
                        }`}>
                        Rana
                    </span>
                </Link>

                {/* Desktop Links */}
                <div ref={linksRef} className="hidden md:flex items-center gap-10">
                    {[
                        { name: 'Home', path: '/' },
                        { name: 'About', path: '/about' },
                        { name: 'Features', path: '/features' },
                        { name: 'Blog', path: '/blog' },
                        { name: 'Contact', path: '/contact' }
                    ].map((link) => (
                        <Link
                            key={link.name}
                            to={link.path}
                            className="relative font-medium text-gray-600 group py-2"
                            onMouseEnter={(e) => handleHover(e, true)}
                            onMouseLeave={(e) => handleHover(e, false)}
                        >
                            {link.name}
                            {/* Animated Underline */}
                            <span className={`absolute bottom-0 left-0 w-full h-0.5 bg-primary transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left ease-out ${location.pathname === link.path ? 'scale-x-100' : ''
                                }`} />
                        </Link>
                    ))}
                </div>

                {/* Actions */}
                <div ref={actionsRef} className="flex items-center gap-4">
                    <Link
                        to="/login"
                        className="font-bold text-slate-700 hover:text-primary transition-colors"
                    >
                        Login
                    </Link>
                    <Link
                        to="/register"
                        className="hidden md:flex relative overflow-hidden px-6 py-3 bg-primary text-white rounded-xl font-bold shadow-[0_10px_20px_rgba(191,9,47,0.3)] hover:shadow-[0_15px_30px_rgba(191,9,47,0.5)] transform hover:-translate-y-0.5 transition-all duration-300 group"
                    >
                        <span className="relative z-10 w-full flex items-center justify-center gap-2">
                            Get Started
                        </span>
                        {/* Sheen Effect */}
                        <div className="absolute top-0 -left-[100%] w-full h-full bg-gradient-to-r from-transparent via-white/20 to-transparent skew-x-12 group-hover:left-[100%] transition-all duration-700 ease-in-out" />
                    </Link>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
