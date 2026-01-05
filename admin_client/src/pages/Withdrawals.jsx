import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { Check, X, Download, Search, AlertCircle, CheckCircle2, XCircle } from 'lucide-react';
import { cn } from '../lib/utils';

const Withdrawals = () => {
    const [withdrawals, setWithdrawals] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('PENDING'); // PENDING, APPROVED, REJECTED
    const [exporting, setExporting] = useState(false);
    const [search, setSearch] = useState('');

    const fetchWithdrawals = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/withdrawals', { params: { status: filter } });
            setWithdrawals(res.data.data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchWithdrawals();
    }, [filter]);

    const handleApprove = async (id) => {
        if (!window.confirm("Are you sure you want to approve this transfer?")) return;
        try {
            await api.put(`/admin/withdrawals/${id}/approve`);
            fetchWithdrawals();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to approve");
        }
    };

    const handleReject = async (id) => {
        const reason = prompt("Enter rejection reason:");
        if (!reason) return;
        try {
            await api.put(`/admin/withdrawals/${id}/reject`, { reason });
            fetchWithdrawals();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to reject");
        }
    };

    const handleExport = async () => {
        setExporting(true);
        try {
            const res = await api.get('/admin/withdrawals/export');
            const data = res.data.data;

            // Convert to CSV
            const csvRows = [];
            const headers = ['ID', 'Date', 'Store Name', 'Tenant', 'Amount', 'Bank', 'Account Number', 'Status'];
            csvRows.push(headers.join(','));

            data.forEach(row => {
                const values = [
                    row.id,
                    new Date(row.createdAt).toISOString(),
                    `"${row.store.name}"`, // Quote strings
                    `"${row.store.tenant.name}"`,
                    row.amount,
                    row.bankName,
                    `'${row.accountNumber}`, // Force text in Excel with '
                    row.status
                ];
                csvRows.push(values.join(','));
            });

            const csvContent = "data:text/csv;charset=utf-8," + csvRows.join("\n");
            const encodedUri = encodeURI(csvContent);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", `withdrawals_report_${new Date().toISOString().split('T')[0]}.csv`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

        } catch (error) {
            console.error(error);
            alert("Failed to export data");
        } finally {
            setExporting(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    const filteredWithdrawals = withdrawals.filter(w =>
        w.store?.name?.toLowerCase().includes(search.toLowerCase()) ||
        w.accountNumber?.includes(search)
    );

    const tabs = [
        { id: 'PENDING', label: 'Pending Request', icon: AlertCircle, color: 'text-yellow-600', activeColor: 'bg-yellow-50 text-yellow-700 border-yellow-200' },
        { id: 'APPROVED', label: 'Approved', icon: CheckCircle2, color: 'text-green-600', activeColor: 'bg-green-50 text-green-700 border-green-200' },
        { id: 'REJECTED', label: 'Rejected', icon: XCircle, color: 'text-red-600', activeColor: 'bg-red-50 text-red-700 border-red-200' },
    ];

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-semibold text-slate-900">Withdrawals</h1>
                        <p className="text-slate-500 mt-1">Manage and track merchant fund transfer requests.</p>
                    </div>
                    <Button
                        variant="outline"
                        icon={Download}
                        onClick={handleExport}
                        isLoading={exporting}
                    >
                        Export CSV
                    </Button>
                </div>

                {/* New Tabs UI */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setFilter(tab.id)}
                            className={cn(
                                "flex items-center justify-center p-4 rounded-xl border transition-all duration-200",
                                filter === tab.id 
                                    ? `border-2 ${tab.activeColor} shadow-sm ring-1 ring-offset-0` 
                                    : "bg-white border-slate-200 text-slate-500 hover:border-slate-300 hover:bg-slate-50"
                            )}
                        >
                            <tab.icon className={cn("mr-3 h-5 w-5", filter === tab.id ? "opacity-100" : "opacity-70")} />
                            <span className={cn("font-semibold", filter === tab.id ? "" : "text-slate-600")}>
                                {tab.label}
                            </span>
                        </button>
                    ))}
                </div>

                <div className="flex flex-col sm:flex-row gap-4 justify-between items-center bg-white p-4 rounded-lg border border-slate-200 shadow-sm">
                    <div className="relative w-full sm:w-96">
                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <Search className="h-4 w-4 text-slate-400" />
                        </div>
                        <input
                            type="text"
                            placeholder="Search by Store Name or Account No..."
                            className="pl-10 pr-4 py-2 w-full border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <div className="text-sm text-slate-500">
                        {loading ? 'Loading...' : `Showing ${filteredWithdrawals.length} ${filter.toLowerCase()} requests`}
                    </div>
                </div>

                <Card className="overflow-hidden border border-slate-200 shadow-sm">
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Request Date</Th>
                                <Th>Merchant</Th>
                                <Th>Amount</Th>
                                <Th>Bank Details</Th>
                                <Th>Status</Th>
                                <Th className="text-right">Actions</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {loading ? (
                                <Tr>
                                    <Td colSpan="6" className="text-center py-12 text-slate-400">Loading data...</Td>
                                </Tr>
                            ) : filteredWithdrawals.length === 0 ? (
                                <Tr>
                                    <Td colSpan="6" className="text-center py-12 text-slate-400">No withdrawals found.</Td>
                                </Tr>
                            ) : filteredWithdrawals.map((w) => (
                                <Tr key={w.id}>
                                    <Td>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-slate-900">{new Date(w.createdAt).toLocaleDateString()}</span>
                                            <span className="text-xs text-slate-500">{new Date(w.createdAt).toLocaleTimeString()}</span>
                                        </div>
                                    </Td>
                                    <Td>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-slate-900">{w.store.name}</span>
                                            <span className="text-xs text-slate-500 text-truncate max-w-[150px]">{w.store.tenant.name}</span>
                                        </div>
                                    </Td>
                                    <Td>
                                        <span className="font-mono font-medium text-slate-700">{formatCurrency(w.amount)}</span>
                                    </Td>
                                    <Td>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-slate-900">{w.bankName}</span>
                                            <span className="text-xs font-mono text-slate-500">{w.accountNumber}</span>
                                        </div>
                                    </Td>
                                    <Td>
                                        <Badge variant={w.status === 'APPROVED' ? 'success' : w.status === 'REJECTED' ? 'error' : 'warning'}>
                                            {w.status}
                                        </Badge>
                                    </Td>
                                    <Td className="text-right">
                                        {w.status === 'PENDING' && (
                                            <div className="flex justify-end gap-2">
                                                <Button
                                                    size="sm"
                                                    onClick={() => handleApprove(w.id)}
                                                    icon={Check}
                                                    className="bg-green-600 hover:bg-green-700"
                                                >
                                                    Approve
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    onClick={() => handleReject(w.id)}
                                                    className="text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200"
                                                >
                                                    Reject
                                                </Button>
                                            </div>
                                        )}
                                        {w.status !== 'PENDING' && (
                                            <span className="text-xs text-slate-400 italic">No actions</span>
                                        )}
                                    </Td>
                                </Tr>
                            ))}
                        </Tbody>
                    </Table>
                </Card>
            </div>
        </AdminLayout>
    );
};

export default Withdrawals;
