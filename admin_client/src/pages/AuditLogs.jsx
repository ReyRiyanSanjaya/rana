import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Table, Thead, Tbody, Th, Td, Tr } from '../components/ui/Table';
import Card from '../components/ui/Card';
import Badge from '../components/ui/Badge';
import { ShieldAlert, User, FileText } from 'lucide-react';

const AuditLogs = () => {
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);

    const fetchLogs = async () => {
        try {
            const res = await api.get('/admin/audit-logs');
            setLogs(res.data.data);
        } catch (error) {
            console.error("Failed to fetch logs", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchLogs();
    }, []);

    const formatDetail = (jsonStr) => {
        try {
            const obj = JSON.parse(jsonStr);
            return JSON.stringify(obj, null, 1).replace(/[{}"\\]/g, ' ').trim();
        } catch {
            return jsonStr;
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">Audit Logs</h1>
                <p className="text-slate-500 mt-1">Security trail of administrative actions.</p>
            </div>

            <Card className="overflow-hidden border border-slate-200 shadow-sm">
                <Table>
                    <Thead>
                        <Tr>
                            <Th>Time</Th>
                            <Th>Actor (User ID)</Th>
                            <Th>Action</Th>
                            <Th>Entity</Th>
                            <Th>Details</Th>
                        </Tr>
                    </Thead>
                    <Tbody>
                        {loading ? (
                            <Tr><Td colSpan="5" className="text-center py-12 text-slate-400">Loading records...</Td></Tr>
                        ) : logs.length === 0 ? (
                            <Tr><Td colSpan="5" className="text-center py-12 text-slate-400">No activity recorded.</Td></Tr>
                        ) : logs.map((log) => (
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
                                    <span className="text-xs text-slate-500 truncate max-w-[200px] block" title={log.newValue}>
                                        {formatDetail(log.newValue)}
                                    </span>
                                </Td>
                            </Tr>
                        ))}
                    </Tbody>
                </Table>
            </Card>
        </AdminLayout>
    );
};

export default AuditLogs;
