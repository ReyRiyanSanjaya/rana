import React, { useState, useEffect, useRef } from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import { Button } from '../components/ui/Button';
import { Search, Filter, Plus, MoreHorizontal, Package, Edit, Trash2, X, List, ShoppingCart, Truck, CheckCircle, QrCode, Printer } from 'lucide-react';
import api from '../api';
import { QRCodeCanvas } from 'qrcode.react';
import { useReactToPrint } from 'react-to-print';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "../components/ui/dropdown-menu";
import Input from "../components/ui/Input";
 

const Kulakan = () => {
    const [activeTab, setActiveTab] = useState('orders'); // Default to orders for monitoring

    // Data States
    const [products, setProducts] = useState([]);
    const [categories, setCategories] = useState([]);
    const [orders, setOrders] = useState([]);
    const [coupons, setCoupons] = useState([]);
    const [banners, setBanners] = useState([]);
    const [loading, setLoading] = useState(true);
    const [orderPage, setOrderPage] = useState(1);
    const [orderPerPage, setOrderPerPage] = useState(9);
    const [productPage, setProductPage] = useState(1);
    const [productPerPage, setProductPerPage] = useState(10);

    // Filter States
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('ALL');
    const [categoryFilter, setCategoryFilter] = useState('Semua');
    const [sortField, setSortField] = useState('price');
    const [sortDir, setSortDir] = useState('asc');
    const [minPrice, setMinPrice] = useState('');
    const [maxPrice, setMaxPrice] = useState('');
    const [scanCode, setScanCode] = useState('');

    // Modal States
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [modalType, setModalType] = useState('product'); // 'product', 'category', 'coupon'
    const [selectedItem, setSelectedItem] = useState(null);

    // Helper for Orders Modal/View
    const [selectedOrder, setSelectedOrder] = useState(null);
    const printRef = useRef();

    // Forms
    const [productForm, setProductForm] = useState({
        name: '', categoryId: '', price: '', stock: '', supplierName: '', description: '', imageUrl: '', isActive: true
    });
    const [categoryForm, setCategoryForm] = useState({ name: '', isActive: true });
    const [couponForm, setCouponForm] = useState({
        code: '', type: 'FIXED', value: '', minOrder: '', maxDiscount: '', startDate: '', endDate: '', isActive: true
    });
    const [bannerForm, setBannerForm] = useState({ title: '', imageUrl: '', description: '', isActive: true });

    // Auto Refresh Logic
    useEffect(() => {
        fetchData();

        // Polling for orders every 10 seconds if on orders tab
        let interval;
        if (activeTab === 'orders') {
            interval = setInterval(() => {
                fetchOrders(true); // silent refresh
            }, 10000);
        }
        return () => clearInterval(interval);
    }, [activeTab]);

    const fetchData = () => {
        setLoading(true);
        if (activeTab === 'products') {
            fetchProducts();
            fetchCategories();
        } else if (activeTab === 'categories') {
            fetchCategories();
        } else if (activeTab === 'orders') {
            fetchOrders();
        } else if (activeTab === 'promotions') {
            fetchCoupons();
        } else if (activeTab === 'banners') {
            fetchBanners();
        }
    };

    const fetchProducts = async () => {
        try {
            const params = new URLSearchParams();
            if (categoryFilter) params.append('category', categoryFilter);
            if (searchTerm) params.append('search', searchTerm);
            const res = await api.get(`/wholesale/products?${params.toString() || ''}`);
            if (res.data.status === 'success') setProducts(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchCategories = async () => {
        try {
            const res = await api.get('/wholesale/categories');
            if (res.data.status === 'success') setCategories(res.data.data);
        } catch (error) { console.error(error); } finally { setLoading(false); }
    };

    const fetchOrders = async (silent = false) => {
        if (!silent) setLoading(true);
        try {
            const params = new URLSearchParams();
            if (statusFilter && statusFilter !== 'ALL') params.append('status', statusFilter);
            const res = await api.get(`/wholesale/orders?${params.toString() || ''}`);
            if (res.data.status === 'success') {
                setOrders(res.data.data);
                // Update selected order if open
                if (selectedOrder) {
                    const updated = res.data.data.find(o => o.id === selectedOrder.id);
                    if (updated) setSelectedOrder(updated);
                }
            }
        } catch (error) { console.error(error); } finally { if (!silent) setLoading(false); }
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

    const deleteProduct = async (id, e) => {
        e.stopPropagation();
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
                await api.put(`/wholesale/coupons/${selectedItem.id}`, couponForm);
            } else {
                await api.post('/wholesale/coupons', couponForm);
            }
            closeModal();
            fetchCoupons();
        } catch (error) { alert("Failed save coupon: " + (error.response?.data?.message || "")); }
    };

    const deleteCoupon = async (id, e) => {
        e.stopPropagation();
        if (!confirm("Delete coupon?")) return;
        await api.delete(`/wholesale/coupons/${id}`);
        fetchCoupons();
    };

    const toggleCoupon = async (id, isActive, e) => {
        e.stopPropagation();
        await api.patch(`/wholesale/coupons/${id}`, { isActive: !isActive });
        fetchCoupons();
    }

    // --- BANNER HANDLERS ---
    const handleBannerSubmit = async () => {
        try {
            if (!bannerForm.title || !bannerForm.imageUrl) return alert("Title/Image required");
            if (selectedItem) {
                await api.put(`/wholesale/banners/${selectedItem.id}`, bannerForm);
            } else {
                await api.post('/wholesale/banners', bannerForm);
            }
            closeModal();
            fetchBanners();
        } catch (error) { alert("Failed save banner"); }
    };

    const deleteBanner = async (id, e) => {
        e.stopPropagation();
        if (!confirm("Delete banner?")) return;
        await api.delete(`/wholesale/banners/${id}`);
        fetchBanners();
    };

    // --- ORDER HANDLERS ---
    const updateOrderStatus = async (id, status, pickupCode) => {
        try {
            await api.put(`/wholesale/orders/${id}/status`, { status, pickupCode });
            fetchOrders(); // Refresh immediately
        } catch (e) { alert("Failed update status"); }
    };

    // --- PRINTING ---
    const handlePrint = useReactToPrint({
        content: () => printRef.current,
        documentTitle: `Invoice-${selectedOrder?.id}`,
    });

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
        setSelectedOrder(null);
    };

    // --- RENDERERS ---

    // INVOICE COMPONENT (Hidden from screen, visible in print)
    const InvoiceToPrint = () => {
        if (!selectedOrder) return null;
        return (
            <div className="hidden print:block"> 
                <div ref={printRef} className="p-8 border border-slate-200 bg-white">
                    <div className="flex justify-between mb-8">
                        <div>
                            <h1 className="text-2xl font-bold text-slate-800">INVOICE / DELIVERY NOTE</h1>
                            <p className="text-sm text-slate-500">Order ID: {selectedOrder.id}</p>
                            <p className="text-sm text-slate-500">Date: {new Date(selectedOrder.createdAt).toLocaleDateString()}</p>
                        </div>
                        <div className="text-right">
                            <h2 className="text-xl font-bold text-indigo-600">Rana Wholesale</h2>
                            <p className="text-sm text-slate-500">Distributor Center</p>
                        </div>
                    </div>

                    <div className="mb-8 p-4 bg-slate-50 rounded">
                        <h3 className="font-semibold mb-2">Ship To:</h3>
                        <p>{selectedOrder.shippingAddress}</p>
                    </div>

                    <table className="w-full mb-8">
                        <thead>
                            <tr className="border-b border-slate-300">
                                <th className="text-left py-2">Item</th>
                                <th className="text-right py-2">Qty</th>
                                <th className="text-right py-2">Price</th>
                                <th className="text-right py-2">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            {selectedOrder.items?.map((item, idx) => (
                                <tr key={idx} className="border-b border-slate-100">
                                    <td className="py-2">{item.productName}</td>
                                    <td className="text-right py-2">{item.quantity}</td>
                                    <td className="text-right py-2">Rp {item.price.toLocaleString()}</td>
                                    <td className="text-right py-2">Rp {(item.price * item.quantity).toLocaleString()}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>

                    <div className="flex justify-end mb-12">
                        <div className="w-64">
                            <div className="flex justify-between mb-2">
                                <span>Shipping:</span>
                                <span>Rp {selectedOrder.shippingCost.toLocaleString()}</span>
                            </div>
                             <div className="flex justify-between mb-2">
                                <span>Service Fee:</span>
                                <span>Rp {selectedOrder.serviceFee.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between font-bold text-lg border-t pt-2">
                                <span>Total:</span>
                                <span>Rp {selectedOrder.totalAmount.toLocaleString()}</span>
                            </div>
                        </div>
                    </div>

                    <div className="flex flex-col items-center justify-center border-t pt-8">
                        <p className="font-bold mb-4">SCAN UPON DELIVERY</p>
                        <QRCodeCanvas value={selectedOrder.pickupCode || selectedOrder.id} size={150} />
                        <p className="text-xs text-slate-400 mt-2">{selectedOrder.pickupCode || selectedOrder.id}</p>
                    </div>
                </div>
            </div>
        );
    };

    const renderOrders = () => {
        const pagedOrders = orders.slice((orderPage - 1) * orderPerPage, (orderPage - 1) * orderPerPage + orderPerPage);
        const totalOrderPages = Math.max(1, Math.ceil(orders.length / orderPerPage));
        // Filter logic could go here
        return (
            <div>
                <InvoiceToPrint />
                <div className="flex items-center gap-2 mb-4">
                    <Input placeholder="Scan/Enter Pickup Code" value={scanCode} onChange={(e)=>setScanCode(e.target.value)} />
                    <Button
                        variant="outline"
                        onClick={async ()=>{
                            if (!scanCode) return;
                            try {
                                const res = await api.post('/wholesale/orders/scan', { pickupCode: scanCode });
                                if (res.data.status === 'success') {
                                    fetchOrders();
                                    setScanCode('');
                                    alert('Order marked as DELIVERED');
                                }
                            } catch {
                                alert('Failed to scan code');
                            }
                        }}
                    >
                        Confirm Delivery
                    </Button>
                </div>
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                        <select
                            className="px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                        >
                            <option value="ALL">All</option>
                            <option value="PENDING">Pending</option>
                            <option value="PAID">Paid</option>
                            <option value="PROCESSED">Processed</option>
                            <option value="SHIPPED">Shipped</option>
                            <option value="DELIVERED">Delivered</option>
                            <option value="CANCELLED">Cancelled</option>
                        </select>
                        <Button variant="outline" onClick={() => fetchOrders()}>Apply</Button>
                    </div>
                    <Button
                        variant="secondary"
                        onClick={() => {
                            const rows = orders.map(o => ({
                                id: o.id,
                                status: o.status,
                                items: o.items?.length || 0,
                                totalAmount: o.totalAmount,
                                serviceFee: o.serviceFee,
                                shippingCost: o.shippingCost,
                                paymentMethod: o.paymentMethod,
                                createdAt: new Date(o.createdAt).toISOString()
                            }));
                            const headers = Object.keys(rows[0] || { id: '', status: '', items: 0, totalAmount: 0, serviceFee: 0, shippingCost: 0, paymentMethod: '', createdAt: '' });
                            const csv = [headers.join(','), ...rows.map(r => headers.map(h => r[h]).join(','))].join('\n');
                            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
                            const url = URL.createObjectURL(blob);
                            const a = document.createElement('a');
                            a.href = url;
                            a.download = `orders_${Date.now()}.csv`;
                            a.click();
                            URL.revokeObjectURL(url);
                        }}
                    >
                        Export CSV
                    </Button>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {pagedOrders.map(order => (
                        <div key={order.id} className="bg-white border rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow cursor-pointer" onClick={() => setSelectedOrder(order)}>
                            <div className="flex justify-between items-start mb-3">
                                <div>
                                    <div className="text-xs text-slate-400 mb-1">{new Date(order.createdAt).toLocaleString()}</div>
                                    <div className="font-bold text-slate-700">{order.id.substring(0, 8)}...</div>
                                </div>
                                <Badge variant={
                                    order.status === 'COMPLETED' ? 'success' :
                                    order.status === 'SHIPPED' ? 'warning' :
                                    order.status === 'CANCELLED' ? 'destructive' : 'secondary'
                                }>
                                    {order.status}
                                </Badge>
                            </div>
                            <div className="mb-3">
                                <div className="text-sm font-medium">{order.items?.length} Items</div>
                                <div className="text-sm text-slate-500">Total: Rp {order.totalAmount.toLocaleString()}</div>
                            </div>
                             {/* Proof of Transfer Preview */}
                             {order.proofUrl && (
                                <div className="mb-3">
                                    <div className="text-xs text-indigo-600 font-semibold mb-1">Payment Proof Attached</div>
                                </div>
                            )}

                            <div className="flex gap-2 mt-4 pt-4 border-t">
                                {order.status === 'PENDING' && (
                                    <Button size="sm" className="w-full bg-indigo-600 text-white" onClick={(e) => {
                                        e.stopPropagation();
                                        updateOrderStatus(order.id, 'PROCESSED');
                                    }}>Process</Button>
                                )}
                                {order.status === 'PROCESSED' && (
                                    <Button size="sm" className="w-full bg-orange-500 text-white" onClick={(e) => {
                                        e.stopPropagation();
                                        updateOrderStatus(order.id, 'SHIPPED');
                                    }}>Ship</Button>
                                )}
                                {order.status === 'SHIPPED' && (
                                     <div className="w-full text-center text-xs text-slate-500 italic">Waiting for scan...</div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
                <div className="flex items-center justify-between mt-4">
                    <div className="flex items-center gap-2">
                        <span className="text-sm text-slate-600">Rows per page</span>
                        <select
                            className="px-2 py-1 border rounded text-sm bg-white"
                            value={orderPerPage}
                            onChange={(e) => { setOrderPerPage(parseInt(e.target.value)); setOrderPage(1); }}
                        >
                            <option value={6}>6</option>
                            <option value={9}>9</option>
                            <option value={12}>12</option>
                        </select>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" onClick={() => setOrderPage(p => Math.max(1, p - 1))}>Prev</Button>
                        <span className="text-sm">Page {orderPage} / {totalOrderPages}</span>
                        <Button variant="outline" onClick={() => setOrderPage(p => Math.min(totalOrderPages, p + 1))}>Next</Button>
                    </div>
                </div>

                {/* ORDER DETAIL MODAL */}
                {selectedOrder && (
                    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                        <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
                            <div className="flex justify-between items-center mb-6">
                                <h3 className="text-xl font-bold">Order Details</h3>
                                <button onClick={() => setSelectedOrder(null)}><X size={24} /></button>
                            </div>

                            <div className="grid grid-cols-2 gap-6 mb-6">
                                <div>
                                    <h4 className="text-sm font-semibold text-slate-500 mb-2">Customer Info</h4>
                                    <p className="font-medium">{selectedOrder.tenantId}</p>
                                    <p className="text-sm text-slate-600">{selectedOrder.shippingAddress}</p>
                                </div>
                                <div>
                                    <h4 className="text-sm font-semibold text-slate-500 mb-2">Order Info</h4>
                                    <Badge className="mb-2">{selectedOrder.status}</Badge>
                                    <p className="text-sm">Method: {selectedOrder.paymentMethod}</p>
                                </div>
                            </div>

                             {selectedOrder.proofUrl && (
                            <div className="mb-6 p-4 border rounded bg-slate-50">
                                <h4 className="text-sm font-semibold text-slate-500 mb-2">Payment Proof</h4>
                                <img src={selectedOrder.proofUrl} alt="Transfer Proof" className="max-h-64 object-contain mx-auto rounded border" />
                            </div>
                            )}
                            {!selectedOrder.proofUrl && (
                                <div className="mb-6 p-4 border rounded bg-slate-50">
                                    <h4 className="text-sm font-semibold text-slate-500 mb-2">Upload Payment Proof</h4>
                                    <input
                                        type="file"
                                        accept="image/*"
                                        onChange={async (e) => {
                                            const file = e.target.files?.[0];
                                            if (!file) return;
                                            const fd = new FormData();
                                            fd.append('file', file);
                                            fd.append('orderId', selectedOrder.id);
                                            try {
                                                await api.post('/wholesale/upload-proof', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
                                                fetchOrders();
                                            } catch {
                                                alert('Failed to upload proof');
                                            }
                                            e.target.value = '';
                                        }}
                                    />
                                </div>
                            )}

                            <div className="border rounded-lg overflow-hidden mb-6">
                                <table className="w-full">
                                    <thead className="bg-slate-50">
                                        <tr>
                                            <th className="px-4 py-2 text-left text-xs font-semibold text-slate-500">Item</th>
                                            <th className="px-4 py-2 text-right text-xs font-semibold text-slate-500">Qty</th>
                                            <th className="px-4 py-2 text-right text-xs font-semibold text-slate-500">Price</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {selectedOrder.items?.map((item, i) => (
                                            <tr key={i} className="border-t border-slate-100">
                                                <td className="px-4 py-2">{item.productName}</td>
                                                <td className="px-4 py-2 text-right">{item.quantity}</td>
                                                <td className="px-4 py-2 text-right">Rp {item.price.toLocaleString()}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>

                            <div className="flex justify-end gap-2">
                                <Button variant="outline" onClick={handlePrint}><Printer size={16} className="mr-2"/> Print Invoice / QR</Button>
                                {selectedOrder.status === 'PENDING' && (
                                    <Button className="bg-green-600 text-white" onClick={() => updateOrderStatus(selectedOrder.id, 'PAID')}>Verify Payment (Mark PAID)</Button>
                                )}
                                {selectedOrder.status === 'PAID' && (
                                    <Button className="bg-indigo-600 text-white" onClick={() => updateOrderStatus(selectedOrder.id, 'PROCESSED')}>Process Order</Button>
                                )}
                                {selectedOrder.status === 'PROCESSED' && (
                                    <>
                                        <Input placeholder="Pickup/Tracking Code" value={selectedOrder.pickupCode || ''} onChange={(e)=>setSelectedOrder({...selectedOrder, pickupCode: e.target.value})} />
                                        <Button className="bg-orange-500 text-white" onClick={() => updateOrderStatus(selectedOrder.id, 'SHIPPED', selectedOrder.pickupCode)}>Ship Order</Button>
                                    </>
                                )}
                                <Button variant="outline" onClick={() => setSelectedOrder(null)}>Close</Button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        );
    };

    // ... (Keep existing Product, Category, Coupon renderers) ...
    const renderProducts = () => {
        const filtered = products
            .filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()))
            .filter(p => {
                const price = p.price || 0;
                const min = minPrice ? parseFloat(minPrice) : null;
                const max = maxPrice ? parseFloat(maxPrice) : null;
                if (min !== null && price < min) return false;
                if (max !== null && price > max) return false;
                return true;
            })
            .sort((a,b) => {
                const va = sortField === 'price' ? (a.price || 0) : (a.stock || 0);
                const vb = sortField === 'price' ? (b.price || 0) : (b.stock || 0);
                return sortDir === 'asc' ? va - vb : vb - va;
            });
        const paged = filtered.slice((productPage - 1) * productPerPage, (productPage - 1) * productPerPage + productPerPage);
        const totalPages = Math.max(1, Math.ceil(filtered.length / productPerPage));
        return (
            <div>
                <div className="flex justify-between items-center mb-4">
                    <div className="relative w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <Input placeholder="Search products..." className="pl-10" value={searchTerm} onChange={e => setSearchTerm(e.target.value)} />
                    </div>
                    <div className="flex items-center gap-2">
                        <select
                            className="px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                            value={categoryFilter}
                            onChange={(e) => setCategoryFilter(e.target.value)}
                        >
                            <option value="Semua">Semua</option>
                            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                        </select>
                        <Input placeholder="Min Price" type="number" value={minPrice} onChange={(e)=>setMinPrice(e.target.value)} />
                        <Input placeholder="Max Price" type="number" value={maxPrice} onChange={(e)=>setMaxPrice(e.target.value)} />
                        <select
                            className="px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                            value={sortField}
                            onChange={(e) => setSortField(e.target.value)}
                        >
                            <option value="price">Price</option>
                            <option value="stock">Stock</option>
                        </select>
                        <select
                            className="px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                            value={sortDir}
                            onChange={(e) => setSortDir(e.target.value)}
                        >
                            <option value="asc">Asc</option>
                            <option value="desc">Desc</option>
                        </select>
                        <Button variant="outline" onClick={() => fetchProducts()}>Apply</Button>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button onClick={() => openModal('product')} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Product</Button>
                        <input
                            id="csvImport"
                            type="file"
                            accept=".csv"
                            style={{ display: 'none' }}
                            onChange={async (e) => {
                                const file = e.target.files?.[0];
                                if (!file) return;
                                const text = await file.text();
                                const lines = text.split(/\r?\n/).filter(l => l.trim().length > 0);
                                const header = lines[0].split(',').map(h => h.trim());
                                const required = ['name','categoryId','price','stock'];
                                if (!required.every(r => header.includes(r))) {
                                    alert('CSV headers wajib: name, categoryId, price, stock');
                                    e.target.value = '';
                                    return;
                                }
                                const idx = Object.fromEntries(header.map((h,i)=>[h,i]));
                                let success = 0, fail = 0;
                                for (let i=1;i<lines.length;i++){
                                    const cols = lines[i].split(',').map(c=>c.trim());
                                    if (cols.length < header.length) continue;
                                    const payload = {
                                        name: cols[idx['name']],
                                        categoryId: cols[idx['categoryId']],
                                        price: parseFloat(cols[idx['price']]),
                                        stock: parseInt(cols[idx['stock']]),
                                        supplierName: idx['supplierName']!==undefined ? cols[idx['supplierName']] : undefined,
                                        imageUrl: idx['imageUrl']!==undefined ? cols[idx['imageUrl']] : undefined,
                                        description: idx['description']!==undefined ? cols[idx['description']] : undefined
                                    };
                                    try { await api.post('/wholesale/products', payload); success++; }
                                    catch { fail++; }
                                }
                                alert(`Import selesai: ${success} sukses, ${fail} gagal`);
                                fetchProducts();
                                e.target.value = '';
                            }}
                        />
                        <Button variant="outline" onClick={() => document.getElementById('csvImport').click()}>Import CSV</Button>
                    </div>
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
                                paged.map(p => (
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
                                <Button variant="ghost" size="sm" className="text-red-500 hover:text-red-700 hover:bg-red-50" onClick={() => deleteProduct(p.id)}><Trash2 size={16} /></Button>
                            </div>
                                        </td>
                                    </tr>
                                ))}
                        </tbody>
                    </table>
                </div>
                <div className="flex items-center justify-between mt-4">
                    <div className="flex items-center gap-2">
                        <span className="text-sm text-slate-600">Rows per page</span>
                        <select
                            className="px-2 py-1 border rounded text-sm bg-white"
                            value={productPerPage}
                            onChange={(e) => { setProductPerPage(parseInt(e.target.value)); setProductPage(1); }}
                        >
                            <option value={10}>10</option>
                            <option value={20}>20</option>
                            <option value={50}>50</option>
                        </select>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" onClick={() => setProductPage(p => Math.max(1, p - 1))}>Prev</Button>
                        <span className="text-sm">Page {productPage} / {totalPages}</span>
                        <Button variant="outline" onClick={() => setProductPage(p => Math.min(totalPages, p + 1))}>Next</Button>
                    </div>
                </div>
            </div>
        );
    };

    const renderCategories = () => (
         <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
             <div className="col-span-1 md:col-span-3 flex justify-end">
                <Button onClick={() => openModal('category')}><Plus size={18} className="mr-2" /> Add Category</Button>
             </div>
             {categories.map(c => (
                 <div key={c.id} className="bg-white p-4 rounded border flex justify-between items-center">
                     <span className="font-medium">{c.name}</span>
                     <div className="flex gap-2">
                         <Badge variant={c.isActive ? 'success' : 'secondary'}>{c.isActive ? 'Active' : 'Inactive'}</Badge>
                         <Button
                            variant="outline"
                            size="sm"
                            onClick={async () => {
                                await api.put(`/wholesale/categories/${c.id}`, { isActive: !c.isActive });
                                fetchCategories();
                            }}
                         >
                            {c.isActive ? 'Deactivate' : 'Activate'}
                         </Button>
                         <Button variant="outline" size="sm" onClick={() => openModal('category', c)}><Edit size={16}/></Button>
                         <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50" onClick={() => deleteCategory(c.id)}><Trash2 size={16}/></Button>
                     </div>
                 </div>
             ))}
         </div>
    );

    const renderCoupons = () => (
        <div className="space-y-4">
             <div className="flex justify-end">
                <Button onClick={() => openModal('coupon')}><Plus size={18} className="mr-2" /> Add Coupon</Button>
             </div>
             {coupons.map(c => (
                 <div key={c.id} className="bg-white p-4 rounded border flex justify-between items-center">
                     <div>
                         <div className="font-bold text-lg">{c.code}</div>
                         <div className="text-sm text-slate-500">Value: {c.value} ({c.type})</div>
                     </div>
                     <div className="flex gap-2 items-center">
                        <Badge variant={c.isActive ? 'success' : 'secondary'}>{c.isActive ? 'Active' : 'Inactive'}</Badge>
                         <Button variant="outline" size="sm" onClick={() => openModal('coupon', c)}><Edit size={16}/></Button>
                         <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50" onClick={(e) => deleteCoupon(c.id, e)}><Trash2 size={16}/></Button>
                     </div>
                 </div>
             ))}
        </div>
    );

     const renderBanners = () => (
        <div className="space-y-4">
             <div className="flex justify-end">
                <Button onClick={() => openModal('banner')}><Plus size={18} className="mr-2" /> Add Banner</Button>
             </div>
             {banners.map(b => (
                 <div key={b.id} className="bg-white p-4 rounded border flex justify-between items-center">
                     <div className="flex items-center gap-4">
                         <img src={b.imageUrl} className="w-24 h-12 object-cover rounded" />
                         <div className="font-medium">{b.title}</div>
                     </div>
                     <div className="flex gap-2 items-center">
                         <Badge variant={b.isActive ? 'success' : 'secondary'}>{b.isActive ? 'Active' : 'Inactive'}</Badge>
                         <Button variant="outline" size="sm" onClick={() => openModal('banner', b)}><Edit size={16}/></Button>
                         <Button
                            variant="outline"
                            size="sm"
                            onClick={async () => {
                                await api.put(`/wholesale/banners/${b.id}`, { isActive: !b.isActive });
                                fetchBanners();
                            }}
                         >
                            {b.isActive ? 'Deactivate' : 'Activate'}
                         </Button>
                         <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50" onClick={(e) => deleteBanner(b.id, e)}><Trash2 size={16}/></Button>
                     </div>
                 </div>
             ))}
        </div>
    );

    return (
        <AdminLayout title="Wholesale Management">
            <div className="flex gap-4 mb-6 border-b">
                {['orders', 'products', 'categories', 'promotions', 'banners'].map(tab => (
                    <button
                        key={tab}
                        onClick={() => setActiveTab(tab)}
                        className={`pb-2 px-4 capitalize font-medium ${activeTab === tab ? 'border-b-2 border-indigo-600 text-indigo-600' : 'text-slate-500'}`}
                    >
                        {tab}
                    </button>
                ))}
            </div>

            {loading ? <div className="text-center py-12">Loading...</div> : (
                <>
                    {activeTab === 'orders' && renderOrders()}
                    {activeTab === 'products' && renderProducts()}
                    {activeTab === 'categories' && renderCategories()}
                    {activeTab === 'promotions' && renderCoupons()}
                    {activeTab === 'banners' && renderBanners()}
                </>
            )}

            {/* MODALS */}
            {isModalOpen && (
                <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
                        <h3 className="text-xl font-bold mb-4 capitalize">{selectedItem ? 'Edit' : 'Add'} {modalType}</h3>
                        
                        <div className="space-y-4">
                            {modalType === 'product' && (
                                <>
                                    <Input label="Product Name" value={productForm.name} onChange={e => setProductForm({...productForm, name: e.target.value})} />
                                    <Input label="Price" type="number" value={productForm.price} onChange={e => setProductForm({...productForm, price: e.target.value})} />
                                    <Input label="Stock" type="number" value={productForm.stock} onChange={e => setProductForm({...productForm, stock: e.target.value})} />
                                    <Input label="Supplier" value={productForm.supplierName} onChange={e => setProductForm({...productForm, supplierName: e.target.value})} />
                                    <Input label="Image URL" value={productForm.imageUrl} onChange={e => setProductForm({...productForm, imageUrl: e.target.value})} />
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Category</label>
                                        <select 
                                            className="w-full border rounded p-2"
                                            value={productForm.categoryId}
                                            onChange={e => setProductForm({...productForm, categoryId: e.target.value})}
                                        >
                                            <option value="">Select Category</option>
                                            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                                        </select>
                                    </div>
                                </>
                            )}
                            
                            {modalType === 'category' && (
                                <Input label="Category Name" value={categoryForm.name} onChange={e => setCategoryForm({...categoryForm, name: e.target.value})} />
                            )}

                            {modalType === 'coupon' && (
                                <>
                                    <Input label="Code" value={couponForm.code} onChange={e => setCouponForm({...couponForm, code: e.target.value})} />
                                    <Input label="Value" type="number" value={couponForm.value} onChange={e => setCouponForm({...couponForm, value: e.target.value})} />
                                    <select className="w-full border rounded p-2" value={couponForm.type} onChange={e => setCouponForm({...couponForm, type: e.target.value})}>
                                        <option value="FIXED">Fixed Amount</option>
                                        <option value="PERCENTAGE">Percentage</option>
                                        <option value="FREE_SHIPPING">Free Shipping</option>
                                    </select>
                                    <Input label="Min Order" type="number" value={couponForm.minOrder} onChange={e => setCouponForm({...couponForm, minOrder: e.target.value})} />
                                    <Input label="Max Discount" type="number" value={couponForm.maxDiscount} onChange={e => setCouponForm({...couponForm, maxDiscount: e.target.value})} />
                                    <Input label="Start Date" type="date" value={couponForm.startDate} onChange={e => setCouponForm({...couponForm, startDate: e.target.value})} />
                                    <Input label="End Date" type="date" value={couponForm.endDate} onChange={e => setCouponForm({...couponForm, endDate: e.target.value})} />
                                </>
                            )}

                             {modalType === 'banner' && (
                                <>
                                    <Input label="Title" value={bannerForm.title} onChange={e => setBannerForm({...bannerForm, title: e.target.value})} />
                                    <Input label="Image URL" value={bannerForm.imageUrl} onChange={e => setBannerForm({...bannerForm, imageUrl: e.target.value})} />
                                </>
                            )}
                        </div>

                         <div className="flex justify-end gap-2 mt-6">
                            <Button variant="outline" onClick={closeModal}>Cancel</Button>
                            <Button 
                                onClick={
                                    modalType === 'product' ? handleProductSubmit : 
                                    modalType === 'category' ? handleCategorySubmit : 
                                    modalType === 'coupon' ? handleCouponSubmit :
                                    handleBannerSubmit
                                }
                            >Save</Button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Kulakan;
