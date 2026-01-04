import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Plus, Trash, Check, Edit } from 'lucide-react';

const Packages = () => {
    const [packages, setPackages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);

    // Form State
    const [form, setForm] = useState({ name: '', price: '', durationDays: 30, description: '' });
    const [isEditing, setIsEditing] = useState(false);
    const [editId, setEditId] = useState(null);

    const fetchPackages = async () => {
        try {
            const res = await api.get('/admin/packages');
            setPackages(res.data.data);
        } catch (error) {
            console.error("Failed to fetch packages", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPackages();
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (isEditing) {
                await api.put(`/admin/packages/${editId}`, form);
                alert("Package updated successfully");
            } else {
                await api.post('/admin/packages', form);
                alert("Package created successfully");
            }
            setShowModal(false);
            setForm({ name: '', price: '', durationDays: 30, description: '' });
            setIsEditing(false);
            setEditId(null);
            fetchPackages();
        } catch (error) {
            alert(isEditing ? "Failed to update package" : "Failed to create package");
        }
    };

    const handleEdit = (pkg) => {
        setForm({
            name: pkg.name,
            price: pkg.price,
            durationDays: pkg.durationDays,
            description: pkg.description
        });
        setIsEditing(true);
        setEditId(pkg.id);
        setShowModal(true);
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Delete this package?")) return;
        try {
            await api.delete(`/admin/packages/${id}`);
            fetchPackages();
        } catch (error) {
            alert("Failed to delete package");
        }
    };

    const openCreateModal = () => {
        setForm({ name: '', price: '', durationDays: 30, description: '' });
        setIsEditing(false);
        setEditId(null);
        setShowModal(true);
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Subscription Packages</h1>
                    <p className="text-slate-500 mt-1">Manage pricing tiers and subscription options for merchants.</p>
                </div>
                <Button icon={Plus} onClick={openCreateModal}>New Package</Button>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Package Name</Th>
                            <Th>Price</Th>
                            <Th>Duration</Th>
                            <Th>Description</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">Loading...</Td>
                            </Tr>
                        ) : packages.length === 0 ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">No active packages found.</Td>
                            </Tr>
                        ) : packages.map((p) => (
                            <Tr key={p.id}>
                                <Td><span className="font-semibold text-slate-900">{p.name}</span></Td>
                                <Td>{formatCurrency(p.price)}</Td>
                                <Td>{p.durationDays} Days</Td>
                                <Td><span className="text-slate-500 text-sm truncate max-w-xs block">{p.description}</span></Td>
                                <Td>
                                    <div className="flex items-center">
                                        <button onClick={() => handleEdit(p)} className="text-blue-500 hover:text-blue-700 p-2">
                                            <Edit size={18} />
                                        </button>
                                        <button onClick={() => handleDelete(p.id)} className="text-red-500 hover:text-red-700 p-2">
                                            <Trash size={18} />
                                        </button>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            {/* Create Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <Card className="w-full max-w-md p-6">
                        <h2 className="text-xl font-bold mb-4">Create New Package</h2>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Package Name</label>
                                <Input required placeholder="e.g. Pro Plan" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Price (IDR)</label>
                                    <Input required type="number" placeholder="50000" value={form.price} onChange={e => setForm({ ...form, price: e.target.value })} />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Duration (Days)</label>
                                    <Input required type="number" value={form.durationDays} onChange={e => setForm({ ...form, durationDays: e.target.value })} />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Benefit Description</label>
                                <textarea
                                    className="w-full border border-slate-300 rounded-lg p-2 text-sm focus:ring-2 focus:ring-primary-500 outline-none"
                                    rows="3"
                                    placeholder="List benefits..."
                                    value={form.description}
                                    onChange={e => setForm({ ...form, description: e.target.value })}
                                ></textarea>
                            </div>
                            <div className="flex justify-end space-x-3 pt-4">
                                <Button type="button" variant="ghost" onClick={() => setShowModal(false)}>Cancel</Button>
                                <Button type="submit">{isEditing ? 'Update Package' : 'Create Package'}</Button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
        </AdminLayout>
    );
};

export default Packages;
