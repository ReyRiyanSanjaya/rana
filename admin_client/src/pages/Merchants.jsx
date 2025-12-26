import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';

const Merchants = () => {
    const [merchants, setMerchants] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');

    const [selectedMerchant, setSelectedMerchant] = useState(null); // For edit modal
    const [subForm, setSubForm] = useState({ plan: 'FREE', status: 'TRIAL' });

    useEffect(() => {
        fetchMerchants();
    }, []);

    const fetchMerchants = async () => {
        try {
            setLoading(true);
            const res = await api.get('/admin/merchants');
            setMerchants(res.data.data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    const filteredMerchants = merchants.filter(m =>
        m.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.email?.toLowerCase().includes(search.toLowerCase())
    );

    const handleEditSubscription = (merchant) => {
        setSelectedMerchant(merchant);
        setSubForm({
            plan: merchant.tenant?.plan || 'FREE',
            status: merchant.tenant?.subscriptionStatus || 'TRIAL'
        });
    };

    const handleSaveSubscription = async () => {
        if (!selectedMerchant) return;
        try {
            await api.put(`/admin/merchants/${selectedMerchant.tenantId}/subscription`, { // Use tenantId
                plan: subForm.plan,
                subscriptionStatus: subForm.status
            });
            alert("Subscription updated!");
            setSelectedMerchant(null);
            fetchMerchants();
        } catch (e) {
            alert("Failed to update subscription");
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Merchants</h1>
                    <p className="text-slate-500 mt-1">View list of all registered stores and their balances.</p>
                </div>
                <div className="w-full md:w-72">
                    <input
                        type="text"
                        placeholder="Search stores, owners..."
                        className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Store Info</Th>
                            <Th>Owner</Th>
                            <Th>Active Balance</Th>
                            <Th>Subscription</Th>
                            <Th>Status</Th>
                            <Th className="text-right">Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">Loading merchants...</Td>
                            </Tr>
                        ) : filteredMerchants.length === 0 ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">No merchants found.</Td>
                            </Tr>
                        ) : filteredMerchants.map((m) => (
                            <Tr key={m.id}>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{m.name}</span>
                                        <span className="text-xs text-slate-500">{m.address || 'No address set'}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="text-slate-900">{m.tenant?.name || 'Unknown'}</span>
                                        <span className="text-xs text-slate-500">{m.tenant?.email}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <span className="font-mono font-medium text-green-700">{formatCurrency(m.balance)}</span>
                                </Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="text-sm font-semibold text-indigo-600">{m.tenant?.plan}</span>
                                        <span className="text-xs text-slate-500">Status: {m.tenant?.subscriptionStatus}</span>
                                        {m.tenant?.trialEndsAt && <span className="text-[10px] text-orange-500">Trial until {new Date(m.tenant.trialEndsAt).toLocaleDateString()}</span>}
                                    </div>
                                </Td>
                                <Td>
                                    <Badge variant="success">Active</Badge>
                                </Td>
                                <Td className="text-right flex gap-2 justify-end">
                                    <button onClick={() => window.location.href = `/merchants/${m.id}`} className="text-slate-600 hover:text-slate-900 text-sm font-medium border border-slate-300 px-3 py-1 rounded">View</button>
                                    <button onClick={() => handleEditSubscription(m)} className="text-indigo-600 hover:text-indigo-800 text-sm font-medium border border-indigo-200 bg-indigo-50 px-3 py-1 rounded">Manage Plan</button>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            {/* Edit Subscription Modal */}
            {selectedMerchant && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <h2 className="text-xl font-bold mb-4">Manage Subscription</h2>
                        <p className="text-sm text-slate-500 mb-6">Update plan for <b>{selectedMerchant.name}</b></p>

                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Plan</label>
                                <select
                                    className="w-full border rounded-lg p-2"
                                    value={subForm.plan}
                                    onChange={e => setSubForm({ ...subForm, plan: e.target.value })}
                                >
                                    <option value="FREE">FREE</option>
                                    <option value="BASIC">BASIC</option>
                                    <option value="PREMIUM">PREMIUM</option>
                                    <option value="ENTERPRISE">ENTERPRISE</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Status</label>
                                <select
                                    className="w-full border rounded-lg p-2"
                                    value={subForm.status}
                                    onChange={e => setSubForm({ ...subForm, status: e.target.value })}
                                >
                                    <option value="TRIAL">TRIAL</option>
                                    <option value="ACTIVE">ACTIVE</option>
                                    <option value="EXPIRED">EXPIRED</option>
                                    <option value="CANCELLED">CANCELLED</option>
                                </select>
                            </div>
                        </div>

                        <div className="flex justify-end gap-3 mt-8">
                            <button onClick={() => setSelectedMerchant(null)} className="px-4 py-2 text-slate-600 hover:bg-slate-50 rounded-lg">Cancel</button>
                            <button onClick={handleSaveSubscription} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Changes</button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Merchants;
