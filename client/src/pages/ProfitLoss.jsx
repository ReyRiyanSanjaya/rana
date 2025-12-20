import React, { useEffect, useState } from 'react';
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
    Legend
} from 'recharts';
import { Calendar, Download, TrendingUp, TrendingDown, DollarSign } from 'lucide-react';
import DashboardLayout from '../components/layout/DashboardLayout';
import { fetchProfitLoss } from '../services/api';

const PnLCard = ({ title, value, subValue, type = 'neutral' }) => {
    const colors = {
        positive: 'text-green-600 bg-green-50',
        negative: 'text-red-600 bg-red-50',
        neutral: 'text-slate-900 bg-white',
        primary: 'text-indigo-600 bg-indigo-50'
    };

    return (
        <div className={`p-6 rounded-xl border border-slate-100 shadow-sm ${type === 'neutral' ? 'bg-white' : colors[type].split(' ')[1]}`}>
            <p className="text-sm font-medium text-slate-500 mb-1">{title}</p>
            <h3 className={`text-2xl font-bold ${colors[type].split(' ')[0]}`}>{value}</h3>
            {subValue && <p className="text-xs mt-2 text-slate-500">{subValue}</p>}
        </div>
    );
};

const ProfitLoss = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [dateRange, setDateRange] = useState('this_month'); // simple toggle for now

    useEffect(() => {
        const now = new Date();
        let start = new Date();
        let end = new Date();

        if (dateRange === 'today') {
            start.setHours(0, 0, 0, 0);
            end.setHours(23, 59, 59, 999);
        } else if (dateRange === 'this_week') {
            // Monday as start
            const day = now.getDay() || 7;
            if (day !== 1) start.setHours(-24 * (day - 1));
            start.setHours(0, 0, 0, 0);
        } else if (dateRange === 'this_month') {
            start.setDate(1);
            start.setHours(0, 0, 0, 0);
        } else if (dateRange === 'last_month') {
            start.setMonth(start.getMonth() - 1);
            start.setDate(1);
            start.setHours(0, 0, 0, 0);
            end.setDate(0); // Last day of prev month
            end.setHours(23, 59, 59, 999);
        }

        const startStr = start.toISOString().split('T')[0];
        const endStr = end.toISOString().split('T')[0];

        fetchProfitLoss(startStr, endStr).then(res => {
            setData(res);
            setLoading(false);
        }).catch(err => {
            console.error("Failed to load PnL", err);
            setLoading(false);
        });
    }, [dateRange]);

    if (loading) return <DashboardLayout>Loading...</DashboardLayout>;

    const { pnl, chartData } = data;
    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    return (
        <DashboardLayout>
            <div className="space-y-6">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h2 className="text-2xl font-bold text-slate-900">Profit & Loss</h2>
                        <p className="text-slate-500">Financial performance analysis</p>
                    </div>

                    <div className="flex items-center space-x-3">
                        <div className="flex items-center space-x-2 bg-white px-3 py-2 rounded-lg border border-slate-200">
                            <Calendar size={18} className="text-slate-500" />
                            <select
                                className="bg-transparent text-sm outline-none cursor-pointer"
                                value={dateRange}
                                onChange={(e) => setDateRange(e.target.value)}
                            >
                                <option value="today">Today</option>
                                <option value="this_week">This Week</option>
                                <option value="this_month">This Month</option>
                                <option value="last_month">Last Month</option>
                            </select>
                        </div>
                        <button className="flex items-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors text-sm font-medium">
                            <Download size={18} />
                            <span>Export PDF</span>
                        </button>
                    </div>
                </div>

                {/* Key Metrics */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <PnLCard
                        title="Total Revenue"
                        value={formatCurrency(pnl.revenue)}
                        subValue={`${pnl.transactionCount || 0} Transactions`}
                        type="primary"
                    />
                    <PnLCard
                        title="COGS"
                        value={formatCurrency(pnl.cogs)}
                        subValue="Cost of Goods Sold"
                        type="neutral"
                    />
                    <PnLCard
                        title="Gross Profit"
                        value={formatCurrency(pnl.grossProfit)}
                        subValue={`${pnl.margin}% Margin`}
                        type="positive"
                    />
                    <PnLCard
                        title="Net Profit"
                        value={formatCurrency(pnl.netProfit)}
                        subValue="After all expenses"
                        type="positive"
                    />
                </div>

                {/* Charts */}
                <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
                    <h3 className="font-bold text-lg mb-6">Revenue vs Profit Trend</h3>
                    <div className="h-80">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={chartData} margin={{ left: 20, right: 20 }}>
                                <defs>
                                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#4F46E5" stopOpacity={0.1} />
                                        <stop offset="95%" stopColor="#4F46E5" stopOpacity={0} />
                                    </linearGradient>
                                    <linearGradient id="colorProf" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#10B981" stopOpacity={0.1} />
                                        <stop offset="95%" stopColor="#10B981" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748B' }} />
                                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#64748B' }} />
                                <Tooltip
                                    contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                                    formatter={(val) => formatCurrency(val)}
                                />
                                <Legend />
                                <Area type="monotone" dataKey="revenue" stroke="#4F46E5" fillOpacity={1} fill="url(#colorRev)" name="Revenue" strokeWidth={2} />
                                <Area type="monotone" dataKey="profit" stroke="#10B981" fillOpacity={1} fill="url(#colorProf)" name="Gross Profit" strokeWidth={2} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Detailed Breakdown Table */}
                <div className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
                    <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                        <h3 className="font-bold text-lg">Financial Breakdown</h3>
                    </div>
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-slate-600 font-medium">
                            <tr>
                                <th className="px-6 py-3">Category</th>
                                <th className="px-6 py-3 text-right">Amount</th>
                                <th className="px-6 py-3 text-right">% of Revenue</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            <tr>
                                <td className="px-6 py-4 font-medium text-slate-900">Gross Sales</td>
                                <td className="px-6 py-4 text-right">{formatCurrency(pnl.revenue + pnl.discountsGiven)}</td>
                                <td className="px-6 py-4 text-right">100%</td>
                            </tr>
                            <tr>
                                <td className="px-6 py-4 text-slate-600">Discounts</td>
                                <td className="px-6 py-4 text-right text-red-500">-{formatCurrency(pnl.discountsGiven)}</td>
                                <td className="px-6 py-4 text-right">{(pnl.discountsGiven / (pnl.revenue + pnl.discountsGiven) * 100).toFixed(1)}%</td>
                            </tr>
                            <tr className="bg-indigo-50/50">
                                <td className="px-6 py-4 font-bold text-indigo-900">Net Revenue</td>
                                <td className="px-6 py-4 text-right font-bold text-indigo-700">{formatCurrency(pnl.revenue)}</td>
                                <td className="px-6 py-4 text-right font-bold text-indigo-700">98%</td>
                            </tr>
                            <tr>
                                <td className="px-6 py-4 text-slate-600">COGS</td>
                                <td className="px-6 py-4 text-right text-red-500">-{formatCurrency(pnl.cogs)}</td>
                                <td className="px-6 py-4 text-right">{(pnl.cogs / pnl.revenue * 100).toFixed(1)}%</td>
                            </tr>
                            <tr>
                                <td className="px-6 py-4 font-bold text-green-900">Gross Profit</td>
                                <td className="px-6 py-4 text-right font-bold text-green-700">{formatCurrency(pnl.grossProfit)}</td>
                                <td className="px-6 py-4 text-right font-bold text-green-700">{pnl.margin}%</td>
                            </tr>
                            {/* Expense Breakdown */}
                            {Object.entries(pnl.expenseBreakdown || {}).map(([cat, amt]) => (
                                <tr key={cat}>
                                    <td className="px-6 py-4 text-slate-600 pl-10 border-l-4 border-l-transparent hover:border-l-red-200">
                                        {cat.replace('EXPENSE_', '')}
                                    </td>
                                    <td className="px-6 py-4 text-right text-red-500">-{formatCurrency(amt)}</td>
                                    <td className="px-6 py-4 text-right">{(pnl.revenue > 0 ? (amt / pnl.revenue * 100) : 0).toFixed(1)}%</td>
                                </tr>
                            ))}
                            <tr className="bg-red-50/30">
                                <td className="px-6 py-4 font-medium text-red-900">Total Expenses</td>
                                <td className="px-6 py-4 text-right font-bold text-red-700">-{formatCurrency(pnl.totalExpenses)}</td>
                                <td className="px-6 py-4 text-right text-red-700">{(pnl.revenue > 0 ? (pnl.totalExpenses / pnl.revenue * 100) : 0).toFixed(1)}%</td>
                            </tr>
                            <tr className="bg-indigo-100/50 text-lg">
                                <td className="px-6 py-4 font-extrabold text-indigo-900">Net Profit</td>
                                <td className="px-6 py-4 text-right font-extrabold text-indigo-700">{formatCurrency(pnl.netProfit)}</td>
                                <td className="px-6 py-4 text-right font-bold text-indigo-700">
                                    {(pnl.revenue > 0 ? (pnl.netProfit / pnl.revenue * 100) : 0).toFixed(1)}%
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

            </div>
        </DashboardLayout>
    );
};

export default ProfitLoss;
