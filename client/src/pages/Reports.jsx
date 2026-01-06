import React, { useState, useEffect } from 'react';
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, PieChart, Pie } from 'recharts';
import { TrendingUp, TrendingDown, DollarSign, Package, Users, Calendar, ArrowRight } from 'lucide-react';
import DashboardLayout from '../components/layout/DashboardLayout';
import { fetchProfitLoss, fetchProducts } from '../services/api';
import { formatCurrency } from '../utils/format';
import { initTransactionsStream, subscribeTransactions } from '../services/transactionsStream';
import RealtimeBadge from '../components/RealtimeBadge';

const COLORS = ['#4F46E5', '#10B981', '#F59E0B', '#EF4444'];

const ReportCard = ({ title, value, subtext, icon: Icon, delay }) => (
    <div
        className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 hover:shadow-lg transition-all duration-500 transform hover:-translate-y-1"
        style={{ animation: `fadeInUp 0.6s ease-out ${delay}s backwards` }}
    >
        <div className="flex justify-between items-start mb-4">
            <div className="p-3 bg-indigo-50 rounded-xl text-indigo-600">
                <Icon size={24} />
            </div>
            <span className="text-xs font-semibold px-2 py-1 bg-green-100 text-green-700 rounded-full flex items-center">
                <TrendingUp size={12} className="mr-1" /> +12%
            </span>
        </div>
        <h3 className="text-slate-500 text-sm font-medium">{title}</h3>
        <h2 className="text-2xl font-bold text-slate-800 mt-1">{value}</h2>
        <p className="text-xs text-slate-400 mt-2">{subtext}</p>
    </div>
);

const Reports = () => {
    const [loading, setLoading] = useState(true);
    const [pnlData, setPnlData] = useState(null);
    const [activeTab, setActiveTab] = useState('sales'); // sales | inventory | customers

    useEffect(() => {
        const loadData = async () => {
            try {
                const end = new Date();
                const start = new Date();
                start.setDate(start.getDate() - 30);
                const data = await fetchProfitLoss(start.toISOString().split('T')[0], end.toISOString().split('T')[0]);
                setPnlData(data);
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        };
        loadData();
        initTransactionsStream();
        const unsub = subscribeTransactions(() => {
            // Refresh analytics when new transactions arrive
            loadData();
        });
        return () => unsub();
    }, []);

    if (loading) return <DashboardLayout><div className="flex h-screen items-center justify-center">Loading Analytics...</div></DashboardLayout>;

    const { pnl } = pnlData || {};

    // Mock Data for Visualization (filling gaps where API is limited)
    const salesTrend = [
        { name: 'Mon', sales: 400000 },
        { name: 'Tue', sales: 300000 },
        { name: 'Wed', sales: 550000 },
        { name: 'Thu', sales: 450000 },
        { name: 'Fri', sales: 800000 },
        { name: 'Sat', sales: 1200000 },
        { name: 'Sun', sales: 950000 },
    ];

    const categoryData = [
        { name: 'Coffee', value: 45 },
        { name: 'Non-Coffee', value: 25 },
        { name: 'Pastry', value: 20 },
        { name: 'Merch', value: 10 },
    ];

    return (
        <DashboardLayout>
            <style>{`
                @keyframes fadeInUp {
                    from { opacity: 0; transform: translateY(20px); }
                    to { opacity: 1; transform: translateY(0); }
                }
            `}</style>

            <div className="space-y-8 max-w-7xl mx-auto">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 animate-in fade-in slide-in-from-top duration-700">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Advanced Analytics</h1>
                        <p className="text-slate-500 mt-1">Real-time insights into your business performance.</p>
                    </div>
                    <div className="flex space-x-2 bg-white p-1 rounded-xl border border-slate-200 shadow-sm">
                        <RealtimeBadge />
                        {['sales', 'inventory', 'customers'].map(tab => (
                            <button
                                key={tab}
                                onClick={() => setActiveTab(tab)}
                                className={`px-4 py-2 rounded-lg text-sm font-medium capitalize transition-all duration-300 ${activeTab === tab ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-500 hover:bg-slate-50'
                                    }`}
                            >
                                {tab}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Key Metrics Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <ReportCard
                        title="Total Revenue"
                        value={formatCurrency(pnlData?.pnl?.revenue || 0)}
                        subtext="Last 30 days"
                        icon={DollarSign}
                        delay={0.1}
                    />
                    <ReportCard
                        title="Net Profit"
                        value={formatCurrency(pnlData?.pnl?.netProfit || 0)}
                        subtext="After expenses & tax"
                        icon={TrendingUp}
                        delay={0.2}
                    />
                    <ReportCard
                        title="Total Transactions"
                        value="1,204"
                        subtext="+5.2% vs last month"
                        icon={Package}
                        delay={0.3}
                    />
                    <ReportCard
                        title="Active Customers"
                        value="342"
                        subtext="85 New this month"
                        icon={Users}
                        delay={0.4}
                    />
                </div>

                {/* Charts Area */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

                    {/* Main Chart */}
                    <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-100" style={{ animation: 'fadeInUp 0.6s ease-out 0.5s backwards' }}>
                        <h3 className="text-lg font-bold text-slate-800 mb-6 flex items-center">
                            <TrendingUp className="mr-2 text-indigo-500" size={20} /> Sales Trend (Weekly)
                        </h3>
                        <div className="h-80 w-full">
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={salesTrend}>
                                    <defs>
                                        <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                                            <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#94a3b8' }} />
                                    <YAxis axisLine={false} tickLine={false} tick={{ fill: '#94a3b8' }} tickFormatter={val => `${val / 1000}k`} />
                                    <Tooltip
                                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)' }}
                                        formatter={(val) => formatCurrency(val)}
                                    />
                                    <Area type="monotone" dataKey="sales" stroke="#6366f1" strokeWidth={3} fillOpacity={1} fill="url(#colorSales)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    {/* Secondary Chart (Pie) */}
                    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100" style={{ animation: 'fadeInUp 0.6s ease-out 0.6s backwards' }}>
                        <h3 className="text-lg font-bold text-slate-800 mb-6">Sales by Category</h3>
                        <div className="h-60 w-full relative">
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={categoryData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={60}
                                        outerRadius={80}
                                        paddingAngle={5}
                                        dataKey="value"
                                    >
                                        {categoryData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip />
                                </PieChart>
                            </ResponsiveContainer>
                            {/* Center Text */}
                            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                                <span className="text-3xl font-bold text-slate-800">100%</span>
                                <span className="text-xs text-slate-400">Distribution</span>
                            </div>
                        </div>
                        <div className="mt-6 space-y-3">
                            {categoryData.map((item, index) => (
                                <div key={item.name} className="flex items-center justify-between text-sm">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: COLORS[index] }}></div>
                                        <span className="text-slate-600">{item.name}</span>
                                    </div>
                                    <span className="font-semibold text-slate-800">{item.value}%</span>
                                </div>
                            ))}
                        </div>
                    </div>

                </div>

                {/* Bottom Section: Recent Events or Insights */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6" style={{ animation: 'fadeInUp 0.6s ease-out 0.7s backwards' }}>
                    <div className="bg-gradient-to-br from-indigo-600 to-violet-700 rounded-2xl p-6 text-white shadow-lg relative overflow-hidden group cursor-pointer">
                        <div className="absolute top-0 right-0 p-32 bg-white opacity-5 rounded-full transform translate-x-10 -translate-y-10 group-hover:scale-110 transition-transform duration-700"></div>
                        <h3 className="text-xl font-bold mb-2 relative z-10">AI Insights</h3>
                        <p className="text-indigo-100 mb-6 relative z-10 max-w-sm">
                            Your sales of <b>Kopi Susu</b> are trending up on weekends. Consider increasing stock by 15% for Saturday.
                        </p>
                        <button className="bg-white/20 hover:bg-white/30 backdrop-blur-sm px-4 py-2 rounded-lg text-sm font-semibold transition flex items-center relative z-10">
                            View Full Report <ArrowRight size={16} className="ml-2" />
                        </button>
                    </div>

                    <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="font-bold text-slate-800">Low Stock Alerts</h3>
                            <span className="text-xs font-bold bg-red-100 text-red-600 px-2 py-1 rounded-full">3 Items</span>
                        </div>
                        <div className="space-y-4">
                            {[1, 2, 3].map(i => (
                                <div key={i} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl hover:bg-slate-100 transition duration-300">
                                    <div className="flex items-center space-x-3">
                                        <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-xl shadow-sm">🥛</div>
                                        <div>
                                            <h4 className="font-bold text-slate-700 text-sm">Fresh Milk 1L</h4>
                                            <p className="text-xs text-slate-400">SKU: MILK-001</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-red-600 font-bold text-sm">Only 2 left</p>
                                        <p className="text-xs text-slate-400">Reorder now</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

            </div>
        </DashboardLayout>
    );
};

export default Reports;
