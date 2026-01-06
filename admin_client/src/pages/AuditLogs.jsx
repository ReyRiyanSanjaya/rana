import React, { useEffect, useState, useRef } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { ShieldAlert, User, FileText, RefreshCcw, Download } from 'lucide-react';

const AuditLogs = () => {
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [query, setQuery] = useState('');
    const [action, setAction] = useState('');
    const [entity, setEntity] = useState('');
    const [user, setUser] = useState('');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [page, setPage] = useState(1);
    const [perPage] = useState(20);
    const timerRef = useRef(null);

    const fetchLogs = async () => {
        try {
            setLoading(true);
            const params = new URLSearchParams();
            if (query) params.append('q', query);
            if (action) params.append('action', action);
            if (entity) params.append('entity', entity);
            if (user) params.append('user', user);
            if (dateFrom) params.append('from', dateFrom);
            if (dateTo) params.append('to', dateTo);
            const res = await api.get(`/admin/audit-logs?${params.toString()}`);
            setLogs(res.data.data || []);
        } catch (error) {
            console.error("Failed to fetch logs", error);
            setLogs([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchLogs();
        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
        };
    }, []);
    useEffect(() => {
        fetchLogs();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [query, action, entity, user, dateFrom, dateTo]);

    const formatDetail = (jsonStr) => {
        try {
            const obj = JSON.parse(jsonStr);
            return JSON.stringify(obj, null, 1).replace(/[{}"\\]/g, ' ').trim();
        } catch {
            return jsonStr;
        }
    };

    const exportCsv = () => {
        const header = ['time','userId','action','entity','ip','details'];
        const rows = logs.map(l => [
            new Date(l.occurredAt).toISOString(),
            l.userId || '',
            l.action || '',
            l.entity || '',
            l.ip || l.ipAddress || '',
            (l.newValue || '').replace(/\s+/g, ' ').slice(0, 1000)
        ]);
        const csv = [header.join(','), ...rows.map(r => r.map(v => String(v).replace(/,/g,' ')).join(','))].join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'audit_logs.csv';
        a.click();
        URL.revokeObjectURL(url);
    };

    const currentLogs = logs.slice((page - 1) * perPage, page * perPage);
    const totalPages = Math.ceil((logs.length || 0) / perPage) || 1;

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Audit Logs</h1>
                    <p className="text-slate-500 mt-1">Security trail of administrative actions.</p>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={fetchLogs}><RefreshCcw size={16} className="mr-2" /> Refresh</Button>
                    <Button variant="secondary" onClick={exportCsv}><Download size={16} className="mr-2" /> Export CSV</Button>
                </div>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <div className="p-3 border-b flex flex-wrap gap-2 items-center">
                    <Input placeholder="Search message/details..." value={query} onChange={e => setQuery(e.target.value)} />
                    <select className="px-3 py-2 border rounded-lg text-sm bg-white" value={action} onChange={(e) => setAction(e.target.value)}>
                        <option value="">All Actions</option>
                        <option value="CREATE">CREATE</option>
                        <option value="UPDATE">UPDATE</option>
                        <option value="DELETE">DELETE</option>
                        <option value="LOGIN">LOGIN</option>
                        <option value="LOGOUT">LOGOUT</option>
                    </select>
                    <Input placeholder="Entity..." value={entity} onChange={e => setEntity(e.target.value)} />
                    <Input placeholder="User ID or email..." value={user} onChange={e => setUser(e.target.value)} />
                    <input type="date" className="px-3 py-2 border rounded-lg text-sm bg-white" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
                    <input type="date" className="px-3 py-2 border rounded-lg text-sm bg-white" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
                </div>
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Time</Th>
                            <Th>Actor (User ID)</Th>
                            <Th>Action</Th>
                            <Th>Entity</Th>
                            <Th>IP</Th>
                            <Th>Details</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr><Td colSpan="6" className="text-center py-12 text-slate-400">Loading records...</Td></Tr>
                        ) : logs.length === 0 ? (
                            <Tr><Td colSpan="6" className="text-center py-12 text-slate-400">No activity recorded.</Td></Tr>
                        ) : currentLogs.map((log) => (
                            <Tr key={log.id}>
                                <Td><span className="text-slate-500 text-xs">{new Date(log.occurredAt).toLocaleString()}</span></Td>
                                <Td>
                                    <div className="flex items-center">
                                        <User size={14} className="mr-2 text-slate-400" />
                                        <span className="text-xs font-mono bg-slate-100 px-1 rounded">{log.userId?.substring(0, 8)}...</span>
                                    </div>
                                </Td>
                                <Td>
                                    <Badge variant={log.action.includes("DELETE") ? "error" : "brand"}>
                                        {log.action}
                                    </Badge>
                                </Td>
                                <Td>
                                    <div className="flex items-center text-slate-700">
                                        <FileText size={14} className="mr-2 text-slate-400" />
                                        {log.entity}
                                    </div>
                                </Td>
                                <Td>
                                    <span className="text-xs text-slate-500">{log.ip || log.ipAddress || '-'}</span>
                                </Td>
                                <Td>
                                    <span className="text-xs text-slate-500 truncate max-w-[200px] block" title={log.newValue}>
                                        {formatDetail(log.newValue)}
                                    </span>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
                {logs.length > 0 && (
                    <div className="flex justify-between items-center p-3 border-t">
                        <span className="text-sm text-slate-500">
                            Showing {(page - 1) * perPage + 1} to {Math.min(page * perPage, logs.length)} of {logs.length} entries
                        </span>
                        <div className="flex gap-2 items-center">
                            <Button variant="outline" size="sm" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>Prev</Button>
                            <span className="text-sm">{page} / {totalPages}</span>
                            <Button variant="outline" size="sm" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>Next</Button>
                        </div>
                    </div>
                )}
            </Card>
        </AdminLayout>
    );
};

export default AuditLogs;
