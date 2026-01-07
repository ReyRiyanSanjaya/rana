import React, { useEffect, useState, useCallback } from 'react';
import { useLocation } from 'react-router-dom';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { Download, ChevronLeft, ChevronRight, Search, X } from 'lucide-react';
import { getSocket } from '../lib/socket';

const Transactions = () => {
    const [transactions, setTransactions] = useState([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [loading, setLoading] = useState(true);
    const [exporting, setExporting] = useState(false);
    const [error, setError] = useState(null);
    const [search, setSearch] = useState('');
    const [selectedTransaction, setSelectedTransaction] = useState(null);

    // Filters
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [area, setArea] = useState('');
    const [category, setCategory] = useState(''); // Store Category
    const [paymentStatus, setPaymentStatus] = useState('');
    const [paymentMethod, setPaymentMethod] = useState('');
    const location = useLocation();

    const fetchTransactions = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const params = {
                page,
                limit: 20,
                startDate: startDate || undefined,
                endDate: endDate || undefined,
                area: area || undefined,
                category: category || undefined,
                paymentStatus: paymentStatus || undefined,
                paymentMethod: paymentMethod || undefined
            };
            const res = await api.get('/admin/transactions', { params });
            if (res.data.status === 'success') {
                setTransactions(res.data.data.transactions || []);
                setTotal(res.data.data.total || 0);
                setTotalPages(res.data.data.totalPages || 1);
            } else {
                setTransactions([]);
                setTotal(0);
                setTotalPages(1);
                setError(res.data.message || 'Failed to load transactions');
            }
        } catch (err) {
            console.error(err);
            setTransactions([]);
            setTotal(0);
            setTotalPages(1);
            setError(err.response?.data?.message || 'Failed to load transactions');
        } finally {
            setLoading(false);
        }
    }, [page, startDate, endDate, area, category, paymentStatus, paymentMethod]);

    useEffect(() => {
        fetchTransactions();
    }, [fetchTransactions]);

    // Socket Listener for Auto Refresh
    useEffect(() => {
        const socket = getSocket();
        if (!socket) return;

        const handleNewTransaction = (data) => {
            console.log('New transaction received, refreshing...', data);
            fetchTransactions();
        };

        socket.on('transactions:created', handleNewTransaction);

        return () => {
            socket.off('transactions:created', handleNewTransaction);
        };
    }, [fetchTransactions]);

    useEffect(() => {
        const params = new URLSearchParams(location.search);
        const qsStartDate = params.get('startDate') || '';
        const qsEndDate = params.get('endDate') || '';
        const qsArea = params.get('area') || '';
        const qsCategory = params.get('category') || '';
        const qsStatus = params.get('paymentStatus') || '';
        const qsMethod = params.get('paymentMethod') || '';

        if (qsStartDate) setStartDate(qsStartDate);
        if (qsEndDate) setEndDate(qsEndDate);
        if (qsArea) setArea(qsArea);
        if (qsCategory) setCategory(qsCategory);
        if (qsStatus) setPaymentStatus(qsStatus);
        if (qsMethod) setPaymentMethod(qsMethod);
    }, [location.search]);

    const handleExport = async () => {
        setExporting(true);
        try {
            const params = {
                startDate: startDate || undefined,
                endDate: endDate || undefined,
                area: area || undefined,
                category: category || undefined,
                paymentStatus: paymentStatus || undefined,
                paymentMethod: paymentMethod || undefined
            };
            const res = await api.get('/admin/transactions/export', { params });
            const data = Array.isArray(res.data.data) ? res.data.data : [];

            const csvRows = [];
            const headers = ['ID', 'Date', 'Merchant', 'Store Location', 'Store Category', 'Amount', 'Payment Method', 'Status', 'O2O Status', 'Cashier'];
            csvRows.push(headers.join(','));

            data.forEach(row => {
                const values = [
                    row.id,
                    row.occurredAt ? new Date(row.occurredAt).toISOString() : '',
                    `"${row.store || ''}"`,
                    `"${row.storeLocation || ''}"`,
                    `"${row.storeCategory || ''}"`,
                    row.totalAmount,
                    row.paymentMethod,
                    row.paymentStatus,
                    row.orderStatus,
                    `"${row.cashier || ''}"`
                ];
                csvRows.push(values.join(','));
            });

            const csvContent = "data:text/csv;charset=utf-8," + csvRows.join("\n");
            const encodedUri = encodeURI(csvContent);
            const link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", `transactions_report_${new Date().toISOString().split('T')[0]}.csv`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (err) {
            console.error(err);
            alert("Failed to export data");
        } finally {
            setExporting(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val || 0);

    const filteredTransactions = transactions.filter((t) => {
        const q = search.trim().toLowerCase();
        if (!q) return true;
        const storeName = (t.store?.name || '').toLowerCase();
        const storeLocation = (t.store?.location || '').toLowerCase();
        const storeCategory = (t.store?.category || '').toLowerCase();
        const tenantName = (t.tenant?.name || '').toLowerCase();
        const cashierName = (t.user?.name || '').toLowerCase();
        const method = (t.paymentMethod || '').toLowerCase();
        const status = (t.paymentStatus || '').toLowerCase();
        const id = (t.id || '').toLowerCase();
        return (
            storeName.includes(q) ||
            storeLocation.includes(q) ||
            storeCategory.includes(q) ||
            tenantName.includes(q) ||
            cashierName.includes(q) ||
            method.includes(q) ||
            status.includes(q) ||
            id.includes(q)
        );
    });

    const pageTotalAmount = filteredTransactions.reduce((sum, t) => sum + (t.totalAmount || 0), 0);

    const getOrderStatusVariant = (status) => {
        if (!status) return 'secondary';
        if (status === 'COMPLETED' || status === 'DELIVERED') return 'success';
        if (status === 'CANCELLED' || status === 'FAILED') return 'error';
        return 'warning';
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col gap-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-semibold text-slate-900">Transactions</h1>
                        <p className="text-slate-500 mt-1">Monitor all merchant sales and transaction history.</p>
                    </div>
                    <div className="flex flex-wrap gap-3">
                        <Button
                            variant="secondary"
                            icon={Download}
                            onClick={handleExport}
                            isLoading={exporting}
                        >
                            Export to Excel (CSV)
                        </Button>
                    </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <Card className="p-4 flex flex-col">
                        <span className="text-xs font-semibold text-slate-500 uppercase">Total Transaksi (filter aktif)</span>
                        <span className="mt-2 text-2xl font-bold text-slate-900">{total}</span>
                    </Card>
                    <Card className="p-4 flex flex-col">
                        <span className="text-xs font-semibold text-slate-500 uppercase">Total Nilai di Halaman Ini</span>
                        <span className="mt-2 text-2xl font-bold text-emerald-700">{formatCurrency(pageTotalAmount)}</span>
                    </Card>
                    <Card className="p-4 flex flex-col">
                        <span className="text-xs font-semibold text-slate-500 uppercase">Rentang Tanggal</span>
                        <span className="mt-2 text-sm text-slate-700">
                            {startDate || endDate
                                ? `${startDate || 'Semua'} s.d. ${endDate || 'Sekarang'}`
                                : 'Semua tanggal'}
                        </span>
                    </Card>
                </div>

                <Card className="p-4">
                    <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4 items-end">
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">Start Date</label>
                            <input
                                type="date"
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm"
                                value={startDate}
                                onChange={e => setStartDate(e.target.value)}
                            />
                        </div>
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">End Date</label>
                            <input
                                type="date"
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm"
                                value={endDate}
                                onChange={e => setEndDate(e.target.value)}
                            />
                        </div>
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">Per Area (Location)</label>
                            <input
                                type="text"
                                placeholder="e.g. Jakarta"
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm"
                                value={area}
                                onChange={e => setArea(e.target.value)}
                            />
                        </div>
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">Category</label>
                            <select
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm bg-white"
                                value={category}
                                onChange={e => setCategory(e.target.value)}
                            >
                                <option value="">All Categories</option>
                                <option value="Retail">Retail</option>
                                <option value="FnB">F&B</option>
                                <option value="Service">Service</option>
                            </select>
                        </div>
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">Status</label>
                            <select
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm bg-white"
                                value={paymentStatus}
                                onChange={e => setPaymentStatus(e.target.value)}
                            >
                                <option value="">All Status</option>
                                <option value="PAID">PAID</option>
                                <option value="UNPAID">UNPAID</option>
                                <option value="REFUNDED">REFUNDED</option>
                            </select>
                        </div>
                        <div className="md:col-span-2 lg:col-span-1">
                            <label className="text-xs font-semibold text-slate-500 uppercase">Method</label>
                            <select
                                className="w-full mt-1 px-3 py-2 border rounded-md text-sm bg-white"
                                value={paymentMethod}
                                onChange={e => setPaymentMethod(e.target.value)}
                            >
                                <option value="">All Methods</option>
                                <option value="CASH">CASH</option>
                                <option value="QRIS">QRIS</option>
                                <option value="TRANSFER">TRANSFER</option>
                            </select>
                        </div>
                    </div>
                    <div className="mt-4 flex flex-col md:flex-row gap-4 md:items-center md:justify-between">
                        <div className="relative w-full md:w-80">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <Search className="h-4 w-4 text-slate-400" />
                            </div>
                            <input
                                type="text"
                                placeholder="Cari ID, Merchant, Kasir, metode pembayaran..."
                                className="pl-10 pr-9 py-2 w-full border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                            />
                            {search && (
                                <button
                                    type="button"
                                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
                                    onClick={() => setSearch('')}
                                >
                                    <X className="h-4 w-4" />
                                </button>
                            )}
                        </div>
                        <div className="flex flex-col md:flex-row md:items-center gap-2 text-sm text-slate-500">
                            <span>{total} total transaksi; menampilkan {filteredTransactions.length} di halaman ini</span>
                            {(startDate || endDate || area || category || paymentStatus || paymentMethod) && (
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => {
                                        setStartDate('');
                                        setEndDate('');
                                        setArea('');
                                        setCategory('');
                                        setPaymentStatus('');
                                        setPaymentMethod('');
                                    }}
                                    className="text-blue-600 border-blue-200 hover:bg-blue-50"
                                >
                                    Clear Filters
                                </Button>
                            )}
                        </div>
                    </div>
                </Card>
            </div>

            {error && (
                <div className="mb-4 p-4 bg-red-50 text-red-700 border border-red-200 rounded-lg text-sm flex items-center justify-between">
                    <span>{error}</span>
                    <Button size="sm" variant="outline" onClick={fetchTransactions}>
                        Retry
                    </Button>
                </div>
            )}

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Date</Th>
                            <Th>Merchant / Area</Th>
                            <Th>Category</Th>
                            <Th>Amount</Th>
                            <Th>Method</Th>
                            <Th>Status</Th>
                            <Th>Cashier</Th>
                            <Th>O2O Status</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="8" className="text-center py-12 text-slate-400">Loading data...</Td>
                            </Tr>
                        ) : filteredTransactions.length === 0 ? (
                            <Tr>
                                <Td colSpan="8" className="text-center py-12 text-slate-400">No transactions found.</Td>
                            </Tr>
                        ) : filteredTransactions.map((t) => (
                            <Tr
                                key={t.id}
                                className="cursor-pointer"
                                onClick={() => setSelectedTransaction(t)}
                            >
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{new Date(t.occurredAt).toLocaleDateString()}</span>
                                        <span className="text-xs text-slate-500">{new Date(t.occurredAt).toLocaleTimeString()}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{t.store?.name}</span>
                                        <span className="text-xs text-slate-500">{t.store?.location || '-'}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <span className="text-sm text-slate-600">{t.store?.category || '-'}</span>
                                </Td>
                                <Td>
                                    <span className="font-mono font-medium text-slate-700">{formatCurrency(t.totalAmount)}</span>
                                </Td>
                                <Td>
                                    <Badge variant="secondary">{t.paymentMethod}</Badge>
                                </Td>
                                <Td>
                                    <Badge variant={t.paymentStatus === 'PAID' ? 'success' : 'warning'}>
                                        {t.paymentStatus}
                                    </Badge>
                                </Td>
                                <Td>
                                    <span className="text-sm text-slate-600">{t.user?.name || '-'}</span>
                                </Td>
                                <Td>
                                    <Badge variant={getOrderStatusVariant(t.orderStatus)}>
                                        {t.orderStatus || '-'}
                                    </Badge>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>

                {/* Pagination */}
                <div className="p-4 border-t border-slate-100 flex items-center justify-between">
                    <div className="text-sm text-slate-500">
                        Page {page} of {totalPages}
                    </div>
                    <div className="flex gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={page === 1}
                            onClick={() => setPage(p => Math.max(1, p - 1))}
                        >
                            <ChevronLeft size={16} /> Previous
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={page >= totalPages}
                            onClick={() => setPage(p => p + 1)}
                        >
                            Next <ChevronRight size={16} />
                        </Button>
                    </div>
                </div>
            </Card>
            {selectedTransaction && (
                <div
                    className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70"
                    onClick={() => setSelectedTransaction(null)}
                >
                    <div
                        className="w-full max-w-2xl bg-white rounded-xl shadow-2xl overflow-hidden"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="flex items-center justify-between px-6 py-4 border-b bg-slate-50">
                            <div>
                                <h2 className="text-lg font-semibold text-slate-900">Detail Transaksi</h2>
                                <p className="text-xs text-slate-500">
                                    ID: {selectedTransaction.id}
                                </p>
                            </div>
                            <button
                                type="button"
                                className="p-1 rounded-full hover:bg-slate-200 text-slate-500"
                                onClick={() => setSelectedTransaction(null)}
                            >
                                <X className="h-5 w-5" />
                            </button>
                        </div>
                        <div className="px-6 py-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <h3 className="text-xs font-semibold text-slate-500 uppercase">Informasi Utama</h3>
                                <div className="text-sm">
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Tanggal</span>
                                        <span className="font-medium text-slate-900">
                                            {selectedTransaction.occurredAt
                                                ? `${new Date(selectedTransaction.occurredAt).toLocaleDateString()} ${new Date(selectedTransaction.occurredAt).toLocaleTimeString()}`
                                                : '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Nominal</span>
                                        <span className="font-semibold text-emerald-700">
                                            {formatCurrency(selectedTransaction.totalAmount)}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Metode</span>
                                        <span className="font-medium text-slate-900">
                                            {selectedTransaction.paymentMethod || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Status Pembayaran</span>
                                        <span>
                                            <Badge variant={selectedTransaction.paymentStatus === 'PAID' ? 'success' : 'warning'}>
                                                {selectedTransaction.paymentStatus}
                                            </Badge>
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Status O2O</span>
                                        <span>
                                            <Badge variant={getOrderStatusVariant(selectedTransaction.orderStatus)}>
                                                {selectedTransaction.orderStatus || '-'}
                                            </Badge>
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div className="space-y-2">
                                <h3 className="text-xs font-semibold text-slate-500 uppercase">Merchant & Kasir</h3>
                                <div className="text-sm space-y-1">
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Merchant</span>
                                        <span className="font-medium text-slate-900">
                                            {selectedTransaction.store?.name || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Lokasi</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.store?.location || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Kategori</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.store?.category || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Tenant</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.tenant?.name || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Kasir</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.user?.name || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Sumber</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.source || '-'}
                                        </span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">Tipe Pemenuhan</span>
                                        <span className="text-slate-900">
                                            {selectedTransaction.fulfillmentType || '-'}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Transactions;
