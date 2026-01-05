import React, { useEffect, useState } from 'react';
import api from '../api';
import { CheckCircle, XCircle, ExternalLink, Calendar, CreditCard, Search, Filter, ChevronLeft, ChevronRight, AlertCircle, CheckCircle2 } from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Button } from '../components/ui/button';
import Badge from '../components/ui/Badge';
import Card from '../components/ui/Card';
import AdminLayout from '../components/AdminLayout';
import { cn } from '../lib/utils';

export default function SubscriptionRequests() {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('PENDING'); // ALL, PENDING, APPROVED, REJECTED
    const [currentPage, setCurrentPage] = useState(1);
    const itemsPerPage = 10;

    useEffect(() => {
        fetchRequests();
    }, []);

    const fetchRequests = async () => {
        setLoading(true);
        try {
            const res = await api.get('/admin/subscriptions');
            // Backend returns array directly in successResponse data
            if (res.data.status === 'success') {
                setRequests(res.data.data);
            } else {
                // Fallback if structure is different
                setRequests(res.data.data || []);
            }
        } catch (error) {
            console.error('Failed to fetch requests', error);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        if (!confirm('Are you sure you want to approve this subscription upgrade?')) return;
        try {
            await api.put(`/admin/subscriptions/${id}/approve`);
            fetchRequests();
        } catch (error) {
            console.error(error);
            alert('Failed to approve request');
        }
    };

    const handleReject = async (id) => {
        if (!confirm('Are you sure you want to reject this request?')) return;
        try {
            await api.put(`/admin/subscriptions/${id}/reject`);
            fetchRequests();
        } catch (error) {
            console.error(error);
            alert('Failed to reject request');
        }
    };

    const formatDate = (dateStr) => {
        return new Date(dateStr).toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    // Filter and Search Logic
    const filteredRequests = requests.filter(req => {
        const matchesSearch = 
            (req.tenant?.name?.toLowerCase() || '').includes(search.toLowerCase()) ||
            (req.tenant?.users?.[0]?.email?.toLowerCase() || '').includes(search.toLowerCase()) ||
            (req.package?.name?.toLowerCase() || '').includes(search.toLowerCase());
        
        const matchesStatus = statusFilter === 'ALL' || (req.status || 'PENDING') === statusFilter;

        return matchesSearch && matchesStatus;
    });

    // Pagination Logic
    const totalPages = Math.ceil(filteredRequests.length / itemsPerPage);
    const paginatedRequests = filteredRequests.slice(
        (currentPage - 1) * itemsPerPage,
        currentPage * itemsPerPage
    );

    const tabs = [
        { id: 'PENDING', label: 'Pending Request', icon: AlertCircle, color: 'text-yellow-600', activeColor: 'bg-yellow-50 text-yellow-700 border-yellow-200' },
        { id: 'APPROVED', label: 'Approved', icon: CheckCircle2, color: 'text-green-600', activeColor: 'bg-green-50 text-green-700 border-green-200' },
        { id: 'REJECTED', label: 'Rejected', icon: XCircle, color: 'text-red-600', activeColor: 'bg-red-50 text-red-700 border-red-200' },
    ];

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Subscription Requests</h1>
                        <p className="text-slate-500 mt-1">Manage merchant subscription upgrade requests.</p>
                    </div>
                </div>

                {/* New Tabs UI */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    {tabs.map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => { setStatusFilter(tab.id); setCurrentPage(1); }}
                            className={cn(
                                "flex items-center justify-center p-4 rounded-xl border transition-all duration-200",
                                statusFilter === tab.id 
                                    ? `border-2 ${tab.activeColor} shadow-sm ring-1 ring-offset-0` 
                                    : "bg-white border-slate-200 text-slate-500 hover:border-slate-300 hover:bg-slate-50"
                            )}
                        >
                            <tab.icon className={cn("mr-3 h-5 w-5", statusFilter === tab.id ? "opacity-100" : "opacity-70")} />
                            <span className={cn("font-semibold", statusFilter === tab.id ? "" : "text-slate-600")}>
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
                            placeholder="Search by tenant, email, or package..."
                            className="pl-10 pr-4 py-2 w-full border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm"
                            value={search}
                            onChange={(e) => { setSearch(e.target.value); setCurrentPage(1); }}
                        />
                    </div>
                    <div className="text-sm text-slate-500">
                        Showing {paginatedRequests.length} of {filteredRequests.length} requests
                    </div>
                </div>

                <Card className="border-slate-200 shadow-sm overflow-hidden">
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Tenant Info</TableHead>
                                <TableHead>Requested Plan</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Requested At</TableHead>
                                <TableHead>Proof of Transfer</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {loading ? (
                                <TableRow>
                                    <TableCell colSpan={6} className="text-center py-8 text-slate-500">
                                        <div className="flex justify-center items-center">
                                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            ) : paginatedRequests.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={6} className="text-center py-8 text-slate-500">
                                        No subscription requests found matching your criteria.
                                    </TableCell>
                                </TableRow>
                            ) : (
                                paginatedRequests.map((req) => (
                                    <TableRow key={req.id}>
                                        <TableCell>
                                            <div className="flex flex-col">
                                                <span className="font-medium text-slate-900">{req.tenant?.name || 'Unknown'}</span>
                                                <span className="text-xs text-slate-500">{req.tenant?.users?.[0]?.email || 'No email'}</span>
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            {req.package ? (
                                                <div className="flex flex-col">
                                                    <Badge variant="brand" className="capitalize w-fit">
                                                        {req.package.name}
                                                    </Badge>
                                                    <span className="text-xs text-slate-500 mt-1">
                                                        Rp {req.package.price?.toLocaleString('id-ID')} / {req.package.durationDays} hari
                                                    </span>
                                                </div>
                                            ) : (
                                                <Badge variant="brand" className="capitalize">
                                                    Premium
                                                </Badge>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant={
                                                req.status === 'APPROVED' ? 'success' : 
                                                req.status === 'REJECTED' ? 'destructive' : 'warning'
                                            }>
                                                {req.status || 'PENDING'}
                                            </Badge>
                                        </TableCell>
                                        <TableCell>
                                            <div className="flex items-center text-slate-500 text-sm">
                                                <Calendar size={14} className="mr-2" />
                                                {formatDate(req.createdAt)}
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            {req.proofUrl ? (
                                                <a
                                                    href={req.proofUrl.startsWith('http') ? req.proofUrl : `http://localhost:4000${req.proofUrl}`}
                                                    target="_blank"
                                                    rel="noreferrer"
                                                    className="inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-800 hover:underline"
                                                >
                                                    <ExternalLink size={14} className="mr-1" />
                                                    View Proof
                                                </a>
                                            ) : (
                                                <span className="text-slate-400 text-sm italic">No proof attached</span>
                                            )}
                                        </TableCell>
                                        <TableCell className="text-right">
                                            {(req.status === 'PENDING' || !req.status) && (
                                                <div className="flex justify-end gap-2">
                                                    <Button
                                                        size="sm"
                                                        variant="outline"
                                                        className="text-red-600 border-red-200 hover:bg-red-50"
                                                        onClick={() => handleReject(req.id)}
                                                    >
                                                        <XCircle size={16} className="mr-1" />
                                                        Reject
                                                    </Button>
                                                    <Button
                                                        size="sm"
                                                        className="bg-green-600 hover:bg-green-700 text-white"
                                                        onClick={() => handleApprove(req.id)}
                                                    >
                                                        <CheckCircle size={16} className="mr-1" />
                                                        Approve
                                                    </Button>
                                                </div>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </Card>

                {/* Pagination Controls */}
                {totalPages > 1 && (
                    <div className="flex justify-between items-center pt-4">
                        <div className="text-sm text-slate-500">
                            Page {currentPage} of {totalPages}
                        </div>
                        <div className="flex gap-2">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                                disabled={currentPage === 1}
                            >
                                <ChevronLeft className="h-4 w-4 mr-1" /> Previous
                            </Button>
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                                disabled={currentPage === totalPages}
                            >
                                Next <ChevronRight className="h-4 w-4 ml-1" />
                            </Button>
                        </div>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
}
