import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Plus, Trash, Bell, Megaphone } from 'lucide-react';
import Badge from '../components/ui/Badge';

const Announcements = () => {
    const [announcements, setAnnouncements] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);

    // Form State
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

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await api.post('/admin/announcements', form);
            setShowModal(false);
            setForm({ title: '', content: '' });
            fetchAnnouncements();
        } catch (error) {
            alert("Failed to create announcement");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Delete this announcement?")) return;
        try {
            await api.delete(`/admin/announcements/${id}`);
            fetchAnnouncements();
        } catch (error) {
            alert("Failed to delete");
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Announcements</h1>
                    <p className="text-slate-500 mt-1">Broadcast news and alerts to all merchant dashboards.</p>
                </div>
                <Button icon={Plus} onClick={() => setShowModal(true)}>New Announcement</Button>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Date</Th>
                            <Th>Title</Th>
                            <Th>Content</Th>
                            <Th>Status</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">Loading...</Td>
                            </Tr>
                        ) : announcements.length === 0 ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">No announcements posted.</Td>
                            </Tr>
                        ) : announcements.map((a) => (
                            <Tr key={a.id}>
                                <Td><span className="text-slate-500 text-sm">{new Date(a.createdAt).toLocaleDateString()}</span></Td>
                                <Td><span className="font-semibold text-slate-900">{a.title}</span></Td>
                                <Td><span className="text-slate-500 text-sm">{a.content}</span></Td>
                                <Td><Badge variant="success">Active</Badge></Td>
                                <Td>
                                    <button onClick={() => handleDelete(a.id)} className="text-red-500 hover:text-red-700 p-2">
                                        <Trash size={18} />
                                    </button>
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
                            <div className="p-2 bg-blue-100 text-blue-600 rounded-lg">
                                <Megaphone size={24} />
                            </div>
                            <h2 className="text-xl font-bold">Broadcast News</h2>
                        </div>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
                                <Input required placeholder="e.g. System Maintenance" value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Content</label>
                                <textarea
                                    className="w-full border border-slate-300 rounded-lg p-2 text-sm focus:ring-2 focus:ring-primary-500 outline-none"
                                    rows="4"
                                    placeholder="Write your message here..."
                                    required
                                    value={form.content}
                                    onChange={e => setForm({ ...form, content: e.target.value })}
                                ></textarea>
                            </div>
                            <div className="flex justify-end space-x-3 pt-4">
                                <Button type="button" variant="ghost" onClick={() => setShowModal(false)}>Cancel</Button>
                                <Button type="submit">Broadcast</Button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
        </AdminLayout>
    );
};

export default Announcements;
