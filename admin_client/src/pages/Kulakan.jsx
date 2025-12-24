import React, { useState, useEffect } from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import { Button } from '../components/ui/button';
import { Search, Filter, Plus, MoreHorizontal, Package, Edit, Trash2, X, List, ShoppingCart, Truck, CheckCircle } from 'lucide-react';
import api from '../api';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "../components/ui/dropdown-menu";
import Input from "../components/ui/Input";

const Kulakan = () => {
    const [activeTab, setActiveTab] = useState('products');

    // Data States
    const [products, setProducts] = useState([]);
    const [categories, setCategories] = useState([]);
    const [orders, setOrders] = useState([]);
    const [coupons, setCoupons] = useState([]);
    const [banners, setBanners] = useState([]); // [NEW]
    const [loading, setLoading] = useState(true);

    // Filter States
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('ALL');

    // Modal States
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [modalType, setModalType] = useState('product'); // 'product', 'category', 'coupon'
    const [selectedItem, setSelectedItem] = useState(null);

    // Helper for Orders Modal/View
    const [selectedOrder, setSelectedOrder] = useState(null);

    // Forms
    const [productForm, setProductForm] = useState({
        name: '', categoryId: '', price: '', stock: '', supplierName: '', description: '', imageUrl: '', isActive: true
    });
    const [categoryForm, setCategoryForm] = useState({ name: '', isActive: true });

    // [NEW] Coupon Form
    const [couponForm, setCouponForm] = useState({
        code: '', type: 'FIXED', value: '', minOrder: '', maxDiscount: '', isActive: true
    });
    // [NEW] Banner Form
    const [bannerForm, setBannerForm] = useState({ title: '', imageUrl: '', description: '', isActive: true });

    useEffect(() => {
        fetchData();
    }, [activeTab]); // Refetch when tab changes

    const fetchData = () => {
        setLoading(true);
        if (activeTab === 'products') {
            fetchProducts();
            fetchCategories(); // Needed for dropdown
        } else if (activeTab === 'categories') {
            fetchCategories();
        } else if (activeTab === 'orders') {
            fetchOrders();
        } else if (activeTab === 'promotions') {
            fetchCoupons();
        } else if (activeTab === 'banners') { // [NEW]
            fetchBanners();
        }
    };

    const fetchProducts = async () => {
        try {
            const res = await api.get('/wholesale/products?category=Semua');
            if (res.data.status === 'success') setProducts(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchCategories = async () => {
        try {
            const res = await api.get('/wholesale/categories');
            if (res.data.status === 'success') setCategories(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchOrders = async () => {
        try {
            const res = await api.get('/wholesale/orders');
            if (res.data.status === 'success') setOrders(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchCoupons = async () => {
        try {
            const res = await api.get('/wholesale/coupons');
            if (res.data.status === 'success') setCoupons(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchBanners = async () => {
        try {
            const res = await api.get('/wholesale/banners');
            if (res.data.status === 'success') setBanners(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    // --- PRODUCT HANDLERS ---
    const handleProductSubmit = async () => {
        try {
            if (!productForm.name || !productForm.price || !productForm.categoryId) return alert("Required fields missing");
            if (selectedItem) {
                await api.put(`/wholesale/products/${selectedItem.id}`, productForm);
            } else {
                await api.post('/wholesale/products', productForm);
            }
            closeModal();
            fetchProducts();
        } catch (error) { alert("Failed to save product"); }
    };

    const deleteProduct = async (id) => {
        if (!confirm("Delete this product?")) return;
        try { await api.delete(`/wholesale/products/${id}`); fetchProducts(); } catch (e) { alert("Failed delete"); }
    };

    // --- CATEGORY HANDLERS ---
    const handleCategorySubmit = async () => {
        try {
            if (!categoryForm.name) return alert("Name is required");
            if (selectedItem) {
                await api.put(`/wholesale/categories/${selectedItem.id}`, categoryForm);
            } else {
                await api.post('/wholesale/categories', categoryForm);
            }
            closeModal();
            fetchCategories();
        } catch (error) { alert("Failed to save category"); }
    };

    const deleteCategory = async (id) => {
        if (!confirm("Delete this category?")) return;
        try { await api.delete(`/wholesale/categories/${id}`); fetchCategories(); } catch (e) { alert(e.response?.data?.message || "Failed delete"); }
    };

    // --- COUPON HANDLERS ---
    const handleCouponSubmit = async () => {
        try {
            if (!couponForm.code || !couponForm.value) return alert("Code and Value required");
            if (selectedItem) {
                // await api.put... (If edit needed, currently backend only has toggle status, lets assume creates only or implement simplified)
                // Actually my backend only had toggle. I should add UPDATE to controller later if needed. For now, we might just Support Create/Delete/Toggle
                alert("Editing not fully supported yet, delete and recreate");
            } else {
                await api.post('/wholesale/coupons', couponForm);
            }
            closeModal();
            fetchCoupons();
        } catch (error) { alert("Failed save coupon: " + (error.response?.data?.message || "")); }
    };

    const deleteCoupon = async (id) => {
        if (!confirm("Delete coupon?")) return;
        await api.delete(`/wholesale/coupons/${id}`);
        fetchCoupons();
    };

    const toggleCoupon = async (id, isActive) => {
        await api.patch(`/wholesale/coupons/${id}`, { isActive: !isActive });
        fetchCoupons();
    }

    // --- BANNER HANDLERS ---
    const handleBannerSubmit = async () => {
        try {
            if (!bannerForm.title || !bannerForm.imageUrl) return alert("Title/Image required");
            if (selectedItem) {
                alert("Editing not supported, delete and recreate");
            } else {
                await api.post('/wholesale/banners', bannerForm);
            }
            closeModal();
            fetchBanners();
        } catch (error) { alert("Failed save banner"); }
    };

    const deleteBanner = async (id) => {
        if (!confirm("Delete banner?")) return;
        await api.delete(`/wholesale/banners/${id}`);
        fetchBanners();
    };

    // --- ORDER HANDLERS ---
    const updateOrderStatus = async (id, status) => {
        try {
            await api.put(`/wholesale/orders/${id}/status`, { status });
            fetchOrders();
            if (selectedOrder && selectedOrder.id === id) {
                setSelectedOrder(prev => ({ ...prev, status }));
            }
        } catch (e) { alert("Failed update status"); }
    };

    // --- COMMON UTILS ---
    const openModal = (type, item = null) => {
        setModalType(type);
        setSelectedItem(item);
        if (type === 'product') {
            setProductForm(item ? { ...item, categoryId: item.categoryId || '' } : { name: '', categoryId: '', price: '', stock: '', supplierName: '', description: '', imageUrl: '', isActive: true });
        } else if (type === 'category') {
            setCategoryForm(item ? { name: item.name, isActive: item.isActive } : { name: '', isActive: true });
        } else if (type === 'coupon') {
            setCouponForm(item ? { ...item } : { code: '', type: 'FIXED', value: '', minOrder: '', maxDiscount: '', isActive: true });
        } else if (type === 'banner') {
            setBannerForm(item ? { ...item } : { title: '', imageUrl: '', description: '', isActive: true });
        }
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
        setSelectedItem(null);
    };

    // --- RENDERERS ---
    const renderProducts = () => {
        const filtered = products.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()));
        return (
            <div>
                <div className="flex justify-between items-center mb-4">
                    <div className="relative w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <Input placeholder="Search products..." className="pl-10" value={searchTerm} onChange={e => setSearchTerm(e.target.value)} />
                    </div>
                    <Button onClick={() => openModal('product')} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Product</Button>
                </div>
                <div className="overflow-x-auto bg-white border rounded-lg">
                    <table className="w-full text-left">
                        <thead className="bg-slate-50 border-b">
                            <tr>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Product</th>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Category</th>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Price</th>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Stock</th>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Status</th>
                                <th className="px-6 py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y">
                            {filtered.length === 0 ? <tr><td colSpan={6} className="p-4 text-center text-slate-500">No products found</td></tr> :
                                filtered.map(p => (
                                    <tr key={p.id} className="hover:bg-slate-50">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center">
                                                <div className="w-10 h-10 rounded bg-indigo-50 flex items-center justify-center mr-3 overflow-hidden">
                                                    {p.imageUrl ? <img src={p.imageUrl} alt="" className="w-full h-full object-cover" /> : <Package size={20} className="text-indigo-600" />}
                                                </div>
                                                <div>
                                                    <div className="font-medium">{p.name}</div>
                                                    <div className="text-xs text-slate-500">{p.supplierName}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-sm">{p.category?.name}</td>
                                        <td className="px-6 py-4 text-sm">Rp {p.price.toLocaleString('id-ID')}</td>
                                        <td className="px-6 py-4 text-sm">{p.stock}</td>
                                        <td className="px-6 py-4"><Badge variant={p.isActive ? "success" : "secondary"}>{p.isActive ? "Active" : "Inactive"}</Badge></td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Button variant="ghost" size="sm" onClick={() => openModal('product', p)}><Edit size={16} /></Button>
                                                <Button variant="ghost" size="sm" className="text-red-500" onClick={() => deleteProduct(p.id)}><Trash2 size={16} /></Button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                        </tbody>
                    </table>
                </div>
            </div>
        );
    };

    const renderCategories = () => {
        return (
            <div>
                <div className="flex justify-end items-center mb-4">
                    <Button onClick={() => openModal('category')} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Category</Button>
                </div>
                <div className="overflow-x-auto bg-white border rounded-lg">
                    <table className="w-full text-left">
                        <thead className="bg-slate-50 border-b">
                            <tr>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Category Name</th>
                                <th className="px-6 py-3 text-xs font-semibold text-slate-500 uppercase">Status</th>
                                <th className="px-6 py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y">
                            {categories.map(c => (
                                <tr key={c.id} className="hover:bg-slate-50">
                                    <td className="px-6 py-4 font-medium">{c.name}</td>
                                    <td className="px-6 py-4"><Badge variant={c.isActive ? "success" : "secondary"}>{c.isActive ? "Active" : "Inactive"}</Badge></td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-2">
                                            <Button variant="ghost" size="sm" onClick={() => openModal('category', c)}><Edit size={16} /></Button>
                                            <Button variant="ghost" size="sm" className="text-red-500" onClick={() => deleteCategory(c.id)}><Trash2 size={16} /></Button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        )
    };

    const renderCoupons = () => {
        return (
            <div>
                <div className="flex justify-end items-center mb-4"><Button onClick={() => openModal('coupon')} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Coupon</Button></div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {coupons.map(c => (
                        <Card key={c.id} className="p-4 relative">
                            <div className="flex justify-between items-start mb-2">
                                <div>
                                    <div className="font-bold text-lg text-indigo-600">{c.code}</div>
                                    <div className="text-sm text-slate-500">{c.type}</div>
                                </div>
                                <Badge variant={c.isActive ? 'success' : 'secondary'} className="cursor-pointer" onClick={() => toggleCoupon(c.id, c.isActive)}>
                                    {c.isActive ? 'Active' : 'Inactive'}
                                </Badge>
                            </div>
                            <div className="space-y-1 text-sm text-slate-600 mb-4">
                                <div>Value: <span className="font-medium">{c.type === 'PERCENTAGE' ? `${c.value}%` : `Rp ${c.value.toLocaleString('id-ID')}`}</span></div>
                                <div>Min Order: Rp {c.minOrder.toLocaleString('id-ID')}</div>
                            </div>
                            <div className="absolute bottom-4 right-4">
                                <Button variant="ghost" size="sm" className="text-red-500" onClick={() => deleteCoupon(c.id)}><Trash2 size={16} /></Button>
                            </div>
                        </Card>
                    ))}
                </div>
            </div>
        );
        );
    }

const renderBanners = () => {
    return (
        <div>
            <div className="flex justify-end items-center mb-4"><Button onClick={() => openModal('banner')} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Banner</Button></div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {banners.map(b => (
                    <Card key={b.id} className="overflow-hidden relative group">
                        <div className="h-32 bg-slate-100 relative">
                            <img src={b.imageUrl} alt={b.title} className="w-full h-full object-cover" />
                            <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                <Button variant="ghost" size="sm" className="text-white hover:text-red-300" onClick={() => deleteBanner(b.id)}><Trash2 size={24} /></Button>
                            </div>
                        </div>
                        <div className="p-4">
                            <div className="font-bold text-lg">{b.title}</div>
                            <div className="text-sm text-slate-500">{b.description || 'No description'}</div>
                        </div>
                    </Card>
                ))}
            </div>
        </div>
    );
};

const renderOrders = () => {
    return (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 space-y-4">
                {orders.map(order => (
                    <div key={order.id} className={`bg-white border rounded-lg p-4 cursor-pointer hover:border-indigo-500 transition ${selectedOrder?.id === order.id ? 'border-indigo-500 ring-1 ring-indigo-500' : ''}`} onClick={() => setSelectedOrder(order)}>
                        <div className="flex justify-between items-start mb-2">
                            <div>
                                <div className="font-bold text-slate-900">{order.tenant?.name || 'Unknown Merchant'}</div>
                                <div className="text-xs text-slate-500">{new Date(order.createdAt).toLocaleString()}</div>
                            </div>
                            <Badge variant={order.status === 'PENDING' ? 'warning' : order.status === 'DELIVERED' ? 'success' : 'default'}>{order.status}</Badge>
                        </div>
                        <div className="flex justify-between items-center text-sm">
                            <div>Total: <span className="font-semibold">Rp {order.totalAmount.toLocaleString('id-ID')}</span></div>
                            <div className="text-slate-500">{order.items.length} Items</div>
                        </div>
                    </div>
                ))}
                {orders.length === 0 && <div className="p-8 text-center text-slate-500 bg-white rounded border">No orders found.</div>}
            </div>

            {/* Order Detail View */}
            <div className="bg-white border rounded-lg p-6 h-fit sticky top-4">
                {selectedOrder ? (
                    <div className="space-y-6">
                        <div>
                            <h3 className="text-lg font-bold mb-1">Order Details</h3>
                            <div className="text-sm text-slate-500">ID: {selectedOrder.id}</div>
                        </div>

                        <div className="space-y-4">
                            <div className="bg-slate-50 p-3 rounded text-sm space-y-2">
                                <div className="flex justify-between"><span>Status</span> <span className="font-medium">{selectedOrder.status}</span></div>
                                <div className="flex justify-between"><span>Payment</span> <span className="font-medium">{selectedOrder.paymentMethod}</span></div>
                                {selectedOrder.couponCode && <div className="flex justify-between text-green-600"><span>Coupon ({selectedOrder.couponCode})</span> <span>-Rp {selectedOrder.discountAmount.toLocaleString('id-ID')}</span></div>}
                                <div className="flex justify-between"><span>Shipping</span> <span className="font-medium">Rp {selectedOrder.shippingCost?.toLocaleString('id-ID')}</span></div>
                            </div>

                            <div className="space-y-2">
                                <div className="font-medium text-sm">Update Status</div>
                                <div className="grid grid-cols-2 gap-2">
                                    {['PENDING', 'PAID', 'PROCESSED', 'SHIPPED', 'DELIVERED', 'CANCELLED'].map(s => (
                                        <Button key={s} size="sm" variant={selectedOrder.status === s ? 'default' : 'outline'}
                                            onClick={() => updateOrderStatus(selectedOrder.id, s)}
                                            className={`text-xs ${selectedOrder.status === s ? 'bg-indigo-600 text-white' : ''}`}
                                        >
                                            {s}
                                        </Button>
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="border-t pt-4">
                            <h4 className="font-medium mb-3">Items</h4>
                            <div className="space-y-3 max-h-60 overflow-y-auto pr-2">
                                {selectedOrder.items.map((item, idx) => (
                                    <div key={idx} className="flex justify-between text-sm">
                                        <div>
                                            <div className="font-medium">{item.product?.name}</div>
                                            <div className="text-xs text-slate-500">{item.quantity} x Rp {item.price.toLocaleString('id-ID')}</div>
                                        </div>
                                        <div className="font-medium">Rp {(item.quantity * item.price).toLocaleString('id-ID')}</div>
                                    </div>
                                ))}
                            </div>
                            <div className="border-t mt-3 pt-3 flex justify-between font-bold">
                                <span>Total</span>
                                <span>Rp {selectedOrder.totalAmount.toLocaleString('id-ID')}</span>
                            </div>
                        </div>
                    </div>
                ) : (
                    <div className="text-center text-slate-400 py-12">Select an order to view details</div>
                )}
            </div>
        </div>
    );
}

return (
    <AdminLayout>
        <div className="flex items-center justify-between mb-8">
            <div>
                <h1 className="text-2xl font-semibold text-slate-900">Marketplace Management</h1>
                <p className="text-slate-500 mt-1">Manage wholesale products, categories, orders, and promotions.</p>
            </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 mb-6 border-b">
            {['products', 'categories', 'promotions', 'banners', 'orders'].map(tab => (
                <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`px-6 py-2 border-b-2 font-medium transition-colors ${activeTab === tab ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
                >
                    {tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
            ))}
        </div>

        {activeTab === 'products' && renderProducts()}
        {activeTab === 'categories' && renderCategories()}
        {activeTab === 'promotions' && renderCoupons()}
        {activeTab === 'banners' && renderBanners()}
        {activeTab === 'orders' && renderOrders()}

        {/* PRODUCT / CATEGORY / COUPON MODAL */}
        {isModalOpen && (
            <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 animate-in fade-in duration-200">
                <div className="bg-white rounded-lg shadow-xl w-full max-w-lg overflow-hidden">
                    <div className="flex justify-between items-center p-6 border-b">
                        <h3 className="text-lg font-semibold">{selectedItem && modalType !== 'coupon' ? `Edit ${modalType}` : `Add New ${modalType}`}</h3>
                        <button onClick={closeModal}><X size={20} className="text-slate-400" /></button>
                    </div>

                    <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
                        {modalType === 'product' ? (
                            <>
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Name</label>
                                    <Input value={productForm.name} onChange={e => setProductForm({ ...productForm, name: e.target.value })} placeholder="Product Name" />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <label className="text-sm font-medium">Category</label>
                                        <select className="flex h-10 w-full rounded-md border bg-white px-3 py-2 text-sm"
                                            value={productForm.categoryId} onChange={e => setProductForm({ ...productForm, categoryId: e.target.value })}>
                                            <option value="" disabled>Select Category</option>
                                            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                                        </select>
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-medium">Price</label>
                                        <Input type="number" value={productForm.price} onChange={e => setProductForm({ ...productForm, price: e.target.value })} placeholder="0" />
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <label className="text-sm font-medium">Stock</label>
                                        <Input type="number" value={productForm.stock} onChange={e => setProductForm({ ...productForm, stock: e.target.value })} placeholder="0" />
                                    </div>
                                    <div className="space-y-2">
                                        <label className="text-sm font-medium">Supplier</label>
                                        <Input value={productForm.supplierName} onChange={e => setProductForm({ ...productForm, supplierName: e.target.value })} placeholder="Supplier Name" />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm font-medium">Image URL</label>
                                    <Input value={productForm.imageUrl} onChange={e => setProductForm({ ...productForm, imageUrl: e.target.value })} placeholder="https://..." />
                                </div>
                            </>
                        ) : modalType === 'category' ? (
                            <div className="space-y-2">
                                <label className="text-sm font-medium">Category Name</label>
                                <Input value={categoryForm.name} onChange={e => setCategoryForm({ ...categoryForm, name: e.target.value })} placeholder="Category Name" />
                            </div>
                        ) : (
                            <>
                                <div className="space-y-2"><label className="text-sm font-medium">Coupon Code</label><Input value={couponForm.code} onChange={e => setCouponForm({ ...couponForm, code: e.target.value.toUpperCase() })} placeholder="e.g. DISKON50" /></div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2"><label className="text-sm font-medium">Type</label><select className="flex h-10 w-full rounded-md border bg-white px-3 py-2 text-sm" value={couponForm.type} onChange={e => setCouponForm({ ...couponForm, type: e.target.value })}><option value="FIXED">Fixed Amount (Rp)</option><option value="PERCENTAGE">Percentage (%)</option><option value="FREE_SHIPPING">Free Shipping</option></select></div>
                                    <div className="space-y-2"><label className="text-sm font-medium">Value</label><Input type="number" value={couponForm.value} onChange={e => setCouponForm({ ...couponForm, value: e.target.value })} placeholder={couponForm.type === 'PERCENTAGE' ? '50' : '10000'} disabled={couponForm.type === 'FREE_SHIPPING'} /></div>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2"><label className="text-sm font-medium">Min Order</label><Input type="number" value={couponForm.minOrder} onChange={e => setCouponForm({ ...couponForm, minOrder: e.target.value })} placeholder="0" /></div>
                                    <div className="space-y-2"><label className="text-sm font-medium">Max Discount</label><Input type="number" value={couponForm.maxDiscount} onChange={e => setCouponForm({ ...couponForm, maxDiscount: e.target.value })} placeholder="Optional for %" /></div>
                                </div>
                            </>
                        ) : (
                        <>
                            <div className="space-y-2"><label className="text-sm font-medium">Title</label><Input value={bannerForm.title} onChange={e => setBannerForm({ ...bannerForm, title: e.target.value })} placeholder="Banner Title" /></div>
                            <div className="space-y-2"><label className="text-sm font-medium">Image URL</label><Input value={bannerForm.imageUrl} onChange={e => setBannerForm({ ...bannerForm, imageUrl: e.target.value })} placeholder="https://..." /></div>
                            <div className="space-y-2"><label className="text-sm font-medium">Description</label><Input value={bannerForm.description} onChange={e => setBannerForm({ ...bannerForm, description: e.target.value })} placeholder="Optional description" /></div>
                        </>
                            )}
                    </div>

                    <div className="p-6 border-t bg-slate-50 flex justify-end gap-2">
                        <Button variant="outline" onClick={closeModal}>Cancel</Button>
                        <Button className="bg-indigo-600 text-white" onClick={modalType === 'product' ? handleProductSubmit : modalType === 'category' ? handleCategorySubmit : modalType === 'coupon' ? handleCouponSubmit : handleBannerSubmit}>Save</Button>
                    </div>
                </div>
            </div>
        )}
    </AdminLayout>
);
};

export default Kulakan;
