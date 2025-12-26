import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Input from "../components/ui/Input"; // [NEW]

const MerchantDetail = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [merchant, setMerchant] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('overview');

    // Modals
    const [showWalletModal, setShowWalletModal] = useState(false);
    const [walletForm, setWalletForm] = useState({ type: 'CREDIT', amount: '', reason: '' });

    const [showNotifyModal, setShowNotifyModal] = useState(false);

    const [notifyForm, setNotifyForm] = useState({ title: '', body: '' });

    // [NEW] Reset Password State
    const [showResetModal, setShowResetModal] = useState(false);
    const [resetPassword, setResetPassword] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);

    useEffect(() => {
        fetchDetail();
    }, [id]);

    const fetchDetail = async () => {
        try {
            const res = await api.get(`/admin/merchants/${id}`);
            setMerchant(res.data.data);
            setLoading(false);
        } catch (error) {
            console.error(error);
            alert("Failed to fetch merchant details");
            navigate('/merchants');
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

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    if (loading) return <AdminLayout><div className="flex justify-center p-10">Loading...</div></AdminLayout>;
    if (!merchant) return null;

    return (
        <AdminLayout>
            {/* Header */}
            <div className="mb-8">
                <button onClick={() => navigate('/merchants')} className="text-slate-500 hover:text-slate-800 mb-2 flex items-center gap-1">
                    &larr; Back to Merchants
                </button>
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                    <div>
                        <h1 className="text-3xl font-bold text-slate-900">{merchant.name}</h1>
                        <p className="text-slate-500">{merchant.tenant?.subscriptionStatus} Plan: {merchant.tenant?.plan}</p>
                    </div>
                    <div className="flex gap-2">
                        <Badge variant={merchant.tenant?.subscriptionStatus === 'ACTIVE' ? 'success' : 'warning'}>{merchant.tenant?.subscriptionStatus}</Badge>
                        <button onClick={() => navigate(`/merchants/${id}/menu`)} className="px-4 py-2 bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 font-medium">Manage Menu</button>
                        <button onClick={() => setShowNotifyModal(true)} className="px-4 py-2 bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 font-medium">Send Notification</button>
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-6 border-b border-slate-200 mb-6">
                <button onClick={() => setActiveTab('overview')} className={`pb-3 px-1 font-medium ${activeTab === 'overview' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Overview</button>
                <button onClick={() => setActiveTab('wallet')} className={`pb-3 px-1 font-medium ${activeTab === 'wallet' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Wallet & Finance</button>
                <button onClick={() => setActiveTab('users')} className={`pb-3 px-1 font-medium ${activeTab === 'users' ? 'text-indigo-600 border-b-2 border-indigo-600' : 'text-slate-500'}`}>Users & Stores</button>
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

            {activeTab === 'wallet' && (
                <div className="space-y-6">
                    <div className="flex justify-between items-center">
                        <Card className="p-6 w-full md:w-1/3 bg-slate-900 text-white">
                            <h3 className="text-white/70 text-sm font-medium uppercase">Current Balance</h3>
                            <p className="text-3xl font-bold mt-2">{formatCurrency(merchant.balance)}</p>
                        </Card>
                        <button onClick={() => setShowWalletModal(true)} className="px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800">
                            Adjust Balance
                        </button>
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
                                        <button onClick={() => { setSelectedUser(u); setShowResetModal(true); }} className="text-xs text-indigo-600 hover:underline">Reset Password</button>
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
                            <button onClick={() => setShowWalletModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-50 rounded-lg">Cancel</button>
                            <button onClick={handleAdjustWallet} className="px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800">Confirm</button>
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
                            <button onClick={() => setShowNotifyModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-50 rounded-lg">Cancel</button>
                            <button onClick={handleSendNotification} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Send</button>
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
                            <button onClick={() => setShowResetModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-50 rounded-lg">Cancel</button>
                            <button onClick={handleResetPassword} className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700">Reset Password</button>
                        </div>
                    </div>
                </div>
            )}

        </AdminLayout>
    );
};

export default MerchantDetail;
