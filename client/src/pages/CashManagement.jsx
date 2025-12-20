import React, { useEffect, useState } from 'react';
import { BadgeDollarSign, UserMinus, Send, Save, CheckCircle, Wallet, ArrowDownCircle, History } from 'lucide-react';
import DashboardLayout from '../components/layout/DashboardLayout';
import { recordExpense, recordDebt, triggerDailyReport, fetchWalletData, requestWithdrawal } from '../services/api';

const CashManagement = () => {
    const [activeTab, setActiveTab] = useState('wallet'); // wallet | expense | debt | report
    const [loading, setLoading] = useState(false);
    const [successMsg, setSuccessMsg] = useState('');

    // Data States
    const [walletData, setWalletData] = useState({ balance: 0, withdrawals: [] });

    // Form States
    const [expenseForm, setExpenseForm] = useState({ amount: '', category: 'EXPENSE_PETTY', description: '' });
    const [debtForm, setDebtForm] = useState({ amount: '', borrowerName: '', notes: '' });
    const [wdForm, setWdForm] = useState({ amount: '', bankName: '', accountNumber: '' });

    useEffect(() => {
        if (activeTab === 'wallet') loadWallet();
    }, [activeTab]);

    const loadWallet = async () => {
        try {
            const data = await fetchWalletData();
            setWalletData(data);
        } catch (err) {
            console.error(err);
        }
    };

    const handleWithdrawalSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            await requestWithdrawal(wdForm);
            setSuccessMsg('Withdrawal Requested Successfully!');
            setWdForm({ amount: '', bankName: '', accountNumber: '' });
            loadWallet(); // Refresh balance
        } catch (err) {
            alert(err.response?.data?.message || 'Withdrawal Failed');
        } finally {
            setLoading(false);
        }
    };

    const handleExpenseSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            // Mock store ID
            await recordExpense({ ...expenseForm, storeId: 'demo-store', date: new Date() });
            setSuccessMsg('Expense recorded successfully!');
            setExpenseForm({ amount: '', category: 'EXPENSE_PETTY', description: '' });
        } catch (err) {
            console.error(err);
            alert('Failed to record expense');
        } finally {
            setLoading(false);
        }
    };

    const handleDebtSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            await recordDebt({ ...debtForm, storeId: 'demo-store', date: new Date() });
            setSuccessMsg('Debt (Kasbon) recorded successfully!');
            setDebtForm({ amount: '', borrowerName: '', notes: '' });
        } catch (err) {
            console.error(err);
            alert('Failed to record debt');
        } finally {
            setLoading(false);
        }
    };

    const handleWAReport = async () => {
        if (!confirm('Send daily report to Owner via WhatsApp?')) return;
        setLoading(true);
        try {
            const today = new Date().toISOString().split('T')[0];
            await triggerDailyReport('demo-store', today);
            alert('Report Sent! 🚀');
        } catch (err) {
            console.error(err);
            alert('Failed to send report. (Make sure backend is running)');
        } finally {
            setLoading(false);
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    return (
        <DashboardLayout>
            <div className="max-w-3xl mx-auto space-y-6">
                <div>
                    <h2 className="text-2xl font-bold text-slate-900">Finance & Operations</h2>
                    <p className="text-slate-500">Manage wallet, petty cash, kasbon, and daily reports.</p>
                </div>

                {/* Tabs */}
                <div className="flex space-x-2 bg-white p-1 rounded-lg border border-slate-200 overflow-x-auto">
                    <button onClick={() => setActiveTab('wallet')} className={`flex-1 min-w-[100px] py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'wallet' ? 'bg-primary text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50'}`}>Wallet</button>
                    <button onClick={() => setActiveTab('expense')} className={`flex-1 min-w-[100px] py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'expense' ? 'bg-primary text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50'}`}>Expense</button>
                    <button onClick={() => setActiveTab('debt')} className={`flex-1 min-w-[100px] py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'debt' ? 'bg-primary text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50'}`}>Kasbon</button>
                    <button onClick={() => setActiveTab('report')} className={`flex-1 min-w-[100px] py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'report' ? 'bg-green-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50'}`}>Report</button>
                </div>

                {/* Content Area */}
                <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100 min-h-[300px]">

                    {successMsg && (
                        <div className="mb-4 p-3 bg-green-50 text-green-700 rounded-lg flex items-center space-x-2">
                            <CheckCircle size={18} />
                            <span>{successMsg}</span>
                        </div>
                    )}

                    {activeTab === 'wallet' && (
                        <div className="space-y-8">
                            {/* Balance Card */}
                            <div className="bg-gradient-to-r from-indigo-600 to-blue-600 rounded-xl p-6 text-white shadow-lg">
                                <p className="text-indigo-100 font-medium mb-1">Total Active Balance</p>
                                <h2 className="text-4xl font-bold">{formatCurrency(walletData.balance)}</h2>
                                <p className="text-sm text-indigo-200 mt-4 opacity-80">Earnings from digital payments & sales</p>
                            </div>

                            {/* Withdrawal Form */}
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                                <div>
                                    <h3 className="font-bold text-lg text-slate-800 mb-4 flex items-center gap-2">
                                        <ArrowDownCircle className="text-primary" /> Request Withdrawal
                                    </h3>
                                    <form onSubmit={handleWithdrawalSubmit} className="space-y-4">
                                        <div>
                                            <label className="text-sm font-medium text-slate-700">Amount to Withdraw</label>
                                            <input type="number" required min="10000" className="w-full mt-1 p-2 border rounded-lg" value={wdForm.amount} onChange={e => setWdForm({ ...wdForm, amount: e.target.value })} placeholder="Min. 10,000" />
                                        </div>
                                        <div>
                                            <label className="text-sm font-medium text-slate-700">Bank Name</label>
                                            <select required className="w-full mt-1 p-2 border rounded-lg" value={wdForm.bankName} onChange={e => setWdForm({ ...wdForm, bankName: e.target.value })}>
                                                <option value="">Select Bank</option>
                                                <option value="BCA">BCA</option>
                                                <option value="MANDIRI">Mandiri</option>
                                                <option value="BRI">BRI</option>
                                                <option value="BNI">BNI</option>
                                                <option value="GOPAY">GoPay</option>
                                                <option value="OVO">OVO</option>
                                                <option value="DANA">DANA</option>
                                            </select>
                                        </div>
                                        <div>
                                            <label className="text-sm font-medium text-slate-700">Account Number</label>
                                            <input type="text" required className="w-full mt-1 p-2 border rounded-lg" value={wdForm.accountNumber} onChange={e => setWdForm({ ...wdForm, accountNumber: e.target.value })} placeholder="e.g. 1234567890" />
                                        </div>
                                        <button disabled={loading} className="w-full bg-primary text-white py-2 rounded-lg font-bold hover:bg-blue-700 transition">
                                            {loading ? 'Processing...' : 'Submit Request'}
                                        </button>
                                    </form>
                                </div>

                                {/* History */}
                                <div>
                                    <h3 className="font-bold text-lg text-slate-800 mb-4 flex items-center gap-2">
                                        <History className="text-slate-500" /> Recent Requests
                                    </h3>
                                    <div className="space-y-3">
                                        {walletData.withdrawals.length === 0 ? (
                                            <p className="text-slate-400 italic">No withdrawal history.</p>
                                        ) : walletData.withdrawals.slice(0, 5).map(w => (
                                            <div key={w.id} className="p-3 bg-slate-50 rounded-lg flex justify-between items-center text-sm">
                                                <div>
                                                    <p className="font-bold text-slate-800">{formatCurrency(w.amount)}</p>
                                                    <p className="text-xs text-slate-500">{new Date(w.createdAt).toLocaleDateString()}</p>
                                                </div>
                                                <span className={`px-2 py-1 rounded-full text-xs font-bold ${w.status === 'APPROVED' ? 'bg-green-100 text-green-600' :
                                                        w.status === 'REJECTED' ? 'bg-red-100 text-red-600' :
                                                            'bg-yellow-100 text-yellow-600'
                                                    }`}>
                                                    {w.status}
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'expense' && (
                        <form onSubmit={handleExpenseSubmit} className="space-y-4">
                            <div className="flex items-center space-x-2 text-primary font-medium mb-4">
                                <BadgeDollarSign />
                                <h3>Record Store Expense (Uang Keluar)</h3>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                                <select className="w-full p-2 border rounded-lg" value={expenseForm.category} onChange={e => setExpenseForm({ ...expenseForm, category: e.target.value })}>
                                    <option value="EXPENSE_PETTY">Petty Cash (Misc)</option>
                                    <option value="EXPENSE_OPERATIONAL">Operational (Bills)</option>
                                    <option value="EXPENSE_PURCHASE">Inventory Purchase</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Amount (Rp)</label>
                                <input type="number" required className="w-full p-2 border rounded-lg" value={expenseForm.amount} onChange={e => setExpenseForm({ ...expenseForm, amount: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
                                <textarea className="w-full p-2 border rounded-lg h-24" placeholder="Description..." value={expenseForm.description} onChange={e => setExpenseForm({ ...expenseForm, description: e.target.value })} />
                            </div>
                            <button disabled={loading} className="w-full bg-primary text-white py-3 rounded-lg font-bold hover:bg-blue-700">{loading ? 'Saving...' : 'Record Expense'}</button>
                        </form>
                    )}

                    {activeTab === 'debt' && (
                        <form onSubmit={handleDebtSubmit} className="space-y-4">
                            <div className="flex items-center space-x-2 text-orange-600 font-medium mb-4">
                                <UserMinus />
                                <h3>Record Debt (Kasbon)</h3>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Borrower</label>
                                <input type="text" required className="w-full p-2 border rounded-lg" placeholder="Name" value={debtForm.borrowerName} onChange={e => setDebtForm({ ...debtForm, borrowerName: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Amount</label>
                                <input type="number" required className="w-full p-2 border rounded-lg" value={debtForm.amount} onChange={e => setDebtForm({ ...debtForm, amount: e.target.value })} />
                            </div>
                            <button disabled={loading} className="w-full bg-orange-600 text-white py-3 rounded-lg font-bold hover:bg-orange-700">{loading ? 'Saving...' : 'Record Debt'}</button>
                        </form>
                    )}

                    {activeTab === 'report' && (
                        <div className="text-center space-y-6 py-8">
                            <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center text-green-600"><Send size={32} /></div>
                            <div>
                                <h3 className="text-xl font-bold text-slate-900">Send Daily Report</h3>
                                <p className="text-slate-500 max-w-sm mx-auto mt-2">Generate summary of Sales, Expenses, and Debts to Owner's WhatsApp.</p>
                            </div>
                            <button onClick={handleWAReport} disabled={loading} className="bg-green-600 text-white px-8 py-3 rounded-full font-bold shadow-lg hover:bg-green-700 disabled:opacity-50">{loading ? 'Sending...' : 'Trigger WhatsApp Report'}</button>
                        </div>
                    )}

                </div>
            </div>
        </DashboardLayout>
    );
};

export default CashManagement;
