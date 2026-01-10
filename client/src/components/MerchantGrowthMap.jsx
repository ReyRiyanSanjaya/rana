import React, { useEffect, useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { io } from 'socket.io-client';

const cityCoordinates = {
    'Jakarta': { x: 30, y: 65 },
    'Surabaya': { x: 55, y: 70 },
    'Bandung': { x: 32, y: 68 },
    'Medan': { x: 15, y: 25 },
    'Makassar': { x: 70, y: 50 },
    'Bali': { x: 60, y: 75 },
    'Yogyakarta': { x: 45, y: 72 },
    'Semarang': { x: 40, y: 68 },
    'Palembang': { x: 22, y: 45 },
    'Balikpapan': { x: 55, y: 40 }
};

const getCoordinates = (city) => {
    if (!city) return { x: 20 + Math.random() * 60, y: 20 + Math.random() * 60 };
    const key = Object.keys(cityCoordinates).find(k => city.includes(k));
    if (key) {
        return { 
            x: cityCoordinates[key].x + (Math.random() * 4 - 2), 
            y: cityCoordinates[key].y + (Math.random() * 4 - 2) 
        };
    }
    // Random fallback within roughly Indonesia bounds on map
    return { x: 20 + Math.random() * 60, y: 20 + Math.random() * 60 };
};

const MerchantGrowthMap = () => {
    const [pings, setPings] = useState([]);
    const [stats, setStats] = useState({
        activeMerchants: 1245,
        transactionsToday: 45230,
        cities: 34
    });

    const addPing = (city, label, type = 'merchant') => {
        const coords = getCoordinates(city);
        const newPing = {
            id: Date.now() + Math.random(),
            x: coords.x,
            y: coords.y,
            city: city || 'Unknown Location',
            label,
            type
        };
        setPings(prev => [...prev, newPing]);
        
        // Remove after animation
        setTimeout(() => {
            setPings(prev => prev.filter(p => p.id !== newPing.id));
        }, 3000);
    };

    // Real-time Socket Connection
    useEffect(() => {
        const socket = io(import.meta.env.VITE_API_URL || 'http://localhost:3000', {
            auth: { token: null } // Guest access
        });

        socket.on('connect', () => {
            console.log('Connected to real-time public stream');
        });

        socket.on('public:merchant_created', (data) => {
            addPing(data.city, 'New Merchant Join!', 'merchant');
            setStats(prev => ({ ...prev, activeMerchants: prev.activeMerchants + 1 }));
        });

        socket.on('public:transaction_created', (data) => {
            addPing(data.city, `Tx: Rp ${data.amount.toLocaleString()}`, 'transaction');
            setStats(prev => ({ ...prev, transactionsToday: prev.transactionsToday + 1 }));
        });

        return () => {
            socket.disconnect();
        };
    }, []);

    // Fallback simulation (keep it for visual activity if real data is slow)
    useEffect(() => {
        const interval = setInterval(() => {
            if (Math.random() > 0.7) {
                const cities = Object.keys(cityCoordinates);
                const randomCity = cities[Math.floor(Math.random() * cities.length)];
                addPing(randomCity, 'Live Transaction', 'transaction');
                setStats(prev => ({ ...prev, transactionsToday: prev.transactionsToday + 1 }));
            }
        }, 3000); // Slower simulation

        return () => clearInterval(interval);
    }, []);

    return (
        <div className="relative w-full h-[400px] bg-slate-900/50 rounded-3xl overflow-hidden border border-white/10 backdrop-blur-sm group">
            {/* Map Grid Background */}
            <div className="absolute inset-0 grid grid-cols-12 grid-rows-6 gap-px opacity-20 pointer-events-none">
                {Array.from({ length: 72 }).map((_, i) => (
                    <div key={i} className="bg-indigo-500/10 hover:bg-indigo-500/30 transition-colors duration-500" />
                ))}
            </div>

            {/* Map Overlay (Abstract Indonesia Shape or just decorative dots) */}
            <div className="absolute inset-0 opacity-30">
                 {/* This would ideally be an SVG of Indonesia, but we'll use a scatter of static dots to represent density */}
                 {[...Array(20)].map((_, i) => (
                     <div 
                        key={i}
                        className="absolute w-1 h-1 bg-slate-400 rounded-full"
                        style={{ 
                            left: `${20 + Math.random() * 60}%`, 
                            top: `${20 + Math.random() * 60}%` 
                        }}
                     />
                 ))}
            </div>

            {/* Live Pings */}
            <AnimatePresence>
                {pings.map(ping => (
                    <motion.div
                        key={ping.id}
                        initial={{ opacity: 0, scale: 0 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 2 }}
                        transition={{ duration: 0.5 }}
                        className="absolute w-4 h-4"
                        style={{ left: `${ping.x}%`, top: `${ping.y}%` }}
                    >
                        <span className={`absolute inline-flex h-full w-full rounded-full opacity-75 animate-ping ${ping.type === 'transaction' ? 'bg-green-400' : 'bg-indigo-400'}`}></span>
                        <span className={`relative inline-flex rounded-full h-3 w-3 border border-white/50 ${ping.type === 'transaction' ? 'bg-green-500' : 'bg-indigo-500'}`}></span>
                        
                        {/* Tooltip */}
                        <motion.div 
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: -20 }}
                            className="absolute -top-6 left-1/2 -translate-x-1/2 bg-slate-800 text-xs text-white px-2 py-1 rounded shadow-lg whitespace-nowrap border border-white/10"
                        >
                            {ping.label || `${ping.city}`}
                        </motion.div>
                    </motion.div>
                ))}
            </AnimatePresence>

            {/* Live Stats Overlay */}
            <div className="absolute bottom-4 left-4 right-4 flex justify-between items-end">
                <div className="bg-slate-900/80 backdrop-blur border border-white/10 p-4 rounded-2xl flex gap-6">
                    <div>
                        <div className="text-slate-400 text-xs uppercase tracking-wider mb-1">Active Merchants</div>
                        <div className="text-2xl font-mono font-bold text-white tabular-nums">
                            {stats.activeMerchants.toLocaleString()}
                        </div>
                    </div>
                    <div className="w-px bg-white/10" />
                    <div>
                        <div className="text-slate-400 text-xs uppercase tracking-wider mb-1">Transactions Today</div>
                        <div className="text-2xl font-mono font-bold text-green-400 tabular-nums">
                            {stats.transactionsToday.toLocaleString()}
                        </div>
                    </div>
                </div>
                
                <div className="flex items-center gap-2 px-3 py-1.5 bg-green-500/10 border border-green-500/20 rounded-full text-green-400 text-xs font-bold uppercase tracking-wider animate-pulse">
                    <div className="w-2 h-2 rounded-full bg-green-500" />
                    Live System
                </div>
            </div>
        </div>
    );
};

export default MerchantGrowthMap;