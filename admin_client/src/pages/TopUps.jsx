import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import { Check, X, Eye } from 'lucide-react';

const TopUps = () => {
    const [topups, setTopups] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('PENDING'); // PENDING, APPROVED, REJECTED
    const [selectedProof, setSelectedProof] = useState(null);
    const [error, setError] = useState(null);

    const fetchTopUps = async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await api.get('/admin/topups', { params: { status: filter } });
            // Ensure data is array, handle potential structure mismatch
            setTopups(Array.isArray(res.data?.data) ? res.data.data : []);
        } catch (error) {
            console.error(error);
            setError("Failed to load top-up requests.");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTopUps();
    }, [filter]);

    const handleApprove = async (id) => {
        if (!window.confirm("Approve this Top Up? Balance will be added to Merchant.")) return;
        try {
            await api.put(`/admin/topups/${id}/approve`);
            fetchTopUps();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to approve");
        }
    };

    const handleReject = async (id) => {
        const reason = prompt("Rejection Reason:");
        if (!reason) return;
        try {
            await api.put(`/admin/topups/${id}/reject`, { reason });
            fetchTopUps();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to reject");
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val || 0);

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Wallet Top Ups</h1>
                    <p className="text-slate-500 mt-1">Review and approve merchant balance top-up requests.</p>
                </div>
                <div className="flex bg-slate-100 p-1 rounded-lg">
                    {['PENDING', 'APPROVED', 'REJECTED'].map(status => (
                        <button
                            key={status}
                            onClick={() => setFilter(status)}
                            className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${filter === status
                                ? 'bg-white text-slate-900 shadow-sm'
                                : 'text-slate-500 hover:text-slate-700'
                                }`}
                        >
                            {status.charAt(0) + status.slice(1).toLowerCase()}
                        </button>
                    ))}
                </div>
            </div>

            {error && (
                <div className="p-4 mb-4 bg-red-50 text-red-600 rounded-lg border border-red-200">
                    {error} <button onClick={fetchTopUps} className="underline ml-2 font-semibold">Retry</button>
                </div>
            )}

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Request Date</Th>
                            <Th>Merchant</Th>
                            <Th>Amount</Th>
                            <Th>Proof</Th>
                            <Th>Status</Th>
                            <Th className="text-right">Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">Loading data...</Td>
                            </Tr>
                        ) : topups.length === 0 ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">No requests found.</Td>
                            </Tr>
                        ) : topups.map((t) => (
                            <Tr key={t.id}>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{t.createdAt ? new Date(t.createdAt).toLocaleDateString() : '-'}</span>
                                        <span className="text-xs text-slate-500">{t.createdAt ? new Date(t.createdAt).toLocaleTimeString() : ''}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{t.store?.name || 'Unknown Store'}</span>
                                        <span className="text-xs text-slate-500 text-truncate max-w-[150px]">{t.store?.tenant?.name || '-'}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <span className="font-mono font-medium text-slate-700">{formatCurrency(t.amount)}</span>
                                </Td>
                                <Td>
                                    <Button
                                        size="xs"
                                        variant="secondary"
                                        icon={Eye}
                                        onClick={() => {
                                            console.log("View Proof Clicked", t.proofUrl);
                                            if (t.proofUrl) setSelectedProof(t.proofUrl);
                                            else alert("No proof image available for this request.");
                                        }}
                                        disabled={!t.proofUrl}
                                        title={!t.proofUrl ? "No proof available" : "View Proof"}
                                    >
                                        View Proof
                                    </Button>
                                </Td>
                                <Td>
                                    <Badge variant={t.status === 'APPROVED' ? 'success' : t.status === 'REJECTED' ? 'error' : 'warning'}>
                                        {t.status}
                                    </Badge>
                                </Td>
                                <Td className="text-right">
                                    {t.status === 'PENDING' && (
                                        <div className="flex justify-end gap-2">
                                            <Button
                                                size="sm"
                                                onClick={() => handleApprove(t.id)}
                                                icon={Check}
                                                className="bg-green-600 hover:bg-green-700"
                                            >
                                                Approve
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="secondary"
                                                onClick={() => handleReject(t.id)}
                                                className="text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200"
                                            >
                                                Reject
                                            </Button>
                                        </div>
                                    )}
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            {/* Proof Modal */}
            {selectedProof && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80" onClick={() => setSelectedProof(null)}>
                    <div className="relative max-w-2xl w-full bg-white rounded-xl overflow-hidden shadow-2xl" onClick={e => e.stopPropagation()}>
                        <div className="p-4 border-b flex justify-between items-center bg-gray-50">
                            <h3 className="font-bold text-gray-900">Transfer Proof</h3>
                            <button onClick={() => setSelectedProof(null)} className="p-1 hover:bg-gray-200 rounded-full"><X size={20} /></button>
                        </div>
                        <div className="p-4 bg-gray-100 flex justify-center">
                            {/* [FIX] Prepend Server URL */}
                            <img
                                src={selectedProof.startsWith('http') || selectedProof.startsWith('data:') ? selectedProof : `http://localhost:4000${selectedProof}`}
                                alt="Proof"
                                className="max-h-[70vh] object-contain rounded-lg border"
                                onError={(e) => { e.target.src = 'https://placehold.co/400?text=Error+Loading+Image'; }}
                            />
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default TopUps;
