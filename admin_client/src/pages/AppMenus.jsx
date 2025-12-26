import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/button';
import Badge from '../components/ui/Badge';
import { Plus, Edit, Trash2, Smartphone, Move, X } from 'lucide-react';
import Input from '../components/ui/Input';

const AppMenus = () => {
    const [menus, setMenus] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [currentMenu, setCurrentMenu] = useState(null); // null = create mode

    // Form State
    const [formData, setFormData] = useState({
        key: '',
        label: '',
        icon: '',
        route: '',
        order: 0,
        isActive: true
    });

    useEffect(() => {
        fetchMenus();
    }, []);

    const fetchMenus = async () => {
        try {
            setLoading(true);
            const res = await api.get('/admin/app-menus');
            setMenus(res.data.data);
        } catch (error) {
            console.error(error);
            alert("Failed to fetch menus");
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (menu = null) => {
        if (menu) {
            setCurrentMenu(menu);
            setFormData({
                key: menu.key,
                label: menu.label,
                icon: menu.icon,
                route: menu.route,
                order: menu.order,
                isActive: menu.isActive
            });
        } else {
            setCurrentMenu(null);
            setFormData({
                key: '',
                label: '',
                icon: '',
                route: '',
                order: 0,
                isActive: true
            });
        }
        setIsModalOpen(true);
    };

    const handleCloseModal = () => {
        setIsModalOpen(false);
        setCurrentMenu(null);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (currentMenu) {
                // Update
                await api.put(`/admin/app-menus/${currentMenu.id}`, formData);
                alert("Menu updated!");
            } else {
                // Create
                await api.post('/admin/app-menus', formData);
                alert("Menu created!");
            }
            handleCloseModal();
            fetchMenus();
        } catch (error) {
            console.error(error);
            alert("Failed to save menu: " + (error.response?.data?.message || ""));
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Are you sure you want to delete this menu?")) return;
        try {
            await api.delete(`/admin/app-menus/${id}`);
            alert("Menu deleted");
            fetchMenus();
        } catch (error) {
            console.error(error);
            alert("Failed to delete menu");
        }
    };

    const toggleStatus = async (menu) => {
        try {
            await api.put(`/admin/app-menus/${menu.id}`, { isActive: !menu.isActive });
            fetchMenus(); // Refresh to see update
        } catch (error) {
            alert("Failed to update status");
        }
    }

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Mobile App Menus</h1>
                    <p className="text-slate-500 mt-1">Configure layout and visibility of mobile app features.</p>
                </div>
                <Button onClick={() => handleOpenModal()} className="bg-indigo-600 text-white"><Plus size={18} className="mr-2" /> Add Menu</Button>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Order</Th>
                            <Th>Icon</Th>
                            <Th>Label</Th>
                            <Th>Key / Route</Th>
                            <Th>Status</Th>
                            <Th className="text-right">Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">Loading menus...</Td>
                            </Tr>
                        ) : menus.length === 0 ? (
                            <Tr>
                                <Td colSpan="6" className="text-center py-12 text-slate-400">No menus configured.</Td>
                            </Tr>
                        ) : menus.map((m) => (
                            <Tr key={m.id}>
                                <Td>
                                    <div className="flex items-center text-slate-500">
                                        <Move size={14} className="mr-2" /> {m.order}
                                    </div>
                                </Td>
                                <Td><span className="font-mono text-xs bg-slate-100 px-2 py-1 rounded">{m.icon}</span></Td>
                                <Td><span className="font-medium text-slate-900">{m.label}</span></Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="text-xs font-bold text-slate-700">{m.key}</span>
                                        <span className="text-xs text-slate-500">{m.route}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <div className="cursor-pointer" onClick={() => toggleStatus(m)}>
                                        <Badge variant={m.isActive ? "success" : "secondary"}>
                                            {m.isActive ? "Active" : "Disabled"}
                                        </Badge>
                                    </div>
                                </Td>
                                <Td className="text-right">
                                    <div className="flex justify-end gap-2">
                                        <Button variant="ghost" size="sm" onClick={() => handleOpenModal(m)}><Edit size={16} /></Button>
                                        <Button variant="ghost" size="sm" className="text-red-500" onClick={() => handleDelete(m.id)}><Trash2 size={16} /></Button>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold text-slate-900">
                                {currentMenu ? 'Edit Menu' : 'Add New Menu'}
                            </h2>
                            <button onClick={handleCloseModal} className="text-slate-400 hover:text-slate-600">
                                <X size={24} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Label (Display Name)</label>
                                <Input required value={formData.label} onChange={e => setFormData({ ...formData, label: e.target.value })} placeholder="e.g. Point of Sale" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Key (Unique)</label>
                                    <Input required value={formData.key} onChange={e => setFormData({ ...formData, key: e.target.value.toUpperCase() })} placeholder="e.g. POS" disabled={!!currentMenu} />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Order Index</label>
                                    <Input type="number" value={formData.order} onChange={e => setFormData({ ...formData, order: e.target.value })} placeholder="0" />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Icon Name</label>
                                    <Input required value={formData.icon} onChange={e => setFormData({ ...formData, icon: e.target.value })} placeholder="e.g. ShoppingCart" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">App Route</label>
                                    <Input required value={formData.route} onChange={e => setFormData({ ...formData, route: e.target.value })} placeholder="e.g. /pos" />
                                </div>
                            </div>

                            <div className="flex items-center mt-2">
                                <input
                                    type="checkbox"
                                    id="isActive"
                                    checked={formData.isActive}
                                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                                    className="h-4 w-4 text-indigo-600 border-slate-300 rounded focus:ring-indigo-500"
                                />
                                <label htmlFor="isActive" className="ml-2 text-sm text-slate-700 font-medium">
                                    Active / Visible
                                </label>
                            </div>

                            <div className="flex justify-end gap-3 mt-6 pt-4 border-t border-slate-100">
                                <Button type="button" variant="ghost" onClick={handleCloseModal}>Cancel</Button>
                                <Button type="submit" className="bg-indigo-600 text-white">{currentMenu ? 'Save Changes' : 'Create Menu'}</Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default AppMenus;
