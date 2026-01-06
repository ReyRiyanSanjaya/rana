import React, { useEffect, useState, useRef } from 'react';
import api from '../api';
import { io } from 'socket.io-client'; // [NEW]
import AdminLayout from '../components/AdminLayout';
import { MessageSquare, Check, X, Send, FileText, Settings as Cog, Filter, Download, AlertTriangle } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import { Table, Thead, Tbody, Tr, Th, Td } from '../components/ui/Table';
import Input from '../components/ui/Input';

const Support = () => {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [replyMessage, setReplyMessage] = useState('');
    const [typingUser, setTypingUser] = useState(null); // [NEW]
    const socketRef = useRef(null);
    const messagesEndRef = useRef(null);
    const quickReplies = [
        "Halo, kami sudah menerima laporan Anda.",
        "Mohon tunggu, kami sedang mengecek kendala ini.",
        "Bisakah kirimkan screenshot/nomor pesanan terkait?",
        "Terima kasih, masalah akan kami tindak lanjuti."
    ];
    const [templates, setTemplates] = useState([]);
    const [showTplModal, setShowTplModal] = useState(false);
    const [tplDraft, setTplDraft] = useState({ title: '', category: 'General', body: '' });
    const [editingTplIndex, setEditingTplIndex] = useState(null);
    const [query, setQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [exporting, setExporting] = useState(false);
    const [metaMap, setMetaMap] = useState({});
    const [slaHours, setSlaHours] = useState(24);
    const [showControls, setShowControls] = useState(false);
    const [autoReplyEnabled, setAutoReplyEnabled] = useState(false);
    const [autoReplyMessage, setAutoReplyMessage] = useState('Halo {merchant_name}, tiket #{ticket_id} sudah kami terima dan sedang diproses. {date}');
    const autoReplyCacheRef = useRef({});
    const [showSuggestions, setShowSuggestions] = useState(false);
    const [showTools, setShowTools] = useState(false);

    const scrollToBottom = () => {
        // smooth scroll to latest message
        if (messagesEndRef.current) {
            messagesEndRef.current.scrollIntoView({ behavior: 'smooth', block: 'end' });
        }
    };

    // Initialize Socket
    useEffect(() => {
        // Connect
        const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';
        const socketUrl = apiUrl.replace(/\/api\/?$/, '');
        console.log("Connecting to Socket:", socketUrl);

        socketRef.current = io(socketUrl, {
            auth: { token: localStorage.getItem('adminToken') },
            transports: ['websocket', 'polling'] // Force try both
        });

        socketRef.current.on('connect', () => {
            console.log("Socket Connected!", socketRef.current.id);
        });

        socketRef.current.on('connect_error', (err) => {
            console.log("Socket Connection Error:", err.message);
        });

        socketRef.current.on('new_message', (msg) => {
            setSelectedTicket(prev => {
                if (prev && prev.id === msg.ticketId) {
                    return { ...prev, messages: [...prev.messages, msg] };
                }
                return prev;
            });
            setTimeout(scrollToBottom, 50);
            const isAdminSender = msg.senderType === 'ADMIN' || msg.isAdmin === true;
            if (!isAdminSender && autoReplyEnabled) {
                const last = autoReplyCacheRef.current[msg.ticketId] || 0;
                const now = Date.now();
                if (now - last > 10 * 60 * 1000) {
                    const m = (selectedTicket?.tenant?.name) || 'Merchant';
                    const id = (msg.ticketId || '').toString().substring(0,8);
                    const date = new Date().toLocaleString();
                    const body = autoReplyMessage.replace('{merchant_name}', m).replace('{ticket_id}', id).replace('{date}', date) + '\n\nSalam,\nTim Support Rana POS\nsupport@rana.id • +62-812-3456-7890';
                    api.post(`/admin/tickets/${msg.ticketId}/reply`, { message: body }).catch(()=>{});
                    autoReplyCacheRef.current[msg.ticketId] = now;
                }
            }
        });
        socketRef.current.on('ticket:created', () => {
            fetchTickets();
        });

        socketRef.current.on('typing', ({ userId, ticketId, isTyping, role }) => {
            // Only show if we are looking at this ticket and user is NOT me (Admin)
            if (role === 'ADMIN') return;

            setSelectedTicket(prev => {
                if (prev && prev.id === ticketId) {
                    setTypingUser(isTyping ? "Merchant is typing..." : null);
                    return prev;
                }
                return prev;
            });
        });

        return () => {
            socketRef.current?.disconnect();
        };
    }, []);

    // Join Room when ticket selected
    useEffect(() => {
        if (selectedTicket) {
            socketRef.current.emit('join_ticket', selectedTicket.id);
            setTypingUser(null);
            setTimeout(scrollToBottom, 50);
        }
    }, [selectedTicket]); // Triggers when selectedTicket changes (ID or content)

    // Handle Typing Emit
    useEffect(() => {
        if (!selectedTicket) return;
        const timeoutId = setTimeout(() => {
            socketRef.current.emit('typing', { ticketId: selectedTicket.id, isTyping: false });
        }, 2000);

        socketRef.current.emit('typing', { ticketId: selectedTicket.id, isTyping: true });

        return () => clearTimeout(timeoutId);
    }, [replyMessage]); // On key press

    const fetchTickets = async () => {
        try {
            const res = await api.get('/admin/tickets');
            setTickets(res.data.data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };
    const fetchTemplates = async () => {
        try {
            const res = await api.get('/admin/settings');
            const map = {};
            (res.data.data || []).forEach(s => map[s.key] = s.value);
            const raw = map.SUPPORT_TICKET_TEMPLATES || '[]';
            let arr = [];
            try { arr = JSON.parse(raw); } catch { arr = []; }
            if (!Array.isArray(arr)) arr = [];
            setTemplates(arr);
            // Meta map
            try {
                const mm = map.SUPPORT_TICKET_META ? JSON.parse(map.SUPPORT_TICKET_META) : {};
                setMetaMap(mm && typeof mm === 'object' ? mm : {});
            } catch { setMetaMap({}); }
            try {
                const sla = parseFloat(map.SUPPORT_SLA_HOURS_DEFAULT || '24');
                setSlaHours(isNaN(sla) ? 24 : sla);
            } catch { setSlaHours(24); }
            try {
                setAutoReplyEnabled(String(map.SUPPORT_AUTO_REPLY_ENABLED || 'false') === 'true');
                setAutoReplyMessage(map.SUPPORT_AUTO_REPLY_MESSAGE || autoReplyMessage);
            } catch {}
        } catch {
            setTemplates([]);
            setMetaMap({});
        }
    };

    useEffect(() => {
        fetchTickets();
        fetchTemplates();
    }, []);

    const handleSelectTicket = async (id) => {
        try {
            const res = await api.get(`/admin/tickets/${id}`);
            setSelectedTicket(res.data.data);
            setTimeout(scrollToBottom, 50);
        } catch (error) {
            alert("Failed to load ticket");
        }
    };

    const formatProfessional = (text) => {
        const m = selectedTicket?.tenant?.name || 'Merchant';
        const id = selectedTicket?.id?.substring(0,8) || '';
        const date = new Date().toLocaleString();
        const body = text.replace('{merchant_name}', m).replace('{ticket_id}', id).replace('{date}', date);
        const signature = '\n\nSalam,\nTim Support Rana POS\nsupport@rana.id • +62-812-3456-7890';
        return body + signature;
    };
    const handleReply = async () => {
        if (!replyMessage.trim()) return;
        try {
            const res = await api.post(`/admin/tickets/${selectedTicket.id}/reply`, { message: formatProfessional(replyMessage) });
            setReplyMessage('');
            // Add new message to UI immediately for better UX
            setSelectedTicket(prev => ({
                ...prev,
                messages: [...prev.messages, res.data.data]
            }));
        } catch (error) {
            alert("Failed to send reply");
        }
    };

    const handleStatus = async (status) => {
        try {
            await api.put(`/admin/tickets/${selectedTicket.id}/status`, { status });
            setSelectedTicket(prev => ({ ...prev, status }));
            fetchTickets(); // Refresh list to update status there too
        } catch (error) {
            alert("Failed to update status");
        }
    };
    const filteredTickets = tickets
        .filter(t => statusFilter ? t.status === statusFilter : true)
        .filter(t => {
            if (!query.trim()) return true;
            const s = query.toLowerCase();
            return (t.subject || '').toLowerCase().includes(s) || (t.tenant?.name || '').toLowerCase().includes(s) || (t.id || '').toLowerCase().includes(s);
        });
    const exportCsv = () => {
        setExporting(true);
        try {
            const header = ['id','subject','merchant','status','updatedAt'];
            const rows = filteredTickets.map(t => [
                t.id, t.subject || '', t.tenant?.name || '', t.status || '', new Date(t.updatedAt).toISOString()
            ]);
            const csv = [header.join(','), ...rows.map(r => r.map(v => String(v).replace(/,/g,' ')).join(','))].join('\n');
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'tickets.csv';
            a.click();
            URL.revokeObjectURL(url);
        } finally {
            setExporting(false);
        }
    };
    const insertTemplate = (tpl) => {
        const m = selectedTicket?.tenant?.name || 'Merchant';
        const id = selectedTicket?.id?.substring(0,8) || '';
        const date = new Date().toLocaleString();
        const body = (tpl.body || '').replace('{merchant_name}', m).replace('{ticket_id}', id).replace('{date}', date);
        setReplyMessage(body);
    };
    const saveTemplates = async (next) => {
        try {
            await api.post('/admin/settings', { key: 'SUPPORT_TICKET_TEMPLATES', value: JSON.stringify(next), description: 'Support Ticket Templates' });
            setTemplates(next);
            setShowTplModal(false);
        } catch {
            alert('Failed to save templates');
        }
    };
    const saveMeta = async (ticketId, partial) => {
        const current = { ...metaMap };
        current[ticketId] = { ...(current[ticketId] || {}), ...partial };
        try {
            await api.post('/admin/settings', { key: 'SUPPORT_TICKET_META', value: JSON.stringify(current), description: 'Support Ticket Metadata' });
            setMetaMap(current);
        } catch {
            alert('Failed to save metadata');
        }
    };
    const exportTranscript = () => {
        if (!selectedTicket) return;
        const lines = [];
        lines.push(`Ticket #${selectedTicket.id}`);
        lines.push(`Subject: ${selectedTicket.subject}`);
        lines.push(`Merchant: ${selectedTicket.tenant?.name || '-'}`);
        lines.push(`Status: ${selectedTicket.status}`);
        lines.push('');
        (selectedTicket.messages || []).forEach(m => {
            const who = (m.isAdmin || m.senderType === 'ADMIN') ? 'ADMIN' : 'MERCHANT';
            lines.push(`[${new Date(m.createdAt).toLocaleString()}] ${who}: ${m.message}`);
        });
        const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ticket_${selectedTicket.id.substring(0,8)}.txt`;
        a.click();
        URL.revokeObjectURL(url);
    };
    const isOverdue = (t) => {
        if (!t?.createdAt || t.status !== 'OPEN') return false;
        const ageMs = Date.now() - new Date(t.createdAt).getTime();
        return ageMs > slaHours * 3600 * 1000;
    };
    const remainingHours = (t) => {
        if (!t?.createdAt || t.status !== 'OPEN') return null;
        const ageMs = Date.now() - new Date(t.createdAt).getTime();
        const left = slaHours - (ageMs / 3600000);
        return Math.max(-999, Math.round(left));
    };

    return (
        <AdminLayout>
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900">Support Tickets</h1>
                    <p className="text-slate-500 mt-1">Resolve merchant inquiries and technical issues.</p>
                </div>
                <div className="flex gap-2">
                    <Input placeholder="Search subject, merchant, id..." value={query} onChange={e => setQuery(e.target.value)} />
                    <select className="px-3 py-2 border rounded-lg text-sm bg-white" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
                        <option value="">All</option>
                        <option value="OPEN">OPEN</option>
                        <option value="RESOLVED">RESOLVED</option>
                        <option value="CLOSED">CLOSED</option>
                    </select>
                    <Button variant="outline" onClick={() => setShowTplModal(true)}><Cog size={16} className="mr-2" /> Templates</Button>
                    <Button variant="secondary" onClick={exportCsv} isLoading={exporting}><Download size={16} className="mr-2" /> Export</Button>
                    <div className="flex items-center gap-2 px-2 py-1 border rounded-lg">
                        <span className="text-xs text-slate-600">Auto Reply</span>
                        <input
                            type="checkbox"
                            checked={autoReplyEnabled}
                            onChange={async (e) => {
                                const val = e.target.checked;
                                setAutoReplyEnabled(val);
                                await api.post('/admin/settings', { key: 'SUPPORT_AUTO_REPLY_ENABLED', value: String(val), description: 'Auto Reply Enabled' }).catch(()=>{});
                            }}
                        />
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 h-[calc(100vh-200px)]">
                {/* Ticket List */}
                <Card className="lg:col-span-1 overflow-y-auto p-0">
                    <div className="p-4 border-b border-slate-100 bg-slate-50 font-medium text-slate-700">
                        Inbox
                    </div>
                    <div>
                        {loading ? (
                            <div className="p-6 text-center text-slate-400">Loading...</div>
                        ) : filteredTickets.length === 0 ? (
                            <div className="p-6 text-center text-slate-400">No tickets found.</div>
                        ) : filteredTickets.map(ticket => (
                            <div
                                key={ticket.id}
                                onClick={() => handleSelectTicket(ticket.id)}
                                className={`p-4 border-b border-slate-50 cursor-pointer hover:bg-slate-50 transition ${selectedTicket?.id === ticket.id ? 'bg-indigo-50 border-l-4 border-l-indigo-500' : ''}`}
                            >
                                <div className="flex justify-between items-start mb-1">
                                    <h4 className="font-medium text-slate-900 truncate pr-2">{ticket.subject}</h4>
                                    <Badge variant={ticket.status === 'OPEN' ? 'warning' : ticket.status === 'RESOLVED' ? 'success' : 'secondary'}>
                                        {ticket.status}
                                    </Badge>
                                </div>
                                <div className="text-xs text-slate-500 flex justify-between items-center">
                                    <span>{ticket.tenant?.name || 'Unknown Merchant'}</span>
                                    <div className="flex items-center gap-2">
                                        <span>{new Date(ticket.updatedAt).toLocaleDateString()}</span>
                                        {isOverdue(ticket) && (
                                            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] bg-red-100 text-red-700">
                                                <AlertTriangle size={10} className="mr-1" /> SLA Overdue
                                            </span>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </Card>

                {/* Ticket Detail / Chat */}
                <Card className="lg:col-span-2 overflow-hidden flex flex-col">
                    {selectedTicket ? (
                        <>
                            {/* Header */}
                            <div className="p-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                                <div>
                                    <h3 className="font-semibold text-slate-900">{selectedTicket.subject}</h3>
                                    <div className="text-xs text-slate-500">
                                        Ticket ID: #{selectedTicket.id.substring(0, 8)} • {selectedTicket.tenant?.name}
                                    </div>
                                    <div className="mt-1 flex items-center gap-2">
                                        <Badge variant={isOverdue(selectedTicket) ? 'danger' : 'secondary'}>
                                            {isOverdue(selectedTicket) ? 'Overdue' : `SLA ${remainingHours(selectedTicket) ?? '-'}h`}
                                        </Badge>
                                        <Badge variant="brand">{(metaMap[selectedTicket.id]?.priority || 'Normal')}</Badge>
                                        {metaMap[selectedTicket.id]?.assignee && (
                                            <Badge variant="secondary">Owner: {metaMap[selectedTicket.id].assignee}</Badge>
                                        )}
                                    </div>
                                </div>
                                <div className="flex gap-2">
                                    {selectedTicket.status !== 'RESOLVED' && (
                                        <Button size="sm" variant="outline" onClick={() => handleStatus('RESOLVED')}>
                                            <Check size={16} className="mr-1" /> Mark Resolved
                                        </Button>
                                    )}
                                    {selectedTicket.status !== 'CLOSED' && (
                                        <Button size="sm" variant="outline" onClick={() => handleStatus('CLOSED')}>
                                            <X size={16} className="mr-1" /> Close
                                        </Button>
                                    )}
                                    <Button size="sm" variant="secondary" onClick={exportTranscript}>
                                        <FileText size={16} className="mr-1" /> Transcript
                                    </Button>
                                    <Button size="sm" variant="outline" onClick={() => setShowControls(true)}>
                                        Show Controls
                                    </Button>
                                </div>
                            </div>

                            {/* Controls moved to modal to keep chat clean */}
                            {/* Messages Area */}
                            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-slate-50/50">
                                {selectedTicket.messages?.length === 0 ? (
                                    <div className="text-center text-slate-400 py-10">No messages yet.</div>
                                ) : selectedTicket.messages?.map(msg => (
                                    <div key={msg.id} className={`flex ${msg.isAdmin || msg.senderType === 'ADMIN' ? 'justify-end' : 'justify-start'}`}>
                                        <div className={`max-w-[70%] rounded-lg p-3 text-sm shadow-sm ${msg.isAdmin || msg.senderType === 'ADMIN'
                                            ? 'bg-indigo-600 text-white rounded-br-none'
                                            : 'bg-white border border-slate-200 text-slate-800 rounded-bl-none'
                                            }`}>
                                            <p>{msg.message}</p>
                                            <div className={`text-[10px] mt-1 ${msg.isAdmin ? 'text-indigo-200' : 'text-slate-400'}`}>
                                                {new Date(msg.createdAt).toLocaleString()}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                                <div ref={messagesEndRef} />
                            </div>

                            {/* Typing Indicator */}
                            {typingUser && (
                                <div className="px-4 py-2 text-xs text-slate-400 italic bg-white border-t border-slate-50 flex items-center gap-2">
                                    <span>{typingUser}</span>
                                    <span className="w-6 h-6">
                                        <lottie-player autoplay loop src="https://assets.lottiefiles.com/datafiles/wZLkZjYqGz9bJwY/data.json" style={{ width: '100%', height: '100%' }}></lottie-player>
                                    </span>
                                </div>
                            )}

                            {/* Reply Box */}
                            <div className="p-4 border-t border-slate-100 bg-white">
                                <div className="flex gap-2">
                                    <input
                                        className="flex-1 px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary-500 outline-none text-sm"
                                        placeholder="Type your reply..."
                                        value={replyMessage}
                                        onChange={e => setReplyMessage(e.target.value)}
                                        onKeyDown={e => e.key === 'Enter' && handleReply()}
                                    />
                                    <Button onClick={handleReply} disabled={!replyMessage.trim()}>
                                        <Send size={18} />
                                    </Button>
                                </div>
                                {showSuggestions && (
                                    <div className="flex flex-wrap gap-2 mt-3 overflow-x-auto">
                                        {quickReplies.map((q, idx) => (
                                            <button
                                                key={idx}
                                                className="px-2 py-0.5 text-[10px] bg-slate-100 hover:bg-slate-200 rounded"
                                                onClick={() => setReplyMessage(q)}
                                            >
                                                {q}
                                            </button>
                                        ))}
                                        {templates.map((t, idx) => (
                                            <button
                                                key={'tpl-' + idx}
                                                className="px-2 py-0.5 text-[10px] bg-indigo-50 hover:bg-indigo-100 rounded text-indigo-700"
                                                onClick={() => insertTemplate(t)}
                                            >
                                                {t.title}
                                            </button>
                                        ))}
                                    </div>
                                )}
                            </div>
                        </>
                    ) : (
                        <div className="flex-1 flex flex-col items-center justify-center text-slate-400">
                            <MessageSquare size={48} className="mb-4 opacity-20" />
                            <p>Select a ticket to view conversation</p>
                        </div>
                    )}
                </Card>
            </div>
            {selectedTicket && (
                <>
                    <button
                        onClick={() => setShowTools(s => !s)}
                        className="fixed bottom-6 right-6 h-12 w-12 rounded-full bg-indigo-600 text-white shadow-lg flex items-center justify-center"
                        aria-label="Tools"
                    >
                        <Cog size={20} />
                    </button>
                    {showTools && (
                        <div className="fixed bottom-24 right-6 bg-white rounded-xl border border-slate-200 shadow-xl p-3 w-80 text-xs space-y-2">
                            <div className="flex items-center justify-between">
                                <span>Suggestions</span>
                                <input type="checkbox" checked={showSuggestions} onChange={(e) => setShowSuggestions(e.target.checked)} />
                            </div>
                            <div className="flex items-center justify-between">
                                <span>Auto Reply</span>
                                <input
                                    type="checkbox"
                                    checked={autoReplyEnabled}
                                    onChange={async (e) => {
                                        const val = e.target.checked;
                                        setAutoReplyEnabled(val);
                                        await api.post('/admin/settings', { key: 'SUPPORT_AUTO_REPLY_ENABLED', value: String(val), description: 'Auto Reply Enabled' }).catch(()=>{});
                                    }}
                                />
                            </div>
                            <div>
                                <div className="text-[10px] text-slate-500 mb-1">Internal Notes</div>
                                <textarea
                                    className="w-full h-24 border rounded p-2 text-xs"
                                    placeholder="Write internal investigation notes..."
                                    value={metaMap[selectedTicket.id]?.notes || ''}
                                    onChange={(e) => saveMeta(selectedTicket.id, { notes: e.target.value })}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-2">
                                <Button size="sm" variant="outline" onClick={() => setShowTplModal(true)}>Templates</Button>
                                <Button size="sm" variant="outline" onClick={exportTranscript}>Transcript</Button>
                            </div>
                        </div>
                    )}
                </>
            )}
            {showTplModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <Card className="w-full max-w-2xl p-6">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-lg font-bold">Manage Templates</h3>
                            <Button variant="outline" onClick={() => setShowTplModal(false)}>Close</Button>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Input placeholder="Title" value={tplDraft.title} onChange={e => setTplDraft({ ...tplDraft, title: e.target.value })} />
                                <select className="w-full border rounded p-2 text-sm bg-white" value={tplDraft.category} onChange={e => setTplDraft({ ...tplDraft, category: e.target.value })}>
                                    <option>General</option>
                                    <option>Onboarding</option>
                                    <option>Troubleshooting</option>
                                    <option>Billing</option>
                                    <option>Closing</option>
                                </select>
                                <textarea className="w-full h-32 border rounded p-2 text-sm" value={tplDraft.body} onChange={e => setTplDraft({ ...tplDraft, body: e.target.value })} placeholder="Use placeholders: {merchant_name}, {ticket_id}, {date}" />
                                <div className="flex gap-2">
                                    <Button onClick={() => {
                                        if (!tplDraft.title.trim() || !tplDraft.body.trim()) return;
                                        const next = editingTplIndex != null ? templates.map((x,i)=> i===editingTplIndex ? tplDraft : x) : [...templates, tplDraft];
                                        setEditingTplIndex(null);
                                        setTplDraft({ title: '', category: 'General', body: '' });
                                        saveTemplates(next);
                                    }}>Save Template</Button>
                                    {editingTplIndex != null && (
                                        <Button variant="secondary" onClick={() => { setEditingTplIndex(null); setTplDraft({ title: '', category: 'General', body: '' }); }}>Cancel Edit</Button>
                                    )}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-slate-500 mb-2">Existing Templates</div>
                                <div className="space-y-2">
                                    {templates.length === 0 ? (
                                        <div className="text-slate-400 text-sm">No templates yet.</div>
                                    ) : templates.map((t, idx) => (
                                        <div key={idx} className="border rounded p-3">
                                            <div className="flex justify-between items-center">
                                                <div className="font-medium">{t.title}</div>
                                                <div className="text-xs text-slate-500">{t.category}</div>
                                            </div>
                                            <div className="text-xs text-slate-600 mt-2 whitespace-pre-line">{t.body}</div>
                                            <div className="mt-2 flex gap-2">
                                                <Button size="sm" variant="outline" onClick={() => { setEditingTplIndex(idx); setTplDraft(t); }}>Edit</Button>
                                                <Button size="sm" variant="destructive" onClick={() => saveTemplates(templates.filter((_,i)=>i!==idx))}>Delete</Button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                        <div className="mt-4 text-xs text-slate-500">Suggested professional templates include Greetings, Follow-up, Troubleshooting steps, Billing clarification, and Resolution/Closing.</div>
                    </Card>
                </div>
            )}
        </AdminLayout>
    );
};

export default Support;
