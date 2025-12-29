import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import gsap from 'gsap';

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
            color: isEnter ? '#6366F1' : '#94A3B8',
            duration: 0.2,
            ease: 'power1.out'
        });

        // Underline animation logic could be added here if we used a span ref
    };

    return (
        <nav
            ref={navRef}
            className={`fixed top-0 w-full z-50 transition-all duration-500 ease-in-out ${isScrolled
                    ? 'bg-slate-900/70 backdrop-blur-xl h-16 border-b border-slate-800'
                    : 'bg-transparent h-24'
                }`}
        >
            <div className="max-w-7xl mx-auto px-6 h-full flex items-center justify-between">

                {/* Logo */}
                <Link to="/" ref={logoRef} className="flex items-center gap-3 group">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-xl transition-all duration-500 ${isScrolled ? 'bg-gradient-to-br from-indigo-600 to-violet-600' : 'bg-gradient-to-br from-indigo-500 to-violet-500'
                        } group-hover:rotate-12`}>
                        R
                    </div>
                    <span className={`text-2xl font-black tracking-tight transition-colors duration-300 ${isScrolled ? 'text-white' : 'text-white'
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
                            className="relative font-medium text-slate-300 hover:text-white group py-2"
                            onMouseEnter={(e) => handleHover(e, true)}
                            onMouseLeave={(e) => handleHover(e, false)}
                        >
                            {link.name}
                            {/* Animated Underline */}
                            <span className={`absolute bottom-0 left-0 w-full h-0.5 bg-gradient-to-r from-indigo-500 to-violet-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300 origin-left ease-out ${location.pathname === link.path ? 'scale-x-100' : ''
                                }`} />
                        </Link>
                    ))}
                </div>

                {/* Actions */}
                <div ref={actionsRef} className="flex items-center gap-4">
                    <Link
                        to="/login"
                        className="font-bold text-slate-300 hover:text-white transition-colors"
                    >
                        Login
                    </Link>
                    <Link
                        to="/register"
                        className="hidden md:flex relative overflow-hidden px-6 py-3 rounded-xl font-bold transform hover:-translate-y-0.5 transition-all duration-300 group bg-gradient-to-r from-indigo-600 to-violet-600 text-white shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)]"
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
