import React, { useState } from 'react';
import { ShoppingCart, Wifi, WifiOff, Save } from 'lucide-react';
import DashboardLayout from '../components/layout/DashboardLayout';
import RanaDB from '../services/db';
import SyncManager from '../services/syncManager';

const POSMode = () => {
    const [cart, setCart] = useState([]);
    const [isOffline, setIsOffline] = useState(!navigator.onLine);

    // Listen to network status
    React.useEffect(() => {
        const handleOnline = () => setIsOffline(false);
        const handleOffline = () => setIsOffline(true);
        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);

        // Start sync manager
        SyncManager.startBackgroundSync(15000); // 15s for demo

        return () => {
            window.removeEventListener('online', handleOnline);
            window.removeEventListener('offline', handleOffline);
            SyncManager.stopBackgroundSync();
        };
    }, []);

    const addToCart = () => {
        // Dummy product
        setCart([...cart, {
            productId: 'prod_123',
            name: 'Demo Product',
            price: 50000,
            qty: 1
        }]);
    };

    const handleCheckout = async () => {
        if (cart.length === 0) return;

        const transaction = {
            offlineId: crypto.randomUUID(),
            tenantId: 'demo-tenant',
            storeId: 'demo-store',
            occurredAt: new Date().toISOString(),
            total: cart.reduce((acc, item) => acc + item.price, 0),
            items: cart
        };

        try {
            await RanaDB.queueTransaction(transaction);
            alert('Transaction saved! (Offline/Queue)');
            setCart([]);
            // Force immediate sync try if online
            SyncManager.pushChanges();
        } catch (e) {
            console.error(e);
            alert('Failed to save transaction');
        }
    };

    return (
        <DashboardLayout>
            <div className="max-w-xl mx-auto space-y-6">
                <div className="flex items-center justify-between">
                    <h2 className="text-2xl font-bold">POS Terminal</h2>
                    <div className={`flex items-center space-x-2 px-3 py-1 rounded-full text-sm font-medium ${isOffline ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                        {isOffline ? <WifiOff size={16} /> : <Wifi size={16} />}
                        <span>{isOffline ? 'OFFLINE' : 'ONLINE'}</span>
                    </div>
                </div>

                <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100 h-64 flex items-center justify-center border-dashed border-2">
                    {cart.length === 0 ? (
                        <p className="text-slate-400">Cart is empty</p>
                    ) : (
                        <div className="w-full space-y-2">
                            {cart.map((item, i) => (
                                <div key={i} className="flex justify-between border-b pb-2">
                                    <span>{item.name}</span>
                                    <span>{item.price}</span>
                                </div>
                            ))}
                            <div className="pt-4 font-bold flex justify-between">
                                <span>Total</span>
                                <span>{cart.reduce((a, b) => a + b.price, 0)}</span>
                            </div>
                        </div>
                    )}
                </div>

                <div className="grid grid-cols-2 gap-4">
                    <button
                        onClick={addToCart}
                        className="bg-slate-100 text-slate-700 py-3 rounded-lg font-medium hover:bg-slate-200"
                    >
                        + Add Item
                    </button>
                    <button
                        onClick={handleCheckout}
                        className="bg-primary text-white py-3 rounded-lg font-medium hover:bg-indigo-700 flex items-center justify-center space-x-2"
                    >
                        <ShoppingCart size={18} />
                        <span>Checkout</span>
                    </button>
                </div>

                <div className="text-xs text-center text-slate-400">
                    Transactions are saved to IndexedDB first, then synced.
                </div>
            </div>
        </DashboardLayout>
    );
};

export default POSMode;
