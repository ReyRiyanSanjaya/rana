import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { Download, ChevronLeft, ChevronRight } from 'lucide-react';

const Transactions = () => {
    const [transactions, setTransactions] = useState([]);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [loading, setLoading] = useState(true);
    const [exporting, setExporting] = useState(false);

    // Filters
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [area, setArea] = useState('');
    const [category, setCategory] = useState(''); // Store Category
    const [paymentStatus, setPaymentStatus] = useState('');
    const [paymentMethod, setPaymentMethod] = useState('');

    const fetchTransactions = async () => {
        setLoading(true);
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
                setTransactions(res.data.data.transactions);
                setTotal(res.data.data.total);
                setTotalPages(res.data.data.totalPages);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        // Debounce or just fetch on simple changes
        fetchTransactions();
    }, [page, startDate, endDate, area, category, paymentStatus, paymentMethod]);

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
            const data = res.data.data;

            // Convert to CSV
            const csvRows = [];
            const headers = ['ID', 'Date', 'Merchant', 'Store Location', 'Store Category', 'Amount', 'Payment Method', 'Status', 'O2O Status'];
            csvRows.push(headers.join(','));

            data.forEach(row => {
                const values = [
                    row.id,
                    new Date(row.occurredAt).toISOString(),
                    `"${row.store.name}"`,
                    `"${row.store.location || ''}"`,
                    `"${row.store.category || ''}"`,
                    row.totalAmount,
                    row.paymentMethod,
                    row.paymentStatus,
                    row.orderStatus
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

        } catch (error) {
            console.error(error);
            alert("Failed to export data");
        } finally {
            setExporting(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

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
                    <div className="mt-4 pt-4 border-t border-slate-100 text-sm text-slate-500 flex justify-between">
                        <span>Filter active: {total} records found</span>
                        {(startDate || endDate || area || category || paymentStatus || paymentMethod) && (
                            <Button variant="link" onClick={() => {
                                setStartDate(''); setEndDate(''); setArea(''); setCategory(''); setPaymentStatus(''); setPaymentMethod('');
                            }} className="text-blue-600 h-auto p-0 hover:no-underline hover:text-blue-800">Clear Filters</Button>
                        )}
                    </div>
                </Card>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Date</Th>
                            <Th>Merchant / Area</Th>
                            <Th>Amount</Th>
                            <Th>Method</Th>
                            <Th>Status</Th>
                            <Th>Cashier</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">Loading data...</Td>
                            </Tr>
                        ) : transactions.length === 0 ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">No transactions found.</Td>
                            </Tr>
                        ) : transactions.map((t) => (
                            <Tr key={t.id}>
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
                            variant="ghost"
                            size="sm"
                            disabled={page === 1}
                            onClick={() => setPage(p => Math.max(1, p - 1))}
                        >
                            <ChevronLeft size={16} /> Previous
                        </Button>
                        <Button
                            variant="ghost"
                            size="sm"
                            disabled={page >= totalPages}
                            onClick={() => setPage(p => p + 1)}
                        >
                            Next <ChevronRight size={16} />
                        </Button>
                    </div>
                </div>
            </Card>
        </AdminLayout>
    );
};

export default Transactions;
