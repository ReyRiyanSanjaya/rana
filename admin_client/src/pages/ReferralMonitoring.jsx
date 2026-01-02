import React, { useEffect, useMemo, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card, { CardHeader, CardTitle, CardDescription, CardContent } from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import { Gift, Users, Wallet, LayoutDashboard, RefreshCw } from 'lucide-react';

const ReferralMonitoring = () => {
    const [programs, setPrograms] = useState([]);
    const [referrals, setReferrals] = useState([]);
    const [rewards, setRewards] = useState([]);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);

    const [programStatusFilter, setProgramStatusFilter] = useState('');
    const [programTypeFilter, setProgramTypeFilter] = useState('');
    const [programSearch, setProgramSearch] = useState('');

    const [referralStatusFilter, setReferralStatusFilter] = useState('');
    const [referralProgramFilter, setReferralProgramFilter] = useState('');

    const [rewardStatusFilter, setRewardStatusFilter] = useState('');
    const [rewardProgramFilter, setRewardProgramFilter] = useState('');
    const [rewardBeneficiarySearch, setRewardBeneficiarySearch] = useState('');

    const fetchData = async () => {
        try {
            setRefreshing(true);
            const [programRes, referralRes, rewardRes] = await Promise.all([
                api.get('/admin/referral/programs'),
                api.get('/admin/referral/referrals'),
                api.get('/admin/referral/rewards')
            ]);

            setPrograms(programRes.data.data || programRes.data || []);
            setReferrals(referralRes.data.data || referralRes.data || []);
            setRewards(rewardRes.data.data || rewardRes.data || []);
        } catch (error) {
            console.error('Failed to load referral data', error);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const formatCurrency = (val) => {
        if (!val) return 'Rp0';
        return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);
    };

    const uniqueProgramStatuses = useMemo(
        () => Array.from(new Set(programs.map((p) => p.status).filter(Boolean))),
        [programs]
    );

    const uniqueProgramTypes = useMemo(
        () => Array.from(new Set(programs.map((p) => p.type).filter(Boolean))),
        [programs]
    );

    const uniqueReferralStatuses = useMemo(
        () => Array.from(new Set(referrals.map((r) => r.status).filter(Boolean))),
        [referrals]
    );

    const uniqueRewardStatuses = useMemo(
        () => Array.from(new Set(rewards.map((r) => r.status).filter(Boolean))),
        [rewards]
    );

    const summary = useMemo(() => {
        const totalPrograms = programs.length;
        const totalReferrals = referrals.length;
        const totalRewards = rewards.length;
        const totalRewardAmount = rewards.reduce((sum, r) => sum + (r.amount || 0), 0);

        return {
            totalPrograms,
            totalReferrals,
            totalRewards,
            totalRewardAmount
        };
    }, [programs, referrals, rewards]);

    const filteredPrograms = useMemo(() => {
        return programs.filter((p) => {
            if (programStatusFilter && p.status !== programStatusFilter) return false;
            if (programTypeFilter && p.type !== programTypeFilter) return false;
            if (programSearch) {
                const q = programSearch.toLowerCase();
                const nameMatch = p.name?.toLowerCase().includes(q);
                const codeMatch = p.code?.toLowerCase().includes(q);
                if (!nameMatch && !codeMatch) return false;
            }
            return true;
        });
    }, [programs, programStatusFilter, programTypeFilter, programSearch]);

    const filteredReferrals = useMemo(() => {
        return referrals.filter((r) => {
            if (referralStatusFilter && r.status !== referralStatusFilter) return false;
            if (referralProgramFilter && r.program?.id !== referralProgramFilter) return false;
            return true;
        });
    }, [referrals, referralStatusFilter, referralProgramFilter]);

    const filteredRewards = useMemo(() => {
        return rewards.filter((r) => {
            if (rewardStatusFilter && r.status !== rewardStatusFilter) return false;
            if (rewardProgramFilter && r.referral?.program?.id !== rewardProgramFilter) return false;
            if (rewardBeneficiarySearch) {
                const q = rewardBeneficiarySearch.toLowerCase();
                const beneficiaryName = r.beneficiary?.name?.toLowerCase() || '';
                const referrerName = r.referral?.referrer?.name?.toLowerCase() || '';
                const refereeName = r.referral?.referee?.name?.toLowerCase() || '';
                if (!beneficiaryName.includes(q) && !referrerName.includes(q) && !refereeName.includes(q)) {
                    return false;
                }
            }
            return true;
        });
    }, [rewards, rewardStatusFilter, rewardProgramFilter, rewardBeneficiarySearch]);

    const programOptions = useMemo(
        () =>
            programs.map((p) => ({
                id: p.id,
                label: p.name || p.code || p.id
            })),
        [programs]
    );

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Referral & Rewards</h1>
                    <p className="text-slate-500 mt-1">
                        Monitor program referral merchant, performa akuisisi, dan komisi pendaftaran.
                    </p>
                </div>
                <div className="flex gap-3">
                    <Button
                        variant="secondary"
                        icon={RefreshCw}
                        onClick={fetchData}
                        isLoading={refreshing && loading}
                    >
                        Refresh Data
                    </Button>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-8">
                <Card className="p-5 flex items-center justify-between">
                    <div>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Program Aktif</p>
                        <p className="mt-2 text-2xl font-bold text-slate-900">{summary.totalPrograms}</p>
                    </div>
                    <div className="h-10 w-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                        <LayoutDashboard className="w-5 h-5" />
                    </div>
                </Card>
                <Card className="p-5 flex items-center justify-between">
                    <div>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Total Referral</p>
                        <p className="mt-2 text-2xl font-bold text-slate-900">{summary.totalReferrals}</p>
                    </div>
                    <div className="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                        <Users className="w-5 h-5" />
                    </div>
                </Card>
                <Card className="p-5 flex items-center justify-between">
                    <div>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Total Reward</p>
                        <p className="mt-2 text-2xl font-bold text-slate-900">{summary.totalRewards}</p>
                    </div>
                    <div className="h-10 w-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                        <Gift className="w-5 h-5" />
                    </div>
                </Card>
                <Card className="p-5 flex items-center justify-between">
                    <div>
                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Total Komisi</p>
                        <p className="mt-2 text-2xl font-bold text-slate-900">{formatCurrency(summary.totalRewardAmount)}</p>
                    </div>
                    <div className="h-10 w-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center">
                        <Wallet className="w-5 h-5" />
                    </div>
                </Card>
            </div>

            <div className="grid gap-6 lg:grid-cols-2 mb-8">
                <Card className="border border-slate-200">
                    <CardHeader>
                        <div className="flex items-center justify-between">
                            <div>
                                <CardTitle>Program Referral</CardTitle>
                                <CardDescription>Daftar program referral dan konfigurasi komisi.</CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="grid gap-4 md:grid-cols-3 mb-4">
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Status</span>
                                <select
                                    className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                    value={programStatusFilter}
                                    onChange={(e) => setProgramStatusFilter(e.target.value)}
                                >
                                    <option value="">Semua</option>
                                    {uniqueProgramStatuses.map((status) => (
                                        <option key={status} value={status}>
                                            {status}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Tipe Program</span>
                                <select
                                    className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                    value={programTypeFilter}
                                    onChange={(e) => setProgramTypeFilter(e.target.value)}
                                >
                                    <option value="">Semua</option>
                                    {uniqueProgramTypes.map((type) => (
                                        <option key={type} value={type}>
                                            {type}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Cari</span>
                                <input
                                    type="text"
                                    placeholder="Nama atau kode program..."
                                    className="w-full px-3 py-2 border rounded-md text-sm"
                                    value={programSearch}
                                    onChange={(e) => setProgramSearch(e.target.value)}
                                />
                            </div>
                        </div>

                        <div className="border border-slate-100 rounded-xl overflow-hidden">
                            <Table>
                                <Thead>
                                    <Tr>
                                        <Th>Program</Th>
                                        <Th>Tipe</Th>
                                        <Th>Reward L1</Th>
                                        <Th>Status</Th>
                                        <Th>Dibuat</Th>
                                    </Tr>
                                </Thead>
                                <Tbody>
                                    {loading ? (
                                        <Tr>
                                            <Td colSpan="5" className="text-center py-8 text-slate-400">
                                                Memuat data...
                                            </Td>
                                        </Tr>
                                    ) : filteredPrograms.length === 0 ? (
                                        <Tr>
                                            <Td colSpan="5" className="text-center py-8 text-slate-400">
                                                Tidak ada program referral.
                                            </Td>
                                        </Tr>
                                    ) : (
                                        filteredPrograms.map((p) => (
                                            <Tr key={p.id}>
                                                <Td>
                                                    <div className="flex flex-col">
                                                        <span className="font-medium text-slate-900">{p.name}</span>
                                                        <span className="text-xs text-slate-500">Kode: {p.code}</span>
                                                    </div>
                                                </Td>
                                                <Td>
                                                    <Badge variant="neutral">{p.type}</Badge>
                                                </Td>
                                                <Td>
                                                    <span className="font-mono text-slate-800">
                                                        {formatCurrency(p.rewardL1 || 0)}
                                                    </span>
                                                </Td>
                                                <Td>
                                                    <Badge
                                                        variant={
                                                            p.status === 'ACTIVE'
                                                                ? 'success'
                                                                : p.status === 'INACTIVE'
                                                                ? 'neutral'
                                                                : 'warning'
                                                        }
                                                    >
                                                        {p.status}
                                                    </Badge>
                                                </Td>
                                                <Td>
                                                    {p.createdAt ? new Date(p.createdAt).toLocaleDateString() : '-'}
                                                </Td>
                                            </Tr>
                                        ))
                                    )}
                                </Tbody>
                            </Table>
                        </div>
                    </CardContent>
                </Card>

                <Card className="border border-slate-200">
                    <CardHeader>
                        <div className="flex items-center justify-between">
                            <div>
                                <CardTitle>Reward Komisi</CardTitle>
                                <CardDescription>
                                    Daftar reward referral yang dibayarkan ke merchant.
                                </CardDescription>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="grid gap-4 md:grid-cols-3 mb-4">
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Status Reward</span>
                                <select
                                    className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                    value={rewardStatusFilter}
                                    onChange={(e) => setRewardStatusFilter(e.target.value)}
                                >
                                    <option value="">Semua</option>
                                    {uniqueRewardStatuses.map((status) => (
                                        <option key={status} value={status}>
                                            {status}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Program</span>
                                <select
                                    className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                    value={rewardProgramFilter}
                                    onChange={(e) => setRewardProgramFilter(e.target.value)}
                                >
                                    <option value="">Semua</option>
                                    {programOptions.map((p) => (
                                        <option key={p.id} value={p.id}>
                                            {p.label}
                                        </option>
                                    ))}
                                </select>
                            </div>
                            <div className="flex flex-col gap-1">
                                <span className="text-xs font-semibold text-slate-500 uppercase">Cari Merchant</span>
                                <input
                                    type="text"
                                    placeholder="Tenant/referrer/referee..."
                                    className="w-full px-3 py-2 border rounded-md text-sm"
                                    value={rewardBeneficiarySearch}
                                    onChange={(e) => setRewardBeneficiarySearch(e.target.value)}
                                />
                            </div>
                        </div>

                        <div className="border border-slate-100 rounded-xl overflow-hidden">
                            <Table>
                                <Thead>
                                    <Tr>
                                        <Th>Tanggal</Th>
                                        <Th>Beneficiary</Th>
                                        <Th>Program</Th>
                                        <Th>Amount</Th>
                                        <Th>Status</Th>
                                    </Tr>
                                </Thead>
                                <Tbody>
                                    {loading ? (
                                        <Tr>
                                            <Td colSpan="5" className="text-center py-8 text-slate-400">
                                                Memuat data...
                                            </Td>
                                        </Tr>
                                    ) : filteredRewards.length === 0 ? (
                                        <Tr>
                                            <Td colSpan="5" className="text-center py-8 text-slate-400">
                                                Tidak ada reward komisi.
                                            </Td>
                                        </Tr>
                                    ) : (
                                        filteredRewards.map((r) => (
                                            <Tr key={r.id}>
                                                <Td>
                                                    <div className="flex flex-col">
                                                        <span className="font-medium text-slate-900">
                                                            {r.createdAt
                                                                ? new Date(r.createdAt).toLocaleDateString()
                                                                : '-'}
                                                        </span>
                                                        <span className="text-xs text-slate-500">
                                                            Level {r.level || 1}
                                                        </span>
                                                    </div>
                                                </Td>
                                                <Td>
                                                    <div className="flex flex-col">
                                                        <span className="font-medium text-slate-900">
                                                            {r.beneficiary?.name || '-'}
                                                        </span>
                                                        <span className="text-xs text-slate-500">
                                                            Referrer: {r.referral?.referrer?.name || '-'}
                                                        </span>
                                                        <span className="text-xs text-slate-500">
                                                            Referee: {r.referral?.referee?.name || '-'}
                                                        </span>
                                                    </div>
                                                </Td>
                                                <Td>
                                                    <div className="flex flex-col">
                                                        <span className="font-medium text-slate-900">
                                                            {r.referral?.program?.name || '-'}
                                                        </span>
                                                        <span className="text-xs text-slate-500">
                                                            Kode: {r.referral?.program?.code || '-'}
                                                        </span>
                                                    </div>
                                                </Td>
                                                <Td>
                                                    <span className="font-mono text-slate-800">
                                                        {formatCurrency(r.amount || 0)}
                                                    </span>
                                                </Td>
                                                <Td>
                                                    <Badge
                                                        variant={
                                                            r.status === 'RELEASED'
                                                                ? 'success'
                                                                : r.status === 'PENDING'
                                                                ? 'warning'
                                                                : 'neutral'
                                                        }
                                                    >
                                                        {r.status}
                                                    </Badge>
                                                </Td>
                                            </Tr>
                                        ))
                                    )}
                                </Tbody>
                            </Table>
                        </div>
                    </CardContent>
                </Card>
            </div>

            <Card className="border border-slate-200">
                <CardHeader>
                    <div className="flex items-center justify-between">
                        <div>
                            <CardTitle>Referral Detail</CardTitle>
                            <CardDescription>
                                Tracking daftar referral yang terjadi per program dan status.
                            </CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-3 mb-4">
                        <div className="flex flex-col gap-1">
                            <span className="text-xs font-semibold text-slate-500 uppercase">Status Referral</span>
                            <select
                                className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                value={referralStatusFilter}
                                onChange={(e) => setReferralStatusFilter(e.target.value)}
                            >
                                <option value="">Semua</option>
                                {uniqueReferralStatuses.map((status) => (
                                    <option key={status} value={status}>
                                        {status}
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div className="flex flex-col gap-1">
                            <span className="text-xs font-semibold text-slate-500 uppercase">Program</span>
                            <select
                                className="w-full px-3 py-2 border rounded-md text-sm bg-white"
                                value={referralProgramFilter}
                                onChange={(e) => setReferralProgramFilter(e.target.value)}
                            >
                                <option value="">Semua</option>
                                {programOptions.map((p) => (
                                    <option key={p.id} value={p.id}>
                                        {p.label}
                                    </option>
                                ))}
                            </select>
                        </div>
                    </div>

                    <div className="border border-slate-100 rounded-xl overflow-hidden">
                        <Table>
                            <Thead>
                                <Tr>
                                    <Th>Tanggal</Th>
                                    <Th>Program</Th>
                                    <Th>Referrer</Th>
                                    <Th>Referee</Th>
                                    <Th>Status</Th>
                                </Tr>
                            </Thead>
                            <Tbody>
                                {loading ? (
                                    <Tr>
                                        <Td colSpan="5" className="text-center py-8 text-slate-400">
                                            Memuat data...
                                        </Td>
                                    </Tr>
                                ) : filteredReferrals.length === 0 ? (
                                    <Tr>
                                        <Td colSpan="5" className="text-center py-8 text-slate-400">
                                            Tidak ada referral tercatat.
                                        </Td>
                                    </Tr>
                                ) : (
                                    filteredReferrals.map((r) => (
                                        <Tr key={r.id}>
                                            <Td>
                                                {r.createdAt
                                                    ? new Date(r.createdAt).toLocaleDateString()
                                                    : '-'}
                                            </Td>
                                            <Td>
                                                <div className="flex flex-col">
                                                    <span className="font-medium text-slate-900">
                                                        {r.program?.name || '-'}
                                                    </span>
                                                    <span className="text-xs text-slate-500">
                                                        Kode: {r.program?.code || '-'}
                                                    </span>
                                                </div>
                                            </Td>
                                            <Td>{r.referrer?.name || '-'}</Td>
                                            <Td>{r.referee?.name || '-'}</Td>
                                            <Td>
                                                <Badge variant="brand">{r.status}</Badge>
                                            </Td>
                                        </Tr>
                                    ))
                                )}
                            </Tbody>
                        </Table>
                    </div>
                </CardContent>
            </Card>
        </AdminLayout>
    );
};

export default ReferralMonitoring;

