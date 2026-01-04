import React, { useEffect, useState } from 'react';
import api from '../api';
import { CheckCircle, XCircle, ExternalLink, Calendar, CreditCard } from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Button } from '../components/ui/button';
import Badge from '../components/ui/Badge';
import Card from '../components/ui/Card';
import AdminLayout from '../components/AdminLayout';

export default function SubscriptionRequests() {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchRequests();
    }, []);

    const fetchRequests = async () => {
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

    return (
        <AdminLayout>
            <div className="space-y-6">
                <div className="flex justify-between items-center">
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight text-slate-900">Subscription Requests</h1>
                        <p className="text-slate-500 mt-1">Manage merchant subscription upgrade requests.</p>
                    </div>
                </div>

                <Card className="border-slate-200 shadow-sm">
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Tenant Info</TableHead>
                                <TableHead>Requested Plan</TableHead>
                                <TableHead>Requested At</TableHead>
                                <TableHead>Proof of Transfer</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {loading ? (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center py-8 text-slate-500">
                                        Loading requests...
                                    </TableCell>
                                </TableRow>
                            ) : requests.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center py-8 text-slate-500">
                                        No pending subscription requests found.
                                    </TableCell>
                                </TableRow>
                            ) : (
                                requests.map((req) => (
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
                                        </TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </Card>
            </div>
        </AdminLayout>
    );
}
