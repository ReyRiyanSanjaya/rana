import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';

const Merchants = () => {
    const [merchants, setMerchants] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');

    useEffect(() => {
        const fetchMerchants = async () => {
            try {
                const res = await api.get('/admin/merchants');
                setMerchants(res.data.data);
            } catch (error) {
                console.error(error);
            } finally {
                setLoading(false);
            }
        };
        fetchMerchants();
    }, []);

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val);

    const filteredMerchants = merchants.filter(m =>
        m.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.name?.toLowerCase().includes(search.toLowerCase()) ||
        m.tenant?.email?.toLowerCase().includes(search.toLowerCase())
    );

    return (
        <AdminLayout>
            <div className="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Merchants</h1>
                    <p className="text-slate-500 mt-1">View list of all registered stores and their balances.</p>
                </div>
                <div className="w-full md:w-72">
                    <input
                        type="text"
                        placeholder="Search stores, owners..."
                        className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none text-sm transition shadow-sm"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Store Info</Th>
                            <Th>Owner</Th>
                            <Th>Active Balance</Th>
                            <Th>Joined Date</Th>
                            <Th>Status</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">Loading merchants...</Td>
                            </Tr>
                        ) : filteredMerchants.length === 0 ? (
                            <Tr>
                                <Td colSpan="5" className="text-center py-12 text-slate-400">No merchants found.</Td>
                            </Tr>
                        ) : filteredMerchants.map((m) => (
                            <Tr key={m.id}>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="font-medium text-slate-900">{m.name}</span>
                                        <span className="text-xs text-slate-500">{m.address || 'No address set'}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <div className="flex flex-col">
                                        <span className="text-slate-900">{m.tenant?.name || 'Unknown'}</span>
                                        <span className="text-xs text-slate-500">{m.tenant?.email}</span>
                                    </div>
                                </Td>
                                <Td>
                                    <span className="font-mono font-medium text-green-700">{formatCurrency(m.balance)}</span>
                                </Td>
                                <Td>
                                    <span className="text-slate-500 text-sm">{new Date(m.createdAt).toLocaleDateString()}</span>
                                </Td>
                                <Td>
                                    <Badge variant="success">Active</Badge>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>
        </AdminLayout>
    );
};

export default Merchants;
