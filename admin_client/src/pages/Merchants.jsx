import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import { Package, Calendar, Clock } from 'lucide-react';

const Merchants = () => {
    const [merchants, setMerchants] = useState([]);
    const [packages, setPackages] = useState([]); // [NEW] Real packages from DB
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');

    const [selectedMerchant, setSelectedMerchant] = useState(null);
    const [selectedPackage, setSelectedPackage] = useState(null);
    const [subForm, setSubForm] = useState({ status: 'TRIAL' }); // Removed plan field

    useEffect(() => {
        fetchMerchants();
        fetchPackages(); // [NEW]
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

    // [NEW] Fetch packages from database
    const fetchPackages = async () => {
        try {
            const res = await api.get('/admin/packages');
            setPackages(res.data.data || []);
        } catch (error) {
            console.error('Failed to fetch packages', error);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);

    const filteredMerchants = merchants.filter(m =>
        m.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.email?.toLowerCase().includes(search.toLowerCase())
    );

    const handleEditSubscription = (merchant) => {
        setSelectedMerchant(merchant);
        setSelectedPackage(null);
        setSubForm({
            status: merchant.tenant?.subscriptionStatus || 'TRIAL'
        });
    };

    // [UPDATED] Save subscription with package duration
    const handleSaveSubscription = async () => {
        if (!selectedMerchant) return;
        try {
            // Calculate subscriptionEndsAt based on selected package
            let subscriptionEndsAt = null;
            if (selectedPackage && subForm.status === 'ACTIVE') {
                const endDate = new Date();
                endDate.setDate(endDate.getDate() + selectedPackage.durationDays);
                subscriptionEndsAt = endDate.toISOString();
            }

            await api.put(`/admin/merchants/${selectedMerchant.tenantId}/subscription`, {
                subscriptionStatus: subForm.status,
                subscriptionEndsAt // End date based on package
            });
            alert("Subscription updated!");
            setSelectedMerchant(null);
            setSelectedPackage(null);
            fetchMerchants();
        } catch (e) {
            alert("Failed to update subscription");
        }
    };

    // [NEW] Format date helper
    const formatDate = (dateStr) => {
        if (!dateStr) return null;
        return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
    };

    // [NEW] Calculate days remaining
    const getDaysRemaining = (endDate) => {
        if (!endDate) return null;
        const now = new Date();
        const end = new Date(endDate);
        const diff = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
        return diff > 0 ? diff : 0;
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
                                        <span className="text-xs text-slate-500">Status: {m.tenant?.subscriptionStatus}</span>
                                        {/* Show subscriptionEndsAt or trialEndsAt */}
                                        {m.tenant?.subscriptionStatus === 'ACTIVE' && m.tenant?.subscriptionEndsAt ? (
                                            <span className="text-[10px] text-green-600 flex items-center gap-1">
                                                <Clock size={10} /> {getDaysRemaining(m.tenant.subscriptionEndsAt)} hari tersisa
                                            </span>
                                        ) : m.tenant?.trialEndsAt && (
                                            <span className="text-[10px] text-orange-500">Trial until {formatDate(m.tenant.trialEndsAt)}</span>
                                        )}
                                    </div>
                                </Td>
                                <Td>
                                    {m.tenant?.subscriptionStatus === 'ACTIVE' ? (
                                        <Badge variant="success">Active</Badge>
                                    ) : m.tenant?.subscriptionStatus === 'TRIAL' ? (
                                        <Badge variant="warning">Trial</Badge>
                                    ) : (
                                        <Badge variant="danger">Expired</Badge>
                                    )}
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

            {/* [UPDATED] Edit Subscription Modal with Real Packages */}
            {selectedMerchant && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
                        <h2 className="text-xl font-bold mb-2">Manage Subscription</h2>
                        <p className="text-sm text-slate-500 mb-6">Update plan for <b>{selectedMerchant.name}</b></p>

                        {/* Package Selection */}
                        {packages.length > 0 && (
                            <div className="mb-6">
                                <label className="block text-sm font-medium text-slate-700 mb-3">Select Package</label>
                                <div className="grid grid-cols-2 gap-3">
                                    {packages.map((pkg) => (
                                        <div
                                            key={pkg.id}
                                            onClick={() => {
                                                setSelectedPackage(pkg);
                                                setSubForm({ status: 'ACTIVE' }); // Just set status
                                            }}
                                            className={`p-4 border-2 rounded-lg cursor-pointer transition ${selectedPackage?.id === pkg.id
                                                ? 'border-indigo-500 bg-indigo-50'
                                                : 'border-slate-200 hover:border-indigo-300'
                                                }`}
                                        >
                                            <div className="flex items-center gap-2 mb-2">
                                                <Package size={16} className="text-indigo-600" />
                                                <span className="font-semibold text-slate-900">{pkg.name}</span>
                                            </div>
                                            <div className="text-lg font-bold text-indigo-600">{formatCurrency(pkg.price)}</div>
                                            <div className="text-xs text-slate-500 flex items-center gap-1 mt-1">
                                                <Calendar size={12} /> {pkg.durationDays} hari
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

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

                        {/* Show selected package info */}
                        {selectedPackage && (
                            <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
                                <div className="text-sm text-green-800">
                                    <b>Selected:</b> {selectedPackage.name} - Subscription will be active for <b>{selectedPackage.durationDays} days</b>
                                </div>
                            </div>
                        )}

                        <div className="flex justify-end gap-3 mt-8">
                            <button onClick={() => { setSelectedMerchant(null); setSelectedPackage(null); }} className="px-4 py-2 text-slate-600 hover:bg-slate-50 rounded-lg">Cancel</button>
                            <button onClick={handleSaveSubscription} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Save Changes</button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Merchants;

