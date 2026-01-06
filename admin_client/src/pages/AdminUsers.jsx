import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Plus, Trash, Shield, Pencil, CheckCircle, Ban, Settings } from 'lucide-react';
import Badge from '../components/ui/Badge';

const AdminUsers = () => {
    const [admins, setAdmins] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [form, setForm] = useState({ name: '', email: '', password: '' });
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [selectedRows, setSelectedRows] = useState([]);
    const [page, setPage] = useState(1);
    const [perPage] = useState(10);
    const [showRoleModal, setShowRoleModal] = useState(false);
    const [roleSelected, setRoleSelected] = useState('ADMIN');
    const [roleMenus, setRoleMenus] = useState({});
    const allMenus = [
        { label: 'Dashboard', path: '/' },
        { label: 'Acquisition Map', path: '/map' },
        { label: 'Merchants', path: '/merchants' },
        { label: 'Kulakan', path: '/kulakan' },
        { label: 'Reports', path: '/reports' },
        { label: 'Transactions', path: '/transactions' },
        { label: 'Withdrawals', path: '/withdrawals' },
        { label: 'Top Ups', path: '/topups' },
        { label: 'Subscriptions', path: '/subscriptions' },
        { label: 'Referrals', path: '/referrals' },
        { label: 'Packages', path: '/packages' },
        { label: 'Broadcasts', path: '/broadcasts' },
        { label: 'App Menus', path: '/app-menus' },
        { label: 'Admins', path: '/admins' },
        { label: 'Audit Logs', path: '/audit-logs' },
        { label: 'Content CMS', path: '/content-manager' },
        { label: 'Blog Manager', path: '/blog' },
        { label: 'Flash Sales', path: '/flashsales' },
        { label: 'Support', path: '/support' },
        { label: 'Settings', path: '/settings' },
    ];

    const fetchAdmins = async () => {
        try {
            const params = new URLSearchParams();
            if (search) params.append('search', search);
            if (roleFilter) params.append('role', roleFilter);
            params.append('page', String(page));
            params.append('limit', String(perPage));
            const res = await api.get(`/admin/admins?${params.toString()}`);
            setAdmins(res.data.data);
        } catch (error) {
            console.error("Failed to fetch admins", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAdmins();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [search, roleFilter, page]);
    useEffect(() => {
        api.get('/admin/settings').then(res => {
            const map = {};
            (res.data.data || []).forEach(s => map[s.key] = s.value);
            try {
                const parsed = map.ADMIN_ROLE_MENU_ACCESS ? JSON.parse(map.ADMIN_ROLE_MENU_ACCESS) : {};
                setRoleMenus(parsed && typeof parsed === 'object' ? parsed : {});
            } catch {
                setRoleMenus({});
            }
        });
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

    const handleUpdateRole = async (id, role) => {
        try {
            await api.put(`/admin/admins/${id}`, { role });
            fetchAdmins();
            alert('Role updated');
        } catch (error) {
            alert(error.response?.data?.message || 'Failed to update role');
        }
    };

    const toggleActive = async (admin) => {
        try {
            await api.put(`/admin/admins/${admin.id}`, { isActive: !admin.isActive });
            fetchAdmins();
        } catch (error) {
            alert(error.response?.data?.message || 'Failed to update status');
        }
    };

    const toggleSelectAll = (checked) => {
        if (checked) setSelectedRows(admins.map(a => a.id));
        else setSelectedRows([]);
    };
    const toggleRow = (id) => {
        setSelectedRows(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
    };
    const bulkSetRole = async (role) => {
        try {
            for (const id of selectedRows) {
                await api.put(`/admin/admins/${id}`, { role });
            }
            setSelectedRows([]);
            fetchAdmins();
            alert('Bulk role update completed');
        } catch {
            alert('Bulk role update failed');
        }
    };
    const bulkDeactivate = async () => {
        try {
            for (const id of selectedRows) {
                await api.put(`/admin/admins/${id}`, { isActive: false });
            }
            setSelectedRows([]);
            fetchAdmins();
            alert('Selected admins deactivated');
        } catch {
            alert('Bulk deactivate failed');
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Admin Management</h1>
                    <p className="text-slate-500 mt-1">Manage system administrators (Staff).</p>
                </div>
                <div className="flex gap-2 items-center">
                    <input
                        type="text"
                        placeholder="Search name or email..."
                        className="px-3 py-2 border border-slate-300 rounded-lg text-sm"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                    <select
                        className="px-3 py-2 border border-slate-300 rounded-lg text-sm bg-white"
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                    >
                        <option value="">All Roles</option>
                        <option value="SUPER_ADMIN">Super Admin</option>
                        <option value="ADMIN">Admin</option>
                        <option value="SUPPORT">Support</option>
                    </select>
                    <Button icon={Settings} variant="outline" onClick={() => setShowRoleModal(true)}>Role Permissions</Button>
                    <Button icon={Plus} onClick={() => setShowModal(true)}>New Admin</Button>
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                {selectedRows.length > 0 && (
                    <div className="flex items-center justify-between p-3 border-b bg-indigo-50">
                        <span className="text-sm text-indigo-700">{selectedRows.length} selected</span>
                        <div className="flex gap-2">
                            <Button size="sm" onClick={() => bulkSetRole('ADMIN')} icon={Pencil}>Set Role: Admin</Button>
                            <Button size="sm" onClick={() => bulkSetRole('SUPPORT')} icon={Pencil}>Set Role: Support</Button>
                            <Button variant="destructive" size="sm" onClick={bulkDeactivate} icon={Ban}>Deactivate</Button>
                        </div>
                    </div>
                )}
                <Table>
                    <Thead>
                        <Tr>
                            <Th>
                                <input
                                    type="checkbox"
                                    checked={selectedRows.length === admins.length && admins.length > 0}
                                    onChange={(e) => toggleSelectAll(e.target.checked)}
                                />
                            </Th>
                            <Th>Name</Th>
                            <Th>Email</Th>
                            <Th>Role</Th>
                            <Th>Created At</Th>
                            <Th>Actions</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr><Td colSpan="6" className="text-center py-12 text-slate-400">Loading...</Td></Tr>
                        ) : admins.length === 0 ? (
                            <Tr><Td colSpan="6" className="text-center py-12 text-slate-400">No admins found.</Td></Tr>
                        ) : admins.map((a) => (
                            <Tr key={a.id}>
                                <Td>
                                    <input
                                        type="checkbox"
                                        checked={selectedRows.includes(a.id)}
                                        onChange={() => toggleRow(a.id)}
                                    />
                                </Td>
                                <Td><span className="font-semibold text-slate-900">{a.name}</span></Td>
                                <Td>{a.email}</Td>
                                <Td>
                                    <div className="flex items-center gap-2">
                                        <Badge variant="brand">{a.role}</Badge>
                                        <select
                                            className="px-2 py-1 border border-slate-300 rounded text-xs bg-white"
                                            value={a.role}
                                            onChange={(e) => handleUpdateRole(a.id, e.target.value)}
                                        >
                                            <option value="SUPER_ADMIN">Super Admin</option>
                                            <option value="ADMIN">Admin</option>
                                            <option value="SUPPORT">Support</option>
                                        </select>
                                    </div>
                                </Td>
                                <Td>{new Date(a.createdAt).toLocaleDateString()}</Td>
                                <Td>
                                    <div className="inline-flex gap-2">
                                        <Button variant="outline" size="icon" onClick={() => toggleActive(a)} className={`${a.isActive ? 'text-green-600 border-green-200 hover:bg-green-50' : 'text-slate-500 border-slate-200 hover:bg-slate-50'}`}>
                                            {a.isActive ? <CheckCircle size={18} /> : <Ban size={18} />}
                                        </Button>
                                        <Button variant="outline" size="icon" onClick={() => handleDelete(a.id)} className="text-red-500 border-red-200 hover:text-red-700 hover:bg-red-50">
                                            <Trash size={18} />
                                        </Button>
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
                                <Button type="button" variant="outline" onClick={() => setShowModal(false)}>Cancel</Button>
                                <Button type="submit">Create Admin</Button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
            {showRoleModal && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <Card className="w-full max-w-xl p-4 max-h-[85vh] overflow-y-auto">
                        <div className="flex items-center justify-between mb-3">
                            <h2 className="text-xl font-bold">Role Menu Access</h2>
                            <Button variant="outline" onClick={() => setShowRoleModal(false)}>Close</Button>
                        </div>
                        <div className="flex gap-2 mb-3">
                            <select
                                className="px-2 py-1 border rounded bg-white text-sm"
                                value={roleSelected}
                                onChange={e => setRoleSelected(e.target.value)}
                            >
                                <option>SUPER_ADMIN</option>
                                <option>ADMIN</option>
                                <option>SUPPORT</option>
                            </select>
                            <Button size="sm" variant="secondary" onClick={() => {
                                const next = { ...roleMenus, [roleSelected]: allMenus.map(m => m.path) };
                                setRoleMenus(next);
                            }}>Grant All</Button>
                            <Button size="sm" variant="outline" onClick={() => {
                                const next = { ...roleMenus, [roleSelected]: [] };
                                setRoleMenus(next);
                            }}>Clear</Button>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                            {allMenus.map((m) => {
                                const checked = (roleMenus[roleSelected] || []).includes(m.path);
                                return (
                                    <label key={m.path} className="flex items-center gap-2 border rounded p-2 text-xs">
                                        <input
                                            type="checkbox"
                                            checked={checked}
                                            onChange={(e) => {
                                                const current = new Set(roleMenus[roleSelected] || []);
                                                if (e.target.checked) current.add(m.path); else current.delete(m.path);
                                                const next = { ...roleMenus, [roleSelected]: Array.from(current) };
                                                setRoleMenus(next);
                                            }}
                                        />
                                        <span className="">{m.label}</span>
                                    </label>
                                );
                            })}
                        </div>
                        <div className="flex justify-end gap-2 mt-4 sticky bottom-0 bg-white pt-2">
                            <Button size="sm" onClick={async () => {
                                await api.post('/admin/settings', { key: 'ADMIN_ROLE_MENU_ACCESS', value: JSON.stringify(roleMenus), description: 'Role Menu Access' });
                                alert('Permissions saved');
                                setShowRoleModal(false);
                            }}>Save</Button>
                        </div>
                    </Card>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminUsers;
