import React, { useEffect, useState } from 'react';
import api from '../api';
import { CheckCircle, XCircle, Clock } from 'lucide-react';

export default function SubscriptionRequests() {
    const [requests, setRequests] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchRequests();
    }, []);

    const fetchRequests = async () => {
        try {
            const res = await api.get('/subscription/requests');
            if (res.data.success) {
                setRequests(res.data.data);
            }
        } catch (error) {
            console.error('Failed to fetch requests', error);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        if (!confirm('Approve this subscription?')) return;
        try {
            await api.post(`/subscription/requests/${id}/approve`);
            fetchRequests(); // Refresh
        } catch (error) {
            alert('Approval failed');
        }
    };

    if (loading) return <div className="p-8">Loading...</div>;

    return (
        <div className="p-8">
            <h1 className="text-2xl font-bold mb-6">Subscription Requests</h1>

            <div className="bg-white rounded-lg shadow overflow-hidden">
                <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tenant</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Plan</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Proof</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {requests.map((req) => (
                            <tr key={req.id}>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    <div className="text-sm font-medium text-gray-900">{req.tenant?.name || 'Unknown'}</div>
                                    <div className="text-sm text-gray-500">{req.tenantId}</div>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Premium</td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    {req.status === 'PENDING' && <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">Pending</span>}
                                    {req.status === 'APPROVED' && <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Approved</span>}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-blue-600">
                                    {req.proofUrl ? <a href={req.proofUrl} target="_blank" rel="noreferrer">View Proof</a> : '-'}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                    {req.status === 'PENDING' && (
                                        <button
                                            onClick={() => handleApprove(req.id)}
                                            className="text-indigo-600 hover:text-indigo-900 flex items-center gap-1"
                                        >
                                            <CheckCircle size={16} /> Approve
                                        </button>
                                    )}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
