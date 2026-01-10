import React, { useState, useEffect, useMemo } from 'react';
import { ShoppingCart, Wifi, WifiOff, Search, Grid, List, Trash, Plus, Minus, User, RefreshCw, LogOut } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import DashboardLayout from '../components/layout/DashboardLayout';
import RanaDB from '../services/db';
import SyncManager from '../services/syncManager';
import { fetchProducts } from '../services/api';
import PaymentModal from '../components/pos/PaymentModal';
import { playBeep, playSuccess, playError } from '../utils/sound';

const POSMode = () => {
    const navigate = useNavigate();
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('All');
    const [viewMode, setViewMode] = useState('grid'); // grid | list

    // Cart State
    const [cart, setCart] = useState([]);
    const [isOffline, setIsOffline] = useState(!navigator.onLine);

    // UI State
    const [showPaymentModal, setShowPaymentModal] = useState(false);

    // Initial Load
    useEffect(() => {
        loadProducts();

        const handleOnline = () => setIsOffline(false);
        const handleOffline = () => setIsOffline(true);
        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);

        // Sync Manager (Just start it)
        SyncManager.startBackgroundSync(30000);

        return () => {
            window.removeEventListener('online', handleOnline);
            window.removeEventListener('offline', handleOffline);
        };
    }, []);

    const loadProducts = async () => {
        setLoading(true);
        try {
            // Try fetch from API, fallback to offline DB? 
            // For now direct API. In strict offline app we might load from IDB.
            const data = await fetchProducts();
            if (data) {
                setProducts(data);
            }
        } catch (error) {
            console.error("Failed to load products", error);
        } finally {
            setLoading(false);
        }
    };

    // Derived State
    const categories = useMemo(() => {
        const cats = new Set(products.map(p => p.category?.name || 'Uncategorized'));
        return ['All', ...Array.from(cats)];
    }, [products]);

    const filteredProducts = useMemo(() => {
        return products.filter(p => {
            const matchSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                p.sku?.toLowerCase().includes(searchTerm.toLowerCase());
            const matchCat = selectedCategory === 'All' || (p.category?.name || 'Uncategorized') === selectedCategory;
            return matchSearch && matchCat;
        });
    }, [products, searchTerm, selectedCategory]);

    const cartTotal = useMemo(() => {
        return cart.reduce((acc, item) => acc + (item.price * item.qty), 0);
    }, [cart]);

    // Actions
    const addToCart = (product) => {
        playBeep();
        setCart(prev => {
            const existing = prev.find(item => item.id === product.id);
            if (existing) {
                return prev.map(item =>
                    item.id === product.id
                        ? { ...item, qty: item.qty + 1 }
                        : item
                );
            }
            return [...prev, { ...product, qty: 1, price: product.sellingPrice }];
        });
    };

    const updateQty = (id, delta) => {
        playBeep(1000, 0.05); // Higher pitch for modification
        setCart(prev => prev.map(item => {
            if (item.id === id) {
                const newQty = Math.max(1, item.qty + delta);
                return { ...item, qty: newQty };
            }
            return item;
        }));
    };

    const setQtyManual = (id, value) => {
        const num = parseInt(value, 10);
        const safe = isNaN(num) ? 1 : Math.max(1, num);
        playBeep(800, 0.05);
        setCart(prev => prev.map(item => {
            if (item.id === id) {
                const capped = item.stock ? Math.min(safe, item.stock) : safe;
                return { ...item, qty: capped };
            }
            return item;
        }));
    };

    const removeFromCart = (id) => {
        setCart(prev => prev.filter(item => item.id !== id));
    };

    const handleCheckout = async (paymentData) => {
        const transaction = {
            offlineId: crypto.randomUUID(),
            occurredAt: new Date().toISOString(),
            totalAmount: cartTotal,
            // Payment Details
            paymentMethod: paymentData.paymentMethod,
            amountPaid: paymentData.amountPaid,
            change: paymentData.change,
            // Items
            items: cart.map(item => ({
                productId: item.id,
                quantity: item.qty,
                price: item.price,
                // Enriched Data for Snapshot
                productName: item.name,
                productSku: item.sku,
                productImage: item.imageUrl,
                basePrice: item.basePrice
            }))
        };

        try {
            await RanaDB.queueTransaction(transaction);

            // Success Feedback
            playSuccess();
            setShowPaymentModal(false);
            setCart([]);
            alert(`Transaksi Berhasil! Kembalian: ${fmt(paymentData.change)}`);

            // Try sync
            if (!isOffline) SyncManager.pushChanges();
        } catch (error) {
            console.error(error);
            alert("Gagal menyimpan transaksi");
        }
    };

    const fmt = (n) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n);

    return (
        <div className="flex h-screen bg-slate-100 dark:bg-slate-900 overflow-hidden">
            {/* LEFT: Product Catalog */}
            <div className="flex-1 flex flex-col min-w-0">
                {/* Header */}
                <div className="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 p-4 px-6 flex items-center justify-between shadow-sm z-10">
                    <div>
                        <h1 className="text-xl font-bold dark:text-white">Rana POS</h1>
                        <div className={`flex items-center space-x-2 text-xs font-medium ${isOffline ? 'text-red-500' : 'text-green-500'}`}>
                            {isOffline ? <WifiOff size={12} /> : <Wifi size={12} />}
                            <span>{isOffline ? 'OFFLINE MODE' : 'CONNECTED'}</span>
                        </div>
                    </div>

                    {/* Search Bar */}
                    <div className="flex-1 max-w-md mx-8 relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input
                            type="text"
                            placeholder="Cari produk (Nama atau SKU)..."
                            value={searchTerm}
                            onChange={e => setSearchTerm(e.target.value)}
                            className="w-full pl-10 pr-4 py-2.5 bg-slate-100 dark:bg-slate-700 border-none rounded-full focus:ring-2 focus:ring-primary outline-none dark:text-white"
                        />
                    </div>

                    <div className="flex items-center space-x-3">
                        <button onClick={loadProducts} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-full text-slate-500" title="Sync Products">
                            <RefreshCw size={20} />
                        </button>
                        <button onClick={() => navigate('/')} className="p-2 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-full text-red-500" title="Exit POS">
                            <LogOut size={20} />
                        </button>
                    </div>
                </div>

                {/* Categories */}
                <div className="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 px-6 py-3 overflow-x-auto whitespace-nowrap scrollbar-hide">
                    <div className="flex space-x-2">
                        {categories.map(cat => (
                            <button
                                key={cat}
                                onClick={() => setSelectedCategory(cat)}
                                className={`px-4 py-1.5 rounded-full text-sm font-medium transition ${selectedCategory === cat
                                    ? 'bg-primary text-white shadow-md'
                                    : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                                    }`}
                            >
                                {cat}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Product Grid */}
                <div className="flex-1 overflow-y-auto p-6">
                    {loading ? (
                        <div className="flex items-center justify-center h-full text-slate-400">Loading products...</div>
                    ) : filteredProducts.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-full text-slate-400">
                            <Search size={48} className="mb-4 opacity-50" />
                            <p>Tidak ada produk ditemukan</p>
                        </div>
                    ) : (
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                            {filteredProducts.map(product => (
                                <div
                                    key={product.id}
                                    onClick={() => addToCart(product)}
                                    className="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-md transition cursor-pointer group"
                                >
                                    <div className="aspect-[4/3] bg-slate-100 dark:bg-slate-700 relative">
                                        {/* Image Placeholder or Real Image */}
                                        <div className="absolute inset-0 flex items-center justify-center text-slate-300">
                                            <span className="text-4xl font-bold opacity-20">{product.name[0]}</span>
                                        </div>
                                        <div className="absolute top-2 right-2 bg-black/60 text-white text-[10px] px-2 py-0.5 rounded-full backdrop-blur-sm">
                                            Stok: {product.stock}
                                        </div>
                                    </div>
                                    <div className="p-3">
                                        <h3 className="font-medium text-slate-800 dark:text-white line-clamp-2 text-sm leading-tight h-10">
                                            {product.name}
                                        </h3>
                                        <p className="mt-2 text-primary font-bold">
                                            {fmt(product.sellingPrice)}
                                        </p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            {/* RIGHT: Cart Panel */}
            <div className="w-[400px] bg-white dark:bg-slate-800 border-l border-slate-200 dark:border-slate-700 flex flex-col shadow-xl z-20">
                {/* Cart Header */}
                <div className="p-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between bg-slate-50 dark:bg-slate-800/50">
                    <div className="flex items-center space-x-2 text-primary font-bold">
                        <ShoppingCart size={20} />
                        <span>Keranjang Belanja</span>
                    </div>
                    <div className="text-sm font-medium bg-primary/10 text-primary px-2 py-1 rounded">
                        {cart.reduce((a, b) => a + b.qty, 0)} Items
                    </div>
                </div>

                {/* Customer (Optional) */}
                <div className="p-3 border-b border-slate-100 dark:border-slate-700">
                    <button className="w-full flex items-center justify-between text-sm text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-700 p-2 rounded-lg">
                        <div className="flex items-center">
                            <User size={16} className="mr-2" />
                            <span>Pilih Pelanggan (Umum)</span>
                        </div>
                        <Plus size={14} />
                    </button>
                </div>

                {/* Cart Items */}
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {cart.length === 0 ? (
                        <div className="h-full flex flex-col items-center justify-center text-slate-400 space-y-3">
                            <ShoppingCart size={64} className="opacity-20" />
                            <p className="text-sm">Belum ada item dipilih</p>
                        </div>
                    ) : (
                        cart.map(item => (
                            <div key={item.id} className="flex justify-between items-start group">
                                <div className="flex-1 pr-3">
                                    <h4 className="text-sm font-medium text-slate-800 dark:text-white">{item.name}</h4>
                                    <p className="text-xs text-slate-500">{fmt(item.price)}</p>
                                </div>
                                <div className="flex items-center space-x-3 bg-slate-50 dark:bg-slate-700/50 rounded-lg p-1">
                                    <button
                                        onClick={() => updateQty(item.id, -1)}
                                        className="w-7 h-7 flex items-center justify-center bg-white dark:bg-slate-600 rounded shadow-sm hover:text-red-500 transition disabled:opacity-50"
                                        disabled={item.qty <= 1}
                                    >
                                        <Minus size={14} />
                                    </button>
                                    <input
                                        type="number"
                                        min="1"
                                        value={item.qty}
                                        onChange={(e) => setQtyManual(item.id, e.target.value)}
                                        onBlur={(e) => setQtyManual(item.id, e.target.value)}
                                        className="w-14 text-sm font-bold text-center bg-white dark:bg-slate-600 rounded shadow-sm outline-none border border-transparent focus:border-primary"
                                    />
                                    <button
                                        onClick={() => updateQty(item.id, 1)}
                                        className="w-7 h-7 flex items-center justify-center bg-white dark:bg-slate-600 rounded shadow-sm hover:text-green-500 transition"
                                    >
                                        <Plus size={14} />
                                    </button>
                                </div>
                                <button
                                    onClick={() => removeFromCart(item.id)}
                                    className="ml-2 p-1.5 text-slate-300 hover:text-red-500 hover:bg-red-50 rounded-lg transition"
                                >
                                    <Trash size={16} />
                                </button>
                            </div>
                        ))
                    )}
                </div>

                {/* Footer Totals */}
                <div className="p-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-700 space-y-3">
                    <div className="space-y-1 text-sm text-slate-600 dark:text-slate-400">
                        <div className="flex justify-between">
                            <span>Subtotal</span>
                            <span>{fmt(cartTotal)}</span>
                        </div>
                        <div className="flex justify-between">
                            <span>Pajak</span>
                            <span>-</span>
                        </div>
                    </div>
                    <div className="flex justify-between items-end border-t border-slate-200 dark:border-slate-700 pt-3">
                        <span className="font-bold text-lg dark:text-white">Total</span>
                        <span className="font-extrabold text-2xl text-primary">{fmt(cartTotal)}</span>
                    </div>

                    <button
                        onClick={() => setShowPaymentModal(true)}
                        disabled={cart.length === 0}
                        className="w-full py-4 bg-primary text-white font-bold rounded-xl shadow-lg hover:bg-indigo-700 hover:shadow-xl transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                    >
                        <span>Bayar Sekarang</span>
                        <div className="w-px h-4 bg-white/30 mx-2"></div>
                        <span>{fmt(cartTotal)}</span>
                    </button>
                </div>
            </div>

            {/* Modal */}
            <PaymentModal
                isOpen={showPaymentModal}
                onClose={() => setShowPaymentModal(false)}
                totalAmount={cartTotal}
                onConfirm={handleCheckout}
            />
        </div>
    );
};

export default POSMode;
