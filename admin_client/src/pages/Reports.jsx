import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import api from '../api';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, PieChart, Pie, Cell } from 'recharts';
import { DollarSign, TrendingUp, Users, Wallet, Activity, TrendingDown, Crown, Download } from 'lucide-react';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

const Reports = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [months, setMonths] = useState(6);
    const [activeTab, setActiveTab] = useState('transactions');
    const [city, setCity] = useState('');
    const [availableCities, setAvailableCities] = useState([]);
    const [merchantCategory, setMerchantCategory] = useState('');
    const [availableCategories, setAvailableCategories] = useState([]);
    const [showTopMerchantsModal, setShowTopMerchantsModal] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        fetchAnalytics();
    }, []);

    const fetchAnalytics = async (overrides = {}) => {
        try {
            setLoading(true);
            setError(null);
            const effectiveMonths = typeof overrides.months === 'number' ? overrides.months : months;
            const effectiveCity = typeof overrides.city === 'string' ? overrides.city : city;
            const effectiveCategory = typeof overrides.merchantCategory === 'string' ? overrides.merchantCategory : merchantCategory;
            const params = { months: effectiveMonths };
            if (effectiveCity) {
                params.city = effectiveCity;
            }
            if (effectiveCategory) {
                params.category = effectiveCategory;
            }
            const res = await api.get('/admin/analytics', { params });
            if (res.data.status === 'success') {
                const nextData = res.data.data;
                setData(nextData);
                if (!effectiveCity && Array.isArray(nextData.merchantByLocation)) {
                    setAvailableCities(
                        nextData.merchantByLocation
                            .map((item) => item.name)
                            .filter((name) => !!name)
                    );
                }
                if (!effectiveCategory && Array.isArray(nextData.merchantByCategory)) {
                    setAvailableCategories(
                        nextData.merchantByCategory
                            .map((item) => item.category)
                            .filter((name) => !!name)
                    );
                }
            } else {
                throw new Error(res.data.message || 'Gagal memuat data analytics');
            }
        } catch (err) {
            setError(err);
            setData(null);
        } finally {
            setLoading(false);
        }
    };

    const handleExport = () => {
        if (!data) return;
        const payload = {
            periodMonths: months,
            cityFilter: city || null,
            merchantCategoryFilter: merchantCategory || null,
            exportedAt: new Date().toISOString(),
            analytics: data
        };
        const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `business_analytics_${months}m_${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    const handleViewTransactions = () => {
        const params = new URLSearchParams();
        if (data.rangeStart) {
            const start = new Date(data.rangeStart);
            params.set('startDate', start.toISOString().slice(0, 10));
        }
        if (data.rangeEnd) {
            const end = new Date(data.rangeEnd);
            params.set('endDate', end.toISOString().slice(0, 10));
        }
        if (city) {
            params.set('area', city);
        }
        if (merchantCategory) {
            params.set('category', merchantCategory);
        }
        const qs = params.toString();
        navigate(qs ? `/transactions?${qs}` : '/transactions');
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
                <p className="mb-2 text-lg font-semibold">Gagal memuat data laporan.</p>
                <p className="text-xs mb-4">
                    {error?.message || 'Silakan coba beberapa saat lagi atau periksa koneksi ke server.'}
                </p>
                <button
                    onClick={fetchAnalytics}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition"
                >
                    Coba Lagi
                </button>
            </div>
        </AdminLayout>
    );

    const pieData = (data.revenueBySource || []).map(item => ({
        name: (item.source || '').replace('_', ' '),
        value: item._sum?.amount || 0
    }));

    const formatCurrency = (val) =>
        `Rp ${(val || 0).toLocaleString('id-ID', { maximumFractionDigits: 0 })}`;

    const lastGrowthEntry =
        Array.isArray(data.growthChart) && data.growthChart.length > 0
            ? data.growthChart[data.growthChart.length - 1]
            : null;

    const reportRangeLabel = (() => {
        if (!data.rangeStart || !data.rangeEnd) return '6 bulan terakhir';
        const start = new Date(data.rangeStart);
        const end = new Date(data.rangeEnd);
        const opts = { day: '2-digit', month: 'short', year: 'numeric' };
        return `${start.toLocaleDateString('id-ID', opts)} s.d. ${end.toLocaleDateString('id-ID', opts)}`;
    })();

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight text-slate-900">Business Analytics</h1>
                        <p className="text-slate-500 mt-1">Ringkasan performa bisnis dan pertumbuhan platform.</p>
                        <div className="mt-2 flex flex-wrap gap-2">
                            <div className="text-sm text-slate-600 bg-slate-50 border border-slate-200 px-3 py-1 rounded-md inline-flex">
                                Periode data: {reportRangeLabel}
                            </div>
                            {city && (
                                <div className="text-xs text-indigo-700 bg-indigo-50 border border-indigo-100 px-3 py-1 rounded-full inline-flex items-center">
                                    <span className="mr-1">Filter kota:</span>
                                    <span className="font-semibold">{city}</span>
                                </div>
                            )}
                            {merchantCategory && (
                                <div className="text-xs text-emerald-700 bg-emerald-50 border border-emerald-100 px-3 py-1 rounded-full inline-flex items-center">
                                    <span className="mr-1">Filter kategori:</span>
                                    <span className="font-semibold">{merchantCategory}</span>
                                </div>
                            )}
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <select
                            className="border border-slate-300 rounded-md px-2 py-1 text-sm bg-white"
                            value={months}
                            onChange={(e) => {
                                const next = parseInt(e.target.value, 10);
                                setMonths(next);
                                fetchAnalytics({ months: next });
                            }}
                        >
                            <option value={3}>3 bulan</option>
                            <option value={6}>6 bulan</option>
                            <option value={12}>12 bulan</option>
                            <option value={24}>24 bulan</option>
                        </select>
                        <select
                            className="border border-slate-300 rounded-md px-2 py-1 text-sm bg-white min-w-[160px]"
                            value={city}
                            onChange={(e) => {
                                const nextCity = e.target.value;
                                setCity(nextCity);
                                fetchAnalytics({ city: nextCity });
                            }}
                        >
                            <option value="">Semua kota</option>
                            {availableCities.map((name) => (
                                <option key={name} value={name}>
                                    {name}
                                </option>
                            ))}
                        </select>
                        <select
                            className="border border-slate-300 rounded-md px-2 py-1 text-sm bg-white min-w-[160px]"
                            value={merchantCategory}
                            onChange={(e) => {
                                const nextCategory = e.target.value;
                                setMerchantCategory(nextCategory);
                                fetchAnalytics({ merchantCategory: nextCategory });
                            }}
                        >
                            <option value="">Semua kategori</option>
                            {availableCategories.map((name) => (
                                <option key={name} value={name}>
                                    {name}
                                </option>
                            ))}
                        </select>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={handleViewTransactions}
                        >
                            Lihat daftar transaksi
                        </Button>
                        <Button
                            variant="outline"
                            icon={Download}
                            size="sm"
                            onClick={handleExport}
                        >
                            Export Summary
                        </Button>
                    </div>
                </div>
                <div className="flex border-b border-slate-200 mb-4 gap-6 overflow-x-auto">
                    <button
                        type="button"
                        className={`pb-2 text-sm font-medium whitespace-nowrap ${activeTab === 'transactions' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}
                        onClick={() => setActiveTab('transactions')}
                    >
                        Transaction Analytics
                    </button>
                    <button
                        type="button"
                        className={`pb-2 text-sm font-medium whitespace-nowrap ${activeTab === 'merchants' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}
                        onClick={() => setActiveTab('merchants')}
                    >
                        Merchant Analytics
                    </button>
                </div>

                {activeTab === 'transactions' && (
                    <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-blue-500">
                        <div className="p-3 bg-blue-50 text-blue-600 rounded-full">
                            <DollarSign size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Total Revenue</p>
                            <h3 className="text-2xl font-bold text-slate-900">
                                {formatCurrency(data.totalRevenue)}
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
                                {formatCurrency(Math.round(data.arpu || 0))}
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
                                +{lastGrowthEntry?.count || 0} bulan terakhir
                            </div>
                        </div>
                    </Card>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-emerald-500">
                        <div className="p-3 bg-emerald-50 text-emerald-600 rounded-full">
                            <Wallet size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Subscription Revenue</p>
                            <h3 className="text-lg font-bold text-slate-900">
                                {formatCurrency(data.totalSubscriptionRevenue)}
                            </h3>
                        </div>
                    </Card>
                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-indigo-500">
                        <div className="p-3 bg-indigo-50 text-indigo-600 rounded-full">
                            <DollarSign size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Transaction Fees</p>
                            <h3 className="text-lg font-bold text-slate-900">
                                {formatCurrency(data.totalTxnFees)}
                            </h3>
                        </div>
                    </Card>
                    <Card className="p-4 flex items-center space-x-4 border-l-4 border-l-amber-500">
                        <div className="p-3 bg-amber-50 text-amber-600 rounded-full">
                            <Activity size={24} />
                        </div>
                        <div>
                            <p className="text-sm font-medium text-slate-500">Wholesale Fees</p>
                            <h3 className="text-lg font-bold text-slate-900">
                                {formatCurrency(data.totalWholesaleFees)}
                            </h3>
                        </div>
                    </Card>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
                        <p className="text-sm text-slate-500">Persentase merchant yang membatalkan langganan.</p>
                    </Card>

                    <Card className="p-6">
                        <div className="flex items-center justify-between mb-2">
                            <h3 className="font-semibold text-slate-900 flex items-center">
                                <Crown size={20} className="mr-2 text-yellow-500" />
                                Top Merchants (Volume)
                            </h3>
                            {(data.topMerchants || []).length > 0 && (
                                <button
                                    type="button"
                                    className="text-xs text-primary-600 hover:text-primary-700"
                                    onClick={() => setShowTopMerchantsModal(true)}
                                >
                                    Breakdown
                                </button>
                            )}
                        </div>
                        <div className="space-y-3">
                            {(data.topMerchants || []).length === 0 ? (
                                <p className="text-sm text-slate-400 italic">Belum ada data transaksi yang cukup.</p>
                            ) : (
                                (data.topMerchants || []).map((m, idx) => (
                                    <div key={idx} className="flex justify-between items-center text-sm">
                                        <span className="font-medium text-slate-700">{idx + 1}. {m.name}</span>
                                        <span className="text-slate-500 font-mono">
                                            {formatCurrency(m.volume)}
                                        </span>
                                    </div>
                                ))
                            )}
                        </div>
                    </Card>

                    <Card className="p-6">
                        <h3 className="font-semibold text-slate-900 mb-4">Platform Summary</h3>
                        <div className="space-y-2 text-sm">
                            <div className="flex justify-between">
                                <span className="text-slate-500">Total Tenants</span>
                                <span className="font-semibold text-slate-900">{data.totalTenants}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-slate-500">Active Subscribers</span>
                                <span className="font-semibold text-slate-900">{data.activeSubscribers}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-slate-500">Cancelled Tenants</span>
                                <span className="font-semibold text-red-600">{data.cancelledTenants}</span>
                            </div>
                            <div className="flex justify-between">
                                <span className="text-slate-500">Churn Rate</span>
                                <span className="font-semibold text-slate-900">{data.churnRate}%</span>
                            </div>
                        </div>
                    </Card>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <Card className="p-6">
                        <h3 className="font-semibold text-lg text-slate-900 mb-4">Transaction Breakdown by Method</h3>
                        <div className="overflow-x-auto">
                            <table className="min-w-full text-sm">
                                <thead>
                                    <tr className="border-b border-slate-200 bg-slate-50">
                                        <th className="text-left px-3 py-2 font-medium text-slate-600">Method</th>
                                        <th className="text-right px-3 py-2 font-medium text-slate-600">Count</th>
                                        <th className="text-right px-3 py-2 font-medium text-slate-600">Amount</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {(data.txnByMethod || []).length === 0 ? (
                                        <tr>
                                            <td colSpan="3" className="px-3 py-4 text-center text-slate-400">
                                                Belum ada data transaksi untuk periode ini.
                                            </td>
                                        </tr>
                                    ) : (
                                        data.txnByMethod.map((row) => (
                                            <tr key={row.paymentMethod || 'UNKNOWN'} className="border-b border-slate-100">
                                                <td className="px-3 py-2 text-slate-700">
                                                    {row.paymentMethod || '-'}
                                                </td>
                                                <td className="px-3 py-2 text-right text-slate-700">
                                                    {row.count}
                                                </td>
                                                <td className="px-3 py-2 text-right font-mono">
                                                    {formatCurrency(row.amount)}
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </Card>

                    <Card className="p-6">
                        <h3 className="font-semibold text-lg text-slate-900 mb-4">Transaction Breakdown by Source</h3>
                        <div className="overflow-x-auto">
                            <table className="min-w-full text-sm">
                                <thead>
                                    <tr className="border-b border-slate-200 bg-slate-50">
                                        <th className="text-left px-3 py-2 font-medium text-slate-600">Source</th>
                                        <th className="text-right px-3 py-2 font-medium text-slate-600">Count</th>
                                        <th className="text-right px-3 py-2 font-medium text-slate-600">Amount</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {(data.txnBySource || []).length === 0 ? (
                                        <tr>
                                            <td colSpan="3" className="px-3 py-4 text-center text-slate-400">
                                                Belum ada data transaksi untuk periode ini.
                                            </td>
                                        </tr>
                                    ) : (
                                        data.txnBySource.map((row, index) => (
                                            <tr key={row.source || index} className="border-b border-slate-100">
                                                <td className="px-3 py-2 text-slate-700">
                                                    {(row.source || '-').replace('_', ' ')}
                                                </td>
                                                <td className="px-3 py-2 text-right text-slate-700">
                                                    {row.count}
                                                </td>
                                                <td className="px-3 py-2 text-right font-mono">
                                                    {formatCurrency(row.amount)}
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </Card>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <Card className="p-6 lg:col-span-2">
                        <h3 className="font-semibold text-lg text-slate-900 mb-4">Revenue Trend (Last 6 Months)</h3>
                        <div className="h-80">
                            <ResponsiveContainer width="100%" height="100%">
                                <LineChart data={data.revenueChart}>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                    <XAxis dataKey="name" axisLine={false} tickLine={false} />
                                    <YAxis axisLine={false} tickLine={false} />
                                    <Tooltip formatter={(value) => formatCurrency(value)} />
                                    <Line type="monotone" dataKey="revenue" stroke="#2563eb" strokeWidth={3} dot={{ r: 4 }} />
                                </LineChart>
                            </ResponsiveContainer>
                        </div>
                    </Card>

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
                                    <Tooltip formatter={(value) => formatCurrency(value)} />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                        <div className="mt-4 space-y-2">
                            {pieData.map((entry, index) => (
                                <div key={index} className="flex items-center text-sm">
                                    <div
                                        className="w-3 h-3 rounded-full mr-2"
                                        style={{ backgroundColor: COLORS[index % COLORS.length] }}
                                    ></div>
                                    <span className="flex-1 text-slate-600">{entry.name}</span>
                                    <span className="font-semibold">
                                        {formatCurrency(entry.value)}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </Card>
                </div>
                    </>
                )}

                {activeTab === 'merchants' && (
                    <>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
                                <p className="text-sm text-slate-500">Persentase merchant yang membatalkan langganan.</p>
                            </Card>

                            <Card className="p-6">
                                <div className="flex items-center justify-between mb-2">
                                    <h3 className="font-semibold text-slate-900 flex items-center">
                                        <Crown size={20} className="mr-2 text-yellow-500" />
                                        Top Merchants (Volume)
                                    </h3>
                                    {(data.topMerchants || []).length > 0 && (
                                        <button
                                            type="button"
                                            className="text-xs text-primary-600 hover:text-primary-700"
                                            onClick={() => setShowTopMerchantsModal(true)}
                                        >
                                            Breakdown
                                        </button>
                                    )}
                                </div>
                                <div className="space-y-3">
                                    {(data.topMerchants || []).length === 0 ? (
                                        <p className="text-sm text-slate-400 italic">Belum ada data transaksi yang cukup.</p>
                                    ) : (
                                        (data.topMerchants || []).slice(0, 5).map((m, idx) => (
                                            <div key={idx} className="flex justify-between items-center text-sm">
                                                <span className="font-medium text-slate-700">{idx + 1}. {m.name}</span>
                                                <span className="text-slate-500 font-mono">
                                                    {formatCurrency(m.volume)}
                                                </span>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </Card>

                            <Card className="p-6">
                                <h3 className="font-semibold text-slate-900 mb-4">Platform Summary</h3>
                                <div className="space-y-2 text-sm">
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Total Tenants</span>
                                        <span className="font-semibold text-slate-900">{data.totalTenants}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Active Subscribers</span>
                                        <span className="font-semibold text-slate-900">{data.activeSubscribers}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Cancelled Tenants</span>
                                        <span className="font-semibold text-red-600">{data.cancelledTenants}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Churn Rate</span>
                                        <span className="font-semibold text-slate-900">{data.churnRate}%</span>
                                    </div>
                                </div>
                            </Card>
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <Card className="p-6">
                                <h3 className="font-semibold text-lg text-slate-900 mb-4">Merchant Segmentation by Category</h3>
                                <div className="overflow-x-auto">
                                    <table className="min-w-full text-sm">
                                        <thead>
                                            <tr className="border-b border-slate-200 bg-slate-50">
                                                <th className="text-left px-3 py-2 font-medium text-slate-600">Category</th>
                                                <th className="text-right px-3 py-2 font-medium text-slate-600">Merchant Count</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {(data.merchantByCategory || []).length === 0 ? (
                                                <tr>
                                                    <td colSpan="2" className="px-3 py-4 text-center text-slate-400">
                                                        Belum ada data kategori merchant.
                                                    </td>
                                                </tr>
                                            ) : (
                                                data.merchantByCategory.map((row, index) => (
                                                    <tr key={row.category || index} className="border-b border-slate-100">
                                                        <td className="px-3 py-2 text-slate-700">
                                                            {row.category || '-'}
                                                        </td>
                                                        <td className="px-3 py-2 text-right text-slate-700">
                                                            {row.count}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </Card>

                            <Card className="p-6">
                                <h3 className="font-semibold text-lg text-slate-900 mb-4">Tenant Segmentation by Plan</h3>
                                <div className="overflow-x-auto">
                                    <table className="min-w-full text-sm">
                                        <thead>
                                            <tr className="border-b border-slate-200 bg-slate-50">
                                                <th className="text-left px-3 py-2 font-medium text-slate-600">Plan</th>
                                                <th className="text-right px-3 py-2 font-medium text-slate-600">Tenant Count</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {(data.tenantByPlan || []).length === 0 ? (
                                                <tr>
                                                    <td colSpan="2" className="px-3 py-4 text-center text-slate-400">
                                                        Belum ada data plan tenant.
                                                    </td>
                                                </tr>
                                            ) : (
                                                data.tenantByPlan.map((row, index) => (
                                                    <tr key={row.plan || index} className="border-b border-slate-100">
                                                        <td className="px-3 py-2 text-slate-700">
                                                            {row.plan || '-'}
                                                        </td>
                                                        <td className="px-3 py-2 text-right text-slate-700">
                                                            {row.count}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </Card>
                        </div>

                        <Card className="p-6">
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
                    </>
                )}
            </div >

            {showTopMerchantsModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4" onClick={() => setShowTopMerchantsModal(false)}>
                    <div
                        className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[80vh] flex flex-col"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="px-6 py-4 border-b flex items-center justify-between bg-slate-50">
                            <h2 className="text-lg font-semibold text-slate-900">Top Merchants Breakdown</h2>
                            <button
                                type="button"
                                className="text-slate-500 hover:text-slate-700"
                                onClick={() => setShowTopMerchantsModal(false)}
                            >
                                ✕
                            </button>
                        </div>
                        <div className="p-6 overflow-auto">
                            <table className="min-w-full text-sm">
                                <thead>
                                    <tr className="border-b border-slate-200 bg-slate-50">
                                        <th className="text-left px-3 py-2 font-medium text-slate-600">#</th>
                                        <th className="text-left px-3 py-2 font-medium text-slate-600">Merchant</th>
                                        <th className="text-left px-3 py-2 font-medium text-slate-600">Tenant</th>
                                        <th className="text-right px-3 py-2 font-medium text-slate-600">Volume</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {(data.topMerchants || []).map((m, idx) => (
                                        <tr key={m.name + idx} className="border-b border-slate-100">
                                            <td className="px-3 py-2 text-slate-500">{idx + 1}</td>
                                            <td className="px-3 py-2 text-slate-800">{m.name}</td>
                                            <td className="px-3 py-2 text-slate-600">{m.tenantName || '-'}</td>
                                            <td className="px-3 py-2 text-right font-mono">
                                                {formatCurrency(m.volume)}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout >
    );
};

export default Reports;
