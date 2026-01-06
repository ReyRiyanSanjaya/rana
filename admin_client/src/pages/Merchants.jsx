import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Package, Calendar, Clock, ChevronLeft, ChevronRight, Plus, Eye, Cog, Download, Ban, CheckCircle } from 'lucide-react';

const Merchants = () => {
    const navigate = useNavigate();
    const [merchants, setMerchants] = useState([]);
    const [packages, setPackages] = useState([]); // [NEW] Real packages from DB
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [planFilter, setPlanFilter] = useState('');
    const [cityFilter, setCityFilter] = useState('');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [sort, setSort] = useState('createdAt:desc');

    // Pagination
    const [currentPage, setCurrentPage] = useState(1);
    const [itemsPerPage] = useState(10);

    const [selectedMerchant, setSelectedMerchant] = useState(null);
    const [selectedPackage, setSelectedPackage] = useState(null);
    const [subForm, setSubForm] = useState({ status: 'TRIAL' }); // Removed plan field
    const [selectedRows, setSelectedRows] = useState([]);

    // Add Merchant State
    const [showAddModal, setShowAddModal] = useState(false);
    const [addForm, setAddForm] = useState({
        name: '',
        email: '',
        password: '',
        phone: '',
        businessName: '',
        address: ''
    });

    useEffect(() => {
        fetchMerchants();
        fetchPackages();
    }, [statusFilter, search, planFilter, cityFilter, dateFrom, dateTo, sort]);

    const fetchMerchants = async () => {
        try {
            setLoading(true);
            const params = new URLSearchParams();
            if (statusFilter) params.append('status', statusFilter);
            if (search) params.append('search', search);
            if (planFilter) params.append('plan', planFilter);
            if (cityFilter) params.append('city', cityFilter);
            if (dateFrom) params.append('createdFrom', dateFrom);
            if (dateTo) params.append('createdTo', dateTo);
            if (sort) params.append('sort', sort);
            const res = await api.get(`/admin/merchants?${params.toString()}`);
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

    const filteredMerchants = merchants;

    // Pagination Logic
    const indexOfLastItem = currentPage * itemsPerPage;
    const indexOfFirstItem = indexOfLastItem - itemsPerPage;
    const currentMerchants = filteredMerchants.slice(indexOfFirstItem, indexOfLastItem);
    const totalPages = Math.ceil(filteredMerchants.length / itemsPerPage);

    const handleAddMerchant = async () => {
        try {
            if (!addForm.email || !addForm.password || !addForm.businessName) {
                alert("Please fill in all required fields");
                return;
            }
            await api.post('/auth/register-merchant', addForm); // Assuming this is the endpoint based on standard practice, otherwise /admin/merchants
            alert("Merchant created successfully!");
            setShowAddModal(false);
            setAddForm({ name: '', email: '', password: '', phone: '', businessName: '', address: '' });
            fetchMerchants();
        } catch (error) {
            console.error(error);
            alert(error.response?.data?.message || "Failed to create merchant");
        }
    };

    const handleEditSubscription = (merchant) => {
        setSelectedMerchant(merchant);
        setSelectedPackage(null);
        setSubForm({
            status: merchant.tenant?.subscriptionStatus || 'TRIAL'
        });
    };

    const toggleSelectAll = (checked) => {
        if (checked) setSelectedRows(currentMerchants.map(m => m.id));
        else setSelectedRows([]);
    };

    const toggleRow = (id) => {
        setSelectedRows(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
    };

    const bulkUpdateSubscription = async (newStatus) => {
        try {
            const targets = merchants.filter(m => selectedRows.includes(m.id));
            for (const m of targets) {
                if (m.tenant?.id) {
                    await api.put(`/admin/merchants/${m.tenant.id}/subscription`, { subscriptionStatus: newStatus });
                }
            }
            alert('Bulk action completed');
            setSelectedRows([]);
            fetchMerchants();
        } catch (e) {
            alert('Bulk action failed');
        }
    };

    const handleExportCsv = () => {
        const params = new URLSearchParams();
        if (statusFilter) params.append('status', statusFilter);
        if (planFilter) params.append('plan', planFilter);
        if (cityFilter) params.append('city', cityFilter);
        if (dateFrom) params.append('createdFrom', dateFrom);
        if (dateTo) params.append('createdTo', dateTo);
        window.open(`/api/admin/merchants/export?format=csv&${params.toString()}`, '_blank');
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
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-slate-900">Merchants Management</h1>
                <Button onClick={() => setShowAddModal(true)} icon={Plus}>
                    Add Merchant
                </Button>
            </div>

            <Card className="mb-6">
                <div className="p-4 flex flex-wrap gap-3 items-center">
                    <input
                        type="text"
                        placeholder="Search merchant, tenant, email..."
                        className="flex-1 min-w-[220px] px-4 py-2 border border-slate-300 rounded-lg outline-none focus:border-indigo-500"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                    <select 
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_140px] min-w-[140px]"
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                    >
                        <option value="">All Status</option>
                        <option value="ACTIVE">Active</option>
                        <option value="TRIAL">Trial</option>
                        <option value="EXPIRED">Expired</option>
                        <option value="CANCELLED">Cancelled</option>
                    </select>
                    <select
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_140px] min-w-[140px]"
                        value={planFilter}
                        onChange={(e) => setPlanFilter(e.target.value)}
                    >
                        <option value="">All Plans</option>
                        <option value="FREE">Free</option>
                        <option value="PREMIUM">Premium</option>
                        <option value="ENTERPRISE">Enterprise</option>
                    </select>
                    <input
                        type="text"
                        placeholder="City"
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_140px] min-w-[140px]"
                        value={cityFilter}
                        onChange={(e) => setCityFilter(e.target.value)}
                    />
                    <input
                        type="date"
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_140px]"
                        value={dateFrom}
                        onChange={(e) => setDateFrom(e.target.value)}
                    />
                    <input
                        type="date"
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_140px]"
                        value={dateTo}
                        onChange={(e) => setDateTo(e.target.value)}
                    />
                    <select
                        className="px-3 py-2 border border-slate-300 rounded-lg outline-none text-sm bg-white flex-[1_1_160px] min-w-[160px]"
                        value={sort}
                        onChange={(e) => setSort(e.target.value)}
                    >
                        <option value="createdAt:desc">Newest</option>
                        <option value="createdAt:asc">Oldest</option>
                        <option value="balance:desc">Balance High</option>
                        <option value="balance:asc">Balance Low</option>
                        <option value="name:asc">Name A-Z</option>
                        <option value="name:desc">Name Z-A</option>
                    </select>
                    <Button variant="outline" onClick={handleExportCsv} icon={Download} className="flex-[0_0_auto]">Export CSV</Button>
                </div>
            </Card>

            <Card className="overflow-hidden">
                {selectedRows.length > 0 && (
                    <div className="flex items-center justify-between p-3 border-b bg-indigo-50">
                        <span className="text-sm text-indigo-700">{selectedRows.length} selected</span>
                        <div className="flex gap-2">
                            <Button variant="destructive" size="sm" onClick={() => bulkUpdateSubscription('CANCELLED')} icon={Ban}>Suspend</Button>
                            <Button size="sm" onClick={() => bulkUpdateSubscription('ACTIVE')} icon={CheckCircle}>Activate</Button>
                        </div>
                    </div>
                )}
                <Table className="min-w-full">
                    <Thead>
                        <Tr>
                            <Th>
                                <input
                                    type="checkbox"
                                    checked={selectedRows.length === currentMerchants.length && currentMerchants.length > 0}
                                    onChange={(e) => toggleSelectAll(e.target.checked)}
                                />
                            </Th>
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
                                <Td colSpan="7" className="text-center py-12 text-slate-400">Loading merchants...</Td>
                            </Tr>
                        ) : currentMerchants.length === 0 ? (
                            <Tr>
                                <Td colSpan="7" className="text-center py-12 text-slate-400">No merchants found.</Td>
                            </Tr>
                        ) : currentMerchants.map((m) => (
                            <Tr key={m.id}>
                                <Td>
                                    <input
                                        type="checkbox"
                                        checked={selectedRows.includes(m.id)}
                                        onChange={() => toggleRow(m.id)}
                                    />
                                </Td>
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
                                <Td className="text-right">
                                    <div className="inline-flex gap-2 flex-wrap justify-end">
                                        <Button variant="outline" size="sm" onClick={() => navigate(`/merchants/${m.id}`)} icon={Eye}>View</Button>
                                        <Button variant="secondary" size="sm" onClick={() => handleEditSubscription(m)} icon={Cog}>Manage Plan</Button>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
                
                {/* Pagination Controls */}
                {totalPages > 1 && (
                    <div className="flex justify-between items-center p-4 border-t border-slate-200">
                        <span className="text-sm text-slate-500">
                            Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, filteredMerchants.length)} of {filteredMerchants.length} entries
                        </span>
                        <div className="flex gap-2">
                            <Button 
                                variant="outline" 
                                size="sm" 
                                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                                disabled={currentPage === 1}
                            >
                                <ChevronLeft size={16} />
                            </Button>
                            <span className="px-3 py-1 flex items-center text-sm font-medium">
                                {currentPage} / {totalPages}
                            </span>
                            <Button 
                                variant="outline" 
                                size="sm" 
                                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                                disabled={currentPage === totalPages}
                            >
                                <ChevronRight size={16} />
                            </Button>
                        </div>
                    </div>
                )}
            </Card>

            {/* Add Merchant Modal */}
            {showAddModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
                        <h2 className="text-xl font-bold mb-4">Register New Merchant</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Business Name (Store Name)</label>
                                <Input 
                                    value={addForm.businessName} 
                                    onChange={e => setAddForm({...addForm, businessName: e.target.value})} 
                                    placeholder="e.g. Toko Berkah"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Owner Name</label>
                                <Input 
                                    value={addForm.name} 
                                    onChange={e => setAddForm({...addForm, name: e.target.value})} 
                                    placeholder="Full Name"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                                <Input 
                                    type="email"
                                    value={addForm.email} 
                                    onChange={e => setAddForm({...addForm, email: e.target.value})} 
                                    placeholder="email@example.com"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                                <Input 
                                    type="password"
                                    value={addForm.password} 
                                    onChange={e => setAddForm({...addForm, password: e.target.value})} 
                                    placeholder="********"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Phone Number</label>
                                <Input 
                                    value={addForm.phone} 
                                    onChange={e => setAddForm({...addForm, phone: e.target.value})} 
                                    placeholder="081234567890"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Address</label>
                                <Input 
                                    value={addForm.address} 
                                    onChange={e => setAddForm({...addForm, address: e.target.value})} 
                                    placeholder="Store Address"
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-8">
                            <Button variant="outline" onClick={() => setShowAddModal(false)}>Cancel</Button>
                            <Button onClick={handleAddMerchant}>Create Merchant</Button>
                        </div>
                    </div>
                </div>
            )}

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
                            <Button variant="outline" onClick={() => { setSelectedMerchant(null); setSelectedPackage(null); }}>Cancel</Button>
                            <Button onClick={handleSaveSubscription}>Save Changes</Button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Merchants;

