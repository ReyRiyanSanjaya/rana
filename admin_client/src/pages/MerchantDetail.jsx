import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Input from "../components/ui/Input"; // [NEW]

const MerchantDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [merchant, setMerchant] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('overview');

    // Tab Data
    const [products, setProducts] = useState([]);
    const [transactions, setTransactions] = useState([]);

    // Modals
    const [showWalletModal, setShowWalletModal] = useState(false);
    const [walletForm, setWalletForm] = useState({ type: 'CREDIT', amount: '', reason: '' });

    const [showNotifyModal, setShowNotifyModal] = useState(false);

    const [notifyForm, setNotifyForm] = useState({ title: '', body: '' });

    // [NEW] Reset Password State
    const [showResetModal, setShowResetModal] = useState(false);
    const [resetPassword, setResetPassword] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);

    // [NEW] Edit Details State
    const [showEditModal, setShowEditModal] = useState(false);
    const [editForm, setEditForm] = useState({
        name: '',
        phone: '',
        address: ''
    });

    useEffect(() => {
        fetchDetail();
    }, [id]);

    useEffect(() => {
        if (activeTab === 'products' && merchant?.storeId) fetchProducts();
        if (activeTab === 'transactions' && merchant?.storeId) fetchTransactions();
    }, [activeTab, merchant]);

    const fetchDetail = async () => {
        try {
            const res = await api.get(`/admin/merchants/${id}`);
            // Normalize data: ensure storeId is available easily if merchant is store object
            const data = res.data.data;
            if (data.id && !data.storeId) data.storeId = data.id; // If returned object is Store
            
            setMerchant(data);
            setLoading(false);
            // Pre-fill edit form
            setEditForm({
                name: data.name || '',
                phone: data.phone || '',
                address: data.address || ''
            });
        } catch (error) {
            console.error(error);
            alert("Failed to fetch merchant details");
            navigate('/merchants');
        }
    };

    const fetchProducts = async () => {
        try {
            const res = await api.get(`/admin/merchants/${merchant.storeId}/products?includeInactive=true`);
            setProducts(res.data.data);
        } catch (error) {
            console.error("Failed to fetch products", error);
        }
    };

    const fetchTransactions = async () => {
        try {
            const res = await api.get(`/admin/transactions?storeId=${merchant.storeId}&limit=50`);
            setTransactions(res.data.data.transactions);
        } catch (error) {
            console.error("Failed to fetch transactions", error);
        }
    };

    const handleSuspend = async () => {
        if (!confirm('Are you sure you want to suspend this merchant? This will cancel their subscription.')) return;
        try {
            await api.put(`/admin/merchants/${merchant.tenantId}/subscription`, { subscriptionStatus: 'CANCELLED' });
            alert('Merchant suspended successfully');
            fetchDetail();
        } catch (error) {
            alert('Failed to suspend merchant');
        }
    };

    const handleActivate = async () => {
        if (!confirm('Are you sure you want to activate this merchant?')) return;
        try {
            await api.put(`/admin/merchants/${merchant.tenantId}/subscription`, { subscriptionStatus: 'ACTIVE' });
            alert('Merchant activated successfully');
            fetchDetail();
        } catch (error) {
            alert('Failed to activate merchant');
        }
    };

    const handleAdjustWallet = async () => {
        try {
            await api.post(`/admin/merchants/${id}/wallet/adjust`, walletForm);
            alert('Wallet adjusted successfully');
            setShowWalletModal(false);
            setWalletForm({ type: 'CREDIT', amount: '', reason: '' });
            fetchDetail(); // Refresh
        } catch (error) {
            alert('Failed to adjust wallet');
        }
    };

    const handleSendNotification = async () => {
        try {
            if (!merchant?.tenantId) return;
            await api.post(`/admin/merchants/${merchant.tenantId}/notify`, notifyForm);
            alert('Notification sent');
            setShowNotifyModal(false);
            setNotifyForm({ title: '', body: '' });
        } catch (error) {
            alert('Failed to send notification');
        }
    };

    // [NEW] Handle Reset Password
    const handleResetPassword = async () => {
        try {
            if (!selectedUser || !resetPassword) return alert("Password required");
            if (resetPassword.length < 6) return alert("Password min 6 chars");

            await api.put(`/admin/users/${selectedUser.id}/password`, { password: resetPassword });
            alert('Password reset successfully');
            setShowResetModal(false);
            setResetPassword('');
            setSelectedUser(null);
        } catch (error) {
            alert('Failed to reset password');
        }
    };

    // [NEW] Update Merchant Details
    const handleUpdateDetails = async () => {
        try {
            await api.put(`/admin/merchants/${id}`, editForm);
            alert('Merchant details updated');
            setShowEditModal(false);
            fetchDetail();
        } catch (error) {
            console.error(error);
            alert('Failed to update details');
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    const getStatusBadge = (status) => {
        switch(status) {
            case 'ACTIVE': return 'success';
            case 'TRIAL': return 'warning';
            case 'CANCELLED': return 'error';
            case 'EXPIRED': return 'error';
            default: return 'neutral';
        }
    };

    if (loading) return <AdminLayout><div className="flex justify-center p-10">Loading...</div></AdminLayout>;
    if (!merchant) return null;

    return (
        <AdminLayout>
            {/* Header */}
            <div className="mb-8">
                <Button variant="outline" onClick={() => navigate('/merchants')} className="mb-4">
                    &larr; Back to Merchants
                </Button>
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-900">{merchant.name}</h1>
                        <p className="text-slate-500">{merchant.tenant?.subscriptionStatus} Plan: {merchant.tenant?.plan}</p>
                        <div className="text-sm text-slate-400 mt-1">{merchant.address} | {merchant.phone}</div>
                    </div>
                    <div className="flex gap-2 flex-wrap">
                        <Badge variant={merchant.tenant?.subscriptionStatus === 'ACTIVE' ? 'success' : 'warning'}>{merchant.tenant?.subscriptionStatus}</Badge>
                        <Button variant="outline" onClick={() => setShowEditModal(true)}>Edit Details</Button>
                        <Button variant="outline" onClick={() => navigate(`/merchants/${id}/menu`)}>Manage Menu</Button>
                        <Button variant="secondary" onClick={() => setShowNotifyModal(true)}>Send Notification</Button>
                        
                        {merchant.tenant?.subscriptionStatus === 'ACTIVE' ? (
                            <Button variant="destructive" onClick={handleSuspend}>Suspend</Button>
                        ) : (
                            <Button className="bg-green-600 hover:bg-green-700 text-white" onClick={handleActivate}>Activate</Button>
                        )}
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-6 border-b border-slate-200 mb-6 overflow-x-auto">
                <button onClick={() => setActiveTab('overview')} className={`pb-3 px-1 font-medium whitespace-nowrap ${activeTab === 'overview' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Overview</button>
                <button onClick={() => setActiveTab('products')} className={`pb-3 px-1 font-medium whitespace-nowrap ${activeTab === 'products' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Products</button>
                <button onClick={() => setActiveTab('transactions')} className={`pb-3 px-1 font-medium whitespace-nowrap ${activeTab === 'transactions' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Transactions</button>
                <button onClick={() => setActiveTab('wallet')} className={`pb-3 px-1 font-medium whitespace-nowrap ${activeTab === 'wallet' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Wallet & Finance</button>
                <button onClick={() => setActiveTab('users')} className={`pb-3 px-1 font-medium whitespace-nowrap ${activeTab === 'users' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Users & Stores</button>
            </div>

            {/* Content */}
            {activeTab === 'overview' && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <Card className="p-6">
                        <h3 className="text-slate-500 text-sm font-medium uppercase">Total Sales (GMV)</h3>
                        <p className="text-2xl font-bold text-slate-900 mt-2">{formatCurrency(merchant.totalGmv || 0)}</p>
                    </Card>
                    <Card className="p-6">
                        <h3 className="text-slate-500 text-sm font-medium uppercase">Transactions</h3>
                        <p className="text-2xl font-bold text-slate-900 mt-2">{merchant._count?.transactions || 0}</p>
                    </Card>
                    <Card className="p-6">
                        <h3 className="text-slate-500 text-sm font-medium uppercase">Products</h3>
                        <p className="text-2xl font-bold text-slate-900 mt-2">{merchant._count?.products || 0}</p>
                    </Card>
                </div>
            )}

            {activeTab === 'products' && (
                <Card>
                    <div className="flex justify-between items-center p-4 border-b">
                        <h3 className="font-semibold">Merchant Products ({products.length})</h3>
                    </div>
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Image</Th>
                                <Th>Name</Th>
                                <Th>Category</Th>
                                <Th>Price</Th>
                                <Th>Stock</Th>
                                <Th>Status</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {products.length === 0 ? (
                                <Tr><Td colSpan="6" className="text-center py-4">No products found</Td></Tr>
                            ) : (
                                products.map(p => (
                                    <Tr key={p.id}>
                                        <Td>
                                            <div className="w-10 h-10 bg-slate-100 rounded bg-cover bg-center" style={{ backgroundImage: `url(${p.imageUrl})` }}></div>
                                        </Td>
                                        <Td>{p.name}</Td>
                                        <Td>{p.category?.name || '-'}</Td>
                                        <Td>{formatCurrency(p.sellingPrice)}</Td>
                                        <Td>{p.stock}</Td>
                                        <Td>
                                            <Badge variant={p.isActive ? 'success' : 'neutral'}>{p.isActive ? 'Active' : 'Inactive'}</Badge>
                                        </Td>
                                    </Tr>
                                ))
                            )}
                        </Tbody>
                    </Table>
                </Card>
            )}

            {activeTab === 'transactions' && (
                <Card>
                    <div className="flex justify-between items-center p-4 border-b">
                        <h3 className="font-semibold">Recent Transactions</h3>
                    </div>
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Date</Th>
                                <Th>Customer</Th>
                                <Th>Total</Th>
                                <Th>Status</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {transactions.length === 0 ? (
                                <Tr><Td colSpan="4" className="text-center py-4">No transactions found</Td></Tr>
                            ) : (
                                transactions.map(t => (
                                    <Tr key={t.id}>
                                        <Td>{new Date(t.occurredAt).toLocaleDateString()} {new Date(t.occurredAt).toLocaleTimeString()}</Td>
                                        <Td>{t.store?.name || 'Customer'}</Td>
                                        <Td>{formatCurrency(t.totalAmount)}</Td>
                                        <Td><Badge variant={t.paymentStatus === 'PAID' ? 'success' : 'warning'}>{t.paymentStatus}</Badge></Td>
                                    </Tr>
                                ))
                            )}
                        </Tbody>
                    </Table>
                </Card>
            )}

            {activeTab === 'wallet' && (
                <div className="space-y-6">
                    <div className="flex justify-between items-center">
                        <Card className="p-6 w-full md:w-1/3 bg-slate-900 text-white">
                            <h3 className="text-white/70 text-sm font-medium uppercase">Current Balance</h3>
                            <p className="text-3xl font-bold mt-2">{formatCurrency(merchant.balance)}</p>
                        </Card>
                        <Button onClick={() => setShowWalletModal(true)} className="bg-slate-900 text-white hover:bg-slate-800">
                            Adjust Balance
                        </Button>
                    </div>

                    <Card>
                        <h3 className="p-4 font-semibold border-b">Recent Wallet Activity</h3>
                        <Table>
                            <Thead>
                                <Tr>
                                    <Th>Date</Th>
                                    <Th>Type</Th>
                                    <Th>Description</Th>
                                    <Th className="text-right">Amount</Th>
                                </Tr>
                            </Thead>
                            <Tbody>
                                {merchant.walletHistory?.map(log => (
                                    <Tr key={log.id}>
                                        <Td>{new Date(log.occurredAt).toLocaleDateString()} {new Date(log.occurredAt).toLocaleTimeString()}</Td>
                                        <Td>
                                            <Badge variant={log.type === 'CASH_IN' ? 'success' : 'danger'}>{log.type}</Badge>
                                        </Td>
                                        <Td>{log.description}</Td>
                                        <Td className={`text-right font-medium ${log.type === 'CASH_IN' ? 'text-green-600' : 'text-red-600'}`}>
                                            {log.type === 'CASH_IN' ? '+' : '-'}{formatCurrency(log.amount)}
                                        </Td>
                                    </Tr>
                                ))}
                            </Tbody>
                        </Table>
                    </Card>
                </div>
            )}

            {activeTab === 'users' && (
                <Card>
                    <h3 className="p-4 font-semibold border-b">Registered Users</h3>
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Name</Th>
                                <Th>Email</Th>
                                <Th>Role</Th>
                                <Th>Actions</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {merchant.tenant.users?.map(u => (
                                <Tr key={u.id}>
                                    <Td>{u.name}</Td>
                                    <Td>{u.email}</Td>
                                    <Td><Badge>{u.role}</Badge></Td>
                                    <Td>
                                        <Button variant="link" className="text-xs text-indigo-600 hover:underline h-auto p-0" onClick={() => { setSelectedUser(u); setShowResetModal(true); }}>Reset Password</Button>
                                    </Td>
                                </Tr>
                            ))}
                        </Tbody>
                    </Table>
                </Card>
            )}

            {/* Wallet Modal */}
            {showWalletModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <h2 className="text-xl font-bold mb-4">Adjust Wallet Balance</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Type</label>
                                <select
                                    className="w-full border rounded-lg p-2"
                                    value={walletForm.type}
                                    onChange={e => setWalletForm({ ...walletForm, type: e.target.value })}
                                >
                                    <option value="CREDIT">CREDIT (Add Balance)</option>
                                    <option value="DEBIT">DEBIT (Deduct Balance)</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Amount</label>
                                <input
                                    type="number"
                                    className="w-full border rounded-lg p-2"
                                    value={walletForm.amount}
                                    onChange={e => setWalletForm({ ...walletForm, amount: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Reason (Internal Note)</label>
                                <input
                                    type="text"
                                    className="w-full border rounded-lg p-2"
                                    value={walletForm.reason}
                                    onChange={e => setWalletForm({ ...walletForm, reason: e.target.value })}
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-8">
                            <Button variant="outline" onClick={() => setShowWalletModal(false)}>Cancel</Button>
                            <Button className="bg-slate-900 text-white hover:bg-slate-800" onClick={handleAdjustWallet}>Confirm</Button>
                        </div>
                    </div>
                </div>
            )}

            {/* Notification Modal */}
            {showNotifyModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <h2 className="text-xl font-bold mb-4">Send In-App Notification</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
                                <input
                                    className="w-full border rounded-lg p-2"
                                    value={notifyForm.title}
                                    onChange={e => setNotifyForm({ ...notifyForm, title: e.target.value })}
                                    placeholder="e.g. Important Update"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Message Body</label>
                                <textarea
                                    className="w-full border rounded-lg p-2 h-24"
                                    value={notifyForm.body}
                                    onChange={e => setNotifyForm({ ...notifyForm, body: e.target.value })}
                                    placeholder="Type your message here..."
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-8">
                            <Button variant="outline" onClick={() => setShowNotifyModal(false)}>Cancel</Button>
                            <Button onClick={handleSendNotification}>Send</Button>
                        </div>
                    </div>
                </div>
            )}

            {/* Reset Password Modal */}
            {showResetModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-sm p-6">
                        <h2 className="text-xl font-bold mb-4">Reset Password</h2>
                        <p className="text-sm text-slate-500 mb-4">Reset password for <b>{selectedUser?.name}</b></p>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">New Password</label>
                                <Input
                                    type="password"
                                    value={resetPassword}
                                    onChange={e => setResetPassword(e.target.value)}
                                    placeholder="Enter new password"
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-8">
                            <Button variant="outline" onClick={() => setShowResetModal(false)}>Cancel</Button>
                            <Button variant="destructive" onClick={handleResetPassword}>Reset Password</Button>
                        </div>
                    </div>
                </div>
            )}

            {/* Edit Details Modal */}
            {showEditModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <h2 className="text-xl font-bold mb-4">Edit Merchant Details</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Store Name</label>
                                <Input
                                    value={editForm.name}
                                    onChange={e => setEditForm({ ...editForm, name: e.target.value })}
                                    placeholder="Store Name"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Phone</label>
                                <Input
                                    value={editForm.phone}
                                    onChange={e => setEditForm({ ...editForm, phone: e.target.value })}
                                    placeholder="Phone Number"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Address</label>
                                <Input
                                    value={editForm.address}
                                    onChange={e => setEditForm({ ...editForm, address: e.target.value })}
                                    placeholder="Address"
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-8">
                            <Button variant="outline" onClick={() => setShowEditModal(false)}>Cancel</Button>
                            <Button onClick={handleUpdateDetails}>Save Changes</Button>
                        </div>
                    </div>
                </div>
            )}

        </AdminLayout>
    );
};

export default MerchantDetail;
