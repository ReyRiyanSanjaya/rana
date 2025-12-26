import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/button';

const ManageMenu = () => {
    const { storeId } = useParams();
    const navigate = useNavigate();
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [currentProduct, setCurrentProduct] = useState(null); // null = create mode

    // Form State
    const [formData, setFormData] = useState({
        name: '',
        basePrice: 0,
        sellingPrice: 0,
        stock: 0,
        description: ''
    });

    useEffect(() => {
        fetchProducts();
    }, [storeId]);

    const fetchProducts = async () => {
        try {
            setLoading(true);
            const res = await api.get(`/admin/merchants/${storeId}/products`);
            setProducts(res.data.data);
        } catch (error) {
            console.error(error);
            alert("Failed to fetch products");
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (product = null) => {
        if (product) {
            setCurrentProduct(product);
            setFormData({
                name: product.name,
                basePrice: product.basePrice,
                sellingPrice: product.sellingPrice,
                stock: product.stock,
                description: product.description || ''
            });
        } else {
            setCurrentProduct(null);
            setFormData({
                name: '',
                basePrice: 0,
                sellingPrice: 0,
                stock: 0,
                description: ''
            });
        }
        setIsModalOpen(true);
    };

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setCurrentProduct(null);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (currentProduct) {
                // Update
                await api.put(`/admin/merchants/${storeId}/products/${currentProduct.id}`, formData);
                alert("Product updated!");
            } else {
                // Create
                await api.post(`/admin/merchants/${storeId}/products`, formData);
                alert("Product created!");
            }
            handleCloseModal();
            fetchProducts();
        } catch (error) {
            console.error(error);
            alert("Failed to save product");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Are you sure you want to delete this product?")) return;
        try {
            await api.delete(`/admin/merchants/${storeId}/products/${id}`);
            alert("Product deleted");
            fetchProducts();
        } catch (error) {
            console.error(error);
            alert("Failed to delete product");
        }
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Manage Menu</h1>
                    <p className="text-slate-500 mt-1">Add, edit, or remove products for this store.</p>
                </div>
                <div className="flex gap-4">
                    <Button variant="outline" onClick={() => navigate('/merchants')}>Back to Merchants</Button>
                    <Button onClick={() => handleOpenModal()}>+ Add Product</Button>
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Product Name</Th>
                            <Th>Base Price</Th>
                            <Th>Selling Price</Th>
                            <Th>Stock</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">Loading menu...</Td>
                            </Tr>
                        ) : products.length === 0 ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">No products found.</Td>
                            </Tr>
                        ) : products.map((p) => (
                            <Tr key={p.id}>
                                <Td>
                                    <div className="font-medium text-slate-900">{p.name}</div>
                                    <div className="text-xs text-slate-500 truncate max-w-xs">{p.description}</div>
                                </Td>
                                <Td>{formatCurrency(p.basePrice)}</Td>
                                <Td>{formatCurrency(p.sellingPrice)}</Td>
                                <Td>{p.stock}</Td>
                                <Td>
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => handleOpenModal(p)}
                                            className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                                        >
                                            Edit
                                        </button>
                                        <button
                                            onClick={() => handleDelete(p.id)}
                                            className="text-red-600 hover:text-red-800 text-sm font-medium"
                                        >
                                            Delete
                                        </button>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6 animate-fade-in">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold text-slate-900">
                                {currentProduct ? 'Edit Product' : 'Add New Product'}
                            </h2>
                            <button onClick={handleCloseModal} className="text-slate-400 hover:text-slate-600">
                                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Product Name</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none transition"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Base Price (Modal)</label>
                                    <input
                                        type="number"
                                        required
                                        className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none transition"
                                        value={formData.basePrice}
                                        onChange={(e) => setFormData({ ...formData, basePrice: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Selling Price</label>
                                    <input
                                        type="number"
                                        required
                                        className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none transition"
                                        value={formData.sellingPrice}
                                        onChange={(e) => setFormData({ ...formData, sellingPrice: e.target.value })}
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Stock</label>
                                <input
                                    type="number"
                                    required
                                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none transition"
                                    value={formData.stock}
                                    onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Description (Optional)</label>
                                <textarea
                                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none transition"
                                    rows="3"
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                />
                            </div>

                            <div className="flex justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                                <Button type="button" variant="ghost" onClick={handleCloseModal}>Cancel</Button>
                                <Button type="submit">{currentProduct ? 'Save Changes' : 'Create Product'}</Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default ManageMenu;
