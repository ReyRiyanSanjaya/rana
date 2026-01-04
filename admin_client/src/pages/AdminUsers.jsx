import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Plus, Trash, Shield } from 'lucide-react';
import Badge from '../components/ui/Badge';

const AdminUsers = () => {
    const [admins, setAdmins] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [form, setForm] = useState({ name: '', email: '', password: '' });

    const fetchAdmins = async () => {
        try {
            const res = await api.get('/admin/admins');
            setAdmins(res.data.data);
        } catch (error) {
            console.error("Failed to fetch admins", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAdmins();
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await api.post('/admin/admins', form);
            setShowModal(false);
            setForm({ name: '', email: '', password: '' });
            fetchAdmins();
            alert("Admin added successfully");
        } catch (error) {
            alert(error.response?.data?.message || "Failed to create admin");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Delete this admin user?")) return;
        try {
            await api.delete(`/admin/admins/${id}`);
            fetchAdmins();
        } catch (error) {
            alert(error.response?.data?.message || "Failed to delete admin");
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Admin Management</h1>
                    <p className="text-slate-500 mt-1">Manage system administrators (Staff).</p>
                </div>
                <Button icon={Plus} onClick={() => setShowModal(true)}>New Admin</Button>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Name</Th>
                            <Th>Email</Th>
                            <Th>Role</Th>
                            <Th>Created At</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr><Td colSpan="5" className="text-center py-12 text-slate-400">Loading...</Td></Tr>
                        ) : admins.length === 0 ? (
                            <Tr><Td colSpan="5" className="text-center py-12 text-slate-400">No admins found.</Td></Tr>
                        ) : admins.map((a) => (
                            <Tr key={a.id}>
                                <Td><span className="font-semibold text-slate-900">{a.name}</span></Td>
                                <Td>{a.email}</Td>
                                <Td><Badge variant="brand">{a.role}</Badge></Td>
                                <Td>{new Date(a.createdAt).toLocaleDateString()}</Td>
                                <Td>
                                    <Button variant="ghost" size="icon" onClick={() => handleDelete(a.id)} className="text-red-500 hover:text-red-700 hover:bg-red-50">
                                        <Trash size={18} />
                                    </Button>
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
                        <div className="flex items-center space-x-3 mb-6">
                            <div className="p-2 bg-indigo-100 text-indigo-600 rounded-lg">
                                <Shield size={24} />
                            </div>
                            <h2 className="text-xl font-bold">Add New Admin</h2>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Name</label>
                                <Input required placeholder="John Doe" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                                <Input required type="email" placeholder="admin@example.com" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                                <Input required type="password" placeholder="Min 6 chars" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} />
                            </div>

                            <div className="flex justify-end space-x-3 pt-4">
                                <Button type="button" variant="ghost" onClick={() => setShowModal(false)}>Cancel</Button>
                                <Button type="submit">Create Admin</Button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminUsers;
