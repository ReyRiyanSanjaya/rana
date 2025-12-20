import React, { useState, useEffect } from 'react';
import { X, Banknote, QrCode, CreditCard, CheckCircle } from 'lucide-react';
import { formatCurrency } from '../../utils/format'; // Assuming utility exists or we use Intl

const PaymentModal = ({ isOpen, onClose, totalAmount, onConfirm }) => {
    const [paymentMethod, setPaymentMethod] = useState('CASH'); // CASH, QRIS, TRANSFER
    const [cashReceived, setCashReceived] = useState('');
    const [change, setChange] = useState(0);

    useEffect(() => {
        if (isOpen) {
            setPaymentMethod('CASH');
            setCashReceived('');
            setChange(0);
        }
    }, [isOpen]);

    useEffect(() => {
        if (paymentMethod === 'CASH' && cashReceived) {
            const received = parseFloat(cashReceived) || 0;
            setChange(Math.max(0, received - totalAmount));
        } else {
            setChange(0);
        }
    }, [cashReceived, totalAmount, paymentMethod]);

    if (!isOpen) return null;

    const handleConfirm = () => {
        // Validation for Cash
        if (paymentMethod === 'CASH') {
            const received = parseFloat(cashReceived) || 0;
            if (received < totalAmount) {
                alert('Uang yang diterima kurang!');
                return;
            }
        }

        onConfirm({
            paymentMethod,
            amountPaid: paymentMethod === 'CASH' ? parseFloat(cashReceived) : totalAmount,
            change: change
        });
    };

    const fmt = (num) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(num);

    const QuickMoneyBtn = ({ amount }) => (
        <button
            onClick={() => setCashReceived(amount.toString())}
            className="px-3 py-2 bg-slate-100 dark:bg-slate-700 rounded text-sm hover:bg-slate-200 dark:hover:bg-slate-600 transition"
        >
            {fmt(amount)}
        </button>
    );

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <div className="bg-white dark:bg-slate-800 w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">

                {/* Header */}
                <div className="flex justify-between items-center p-5 border-b border-slate-100 dark:border-slate-700">
                    <h3 className="text-xl font-bold dark:text-white">Pembayaran</h3>
                    <button onClick={onClose} className="p-1 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-full">
                        <X size={24} className="text-slate-500" />
                    </button>
                </div>

                <div className="p-6 space-y-6">
                    {/* Total Display */}
                    <div className="text-center space-y-1">
                        <p className="text-sm text-slate-500 dark:text-slate-400">Total Tagihan</p>
                        <h2 className="text-4xl font-extrabold text-primary">{fmt(totalAmount)}</h2>
                    </div>

                    {/* Method Selection */}
                    <div className="grid grid-cols-3 gap-3">
                        <button
                            onClick={() => setPaymentMethod('CASH')}
                            className={`flex flex-col items-center justify-center p-4 rounded-xl border-2 transition ${paymentMethod === 'CASH'
                                    ? 'border-primary bg-primary/5 text-primary'
                                    : 'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:text-slate-300'
                                }`}
                        >
                            <Banknote size={24} className="mb-2" />
                            <span className="text-sm font-bold">Tunai</span>
                        </button>
                        <button
                            onClick={() => setPaymentMethod('QRIS')}
                            className={`flex flex-col items-center justify-center p-4 rounded-xl border-2 transition ${paymentMethod === 'QRIS'
                                    ? 'border-primary bg-primary/5 text-primary'
                                    : 'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:text-slate-300'
                                }`}
                        >
                            <QrCode size={24} className="mb-2" />
                            <span className="text-sm font-bold">QRIS</span>
                        </button>
                        <button
                            onClick={() => setPaymentMethod('TRANSFER')}
                            className={`flex flex-col items-center justify-center p-4 rounded-xl border-2 transition ${paymentMethod === 'TRANSFER'
                                    ? 'border-primary bg-primary/5 text-primary'
                                    : 'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:text-slate-300'
                                }`}
                        >
                            <CreditCard size={24} className="mb-2" />
                            <span className="text-sm font-bold">Transfer</span>
                        </button>
                    </div>

                    {/* Cash Input Section */}
                    {paymentMethod === 'CASH' && (
                        <div className="space-y-4 animate-in slide-in-from-top-2">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                    Uang Diterima
                                </label>
                                <input
                                    type="number"
                                    value={cashReceived}
                                    onChange={(e) => setCashReceived(e.target.value)}
                                    className="w-full text-lg p-3 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary focus:outline-none dark:bg-slate-700 dark:text-white"
                                    placeholder="0"
                                    autoFocus
                                />
                            </div>

                            {/* Quick Money Buttons */}
                            <div className="flex flex-wrap gap-2">
                                <QuickMoneyBtn amount={totalAmount} />
                                <QuickMoneyBtn amount={50000} />
                                <QuickMoneyBtn amount={100000} />
                            </div>

                            {/* Change Display */}
                            <div className="flex justify-between items-center p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg border border-slate-200 dark:border-slate-700">
                                <span className="font-medium text-slate-600 dark:text-slate-300">Kembalian</span>
                                <span className="text-xl font-bold text-green-600">{fmt(change)}</span>
                            </div>
                        </div>
                    )}

                    {/* QRIS / Transfer Instructions */}
                    {paymentMethod !== 'CASH' && (
                        <div className="p-6 bg-slate-50 dark:bg-slate-700/50 rounded-xl flex flex-col items-center text-center animate-in slide-in-from-top-2">
                            {paymentMethod === 'QRIS' ? (
                                <>
                                    <div className="bg-white p-2 rounded-lg shadow-sm mb-3">
                                        <QrCode size={120} className="text-slate-800" />
                                    </div>
                                    <p className="text-sm text-slate-500">Scan QR Code ini untuk membayar</p>
                                </>
                            ) : (
                                <>
                                    <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-3 text-blue-600">
                                        <CreditCard size={32} />
                                    </div>
                                    <h4 className="font-bold dark:text-white">Bank BCA</h4>
                                    <p className="text-lg font-mono my-1 tracking-wider dark:text-slate-300">123 456 7890</p>
                                    <p className="text-sm text-slate-500">a.n. Rana Merchant</p>
                                </>
                            )}
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className="p-5 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 flex justify-end gap-3">
                    <button
                        onClick={onClose}
                        className="px-5 py-2.5 text-slate-600 dark:text-slate-300 font-medium hover:bg-slate-200 dark:hover:bg-slate-700 rounded-lg transition"
                    >
                        Batal
                    </button>
                    <button
                        onClick={handleConfirm}
                        className="px-6 py-2.5 bg-green-600 hover:bg-green-700 text-white font-bold rounded-lg shadow-lg hover:shadow-xl transition flex items-center"
                    >
                        <CheckCircle size={18} className="mr-2" />
                        Selesaikan Transaksi
                    </button>
                </div>
            </div>
        </div>
    );
};

export default PaymentModal;
