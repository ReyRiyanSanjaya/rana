import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Home, Info, Zap, BookOpen, Mail, User } from 'lucide-react';

const navItems = [
    { name: 'Home', path: '/', icon: Home },
    { name: 'About', path: '/about', icon: Info },
    { name: 'Features', path: '/features', icon: Zap },
    { name: 'Blog', path: '/blog', icon: BookOpen },
    { name: 'Contact', path: '/contact', icon: Mail },
];

const BottomNav = () => {
    const location = useLocation();
    const [activeTab, setActiveTab] = useState(location.pathname);
    const [isVisible, setIsVisible] = useState(true);
    const [lastScrollY, setLastScrollY] = useState(0);

    useEffect(() => {
        setActiveTab(location.pathname);
    }, [location]);

    // Hide on scroll down, show on scroll up
    useEffect(() => {
        const handleScroll = () => {
            const currentScrollY = window.scrollY;
            
            if (currentScrollY > lastScrollY && currentScrollY > 100) {
                setIsVisible(false);
            } else {
                setIsVisible(true);
            }
            
            setLastScrollY(currentScrollY);
        };

        window.addEventListener('scroll', handleScroll, { passive: true });
        return () => window.removeEventListener('scroll', handleScroll);
    }, [lastScrollY]);

    return (
        <div className="fixed bottom-0 left-0 right-0 z-50 md:hidden pointer-events-none pb-4">
            <AnimatePresence>
                {isVisible && (
                    <motion.div
                        initial={{ y: 100, opacity: 0 }}
                        animate={{ y: 0, opacity: 1 }}
                        exit={{ y: 100, opacity: 0 }}
                        transition={{ type: "spring", stiffness: 260, damping: 20 }}
                        className="pointer-events-auto mx-4 mb-4"
                    >
                        <nav className="bg-[#0f172a]/80 backdrop-blur-xl border border-white/10 rounded-2xl shadow-[0_10px_30px_rgba(0,0,0,0.5)] px-2 py-3">
                            <ul className="flex justify-around items-center">
                                {navItems.map((item) => {
                                    const isActive = activeTab === item.path;
                                    const Icon = item.icon;

                                    return (
                                        <li key={item.name} className="relative z-10">
                                            <Link
                                                to={item.path}
                                                className="relative flex flex-col items-center justify-center w-12 h-12"
                                                onClick={() => setActiveTab(item.path)}
                                            >
                                                {/* Active Background Bubble */}
                                                {isActive && (
                                                    <motion.div
                                                        layoutId="activeTabBubble"
                                                        className="absolute inset-0 bg-gradient-to-tr from-indigo-600 to-violet-600 rounded-xl -z-10"
                                                        transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                                                    />
                                                )}

                                                {/* Icon */}
                                                <motion.div
                                                    animate={{
                                                        scale: isActive ? 1.1 : 1,
                                                        y: isActive ? -2 : 0
                                                    }}
                                                    transition={{ type: "spring", stiffness: 300, damping: 20 }}
                                                >
                                                    <Icon 
                                                        size={22} 
                                                        className={`transition-colors duration-200 ${
                                                            isActive ? 'text-white' : 'text-slate-400'
                                                        }`} 
                                                    />
                                                </motion.div>

                                                {/* Label (Optional - hidden for cleaner look or shown on active) */}
                                                {/* <AnimatePresence>
                                                    {isActive && (
                                                        <motion.span
                                                            initial={{ opacity: 0, scale: 0.5 }}
                                                            animate={{ opacity: 1, scale: 1 }}
                                                            exit={{ opacity: 0, scale: 0.5 }}
                                                            className="text-[10px] font-medium text-white mt-0.5"
                                                        >
                                                            {item.name}
                                                        </motion.span>
                                                    )}
                                                </AnimatePresence> */}
                                            </Link>
                                        </li>
                                    );
                                })}
                            </ul>
                        </nav>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default BottomNav;
