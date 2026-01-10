import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { BarChart3, TrendingUp, Users, ShoppingCart, DollarSign, Activity } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
    { name: 'Mon', sales: 4000, profit: 2400 },
    { name: 'Tue', sales: 3000, profit: 1398 },
    { name: 'Wed', sales: 9800, profit: 6800 },
    { name: 'Thu', sales: 3908, profit: 2908 },
    { name: 'Fri', sales: 4800, profit: 2800 },
    { name: 'Sat', sales: 11800, profit: 8800 },
    { name: 'Sun', sales: 13800, profit: 9800 },
];

const StatCard = ({ title, value, icon: Icon, trend, color }) => (
    <motion.div 
        whileHover={{ scale: 1.05 }}
        className="bg-[#1e293b]/80 border border-slate-700/50 p-4 rounded-xl flex items-center justify-between"
    >
        <div>
            <div className="text-slate-400 text-xs mb-1 font-medium">{title}</div>
            <div className="text-xl font-bold text-white flex items-end gap-2">
                {value}
                <span className={`text-xs ${trend > 0 ? 'text-green-400' : 'text-red-400'} flex items-center`}>
                    {trend > 0 ? '+' : ''}{trend}%
                </span>
            </div>
        </div>
        <div className={`p-2 rounded-lg bg-${color}-500/20 text-${color}-400`}>
            <Icon size={20} />
        </div>
    </motion.div>
);

const LiveDashboardPreview = () => {
    const [activeTransaction, setActiveTransaction] = useState(null);

    // Simulate live transactions
    useEffect(() => {
        const interval = setInterval(() => {
            const items = ['Kopi Susu', 'Nasi Goreng', 'Es Teh Manis', 'Mie Ayam', 'Roti Bakar'];
            const randomItem = items[Math.floor(Math.random() * items.length)];
            const randomPrice = Math.floor(Math.random() * 50) * 1000 + 10000;
            
            setActiveTransaction({
                item: randomItem,
                price: randomPrice,
                time: new Date().toLocaleTimeString(),
                id: Math.random().toString(36).substr(2, 9)
            });
        }, 3000);

        return () => clearInterval(interval);
    }, []);

    return (
        <div className="relative w-full max-w-5xl mx-auto">
            {/* Glowing Border Background */}
            <div className="absolute -inset-1 bg-gradient-to-r from-indigo-500 via-violet-500 to-cyan-500 rounded-3xl blur opacity-30 animate-pulse"></div>
            
            {/* Main Dashboard Container */}
            <div className="relative bg-[#0f172a] border border-slate-700 rounded-2xl overflow-hidden shadow-2xl">
                {/* Header */}
                <div className="bg-[#1e293b] border-b border-slate-700 p-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="flex gap-1.5">
                            <div className="w-3 h-3 rounded-full bg-red-500" />
                            <div className="w-3 h-3 rounded-full bg-yellow-500" />
                            <div className="w-3 h-3 rounded-full bg-green-500" />
                        </div>
                        <div className="h-6 w-[1px] bg-slate-700 mx-2" />
                        <span className="text-sm font-medium text-slate-300">Rana Dashboard - Live View</span>
                    </div>
                    <div className="flex items-center gap-2">
                         <span className="flex h-2 w-2 relative">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                        </span>
                        <span className="text-xs text-green-400 font-medium">System Online</span>
                    </div>
                </div>

                {/* Dashboard Content */}
                <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
                    {/* Left Column - Stats */}
                    <div className="md:col-span-2 space-y-6">
                        <div className="grid grid-cols-2 gap-4">
                            <StatCard title="Total Omzet" value="Rp 24.5Jt" icon={DollarSign} trend={12.5} color="indigo" />
                            <StatCard title="Transaksi" value="1,240" icon={ShoppingCart} trend={8.2} color="violet" />
                        </div>
                        
                        <div className="bg-[#1e293b]/50 border border-slate-700/50 rounded-xl p-4 h-[250px]">
                            <h4 className="text-slate-300 text-sm font-medium mb-4 flex items-center gap-2">
                                <Activity size={16} className="text-indigo-400" />
                                Grafik Penjualan (Real-time)
                            </h4>
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={data}>
                                    <defs>
                                        <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3}/>
                                            <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                                        </linearGradient>
                                    </defs>
                                    <XAxis dataKey="name" stroke="#475569" fontSize={12} tickLine={false} axisLine={false} />
                                    <YAxis stroke="#475569" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `${value/1000}k`} />
                                    <Tooltip 
                                        contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', borderRadius: '8px', color: '#f1f5f9' }}
                                        itemStyle={{ color: '#818cf8' }}
                                    />
                                    <Area type="monotone" dataKey="sales" stroke="#6366f1" strokeWidth={3} fillOpacity={1} fill="url(#colorSales)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    {/* Right Column - Live Feed */}
                    <div className="bg-[#1e293b]/50 border border-slate-700/50 rounded-xl p-4 flex flex-col">
                        <h4 className="text-slate-300 text-sm font-medium mb-4 flex items-center justify-between">
                            <span>Live Transactions</span>
                            <span className="text-xs px-2 py-0.5 bg-indigo-500/20 text-indigo-300 rounded-full">Just Now</span>
                        </h4>
                        
                        <div className="space-y-3 overflow-hidden relative flex-1">
                            <AnimatePresence mode="popLayout">
                                {activeTransaction && (
                                    <motion.div
                                        key={activeTransaction.id}
                                        initial={{ opacity: 0, x: 20 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        exit={{ opacity: 0, scale: 0.9 }}
                                        className="bg-[#0f172a] p-3 rounded-lg border border-slate-700/50 flex items-center justify-between shadow-lg"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-indigo-500/20 flex items-center justify-center text-indigo-400 font-bold text-xs">
                                                {activeTransaction.item.charAt(0)}
                                            </div>
                                            <div>
                                                <div className="text-sm text-slate-200 font-medium">{activeTransaction.item}</div>
                                                <div className="text-xs text-slate-500">{activeTransaction.time}</div>
                                            </div>
                                        </div>
                                        <div className="text-green-400 font-mono text-sm">
                                            +Rp{activeTransaction.price.toLocaleString('id-ID')}
                                        </div>
                                    </motion.div>
                                )}
                                {/* Static placeholders for look */}
                                {[1, 2, 3].map((i) => (
                                    <div key={i} className="bg-[#0f172a]/50 p-3 rounded-lg border border-slate-800 flex items-center justify-between opacity-50">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center"></div>
                                            <div className="w-20 h-2 bg-slate-700 rounded"></div>
                                        </div>
                                        <div className="w-12 h-2 bg-slate-700 rounded"></div>
                                    </div>
                                ))}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default LiveDashboardPreview;
