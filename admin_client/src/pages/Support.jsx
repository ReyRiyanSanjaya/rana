import React, { useEffect, useState, useRef } from 'react';
import api from '../api';
import { io } from 'socket.io-client'; // [NEW]
import AdminLayout from '../components/AdminLayout';
import { MessageSquare, Check, X, Send } from 'lucide-react';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import { Table, Thead, Tbody, Tr, Th, Td } from '../components/ui/Table';

const Support = () => {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [replyMessage, setReplyMessage] = useState('');
    const [typingUser, setTypingUser] = useState(null); // [NEW]
    const socketRef = useRef(null);

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

    useEffect(() => {
        fetchTickets();
    }, []);

    const handleSelectTicket = async (id) => {
        try {
            const res = await api.get(`/admin/tickets/${id}`);
            setSelectedTicket(res.data.data);
        } catch (error) {
            alert("Failed to load ticket");
        }
    };

    const handleReply = async () => {
        if (!replyMessage.trim()) return;
        try {
            const res = await api.post(`/admin/tickets/${selectedTicket.id}/reply`, { message: replyMessage });
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

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">Support Tickets</h1>
                <p className="text-slate-500 mt-1">Resolve merchant inquiries and technical issues.</p>
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
                        ) : tickets.length === 0 ? (
                            <div className="p-6 text-center text-slate-400">No tickets found.</div>
                        ) : tickets.map(ticket => (
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
                                <div className="text-xs text-slate-500 flex justify-between">
                                    <span>{ticket.tenant?.name || 'Unknown Merchant'}</span>
                                    <span>{new Date(ticket.updatedAt).toLocaleDateString()}</span>
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
                                </div>
                                <div className="flex gap-2">
                                    {selectedTicket.status !== 'RESOLVED' && (
                                        <Button size="sm" variant="outline" onClick={() => handleStatus('RESOLVED')}>
                                            <Check size={16} className="mr-1" /> Mark Resolved
                                        </Button>
                                    )}
                                    {selectedTicket.status !== 'CLOSED' && (
                                        <Button size="sm" variant="outline" onClick={() => handleStatus('CLOSED')} className="text-slate-600 border-slate-200 hover:bg-slate-50">
                                            <X size={16} className="mr-1" /> Close
                                        </Button>
                                    )}
                                </div>
                            </div>

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
                            </div>

                            {/* Typing Indicator */}
                            {typingUser && (
                                <div className="px-4 py-2 text-xs text-slate-400 italic bg-white border-t border-slate-50">
                                    {typingUser}
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
        </AdminLayout>
    );
};

export default Support;
