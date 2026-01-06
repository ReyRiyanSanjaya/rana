import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import { Plus, Edit, Trash2, Smartphone, Move, X } from 'lucide-react';
import Input from '../components/ui/Input';

const AppMenus = () => {
    const [menus, setMenus] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [currentMenu, setCurrentMenu] = useState(null); // null = create mode
    const [query, setQuery] = useState('');
    const [publicMenus, setPublicMenus] = useState([]);
    const [maintenanceMap, setMaintenanceMap] = useState({});
    const [maintModal, setMaintModal] = useState({ open: false, menu: null });
    const [maintForm, setMaintForm] = useState({ active: false, message: '', until: '' });
    const [selectedRows, setSelectedRows] = useState([]);
    const [statusFilter, setStatusFilter] = useState('');
    const [sortOrder, setSortOrder] = useState('asc');
    const allowedKeys = ['POS','PRODUCT','REPORT','STOCK','ADS','FLASH_SALE','PROMO','SUPPORT','SETTINGS','KULAKAN','PPOB','WALLET','SCAN','ORDER'];
    const allowedRoutes = ['/pos','/products','/reports','/stock','/marketing','/flashsale','/promo','/support','/settings','/kulakan','/ppob','/wallet','/orders','/scan'];
    const defaultMobileMenus = [
        { label: 'Kasir', key: 'POS', route: '/pos', icon: 'POS' },
        { label: 'Produk', key: 'PRODUCT', route: '/products', icon: 'PRODUCT' },
        { label: 'Laporan', key: 'REPORT', route: '/reports', icon: 'REPORT' },
        { label: 'Stok', key: 'STOCK', route: '/stock', icon: 'STOCK' },
        { label: 'Kulakan', key: 'KULAKAN', route: '/kulakan', icon: 'KULAKAN' },
        { label: 'Promosi', key: 'PROMO', route: '/promo', icon: 'PROMO' },
        { label: 'Bantuan', key: 'SUPPORT', route: '/support', icon: 'SUPPORT' },
        { label: 'PPOB', key: 'PPOB', route: '/ppob', icon: 'PPOB' }
    ];

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
        fetchMaintenance();
    }, []);

    const fetchMenus = async () => {
        try {
            setLoading(true);
            const res = await api.get('/admin/app-menus');
            setMenus(res.data.data);
            await fetchPublicMenus();
        } catch (error) {
            console.error(error);
            alert("Failed to fetch menus");
        } finally {
            setLoading(false);
        }
    };
    const fetchPublicMenus = async () => {
        try {
            const res = await api.get('/system/app-menus');
            setPublicMenus(res.data.data || []);
        } catch (error) {
            setPublicMenus([]);
        }
    };
    const fetchMaintenance = async () => {
        try {
            const res = await api.get('/admin/app-menus/maintenance');
            setMaintenanceMap(res.data.data || {});
        } catch (e) {
            setMaintenanceMap({});
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

    const seedDefaultMenus = async () => {
        try {
            for (let i = 0; i < defaultMobileMenus.length; i++) {
                const m = defaultMobileMenus[i];
                await api.post('/admin/app-menus', {
                    key: m.key,
                    label: m.label,
                    icon: m.icon,
                    route: m.route,
                    order: i
                }).catch(() => {});
            }
            await fetchMenus();
            alert('Default menus created or already exist');
        } catch (e) {
            alert('Failed to seed default menus');
        }
    };

    const moveUp = async (menu) => {
        const idx = menus.findIndex(m => m.id === menu.id);
        if (idx <= 0) return;
        const prev = menus[idx - 1];
        try {
            await api.put(`/admin/app-menus/${prev.id}`, { order: menu.order });
            await api.put(`/admin/app-menus/${menu.id}`, { order: prev.order });
            fetchMenus();
        } catch {
            alert('Failed to reorder');
        }
    };

    const moveDown = async (menu) => {
        const idx = menus.findIndex(m => m.id === menu.id);
        if (idx === -1 || idx >= menus.length - 1) return;
        const next = menus[idx + 1];
        try {
            await api.put(`/admin/app-menus/${next.id}`, { order: menu.order });
            await api.put(`/admin/app-menus/${menu.id}`, { order: next.order });
            fetchMenus();
        } catch {
            alert('Failed to reorder');
        }
    };

    const toggleSelectAll = (checked) => {
        if (checked) setSelectedRows(filteredMenus.map(m => m.id));
        else setSelectedRows([]);
    };
    const toggleRow = (id) => {
        setSelectedRows(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
    };
    const bulkActivate = async () => {
        try {
            for (const id of selectedRows) {
                await api.put(`/admin/app-menus/${id}`, { isActive: true });
            }
            setSelectedRows([]);
            fetchMenus();
        } catch {
            alert('Bulk activate failed');
        }
    };
    const bulkDisable = async () => {
        try {
            for (const id of selectedRows) {
                await api.put(`/admin/app-menus/${id}`, { isActive: false });
            }
            setSelectedRows([]);
            fetchMenus();
        } catch {
            alert('Bulk disable failed');
        }
    };
    const bulkDelete = async () => {
        if (!window.confirm('Delete selected menus?')) return;
        try {
            for (const id of selectedRows) {
                await api.delete(`/admin/app-menus/${id}`);
            }
            setSelectedRows([]);
            fetchMenus();
        } catch {
            alert('Bulk delete failed');
        }
    };
    const exportCsv = () => {
        const rows = (publicMenus.length ? publicMenus : filteredMenus).map(m => [
            m.order, m.icon || '', m.label || '', m.key || '', m.route || ''
        ]);
        const header = ['order','icon','label','key','route'];
        const csv = [header.join(','), ...rows.map(r => r.map(v => String(v).replace(/,/g,' ')).join(','))].join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'app_menus.csv';
        a.click();
        URL.revokeObjectURL(url);
    };

    const filteredMenus = menus
        .filter(m => m.label.toLowerCase().includes(query.toLowerCase()) || m.key.toLowerCase().includes(query.toLowerCase()))
        .filter(m => statusFilter ? (statusFilter === 'ACTIVE' ? m.isActive : !m.isActive) : true)
        .sort((a, b) => a.order - b.order);
    const sortedMenus = sortOrder === 'asc' ? filteredMenus : [...filteredMenus].sort((a, b) => b.order - a.order);
    const [dragId, setDragId] = useState(null);
    const onDragStart = (id) => setDragId(id);
    const reorderList = (list, fromId, toId) => {
        const curIdx = list.findIndex(x => x.id === fromId);
        const tgtIdx = list.findIndex(x => x.id === toId);
        if (curIdx < 0 || tgtIdx < 0 || curIdx === tgtIdx) return list;
        const res = [...list];
        const [m] = res.splice(curIdx, 1);
        res.splice(tgtIdx, 0, m);
        const base = Math.min(...res.map(i => i.order ?? 0));
        return res.map((item, idx) => ({ ...item, order: base + idx }));
    };
    const persistOrder = async (list) => {
        for (const item of list) {
            await api.put(`/admin/app-menus/${item.id}`, { order: item.order }).catch(() => {});
        }
    };
    const onDropRow = async (id) => {
        if (!dragId) return;
        const updatedSubset = reorderList(sortedMenus, dragId, id);
        const updatedMenus = menus.map(m => {
            const u = updatedSubset.find(x => x.id === m.id);
            return u ? { ...m, order: u.order } : m;
        });
        setMenus(updatedMenus);
        setDragId(null);
        await persistOrder(updatedSubset);
        await fetchPublicMenus();
    };

    const LottieBox = ({ src, loop = true, style }) => {
        return <lottie-player autoplay loop={loop} src={src} style={style}></lottie-player>;
    };
    const maintenanceAnim = "https://assets.lottiefiles.com/packages/lf20_jcikwtux.json";
    const emptyAnim = "https://assets.lottiefiles.com/packages/lf20_q5pk6p1k.json";

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Mobile App Menus</h1>
                    <p className="text-slate-500 mt-1">Configure layout and visibility of mobile app features.</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={seedDefaultMenus}>Seed Default Menus</Button>
                    <Button onClick={() => handleOpenModal()}><Plus size={18} className="mr-2" /> Add Menu</Button>
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <div className="p-3 border-b flex items-center gap-3">
                    <Input placeholder="Search by label or key..." value={query} onChange={e => setQuery(e.target.value)} />
                    <select
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                    >
                        <option value="">All</option>
                        <option value="ACTIVE">Active</option>
                        <option value="DISABLED">Disabled</option>
                    </select>
                    <select
                        className="px-3 py-2 border border-primary-300 rounded-lg text-sm bg-white"
                        value={sortOrder}
                        onChange={(e) => setSortOrder(e.target.value)}
                    >
                        <option value="asc">Order Asc</option>
                        <option value="desc">Order Desc</option>
                    </select>
                    <div className="ml-auto flex gap-2">
                        <Button variant="outline" onClick={exportCsv}>Export CSV</Button>
                        {selectedRows.length > 0 && (
                            <>
                                <Button onClick={bulkActivate}>Activate</Button>
                                <Button variant="secondary" onClick={bulkDisable}>Disable</Button>
                                <Button variant="destructive" onClick={bulkDelete}>Delete</Button>
                            </>
                        )}
                    </div>
                </div>
                <Table>
                    <Thead>
                        <Tr>
                            <Th>
                                <input
                                    type="checkbox"
                                    checked={selectedRows.length === sortedMenus.length && sortedMenus.length > 0}
                                    onChange={(e) => toggleSelectAll(e.target.checked)}
                                />
                            </Th>
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
                                <Td colSpan="7" className="text-center py-12 text-slate-400">Loading menus...</Td>
                            </Tr>
                        ) : sortedMenus.length === 0 ? (
                            <Tr>
                                <Td colSpan="7" className="text-center py-12">
                                    <div className="flex flex-col items-center gap-2">
                                        <div className="w-40 h-40">
                                            <LottieBox src={emptyAnim} style={{ width: '100%', height: '100%' }} />
                                        </div>
                                        <div className="text-slate-400">No menus configured.</div>
                                    </div>
                                </Td>
                            </Tr>
                        ) : sortedMenus.map((m) => (
                            <Tr
                                key={m.id}
                                draggable
                                onDragStart={() => onDragStart(m.id)}
                                onDragOver={(e) => e.preventDefault()}
                                onDrop={() => onDropRow(m.id)}
                            >
                                <Td>
                                    <input
                                        type="checkbox"
                                        checked={selectedRows.includes(m.id)}
                                        onChange={() => toggleRow(m.id)}
                                    />
                                </Td>
                                <Td>
                                    <div className="flex items-center text-slate-500">
                                        <Move size={14} className="mr-2" /> {m.order}
                                        <div className="ml-2 flex gap-1">
                                            <Button size="sm" variant="outline" onClick={() => moveUp(m)}>↑</Button>
                                            <Button size="sm" variant="outline" onClick={() => moveDown(m)}>↓</Button>
                                        </div>
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
                                        {maintenanceMap[m.key]?.active && (
                                            <div className="mt-1 flex items-center gap-1">
                                                <div className="w-6 h-6"><LottieBox src={maintenanceAnim} style={{ width: '100%', height: '100%' }} /></div>
                                                <div className="text-[10px] text-red-600">Maintenance: {maintenanceMap[m.key]?.until ? new Date(maintenanceMap[m.key].until).toLocaleString() : 'until resolved'}</div>
                                            </div>
                                        )}
                                    </div>
                                </Td>
                                <Td className="text-right">
                                    <div className="flex justify-end gap-2">
                                        <Button variant="outline" size="sm" onClick={() => handleOpenModal(m)}><Edit size={16} /></Button>
                                        <Button variant="destructive" size="sm" onClick={() => handleDelete(m.id)}><Trash2 size={16} /></Button>
                                        <Button variant="secondary" size="sm" onClick={() => {
                                            const cur = maintenanceMap[m.key] || { active: false, message: '', until: '' };
                                            setMaintForm({
                                                active: !!cur.active,
                                                message: cur.message || '',
                                                until: cur.until ? new Date(cur.until).toISOString().slice(0,16) : ''
                                            });
                                            setMaintModal({ open: true, menu: m });
                                        }}>Maintenance</Button>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            <Card className="mt-6 overflow-hidden border border-slate-200 shadow-sm">
                <div className="p-3 border-b flex items-center gap-3">
                    <Smartphone size={18} className="text-slate-600" />
                    <h3 className="font-semibold">Active Menus in Mobile App</h3>
                </div>
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Order</Th>
                            <Th>Icon</Th>
                            <Th>Label</Th>
                            <Th>Key / Route</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {publicMenus.length === 0 ? (
                            <Tr>
                                <Td colSpan="4" className="text-center py-8">
                                    <div className="flex flex-col items-center gap-2">
                                        <div className="w-32 h-32">
                                            <LottieBox src="https://assets.lottiefiles.com/packages/lf20_q5pk6p1k.json" style={{ width: '100%', height: '100%' }} />
                                        </div>
                                        <div className="text-slate-400 text-sm">Tidak ada menu aktif</div>
                                    </div>
                                </Td>
                            </Tr>
                        ) : publicMenus.map((m) => (
                            <Tr key={m.id}>
                                <Td>{m.order}</Td>
                                <Td><span className="font-mono text-xs bg-slate-100 px-2 py-1 rounded">{m.icon}</span></Td>
                                <Td><span className="font-medium text-slate-900">{m.label}</span></Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="text-xs font-bold text-slate-700">{m.key}</span>
                                        <span className="text-xs text-slate-500">{m.route}</span>
                                    </div>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>

            <Card className="mt-6">
                <div className="p-4 border-b flex items-center gap-2">
                    <Smartphone size={18} className="text-slate-600" />
                    <h3 className="font-semibold">Mobile Preview (Active Menus)</h3>
                    <span className="text-xs text-slate-500 ml-auto">Data diambil dari konfigurasi aktif</span>
                </div>
                <div className="p-4 grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
                    {publicMenus.length === 0 ? (
                        <div className="col-span-full text-center">
                            <div className="mx-auto w-40 h-40">
                                <LottieBox src="https://assets.lottiefiles.com/packages/lf20_q5pk6p1k.json" style={{ width: '100%', height: '100%' }} />
                            </div>
                            <div className="text-slate-400 text-sm">Tidak ada menu aktif</div>
                        </div>
                    ) : publicMenus.map(m => (
                        <div key={m.id} className="rounded-xl border border-slate-200 bg-white p-3 flex flex-col items-center justify-center">
                            <div className="w-10 h-10 rounded-full bg-primary-100 text-primary-900 flex items-center justify-center font-bold">{(m.icon || '•').slice(0,1)}</div>
                            <div className="mt-2 text-sm font-medium text-slate-800">{m.label}</div>
                        </div>
                    ))}
                </div>
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
                                    <select
                                        className="w-full border rounded-xl p-2.5"
                                        value={formData.key}
                                        onChange={e => setFormData({ ...formData, key: e.target.value })}
                                        disabled={!!currentMenu}
                                        required
                                    >
                                        <option value="">Select Key</option>
                                        {allowedKeys.map(k => <option key={k} value={k}>{k}</option>)}
                                    </select>
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
                                    <select
                                        className="w-full border rounded-xl p-2.5"
                                        value={formData.route}
                                        onChange={e => setFormData({ ...formData, route: e.target.value })}
                                        required
                                    >
                                        <option value="">Select Route</option>
                                        {allowedRoutes.map(r => <option key={r} value={r}>{r}</option>)}
                                    </select>
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
                                <Button type="button" variant="outline" onClick={handleCloseModal}>Cancel</Button>
                                <Button type="submit">{currentMenu ? 'Save Changes' : 'Create Menu'}</Button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
            {maintModal.open && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold text-slate-900">Manage Maintenance</h2>
                            <button onClick={() => setMaintModal({ open: false, menu: null })} className="text-slate-400 hover:text-slate-600">
                                <X size={24} />
                            </button>
                        </div>
                        <div className="space-y-4">
                            <div className="flex items-center">
                                <input
                                    type="checkbox"
                                    id="maintActive"
                                    checked={maintForm.active}
                                    onChange={(e) => setMaintForm({ ...maintForm, active: e.target.checked })}
                                    className="h-4 w-4 text-indigo-600 border-slate-300 rounded focus:ring-indigo-500"
                                />
                                <label htmlFor="maintActive" className="ml-2 text-sm text-slate-700 font-medium">Maintenance Active</label>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Message</label>
                                <Input value={maintForm.message} onChange={e => setMaintForm({ ...maintForm, message: e.target.value })} placeholder="Reason or message for users" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Until</label>
                                <input
                                    type="datetime-local"
                                    className="w-full border rounded-xl p-2.5"
                                    value={maintForm.until}
                                    onChange={e => setMaintForm({ ...maintForm, until: e.target.value })}
                                />
                            </div>
                        </div>
                        <div className="flex justify-end gap-3 mt-6">
                            <Button variant="outline" onClick={() => setMaintModal({ open: false, menu: null })}>Cancel</Button>
                            <Button onClick={async () => {
                                try {
                                    await api.put(`/admin/app-menus/${maintModal.menu.id}/maintenance`, {
                                        active: maintForm.active,
                                        message: maintForm.message,
                                        until: maintForm.until || null
                                    });
                                    setMaintModal({ open: false, menu: null });
                                    setMaintForm({ active: false, message: '', until: '' });
                                    await fetchMenus();
                                    await fetchMaintenance();
                                    alert('Maintenance updated');
                                } catch (e) {
                                    alert('Failed to update maintenance');
                                }
                            }}>Save</Button>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default AppMenus;
