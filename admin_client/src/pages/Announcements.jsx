import React, { useState, useEffect } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Button from '../components/ui/Button';
import { Edit, Trash2, Plus, X } from 'lucide-react';

const Announcements = () => {
    const [announcements, setAnnouncements] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({ title: '', content: '', isActive: true });

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const { data } = await api.get('/admin/announcements');
            // Check if data is array or wrapped
            if (data.success && Array.isArray(data.data)) {
                setAnnouncements(data.data);
            } else if (Array.isArray(data)) {
                setAnnouncements(data);
            } else if (Array.isArray(data.data)) { // systemController returns { data: [...] } usually via successResponse? 
                // successResponse(res, announcements) -> res.json({ status: 'success', data: announcements })
                setAnnouncements(data.data);
            }
        } catch (error) {
            console.error('Failed to fetch', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingItem) {
                await api.put(`/admin/announcements/${editingItem.id}`, formData);
            } else {
                await api.post('/admin/announcements', formData);
            }
            setIsModalOpen(false);
            setEditingItem(null);
            setFormData({ title: '', content: '', isActive: true });
            fetchData();
        } catch (error) {
            alert('Failed to save');
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure?')) return;
        try {
            await api.delete(`/admin/announcements/${id}`);
            fetchData();
        } catch (error) {
            alert('Failed to delete');
        }
    };

    const openEdit = (item) => {
        setEditingItem(item);
        setFormData({ title: item.title, content: item.content, isActive: item.isActive });
        setIsModalOpen(true);
    };

    return (
        <AdminLayout>
            <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-bold text-slate-800">Info Terkini (Announcements)</h1>
                    <Button
                        onClick={() => { setEditingItem(null); setFormData({ title: '', content: '', isActive: true }); setIsModalOpen(true); }}
                        className="bg-red-600 hover:bg-red-700 text-white"
                    >
                        <Plus size={18} className="mr-2" />
                        Buat Info Baru
                    </Button>
                </div>

                {loading ? (
                    <div className="text-center py-10">Loading...</div>
                ) : (
                    <div className="bg-white rounded-xl shadow-sm overflow-hidden border border-slate-200">
                        <table className="w-full text-left">
                            <thead className="bg-slate-50 border-b border-slate-200">
                                <tr>
                                    <th className="p-4 font-semibold text-slate-600">Judul</th>
                                    <th className="p-4 font-semibold text-slate-600">Konten</th>
                                    <th className="p-4 font-semibold text-slate-600">Status</th>
                                    <th className="p-4 font-semibold text-slate-600">Tanggal</th>
                                    <th className="p-4 font-semibold text-slate-600 text-right">Aksi</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {announcements.map((item) => (
                                    <tr key={item.id} className="hover:bg-slate-50">
                                        <td className="p-4 font-medium text-slate-900">{item.title}</td>
                                        <td className="p-4 text-slate-600 max-w-xs truncate">{item.content}</td>
                                        <td className="p-4">
                                            <span className={`px-2 py-1 rounded-full text-xs font-semibold ${item.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                                                {item.isActive ? 'Aktif' : 'Non-Aktif'}
                                            </span>
                                        </td>
                                        <td className="p-4 text-slate-500 text-sm">{new Date(item.createdAt).toLocaleDateString('id-ID')}</td>
                                        <td className="p-4 text-right space-x-2">
                                            <Button variant="outline" size="sm" onClick={() => openEdit(item)} className="text-blue-600 border-blue-200 hover:bg-blue-50">
                                                <Edit size={14} className="mr-1" /> Edit
                                            </Button>
                                            <Button variant="outline" size="sm" onClick={() => handleDelete(item.id)} className="text-red-600 border-red-200 hover:bg-red-50">
                                                <Trash2 size={14} className="mr-1" /> Hapus
                                            </Button>
                                        </td>
                                    </tr>
                                ))}
                                {announcements.length === 0 && (
                                    <tr>
                                        <td colSpan="5" className="p-8 text-center text-slate-500">Belum ada info terkini via sistem ini.</td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Modal */}
                {isModalOpen && (
                    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                        <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl animate-in fade-in zoom-in duration-200">
                            <h2 className="text-xl font-bold mb-4">{editingItem ? 'Edit Info' : 'Buat Info Baru'}</h2>
                            <form onSubmit={handleSubmit} className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Judul</label>
                                    <input
                                        type="text"
                                        required
                                        className="w-full border border-slate-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none"
                                        value={formData.title}
                                        onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Konten</label>
                                    <textarea
                                        required
                                        rows="4"
                                        className="w-full border border-slate-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none"
                                        value={formData.content}
                                        onChange={e => setFormData({ ...formData, content: e.target.value })}
                                    ></textarea>
                                </div>
                                <div className="flex items-center space-x-2">
                                    <input
                                        type="checkbox"
                                        id="isActive"
                                        className="w-4 h-4 text-red-600 rounded focus:ring-red-500"
                                        checked={formData.isActive}
                                        onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                                    />
                                    <label htmlFor="isActive" className="text-sm font-medium text-slate-700">Tampilkan ke Aplikasi (Aktif)</label>
                                </div>
                                <div className="flex justify-end space-x-3 pt-4 border-t border-slate-100 mt-4">
                                    <Button type="button" variant="ghost" onClick={() => setIsModalOpen(false)}>Batal</Button>
                                    <Button type="submit" className="bg-red-600 hover:bg-red-700 text-white">Simpan</Button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}
            </div>
        </AdminLayout>
    );
};

export default Announcements;
