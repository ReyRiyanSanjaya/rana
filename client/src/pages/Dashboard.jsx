import React, { useEffect, useRef, useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { DollarSign, ShoppingBag, CreditCard, Activity } from 'lucide-react';
import DashboardLayout from '../components/layout/DashboardLayout';
import { fetchDashboardStats } from '../services/api';
import api from '../services/api'; // [NEW] Default export is axios instance
import { io } from 'socket.io-client';
import RealtimeBadge from '../components/RealtimeBadge';

const StatCard = ({ title, value, subtext, icon: Icon, colorClass }) => (
    <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
        <div className="flex items-center justify-between">
            <div>
                <p className="text-sm font-medium text-slate-500">{title}</p>
                <h3 className="text-2xl font-bold mt-1 text-slate-900">{value}</h3>
            </div>
            <div className={`p-3 rounded-lg ${colorClass}`}>
                <Icon size={24} />
            </div>
        </div>
        {subtext && <p className="mt-4 text-sm text-slate-600">{subtext}</p>}
    </div>
);

const Dashboard = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    const [announcements, setAnnouncements] = useState([]);
    const socketRef = useRef(null);

    const loadData = async () => {
        const today = new Date().toISOString().split('T')[0];

        try {
            const [stats, annRes] = await Promise.all([
                fetchDashboardStats(today),
                api.get('/system/announcements')
            ]);
            setData(stats);
            setAnnouncements(annRes.data.data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();

        const token = localStorage.getItem('token');
        if (!token) return;

        const baseUrl = api?.defaults?.baseURL || '';
        const socketUrl = baseUrl ? baseUrl.replace(/\/api\/?$/, '') : 'http://localhost:4000';

        socketRef.current = io(socketUrl, {
            auth: { token },
            transports: ['websocket', 'polling']
        });

        socketRef.current.on('transactions:created', loadData);
        socketRef.current.on('inventory:changed', loadData);

        return () => {
            socketRef.current?.disconnect();
        };
    }, []);

    if (loading || !data) return (
        <DashboardLayout>
            <div className="flex items-center justify-center h-full">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
        </DashboardLayout>
    );

    const { financials, topProducts } = data;

    const formatCurrency = (val) =>
        new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    return (
        <DashboardLayout>
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h2 className="text-2xl font-bold text-slate-900">Financial Overview</h2>
                        <p className="text-slate-500">Today's performance summary</p>
                    </div>
                    <RealtimeBadge />
                </div>

                {/* Financial Metrics */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <StatCard
                        title="Gross Profit"
                        value={formatCurrency(financials.grossProfit)}
                        subtext="+12% from yesterday"
                        icon={DollarSign}
                        colorClass="bg-green-100 text-green-600"
                    />
                    <StatCard
                        title="Net Sales"
                        value={formatCurrency(financials.netSales)}
                        subtext={`${financials.transactionCount} transactions`}
                        icon={CreditCard}
                        colorClass="bg-blue-100 text-blue-600"
                    />
                    <StatCard
                        title="Avg Order Value"
                        value={formatCurrency(financials.netSales / (financials.transactionCount || 1))}
                        subtext="Per transaction"
                        icon={ShoppingBag}
                        colorClass="bg-indigo-100 text-indigo-600"
                    />
                    <StatCard
                        title="COGS"
                        value={formatCurrency(financials.grossSales - financials.grossProfit)} // Rough calc for display
                        subtext="Cost of Goods Sold"
                        icon={Activity}
                        colorClass="bg-orange-100 text-orange-600"
                    />
                </div>

                {/* Charts Section */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                    {/* Top Products Chart */}
                    <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
                        <h3 className="font-bold text-lg mb-6">Top Selling Products (Revenue)</h3>
                        <div className="h-80">
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={topProducts} layout="vertical" margin={{ left: 40 }}>
                                    <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                                    <XAxis type="number" hide />
                                    <YAxis
                                        dataKey="product.name"
                                        type="category"
                                        width={100}
                                        tick={{ fontSize: 12 }}
                                    />
                                    <Tooltip
                                        formatter={(value) => formatCurrency(value)}
                                        cursor={{ fill: 'transparent' }}
                                    />
                                    <Bar dataKey="revenue" fill="#4F46E5" radius={[0, 4, 4, 0]} barSize={20} />
                                </BarChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    {/* Quick Actions / Recent Activity Placeholder */}
                    <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
                        <h3 className="font-bold text-lg mb-4">Pending Sync Status</h3>
                        <div className="space-y-4">
                            <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
                                <span className="text-slate-600">Unsynced Transactions</span>
                                <span className="font-bold text-orange-500">0</span>
                            </div>
                            <div className="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
                                <span className="text-slate-600">Last Sync</span>
                                <span className="font-bold text-slate-900">Just now</span>
                            </div>
                            <div className="mt-6 p-4 bg-blue-50 text-blue-700 rounded-lg text-sm">
                                ⚠️ System is currently running in Hybrid Mode. Financials are updated every 15 minutes.
                            </div>
                        </div>
                    </div>

                </div>

                {/* [NEW] Announcements Section */}
                {announcements.length > 0 && (
                    <div className="bg-white p-6 rounded-xl shadow-sm border border-blue-200 bg-blue-50">
                        <div className="flex items-center space-x-2 mb-4">
                            <span className="bg-blue-600 text-white p-1 rounded">
                                <Activity size={16} />
                            </span>
                            <h3 className="font-bold text-lg text-slate-800">Latest Announcements</h3>
                        </div>
                        <div className="space-y-4">
                            {announcements.map((ann) => (
                                <div key={ann.id} className="bg-white p-4 rounded-lg border border-blue-100 shadow-sm">
                                    <div className="flex justify-between items-start">
                                        <h4 className="font-bold text-slate-900">{ann.title}</h4>
                                        <span className="text-xs text-slate-500">{new Date(ann.createdAt).toLocaleDateString()}</span>
                                    </div>
                                    <p className="text-sm text-slate-600 mt-1">{ann.content}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        </DashboardLayout>
    );
};

export default Dashboard;
