import React, { useEffect, useState } from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import api from '../api';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, PieChart, Pie, Cell } from 'recharts';
import { DollarSign, TrendingUp, Users, Wallet, Activity, TrendingDown, Crown } from 'lucide-react';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

const Reports = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        fetchAnalytics();
    }, []);

    const fetchAnalytics = async () => {
        try {
            setLoading(true);
            setError(null);
            const res = await api.get('/admin/analytics');
            console.log('Analytics Response:', res); // Debug log
            if (res.data.status === 'success') {
                setData(res.data.data);
            } else {
                console.warn('Success false:', res.data);
                throw new Error(res.data.message || 'API verification failed');
            }
        } catch (error) {
            console.error('Failed to fetch analytics', error);
            setError(error);
            setData(null);
        } finally {
            setLoading(false);
        }
    };

    if (loading) return (
        <AdminLayout>
            <div className="flex items-center justify-center h-full pt-20">
                <div className="text-slate-500 animate-pulse">Loading Analytics...</div>
            </div>
        </AdminLayout>
    );

    if (!data) return (
        <AdminLayout>
            <div className="flex flex-col items-center justify-center h-full pt-20 text-slate-500">
                <p className="mb-2 text-lg font-semibold">Failed to load analytics data.</p>
                <code className="bg-slate-100 p-2 rounded text-xs text-red-500 mb-4 max-w-lg overflow-auto">
                    {error ? JSON.stringify(error.message || error) : 'Unknown Error'}
                    <br />
                    Check console for details.
                </code>
                <p className="text-xs mb-4">Please ensure the server is running and database is migrated.</p>
                <button
                    onClick={fetchAnalytics}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition"
                >
                    Retry
                </button>
            </div>
        </AdminLayout>
    );

    // Process Pie Data
    const pieData = (data.revenueBySource || []).map(item => ({
        name: item.source.replace('_', ' '),
        value: item._sum.amount
    }));

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold tracking-tight text-slate-900">Business Analytics</h1>
                    <p className="text-slate-500 mt-1">Deep dive into platform revenue and growth.</p>
                </div>

                {/* KPI Cards Row 1 */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-blue-500">
                        <div className="p-3 bg-blue-50 text-blue-600 rounded-full">
                            <DollarSign size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Total Revenue</p>
                            <h3 className="text-2xl font-bold text-slate-900">
                                Rp {data.totalRevenue?.toLocaleString('id-ID')}
                            </h3>
                        </div>
                    </Card>

                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-green-500">
                        <div className="p-3 bg-green-50 text-green-600 rounded-full">
                            <TrendingUp size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Active Subscribers</p>
                            <h3 className="text-2xl font-bold text-slate-900">
                                {data.activeSubscribers}
                            </h3>
                        </div>
                    </Card>

                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-purple-500">
                        <div className="p-3 bg-purple-50 text-purple-600 rounded-full">
                            <Activity size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">ARPU</p>
                            <h3 className="text-lg font-bold text-slate-900">
                                Rp {Math.round(data.arpu || 0).toLocaleString('id-ID')}
                            </h3>
                        </div>
                    </Card>

                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-orange-500">
                        <div className="p-3 bg-orange-50 text-orange-600 rounded-full">
                            <Users size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Merchant Growth</p>
                            <div className="flex items-center text-green-600 text-sm font-bold">
                                +{data.growthChart?.[data.growthChart.length - 1]?.count || 0} This Month
                            </div>
                        </div>
                    </Card>
                </div>

                {/* KPI Cards Row 2 - Extra Metrics */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Card className="p-6">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="font-semibold text-slate-900 flex items-center">
                                <TrendingDown size={20} className="mr-2 text-red-500" />
                                Churn Rate
                            </h3>
                            <span className="text-2xl font-bold text-slate-900">
                                {data.churnRate}%
                            </span>
                        </div>
                        <p className="text-sm text-slate-500">Percentage of merchants who cancelled subscriptions.</p>
                    </Card>

                    <Card className="p-6">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="font-semibold text-slate-900 flex items-center">
                                <Crown size={20} className="mr-2 text-yellow-500" />
                                Top Merchants (Volume)
                            </h3>
                        </div>
                        <div className="space-y-3">
                            {(data.topMerchants || []).length === 0 ? (
                                <p className="text-sm text-slate-400 italic">No transaction data available yet.</p>
                            ) : (
                                (data.topMerchants || []).map((m, idx) => (
                                    <div key={idx} className="flex justify-between items-center text-sm">
                                        <span className="font-medium text-slate-700">{idx + 1}. {m.name}</span>
                                        <span className="text-slate-500 font-mono">Rp {m.volume?.toLocaleString('id-ID')}</span>
                                    </div>
                                ))
                            )}
                        </div>
                    </Card>
                </div>

                {/* Charts Area */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {/* Revenue Trend (Line) */}
                    <Card className="p-6 lg:col-span-2">
                        <h3 className="font-semibold text-lg text-slate-900 mb-4">Revenue Trend (Last 6 Months)</h3>
                        <div className="h-80">
                            <ResponsiveContainer width="100%" height="100%">
                                <LineChart data={data.revenueChart}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                    <XAxis dataKey="name" axisLine={false} tickLine={false} />
                                    <YAxis axisLine={false} tickLine={false} />
                                    <Tooltip formatter={(value) => `Rp ${value.toLocaleString('id-ID')}`} />
                                    <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={3} dot={{ r: 4 }} />
                                </LineChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>

                    {/* Revenue Distribution (Pie) */}
                    <Card className="p-6">
                        <h3 className="font-semibold text-lg text-slate-900 mb-4">Revenue Distribution</h3>
                        <div className="h-64">
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={pieData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={60}
                                        outerRadius={80}
                                        paddingAngle={5}
                                        dataKey="value"
                                    >
                                        {pieData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                        ))}
                                    </Pie>
                                    <Tooltip formatter={(value) => `Rp ${value.toLocaleString('id-ID')}`} />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                        <div className="mt-4 space-y-2">
                            {pieData.map((entry, index) => (
                                <div key={index} className="flex items-center text-sm">
                                    <div className="w-3 h-3 rounded-full mr-2" style={{ backgroundColor: COLORS[index % COLORS.length] }}></div>
                                    <span className="flex-1 text-slate-600">{entry.name}</span>
                                    <span className="font-semibold">Rp {entry.value?.toLocaleString('id-ID')}</span>
                                </div>
                            ))}
                        </div>
                    </Card>
                </div>



                {/* Merchant Location */}
                < Card className="p-6" >
                    <h3 className="font-semibold text-lg text-slate-900 mb-4">Acquisition by Location</h3>
                    <div className="h-80">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart layout="vertical" data={data.merchantByLocation || []}>
                                <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                                <XAxis type="number" hide />
                                <YAxis dataKey="name" type="category" width={100} tick={{ fontSize: 12 }} />
                                <Tooltip />
                                <Bar dataKey="count" fill="#8884d8" radius={[0, 4, 4, 0]} barSize={20} />
                            </BarChart>
                        </ResponsiveContainer>
                        <p className="text-xs text-slate-400 mt-2 text-center">Top 10 Locations</p>
                    </div>
                </Card >
            </div >
        </AdminLayout >
    );
};

export default Reports;
