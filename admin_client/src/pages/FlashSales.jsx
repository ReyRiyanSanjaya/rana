import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { Check, X, Eye, Search, Zap, Clock, AlertCircle, CheckCircle2, XCircle, Timer } from 'lucide-react';
import { cn } from '../lib/utils';

const FlashSales = () => {
    const [flashSales, setFlashSales] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('WAITING_APPROVAL'); // WAITING_APPROVAL, ACTIVE, ENDED, REJECTED
    const [search, setSearch] = useState('');
    const [selectedSale, setSelectedSale] = useState(null);
    const [error, setError] = useState(null);

    const fetchFlashSales = async () => {
        setLoading(true);
        setError(null);
        try {
            const params = {};
            if (filter === 'WAITING_APPROVAL') params.status = 'WAITING_APPROVAL';
            else if (filter === 'ENDED') params.status = 'ENDED';
            else if (filter === 'REJECTED') params.status = 'REJECTED';
            const res = await api.get('/admin/flashsales', { params });
            setFlashSales(Array.isArray(res.data?.data) ? res.data.data : []);
        } catch (error) {
            console.error(error);
            setError("Failed to load flash sales.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchFlashSales();
    }, []);

    const updateStatus = async (id, action) => {
        if (!window.confirm(`Are you sure you want to ${action.toLowerCase()} this flash sale?`)) return;
        try {
            await api.put(`/admin/flashsales/${id}/status`, { action });
            fetchFlashSales();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to update status");
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(val || 0);

    const filteredSales = flashSales.filter(fs => {
        const matchesSearch = (fs.title?.toLowerCase() || '').includes(search.toLowerCase()) ||
                              (fs.store?.name?.toLowerCase() || '').includes(search.toLowerCase());
        
        let matchesStatus = false;
        if (filter === 'WAITING_APPROVAL') matchesStatus = fs.status === 'PENDING';
        else if (filter === 'ACTIVE') matchesStatus = ['ACTIVE', 'APPROVED'].includes(fs.status);
        else if (filter === 'ENDED') matchesStatus = fs.status === 'ENDED';
        else if (filter === 'REJECTED') matchesStatus = fs.status === 'REJECTED';
        else matchesStatus = true; // ALL

        return matchesSearch && matchesStatus;
    });

    const tabs = [
        { id: 'WAITING_APPROVAL', label: 'Pending Approval', icon: AlertCircle, color: 'text-yellow-600', activeColor: 'bg-yellow-50 text-yellow-700 border-yellow-200' },
        { id: 'ACTIVE', label: 'Active / Approved', icon: Zap, color: 'text-green-600', activeColor: 'bg-green-50 text-green-700 border-green-200' },
        { id: 'ENDED', label: 'Ended', icon: Timer, color: 'text-slate-600', activeColor: 'bg-slate-50 text-slate-700 border-slate-200' },
        { id: 'REJECTED', label: 'Rejected', icon: XCircle, color: 'text-red-600', activeColor: 'bg-red-50 text-red-700 border-red-200' },
    ];

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-2xl font-semibold text-slate-900">Flash Sales Management</h1>
                        <p className="text-slate-500 mt-1">Approve, monitor, and manage merchant flash sales.</p>
                    </div>
                    <Button onClick={fetchFlashSales} variant="outline" icon={Clock}>Refresh Data</Button>
                </div>

                {/* Tabs UI */}
                <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
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
                            placeholder="Search by Title or Store Name..."
                            className="pl-10 pr-4 py-2 w-full border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <div className="text-sm text-slate-500">
                        {loading ? 'Loading...' : `Showing ${filteredSales.length} requests`}
                    </div>
                </div>

                {error && (
                    <div className="p-4 mb-4 bg-red-50 text-red-600 rounded-lg border border-red-200">
                        {error} <button onClick={fetchFlashSales} className="underline ml-2 font-semibold">Retry</button>
                    </div>
                )}

                <Card className="overflow-hidden border border-slate-200 shadow-sm">
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Title</Th>
                                <Th>Store</Th>
                                <Th>Period</Th>
                                <Th>Items</Th>
                                <Th>Status</Th>
                                <Th className="text-right">Actions</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {loading ? (
                                <Tr>
                                    <Td colSpan="6" className="text-center py-12 text-slate-400">Loading data...</Td>
                                </Tr>
                            ) : filteredSales.length === 0 ? (
                                <Tr>
                                    <Td colSpan="6" className="text-center py-12 text-slate-400">No flash sales found matching your criteria.</Td>
                                </Tr>
                            ) : filteredSales.map((fs) => (
                                <Tr key={fs.id}>
                                    <Td>
                                        <div className="font-medium text-slate-900">{fs.title}</div>
                                    </Td>
                                    <Td>
                                        <div className="flex flex-col">
                                            <span className="font-medium text-slate-900">{fs.store?.name || 'Unknown Store'}</span>
                                        </div>
                                    </Td>
                                    <Td>
                                        <div className="flex flex-col text-sm text-slate-600">
                                            <span>Start: {new Date(fs.startAt).toLocaleString()}</span>
                                            <span>End: {new Date(fs.endAt).toLocaleString()}</span>
                                        </div>
                                    </Td>
                                    <Td>
                                        <div className="flex items-center gap-2">
                                            <span className="text-sm font-medium">{fs.items?.length || 0} items</span>
                                            <Button 
                                                size="xs" 
                                                variant="secondary" 
                                                icon={Eye} 
                                                onClick={() => setSelectedSale(fs)}
                                            >
                                                View
                                            </Button>
                                        </div>
                                    </Td>
                                    <Td>
                                        <Badge variant={
                                            fs.status === 'ACTIVE' || fs.status === 'APPROVED' ? 'success' : 
                                            fs.status === 'REJECTED' ? 'error' : 
                                            fs.status === 'ENDED' ? 'secondary' : 'warning'
                                        }>
                                            {fs.status === 'PENDING' ? 'WAITING_APPROVAL' : fs.status}
                                        </Badge>
                                    </Td>
                                    <Td className="text-right">
                                        <div className="flex justify-end gap-2">
                                            {fs.status === 'PENDING' && (
                                                <>
                                                    <Button
                                                        size="sm"
                                                        onClick={() => updateStatus(fs.id, 'APPROVE')}
                                                        icon={Check}
                                                        className="bg-green-600 hover:bg-green-700"
                                                    >
                                                        Approve
                                                    </Button>
                                                    <Button
                                                        size="sm"
                                                        variant="secondary"
                                                        onClick={() => updateStatus(fs.id, 'REJECT')}
                                                        className="text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200"
                                                    >
                                                        Reject
                                                    </Button>
                                                </>
                                            )}
                                            {fs.status === 'APPROVED' && (
                                                <Button
                                                    size="sm"
                                                    onClick={() => updateStatus(fs.id, 'ACTIVATE')}
                                                    icon={Zap}
                                                    className="bg-blue-600 hover:bg-blue-700"
                                                >
                                                    Activate
                                                </Button>
                                            )}
                                            {fs.status === 'ACTIVE' && (
                                                <Button
                                                    size="sm"
                                                    onClick={() => updateStatus(fs.id, 'END')}
                                                    className="bg-slate-600 hover:bg-slate-700"
                                                >
                                                    End Sale
                                                </Button>
                                            )}
                                        </div>
                                    </Td>
                                </Tr>
                            ))}
                        </Tbody>
                    </Table>
                </Card>
            </div>

            {/* Items Modal */}
            {selectedSale && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80" onClick={() => setSelectedSale(null)}>
                    <div className="relative max-w-4xl w-full bg-white rounded-xl overflow-hidden shadow-2xl max-h-[80vh] flex flex-col" onClick={e => e.stopPropagation()}>
                        <div className="p-4 border-b flex justify-between items-center bg-gray-50">
                            <div>
                                <h3 className="font-bold text-gray-900 text-lg">{selectedSale.title}</h3>
                                <p className="text-sm text-gray-500">{selectedSale.store?.name}</p>
                            </div>
                            <button onClick={() => setSelectedSale(null)} className="p-1 hover:bg-gray-200 rounded-full"><X size={20} /></button>
                        </div>
                        <div className="p-0 overflow-y-auto flex-1">
                            <Table>
                                <Thead>
                                    <Tr>
                                        <Th>Product</Th>
                                        <Th>Original Price</Th>
                                        <Th>Flash Sale Price</Th>
                                        <Th>Stock</Th>
                                        <Th>Limit/Order</Th>
                                    </Tr>
                                </Thead>
                                <Tbody>
                                    {selectedSale.items?.map((item) => (
                                        <Tr key={item.id}>
                                            <Td>
                                                <div className="font-medium">{item.product?.name || 'Unknown Product'}</div>
                                            </Td>
                                            <Td>
                                                <span className="text-slate-500 line-through">{formatCurrency(item.product?.sellingPrice)}</span>
                                            </Td>
                                            <Td>
                                                <span className="font-bold text-red-600">{formatCurrency(item.salePrice)}</span>
                                            </Td>
                                            <Td>{item.saleStock ?? 'Unlimited'}</Td>
                                            <Td>{item.maxQtyPerOrder || 'No Limit'}</Td>
                                        </Tr>
                                    ))}
                                </Tbody>
                            </Table>
                        </div>
                        <div className="p-4 border-t bg-gray-50 flex justify-end">
                            <Button variant="secondary" onClick={() => setSelectedSale(null)}>Close</Button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default FlashSales;
