import React, { useEffect, useState } from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { ArrowRight, Wallet, Settings, Users, TrendingUp, Clock, AlertCircle, Download, ShoppingBag, Receipt } from 'lucide-react'; // [NEW] Icons
import { Link } from 'react-router-dom';
import api from '../api';
import Badge from '../components/ui/Badge';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

const Dashboard = () => {
    const user = JSON.parse(localStorage.getItem('adminUser') || '{}');
    const [stats, setStats] = useState({
        totalStores: 0,
        totalPayouts: 0,
        pendingWithdrawals: 0,
        recentWithdrawals: []
    });
    const [recentTransactions, setRecentTransactions] = useState([]); // [NEW]
    const [txnStats, setTxnStats] = useState({ totalCount: 0, totalAmount: 0 }); // [NEW]
    const [chartData, setChartData] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            try {
                // [NEW] Fetch Transactions for monitoring
                const txnRes = await api.get('/admin/transactions?limit=5');
                const txns = txnRes.data.data.transactions || [];
                setRecentTransactions(txns);
                setTxnStats({
                    totalCount: txnRes.data.data.total || 0,
                    // Note: totalAmount might not be available in list endpoint, using placeholder or calculated from recent if needed
                    // For now we only have total count from this endpoint.
                });

                const [statsRes, chartRes] = await Promise.all([
                    api.get('/admin/stats'),
                    api.get('/admin/stats/chart')
                ]);
                setStats(statsRes.data.data);
                setChartData(chartRes.data.data);
            } catch (error) {
                console.error("Failed to fetch data", error);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);

    const StatCard = ({ title, value, icon: Icon, colorClass, link }) => (
        <Card className="p-6 relative overflow-hidden transition-all duration-200 hover:shadow-md border-slate-200">
            <div className="flex justify-between items-start">
                <div>
                    <p className="text-sm font-medium text-slate-500 mb-1">{title}</p>
                    <h3 className="text-2xl font-bold text-slate-900">{loading ? '...' : value}</h3>
                </div>
                <div className={`p-3 rounded-lg ${colorClass}`}>
                    <Icon size={24} />
                </div>
            </div>
            {link && (
                <div className="mt-4 pt-4 border-t border-slate-100">
                    <Link to={link} className="text-sm font-medium text-primary-600 flex items-center hover:underline">
                        View Details <ArrowRight size={16} className="ml-1" />
                    </Link>
                </div>
            )}
        </Card>
    );

    const handleExport = async () => {
        try {
            const res = await api.get('/admin/export/dashboard');
            const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(res.data.data, null, 2));
            const downloadAnchorNode = document.createElement('a');
            downloadAnchorNode.setAttribute("href", dataStr);
            downloadAnchorNode.setAttribute("download", "dashboard_export_" + Date.now() + ".json");
            document.body.appendChild(downloadAnchorNode); // required for firefox
            downloadAnchorNode.click();
            downloadAnchorNode.remove();
        } catch (error) {
            alert("Failed to export data");
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Dashboard</h1>
                        <p className="text-slate-500 mt-1">Overview of your store performance.</p>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button
                            onClick={handleExport}
                            variant="outline"
                            icon={Download}
                        >
                            Export Data
                        </Button>
                        <Badge variant="outline" className="px-3 py-1">
                            {new Date().toLocaleDateString('id-ID', { dateStyle: 'full' })}
                        </Badge>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <StatCard
                    title="Total Transactions"
                    value={txnStats.totalCount}
                    icon={Receipt}
                    colorClass="bg-indigo-50 text-indigo-600"
                    link="/transactions"
                />
                <StatCard
                    title="Total Active Merchants"
                    value={stats.totalStores}
                    icon={Users}
                    colorClass="bg-blue-50 text-blue-600"
                />
                <StatCard
                    title="Total Payouts Processed"
                    value={formatCurrency(stats.totalPayouts)}
                    icon={TrendingUp}
                    colorClass="bg-green-50 text-green-600"
                />
                <StatCard
                    title="Pending Requests"
                    value={stats.pendingWithdrawals}
                    icon={Clock}
                    colorClass={stats.pendingWithdrawals > 0 ? "bg-orange-50 text-orange-600" : "bg-slate-100 text-slate-500"}
                    link="/withdrawals"
                />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* Recent Transactions [NEW] */}
                <Card className="h-full shadow-sm border-slate-200">
                    <div className="p-6 border-b border-slate-100 flex justify-between items-center">
                        <h3 className="font-semibold text-slate-900">Recent Transactions</h3>
                        <Link to="/transactions" className="text-sm text-primary-600 hover:text-primary-700 font-medium flex items-center">
                            View all <ArrowRight size={14} className="ml-1" />
                        </Link>
                    </div>
                    <div>
                        {loading ? (
                            <div className="p-6 text-center text-slate-400">Loading...</div>
                        ) : recentTransactions.length === 0 ? (
                            <div className="p-6 text-center text-slate-400">No recent transactions.</div>
                        ) : (
                            <div className="divide-y divide-slate-100">
                                {recentTransactions.map((t) => (
                                    <div key={t.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition">
                                        <div className="flex items-center space-x-3">
                                            <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-500">
                                                <ShoppingBag size={18} />
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-slate-900">{t.store?.name}</p>
                                                <p className="text-xs text-slate-500">{new Date(t.occurredAt).toLocaleDateString()}</p>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <p className="text-sm font-bold text-slate-900">{formatCurrency(t.totalAmount)}</p>
                                            <div className="mt-1">
                                                <Badge variant={t.paymentStatus === 'PAID' ? 'success' : 'warning'}>
                                                    {t.paymentStatus}
                                                </Badge>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </Card>

                {/* Recent Withdrawals (Moved here or kept) */}
                <Card className="h-full shadow-sm border-slate-200">
                    <div className="p-6 border-b border-slate-100 flex justify-between items-center">
                        <h3 className="font-semibold text-slate-900">Recent Withdrawals</h3>
                        <Link to="/withdrawals" className="text-sm text-primary-600 hover:text-primary-700 font-medium flex items-center">
                            View all <ArrowRight size={14} className="ml-1" />
                        </Link>
                    </div>
                    <div>
                        {loading ? (
                            <div className="p-6 text-center text-slate-400">Loading...</div>
                        ) : stats.recentWithdrawals.length === 0 ? (
                            <div className="p-6 text-center text-slate-400">No recent activity.</div>
                        ) : (
                            <div className="divide-y divide-slate-100">
                                {stats.recentWithdrawals.map((w) => (
                                    <div key={w.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition">
                                        <div className="flex items-center space-x-3">
                                            <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-500">
                                                <Wallet size={18} />
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-slate-900">{w.store.name}</p>
                                                <p className="text-xs text-slate-500">{new Date(w.createdAt).toLocaleDateString()}</p>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <p className="text-sm font-bold text-slate-900">{formatCurrency(w.amount)}</p>
                                            <div className="mt-1">
                                                <Badge variant={w.status === 'APPROVED' ? 'success' : w.status === 'REJECTED' ? 'error' : 'warning'}>
                                                    {w.status}
                                                </Badge>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </Card>
            </div>
        </AdminLayout>
    );
};

export default Dashboard;
