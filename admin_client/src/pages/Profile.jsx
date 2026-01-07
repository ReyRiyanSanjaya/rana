import React from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/ui/Card';
import { User, Mail, Shield, Key, CalendarDays, Copy, CheckCircle, Building2, Phone, MapPin } from 'lucide-react';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import { Avatar, AvatarFallback } from '../components/ui/avatar';
import Swal from 'sweetalert2';
import { getUser } from '../lib/auth';

const Profile = () => {
    const [user, setUser] = React.useState({
        id: '', name: '', email: '', role: '', joined: ''
    });
    const [tenant, setTenant] = React.useState({ id: '', name: '', plan: '', subscriptionStatus: '' });
    const [store, setStore] = React.useState({ id: '', name: '', waNumber: '', location: '' });
    const [loading, setLoading] = React.useState(true);
    const [showChangePwd, setShowChangePwd] = React.useState(false);
    const [password, setPassword] = React.useState('');
    const [confirmPassword, setConfirmPassword] = React.useState('');
    const [pwdError, setPwdError] = React.useState('');
    const [savingPwd, setSavingPwd] = React.useState(false);
    const [nameInput, setNameInput] = React.useState('');
    const [savingName, setSavingName] = React.useState(false);

    React.useEffect(() => {
        (async () => {
            try {
                const res = await api.get('/auth/me');
                const data = res.data.data;
                setUser({
                    id: data.id,
                    name: data.name,
                    email: data.email,
                    role: data.role,
                    joined: new Date(data.createdAt).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
                });
                setTenant({
                    id: data.tenant?.id || '',
                    name: data.tenant?.name || '',
                    plan: data.tenant?.plan || '',
                    subscriptionStatus: data.tenant?.subscriptionStatus || ''
                });
                setStore({
                    id: data.store?.id || '',
                    name: data.store?.name || '',
                    waNumber: data.store?.waNumber || '',
                    location: data.store?.location || ''
                });
            } catch (err) {
                console.error(err);
            } finally {
                setLoading(false);
            }
        })();
    }, []);

    const initial = (user.name || user.email || 'A').charAt(0).toUpperCase();
    const roleVariant = user.role === 'SUPER_ADMIN' ? 'brand' : user.role === 'ADMIN' ? 'neutral' : 'secondary';
    React.useEffect(() => {
        setNameInput(user.name || '');
    }, [user.name]);

    const copyEmail = async () => {
        try {
            await navigator.clipboard.writeText(user.email || '');
            Swal.fire({ icon: 'success', title: 'Email disalin', timer: 1200, showConfirmButton: false });
        } catch {
            alert('Gagal menyalin email');
        }
    };

    const validatePassword = () => {
        if (!password || password.length < 6) return 'Minimal 6 karakter';
        if (password !== confirmPassword) return 'Konfirmasi tidak cocok';
        return '';
    };

    const handleChangePassword = async () => {
        const err = validatePassword();
        setPwdError(err);
        if (err) return;
        setSavingPwd(true);
        try {
            const current = getUser();
            const id = current?.id || user.id;
            await api.put(`/admin/users/${id}/password`, { password });
            setShowChangePwd(false);
            setPassword('');
            setConfirmPassword('');
            Swal.fire({ icon: 'success', title: 'Password berhasil diubah', timer: 1500, showConfirmButton: false });
        } catch (e) {
            Swal.fire({ icon: 'error', title: e.response?.data?.message || 'Gagal mengubah password' });
        } finally {
            setSavingPwd(false);
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">My Profile</h1>
                <p className="text-slate-500 mt-1">Kelola informasi akun dan keamanan Anda.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card className="md:col-span-1">
                    <CardHeader>
                        <div className="flex items-center gap-4">
                            <Avatar className="h-14 w-14 rounded-xl">
                                <AvatarFallback className="bg-indigo-100 text-indigo-700 font-bold">{initial}</AvatarFallback>
                            </Avatar>
                            <div className="space-y-1">
                                <CardTitle className="text-slate-900">{user.name || '—'}</CardTitle>
                                <CardDescription className="flex items-center gap-2">
                                    <Badge variant={roleVariant}>{user.role || '—'}</Badge>
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="pt-2">
                        {loading ? (
                            <div className="text-sm text-slate-500">Loading...</div>
                        ) : (
                            <div className="space-y-3">
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center text-sm text-slate-700">
                                        <Mail size={16} className="mr-2 text-slate-400" />
                                        {user.email}
                                    </div>
                                    <Button variant="ghost" size="icon" onClick={copyEmail} title="Copy email">
                                        <Copy className="h-4 w-4" />
                                    </Button>
                                </div>
                                <div className="flex items-center text-sm text-slate-700">
                                    <Shield size={16} className="mr-2 text-slate-400" />
                                    {user.role}
                                </div>
                                <div className="flex items-center text-sm text-slate-700">
                                    <CalendarDays size={16} className="mr-2 text-slate-400" />
                                    Joined {user.joined}
                                </div>
                            </div>
                        )}
                    </CardContent>
                </Card>

                <Card className="md:col-span-2">
                    <CardHeader>
                        <div className="flex items-center justify-between">
                            <div>
                                <CardTitle className="flex items-center gap-2">
                                    <User size={18} className="text-indigo-600" />
                                    Account Details
                                </CardTitle>
                                <CardDescription>Informasi dasar akun</CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-4">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <Input label="Full Name" value={nameInput} onChange={(e) => setNameInput(e.target.value)} />
                                <Input label="Email Address" value={user.email} readOnly />
                            </div>
                            <div className="flex justify-end">
                                <Button
                                    onClick={async () => {
                                        if (!nameInput || nameInput.trim().length < 2) {
                                            Swal.fire({ icon: 'error', title: 'Nama tidak valid' });
                                            return;
                                        }
                                        setSavingName(true);
                                        try {
                                            await api.put('/auth/me', { name: nameInput.trim() });
                                            setUser({ ...user, name: nameInput.trim() });
                                            try {
                                                const raw = localStorage.getItem('adminUser') || '{}';
                                                const obj = JSON.parse(raw);
                                                obj.name = nameInput.trim();
                                                localStorage.setItem('adminUser', JSON.stringify(obj));
                                            } catch {}
                                            Swal.fire({ icon: 'success', title: 'Nama diperbarui', timer: 1200, showConfirmButton: false });
                                        } catch (e) {
                                            Swal.fire({ icon: 'error', title: e.response?.data?.message || 'Gagal memperbarui nama' });
                                        } finally {
                                            setSavingName(false);
                                        }
                                    }}
                                    isLoading={savingName}
                                    icon={CheckCircle}
                                >
                                    Simpan Nama
                                </Button>
                            </div>
                            <div className="pt-4 border-t border-slate-100 mt-4">
                                <h3 className="font-semibold text-lg text-slate-900 mb-4 flex items-center">
                                    <Key size={20} className="mr-2 text-indigo-600" />
                                    Security
                                </h3>
                                <div className="flex items-center gap-3">
                                    <Button variant="outline" onClick={() => setShowChangePwd(true)} icon={Key}>
                                        Change Password
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Building2 size={18} className="text-indigo-600" />
                            Organization & Store
                        </CardTitle>
                        <CardDescription>Data organisasi dan toko Anda</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-3">
                            <div className="flex items-center text-sm text-slate-700">
                                <Building2 size={16} className="mr-2 text-slate-400" />
                                {tenant.name || '—'} {tenant.plan && <Badge variant="brand" className="ml-2">{tenant.plan}</Badge>}
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <Shield size={16} className="mr-2 text-slate-400" />
                                Subscription {tenant.subscriptionStatus || '—'}
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <StoreIcon />
                                <span className="ml-2">{store.name || '—'}</span>
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <Phone size={16} className="mr-2 text-slate-400" />
                                {store.waNumber || '—'}
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <MapPin size={16} className="mr-2 text-slate-400" />
                                {store.location || '—'}
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {showChangePwd && (
                <div className="fixed inset-0 z-50 flex items-center justify-center">
                    <div className="absolute inset-0 bg-black/30" onClick={() => setShowChangePwd(false)} />
                    <div className="relative w-full max-w-md">
                        <Card className="p-6">
                            <h3 className="font-semibold text-lg text-slate-900 mb-4">Change Password</h3>
                            <div className="space-y-3">
                                <Input
                                    label="New Password"
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    error={pwdError ? undefined : undefined}
                                />
                                <Input
                                    label="Confirm Password"
                                    type="password"
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                />
                                {pwdError && <div className="text-sm text-red-600">{pwdError}</div>}
                            </div>
                            <div className="flex justify-end gap-2 mt-6">
                                <Button variant="ghost" onClick={() => setShowChangePwd(false)}>Batal</Button>
                                <Button onClick={handleChangePassword} isLoading={savingPwd} icon={CheckCircle}>
                                    Simpan
                                </Button>
                            </div>
                        </Card>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default Profile;

function StoreIcon() {
    return (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-slate-400" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M3 9l1-5h16l1 5" strokeWidth="2" />
            <path d="M4 9h16v11H4z" strokeWidth="2" />
            <path d="M10 13h4v7h-4z" strokeWidth="2" />
        </svg>
    );
}
