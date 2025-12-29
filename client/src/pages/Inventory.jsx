
import React, { useEffect, useRef, useState } from 'react';
import DashboardLayout from '../components/layout/DashboardLayout';
import api, { fetchProductLogs, adjustStock, fetchInventoryIntelligence, fetchDashboardStats, createProduct, updateProduct, deleteProduct, fetchProducts } from '../services/api';
import { Package, Plus, Minus, History, AlertTriangle, Search, TrendingUp, TrendingDown, Edit, Trash2, X } from 'lucide-react';
import { io } from 'socket.io-client';

const Inventory = () => {
    const [activeTab, setActiveTab] = useState('stock'); // 'stock', 'intelligence'
    const [products, setProducts] = useState([]);
    const [intelligence, setIntelligence] = useState({ slowMoving: [], topProducts: [] });
    const [loading, setLoading] = useState(true);
    const socketRef = useRef(null);

    // Modal States
    const [selectedProduct, setSelectedProduct] = useState(null);
    const [showAdjustModal, setShowAdjustModal] = useState(false);
    const [showHistoryModal, setShowHistoryModal] = useState(false);
    const [showProductModal, setShowProductModal] = useState(false);
    const [logs, setLogs] = useState([]);

    // Adjustment Form
    const [adjustType, setAdjustType] = useState('IN');
    const [adjustQty, setAdjustQty] = useState(0);
    const [adjustReason, setAdjustReason] = '';

    // Product Form (Add/Edit)
    const [productForm, setProductForm] = useState({
        name: '', sku: '', basePrice: 0, sellingPrice: 0, stock: 0, minStock: 5, categoryId: '', description: ''
    });
    const [isEditing, setIsEditing] = useState(false);

    useEffect(() => {
        loadData();

        const token = localStorage.getItem('token');
        if (!token) return;

        const baseUrl = api?.defaults?.baseURL || '';
        const socketUrl = baseUrl ? baseUrl.replace(/\/api\/?$/, '') : 'http://localhost:4000';

        socketRef.current = io(socketUrl, {
            auth: { token },
            transports: ['websocket', 'polling']
        });

        const refresh = () => loadData();
        socketRef.current.on('inventory:changed', refresh);
        socketRef.current.on('products:changed', refresh);
        socketRef.current.on('transactions:created', refresh);

        return () => {
            socketRef.current?.disconnect();
        };
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            // Load Analysis Data
            const resIntel = await fetchInventoryIntelligence();

            // Load Dashboard Stats (for Top Products)
            const resDash = await fetchDashboardStats(new Date().toISOString().split('T')[0]);

            // Load Products
            const items = await fetchProducts();

            setProducts(items.map(i => ({
                ...i,
                stock: i.stock || 0,
                minStock: i.minStock || 5
            })));

            setIntelligence({
                slowMoving: resIntel.slowMoving || [],
                topProducts: resDash.topProducts || []
            });

        } catch (error) {
            console.error("Failed to load inventory data", error);
        } finally {
            setLoading(false);
        }
    };

    // --- Product CRUD Handlers ---

    const handleOpenAddProduct = () => {
        setProductForm({ name: '', sku: '', basePrice: 0, sellingPrice: 0, stock: 0, minStock: 5, categoryId: '', description: '' });
        setIsEditing(false);
        setShowProductModal(true);
    };

    const handleOpenEditProduct = (product) => {
        setProductForm({
            name: product.name,
            sku: product.sku || '',
            basePrice: product.basePrice || 0,
            sellingPrice: product.sellingPrice || product.price || 0, // Fallback for old seed data
            stock: product.stock,
            minStock: product.minStock || 5,
            categoryId: product.categoryId || '',
            description: product.description || ''
        });
        setSelectedProduct(product);
        setIsEditing(true);
        setShowProductModal(true);
    };

    const handleDeleteProduct = async (id) => {
        if (!window.confirm('Are you sure you want to delete this product?')) return;
        try {
            await deleteProduct(id);
            loadData();
            alert('Product deleted');
        } catch (error) {
            alert('Failed to delete product');
        }
    };

    const submitProductForm = async (e) => {
        e.preventDefault();
        try {
            if (isEditing) {
                await updateProduct(selectedProduct.id, productForm);
                alert('Product updated');
            } else {
                await createProduct(productForm);
                alert('Product created');
            }
            setShowProductModal(false);
            loadData();
        } catch (error) {
            console.error(error);
            alert('Failed to save product');
        }
    };

    // --- Existing Handlers ---

    const handleOpenAdjust = (product) => {
        setSelectedProduct(product);
        setAdjustType('IN');
        setAdjustQty(0);
        setAdjustReason('');
        setShowAdjustModal(true);
    };

    const handleOpenHistory = async (product) => {
        setSelectedProduct(product);
        setShowHistoryModal(true);
        try {
            const res = await fetchProductLogs(product.id);
            setLogs(res.data.data);
        } catch (error) {
            console.error(error);
            setLogs([]);
        }
    };

    const submitAdjustment = async (e) => {
        e.preventDefault();
        try {
            await adjustStock({
                productId: selectedProduct.id,
                quantity: parseInt(adjustQty),
                type: adjustType,
                reason: adjustReason
            });
            setShowAdjustModal(false);
            loadData(); // Refresh all
            alert('Stock adjusted successfully');
        } catch (error) {
            alert('Failed to adjust stock');
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);

    return (
        <DashboardLayout title="Inventory Management">
            <div className="space-y-6">
                <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                    <div>
                        <h2 className="text-2xl font-bold dark:text-white">Inventory Management</h2>
                        <p className="text-slate-500 dark:text-slate-400">Track stock levels and analyze product performance.</p>
                    </div>
                    <div className="flex items-center space-x-3">
                        <div className="flex bg-slate-100 dark:bg-slate-800 p-1 rounded-lg">
                            <button
                                onClick={() => setActiveTab('stock')}
                                className={`px - 4 py - 2 text - sm font - medium rounded - md transition - all ${activeTab === 'stock'
                                    ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                                    : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                                    } `}
                            >
                                Stock Control
                            </button>
                            <button
                                onClick={() => setActiveTab('intelligence')}
                                className={`px - 4 py - 2 text - sm font - medium rounded - md transition - all ${activeTab === 'intelligence'
                                    ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm'
                                    : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                                    } `}
                            >
                                Intelligence (Analysis)
                            </button>
                        </div>
                        {activeTab === 'stock' && (
                            <button
                                onClick={handleOpenAddProduct}
                                className="flex items-center px-4 py-2.5 bg-primary-600 hover:bg-primary-700 text-white rounded-lg font-medium transition-colors"
                            >
                                <Plus size={18} className="mr-2" />
                                Add Product
                            </button>
                        )}
                    </div>
                </div>

                {loading ? (
                    <div className="text-center py-12 text-slate-400">Loading data...</div>
                ) : (
                    <>
                        {/* TAB: INTELLIGENCE */}
                        {activeTab === 'intelligence' && (
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                {/* Top Selling */}
                                <div className="bg-white dark:bg-slate-900 rounded-xl shadow-sm p-6 border border-slate-200 dark:border-slate-800">
                                    <div className="flex items-center space-x-3 mb-6">
                                        <div className="p-2 bg-green-100 text-green-600 rounded-lg dark:bg-green-900/30 dark:text-green-400">
                                            <TrendingUp size={20} />
                                        </div>
                                        <div>
                                            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Top Selling Products</h3>
                                            <p className="text-sm text-slate-500 dark:text-slate-400">Highest revenue contributors</p>
                                        </div>
                                    </div>
                                    <div className="space-y-4">
                                        {intelligence.topProducts.map((item, idx) => (
                                            <div key={idx} className="flex items-center justify-between p-3 hover:bg-slate-50 dark:hover:bg-slate-800/50 rounded-lg transition-colors">
                                                <div className="flex items-center space-x-3">
                                                    <span className="text-sm font-bold text-slate-400 w-6">#{idx + 1}</span>
                                                    <span className="font-medium text-slate-900 dark:text-white">{item.product.name}</span>
                                                </div>
                                                <span className="font-bold text-slate-900 dark:text-white">{formatCurrency(item.revenue)}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                {/* Slow Moving */}
                                <div className="bg-white dark:bg-slate-900 rounded-xl shadow-sm p-6 border border-slate-200 dark:border-slate-800">
                                    <div className="flex items-center space-x-3 mb-6">
                                        <div className="p-2 bg-orange-100 text-orange-600 rounded-lg dark:bg-orange-900/30 dark:text-orange-400">
                                            <TrendingDown size={20} />
                                        </div>
                                        <div>
                                            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Slow Moving Items</h3>
                                            <p className="text-sm text-slate-500 dark:text-slate-400">No sales in &gt;30 days</p>
                                        </div>
                                    </div>
                                    <div className="space-y-4">
                                        {intelligence.slowMoving.map((item) => (
                                            <div key={item.id} className="flex items-center justify-between p-3 hover:bg-slate-50 dark:hover:bg-slate-800/50 rounded-lg transition-colors border border-dashed border-slate-200 dark:border-slate-700">
                                                <div>
                                                    <p className="font-medium text-slate-900 dark:text-white">{item.name}</p>
                                                    <p className="text-xs text-slate-500 dark:text-slate-400">SKU: {item.sku}</p>
                                                </div>
                                                <div className="text-right">
                                                    <div className="text-sm font-semibold text-orange-600 dark:text-orange-400">{item.daysInactive} Days</div>
                                                    <div className="text-xs text-slate-400">Inactive</div>
                                                </div>
                                            </div>
                                        ))}
                                        {intelligence.slowMoving.length === 0 && (
                                            <p className="text-center text-slate-500 text-sm py-4">Great! No slow moving inventory detected.</p>
                                        )}
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* TAB: STOCK CONTROL */}
                        {activeTab === 'stock' && (
                            <div className="bg-white dark:bg-slate-900 rounded-xl shadow-sm overflow-hidden border border-slate-200 dark:border-slate-800">
                                <div className="overflow-x-auto">
                                    <table className="w-full text-left text-sm">
                                        <thead className="bg-slate-50 dark:bg-slate-800 text-slate-500 dark:text-slate-400 font-medium border-b border-slate-200 dark:border-slate-700">
                                            <tr>
                                                <th className="px-6 py-4">Product Name</th>
                                                <th className="px-6 py-4">SKU</th>
                                                <th className="px-6 py-4">Price</th>
                                                <th className="px-6 py-4 text-center">Stock</th>
                                                <th className="px-6 py-4">Status</th>
                                                <th className="px-6 py-4 text-right">Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                            {products.length === 0 && (
                                                <tr><td colSpan="6" className="p-6 text-center text-slate-500">No inventory found.</td></tr>
                                            )}
                                            {products.map((product) => (
                                                <tr key={product.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                                    <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">
                                                        {product.name}
                                                    </td>
                                                    <td className="px-6 py-4 text-slate-500 dark:text-slate-400">{product.sku || '-'}</td>
                                                    <td className="px-6 py-4 text-slate-900 dark:text-white">
                                                        {formatCurrency(product.sellingPrice || product.price || 0)}
                                                    </td>
                                                    <td className="px-6 py-4 text-center">
                                                        <span className={`px - 3 py - 1 rounded - full text - xs font - bold ${product.stock <= product.minStock
                                                            ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                                                            : 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                            } `}>
                                                            {product.stock}
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-4">
                                                        {product.stock <= product.minStock && (
                                                            <div className="flex items-center text-red-600 dark:text-red-400 text-xs font-medium">
                                                                <AlertTriangle size={14} className="mr-1" />
                                                                Low Stock
                                                            </div>
                                                        )}
                                                    </td>
                                                    <td className="px-6 py-4 text-right space-x-2 flex justify-end items-center">
                                                        <button
                                                            onClick={() => handleOpenHistory(product)}
                                                            className="p-2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                                                            title="View History"
                                                        >
                                                            <History size={16} />
                                                        </button>
                                                        <button
                                                            onClick={(e) => { e.stopPropagation(); handleOpenEditProduct(product); }}
                                                            className="p-2 text-slate-400 hover:text-indigo-600 dark:hover:text-indigo-400"
                                                            title="Edit Product"
                                                        >
                                                            <Edit size={16} />
                                                        </button>
                                                        <button
                                                            onClick={(e) => { e.stopPropagation(); handleDeleteProduct(product.id); }}
                                                            className="p-2 text-slate-400 hover:text-red-600 dark:hover:text-red-400"
                                                            title="Delete Product"
                                                        >
                                                            <Trash2 size={16} />
                                                        </button>
                                                        <div className="border-l border-slate-200 dark:border-slate-700 h-6 mx-1"></div>
                                                        <button
                                                            onClick={() => handleOpenAdjust(product)}
                                                            className="px-3 py-1.5 text-xs font-medium bg-indigo-50 text-indigo-600 rounded-lg hover:bg-indigo-100 dark:bg-indigo-900/40 dark:text-indigo-300 dark:hover:bg-indigo-900/60"
                                                        >
                                                            Adjust
                                                        </button>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}
                    </>
                )}

                {/* Adjust Modal */}
                {showAdjustModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                        <div className="bg-white dark:bg-slate-900 w-full max-w-md rounded-2xl p-6 shadow-xl border border-slate-200 dark:border-slate-800">
                            <h3 className="text-xl font-bold mb-4 dark:text-white">Adjust Stock: {selectedProduct?.name}</h3>
                            <form onSubmit={submitAdjustment} className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1 dark:text-slate-300">Action</label>
                                    <div className="grid grid-cols-2 gap-2">
                                        <button
                                            type="button"
                                            onClick={() => setAdjustType('IN')}
                                            className={`py - 2 rounded - lg text - sm font - medium border ${adjustType === 'IN'
                                                ? 'bg-green-50 border-green-200 text-green-700 dark:bg-green-900/30 dark:border-green-800 dark:text-green-400'
                                                : 'border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-400'
                                                } `}
                                        >
                                            Restock (+IN)
                                        </button>
                                        <button
                                            type="button"
                                            onClick={() => setAdjustType('OUT')}
                                            className={`py - 2 rounded - lg text - sm font - medium border ${adjustType === 'OUT'
                                                ? 'bg-red-50 border-red-200 text-red-700 dark:bg-red-900/30 dark:border-red-800 dark:text-red-400'
                                                : 'border-slate-200 text-slate-600 dark:border-slate-700 dark:text-slate-400'
                                                } `}
                                        >
                                            Reduce (-OUT)
                                        </button>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 dark:text-slate-300">Quantity</label>
                                    <input
                                        type="number"
                                        min="1"
                                        required
                                        value={adjustQty}
                                        onChange={e => setAdjustQty(e.target.value)}
                                        className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 dark:text-slate-300">Reason</label>
                                    <input
                                        type="text"
                                        placeholder="e.g. Broken, Expired, Stock Opname"
                                        required
                                        value={adjustReason}
                                        onChange={e => setAdjustReason(e.target.value)}
                                        className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                    />
                                </div>
                                <div className="flex justify-end space-x-2 pt-4">
                                    <button
                                        type="button"
                                        onClick={() => setShowAdjustModal(false)}
                                        className="px-4 py-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
                                    >
                                        Save Adjustment
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* History Modal */}
                {showHistoryModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                        <div className="bg-white dark:bg-slate-900 w-full max-w-lg rounded-2xl p-6 shadow-xl border border-slate-200 dark:border-slate-800 max-h-[80vh] flex flex-col">
                            <div className="flex justify-between items-center mb-4">
                                <h3 className="text-xl font-bold dark:text-white">History: {selectedProduct?.name}</h3>
                                <button onClick={() => setShowHistoryModal(false)} className="text-slate-400 hover:text-slate-600">
                                    <X size={20} />
                                </button>
                            </div>

                            <div className="overflow-y-auto flex-1">
                                {logs.length === 0 ? (
                                    <p className="text-center text-slate-500 py-8">No history found.</p>
                                ) : (
                                    <div className="space-y-3">
                                        {logs.map(log => (
                                            <div key={log.id} className="flex justify-between items-center p-3 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700">
                                                <div>
                                                    <p className="text-sm font-medium text-slate-900 dark:text-white">{log.reason}</p>
                                                    <p className="text-xs text-slate-500">{new Date(log.createdAt).toLocaleString()}</p>
                                                </div>
                                                <div className={`text - sm font - bold ${log.quantity > 0 ? 'text-green-600' : 'text-red-600'
                                                    } `}>
                                                    {log.quantity > 0 ? '+' : ''}{log.quantity}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )}

                {/* Product Form Modal (Add/Edit) */}
                {showProductModal && (
                    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                        <div className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-2xl p-6 shadow-xl border border-slate-200 dark:border-slate-800 overflow-y-auto max-h-[90vh]">
                            <h3 className="text-xl font-bold mb-6 dark:text-white">{isEditing ? 'Edit Product' : 'Add New Product'}</h3>
                            <form onSubmit={submitProductForm} className="space-y-4">
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="col-span-2">
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Product Name</label>
                                        <input
                                            type="text"
                                            required
                                            value={productForm.name}
                                            onChange={e => setProductForm({ ...productForm, name: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">SKU</label>
                                        <input
                                            type="text"
                                            required
                                            value={productForm.sku}
                                            onChange={e => setProductForm({ ...productForm, sku: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Base Price (Modal)</label>
                                        <input
                                            type="number"
                                            required
                                            min="0"
                                            value={productForm.basePrice}
                                            onChange={e => setProductForm({ ...productForm, basePrice: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Selling Price</label>
                                        <input
                                            type="number"
                                            required
                                            min="0"
                                            value={productForm.sellingPrice}
                                            onChange={e => setProductForm({ ...productForm, sellingPrice: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Initial Stock</label>
                                        <input
                                            type="number"
                                            min="0"
                                            disabled={isEditing} // Stock should be adjusted, not edited directly after creation usually
                                            value={productForm.stock}
                                            onChange={e => setProductForm({ ...productForm, stock: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Low Stock Alert</label>
                                        <input
                                            type="number"
                                            min="0"
                                            value={productForm.minStock}
                                            onChange={e => setProductForm({ ...productForm, minStock: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                    <div className="col-span-2">
                                        <label className="block text-sm font-medium mb-1 dark:text-slate-300">Description</label>
                                        <textarea
                                            rows="3"
                                            value={productForm.description}
                                            onChange={e => setProductForm({ ...productForm, description: e.target.value })}
                                            className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-primary-500"
                                        />
                                    </div>
                                </div>
                                <div className="flex justify-end space-x-2 pt-4">
                                    <button
                                        type="button"
                                        onClick={() => setShowProductModal(false)}
                                        className="px-4 py-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
                                    >
                                        {isEditing ? 'Save Changes' : 'Create Product'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}


            </div>
        </DashboardLayout>
    );
};

export default Inventory;

