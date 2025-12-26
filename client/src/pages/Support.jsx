import React, { useEffect, useState } from 'react';
import api from '../services/api';
import DashboardLayout from '../components/layout/DashboardLayout';
import { MessageSquare, Check, X, Send, Plus, HelpCircle } from 'lucide-react';
// Simple Card replacement since ui/card might not exist yet
const Card = ({ children, className }) => (
    <div className={`bg-white rounded-xl shadow-sm border border-slate-100 ${className}`}>{children}</div>
);

const Badge = ({ children, variant }) => {
    const colors = {
        OPEN: 'bg-yellow-100 text-yellow-700',
        RESOLVED: 'bg-green-100 text-green-700',
        CLOSED: 'bg-slate-100 text-slate-700',
        IN_PROGRESS: 'bg-blue-100 text-blue-700'
    };
    return <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${colors[variant] || colors.CLOSED}`}>{children}</span>;
}

const Support = () => {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [replyMessage, setReplyMessage] = useState('');

    // Create Modal State
    const [showCreate, setShowCreate] = useState(false);
    const [newTicket, setNewTicket] = useState({ subject: '', message: '', priority: 'NORMAL' });

    const fetchTickets = async () => {
        try {
            const res = await api.get('/tickets'); // Corrected path
            setTickets(res.data.data);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTickets();
    }, []);

    const handleSelectTicket = async (id) => {
        try {
            const res = await api.get(`/tickets/${id}`);
            setSelectedTicket(res.data.data);
        } catch (error) {
            alert("Failed to load ticket");
        }
    };

    const handleCreate = async (e) => {
        e.preventDefault();
        try {
            await api.post('/tickets', newTicket);
            setShowCreate(false);
            setNewTicket({ subject: '', message: '', priority: 'NORMAL' });
            fetchTickets();
            alert("Ticket created!");
        } catch (error) {
            alert("Failed to create ticket");
        }
    };

    const handleReply = async () => {
        if (!replyMessage.trim()) return;
        try {
            const res = await api.post(`/tickets/${selectedTicket.id}/reply`, { message: replyMessage });
            setReplyMessage('');
            setSelectedTicket(prev => ({
                ...prev,
                messages: [...prev.messages, res.data.data]
            }));
        } catch (error) {
            alert("Failed to send reply");
        }
    };

    return (
        <DashboardLayout>
            <div className="mb-6 flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900">Help & Support</h1>
                    <p className="text-slate-500 mt-1">Get help with technical issues or billing.</p>
                </div>
                <button
                    onClick={() => setShowCreate(true)}
                    className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition"
                >
                    <Plus size={18} /> New Ticket
                </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[calc(100vh-200px)]">
                {/* LIST */}
                <Card className="lg:col-span-1 overflow-hidden flex flex-col">
                    <div className="p-4 border-b border-slate-100 bg-slate-50 font-medium text-slate-700">
                        Recent Tickets
                    </div>
                    <div className="overflow-y-auto flex-1">
                        {loading ? (
                            <div className="p-6 text-center text-slate-400">Loading...</div>
                        ) : tickets.length === 0 ? (
                            <div className="p-6 text-center text-slate-400 flex flex-col items-center">
                                <HelpCircle size={32} className="mb-2 opacity-50" />
                                No support tickets yet.
                            </div>
                        ) : tickets.map(ticket => (
                            <div
                                key={ticket.id}
                                onClick={() => handleSelectTicket(ticket.id)}
                                className={`p-4 border-b border-slate-50 cursor-pointer hover:bg-slate-50 transition ${selectedTicket?.id === ticket.id ? 'bg-indigo-50 border-l-4 border-l-indigo-500' : ''}`}
                            >
                                <div className="flex justify-between items-start mb-1">
                                    <h4 className="font-medium text-slate-900 truncate pr-2">{ticket.subject}</h4>
                                    <Badge variant={ticket.status}>{ticket.status}</Badge>
                                </div>
                                <div className="text-xs text-slate-500 flex justify-between">
                                    <span>#{ticket.id.substring(0, 8)}</span>
                                    <span>{new Date(ticket.updatedAt).toLocaleDateString()}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </Card>

                {/* DETAIL */}
                <Card className="lg:col-span-2 overflow-hidden flex flex-col">
                    {selectedTicket ? (
                        <>
                            <div className="p-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                                <div>
                                    <h3 className="font-semibold text-slate-900">{selectedTicket.subject}</h3>
                                    <div className="text-xs text-slate-500">
                                        Ticket ID: #{selectedTicket.id.substring(0, 8)}
                                    </div>
                                </div>
                                <div className="flex gap-2">
                                    <Badge variant={selectedTicket.status}>{selectedTicket.status}</Badge>
                                </div>
                            </div>

                            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-slate-50/50">
                                {selectedTicket.messages?.map(msg => (
                                    <div key={msg.id} className={`flex ${msg.senderType === 'MERCHANT' ? 'justify-end' : 'justify-start'}`}>
                                        <div className={`max-w-[75%] rounded-lg p-3 text-sm shadow-sm ${msg.senderType === 'MERCHANT'
                                            ? 'bg-indigo-600 text-white rounded-br-none'
                                            : 'bg-white border border-slate-200 text-slate-800 rounded-bl-none'
                                            }`}>
                                            <p>{msg.message}</p>
                                            <div className={`text-[10px] mt-1 ${msg.senderType === 'MERCHANT' ? 'text-indigo-200' : 'text-slate-400'}`}>
                                                {new Date(msg.createdAt).toLocaleString()}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>

                            <div className="p-4 border-t border-slate-100 bg-white">
                                <div className="flex gap-2">
                                    <input
                                        className="flex-1 px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none text-sm"
                                        placeholder="Type your reply..."
                                        value={replyMessage}
                                        onChange={e => setReplyMessage(e.target.value)}
                                        onKeyDown={e => e.key === 'Enter' && handleReply()}
                                    />
                                    <button
                                        onClick={handleReply}
                                        disabled={!replyMessage.trim()}
                                        className="bg-indigo-600 text-white p-2 rounded-lg hover:bg-indigo-700 disabled:opacity-50"
                                    >
                                        <Send size={18} />
                                    </button>
                                </div>
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

            {/* CREATE MODAL */}
            {showCreate && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                    <Card className="w-full max-w-md p-6 animate-in zoom-in-95 duration-200">
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold">New Support Ticket</h2>
                            <button onClick={() => setShowCreate(false)} className="text-slate-400 hover:text-slate-600"><X size={24} /></button>
                        </div>
                        <form onSubmit={handleCreate} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Subject</label>
                                <input
                                    required
                                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none"
                                    placeholder="e.g., Issue with payments"
                                    value={newTicket.subject}
                                    onChange={e => setNewTicket({ ...newTicket, subject: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Priority</label>
                                <select
                                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none"
                                    value={newTicket.priority}
                                    onChange={e => setNewTicket({ ...newTicket, priority: e.target.value })}
                                >
                                    <option value="NORMAL">Normal</option>
                                    <option value="HIGH">High</option>
                                    <option value="URGENT">Urgent</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Message</label>
                                <textarea
                                    required
                                    rows={4}
                                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none"
                                    placeholder="Describe your issue..."
                                    value={newTicket.message}
                                    onChange={e => setNewTicket({ ...newTicket, message: e.target.value })}
                                />
                            </div>
                            <div className="flex justify-end gap-3 pt-2">
                                <button type="button" onClick={() => setShowCreate(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                                <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">Submit Ticket</button>
                            </div>
                        </form>
                    </Card>
                </div>
            )}
        </DashboardLayout>
    );
};

export default Support;
