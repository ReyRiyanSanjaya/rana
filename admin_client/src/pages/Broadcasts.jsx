import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Megaphone, Trash2, CheckCircle, XCircle } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Table, Thead, Tbody, Tr, Th, Td } from '../components/ui/Table';
import Badge from '../components/ui/Badge';

const Broadcasts = () => {
    const [announcements, setAnnouncements] = useState([]);
    const [loading, setLoading] = useState(true);
    const [form, setForm] = useState({ title: '', content: '' });

    const fetchAnnouncements = async () => {
        try {
            const res = await api.get('/admin/announcements');
            setAnnouncements(res.data.data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAnnouncements();
    }, []);

    const handleCreate = async () => {
        if (!form.title || !form.content) return alert("Please fill all fields");
        try {
            await api.post('/admin/announcements', { ...form, isActive: true });
            setForm({ title: '', content: '' });
            fetchAnnouncements();
            alert("Broadcast created!");
        } catch (error) {
            alert("Failed to create broadcast");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Delete this broadcast?")) return;
        try {
            await api.delete(`/admin/announcements/${id}`);
            fetchAnnouncements();
        } catch (error) {
            alert("Failed to delete");
        }
    };

    const toggleActive = async (id, currentStatus) => {
        try {
            await api.put(`/admin/announcements/${id}/active`, { isActive: !currentStatus });
            fetchAnnouncements();
        } catch (error) {
            alert("Failed to update status");
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Broadcasts</h1>
                    <p className="text-slate-500 mt-1">Manage announcements sent to all merchant devices.</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Create Form */}
                <div className="lg:col-span-1">
                    <Card className="p-6">
                        <h3 className="font-semibold text-slate-900 mb-4 flex items-center gap-2">
                            <Megaphone size={18} />
                            New Announcement
                        </h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
                                <Input
                                    placeholder="e.g. System Maintenance"
                                    value={form.title}
                                    onChange={e => setForm({ ...form, title: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Content</label>
                                <textarea
                                    className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm h-32"
                                    placeholder="Message details..."
                                    value={form.content}
                                    onChange={e => setForm({ ...form, content: e.target.value })}
                                />
                            </div>
                            <Button onClick={handleCreate} className="w-full">
                                Send Broadcast
                            </Button>
                        </div>
                    </Card>
                </div>

                {/* List */}
                <div className="lg:col-span-2">
                    <Card className="overflow-hidden">
                        <Table>
                            <Thead>
                                <Tr>
                                    <Th>Announcement</Th>
                                    <Th>Status</Th>
                                    <Th>Date</Th>
                                    <Th>Action</Th>
                                </Tr>
                            </Thead>
                            <Tbody>
                                {loading ? (
                                    <Tr><Td colSpan="4" className="text-center py-8 text-slate-400">Loading...</Td></Tr>
                                ) : announcements.length === 0 ? (
                                    <Tr><Td colSpan="4" className="text-center py-8 text-slate-400">No announcements yet.</Td></Tr>
                                ) : announcements.map(item => (
                                    <Tr key={item.id}>
                                        <Td>
                                            <div className="font-medium text-slate-900">{item.title}</div>
                                            <div className="text-sm text-slate-500 truncate max-w-xs">{item.content}</div>
                                        </Td>
                                        <Td>
                                            <button onClick={() => toggleActive(item.id, item.isActive)}>
                                                <Badge variant={item.isActive ? "success" : "secondary"}>
                                                    {item.isActive ? "Active" : "Inactive"}
                                                </Badge>
                                            </button>
                                        </Td>
                                        <Td>
                                            <span className="text-xs text-slate-500">
                                                {new Date(item.createdAt).toLocaleDateString()}
                                            </span>
                                        </Td>
                                        <Td>
                                            <button
                                                onClick={() => handleDelete(item.id)}
                                                className="p-2 text-rose-600 hover:bg-rose-50 rounded-lg transition"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </Td>
                                    </Tr>
                                ))}
                            </Tbody>
                        </Table>
                    </Card>
                </div>
            </div>
        </AdminLayout>
    );
};

export default Broadcasts;
