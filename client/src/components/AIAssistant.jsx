import React, { useState, useRef, useEffect } from 'react';
import { MessageSquare, X, Send, Sparkles, Bot } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const AIAssistant = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [messages, setMessages] = useState([
        { type: 'bot', text: 'Halo! Saya Rana AI. Ada yang bisa saya bantu terkait pengembangan bisnis Anda?' }
    ]);
    const [input, setInput] = useState('');
    const [isTyping, setIsTyping] = useState(false);
    const messagesEndRef = useRef(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const handleSend = async () => {
        if (!input.trim()) return;

        const userMessage = input;
        setMessages(prev => [...prev, { type: 'user', text: userMessage }]);
        setInput('');
        setIsTyping(true);

        // Simulate AI processing
        setTimeout(() => {
            const botResponse = generateResponse(userMessage);
            setMessages(prev => [...prev, { type: 'bot', text: botResponse }]);
            setIsTyping(false);
        }, 1500);
    };

    const generateResponse = (text) => {
        const lowerText = text.toLowerCase();
        if (lowerText.includes('harga') || lowerText.includes('biaya')) {
            return "Kami menawarkan paket fleksibel mulai dari Gratis untuk pemula hingga Enterprise untuk bisnis skala besar. Apakah Anda ingin melihat detail paket?";
        } else if (lowerText.includes('fitur') || lowerText.includes('bisa apa')) {
            return "Rana memiliki fitur lengkap: POS (Kasir), Manajemen Stok, Laporan Keuangan, dan Analisis Bisnis berbasis AI. Fitur mana yang paling menarik bagi Anda?";
        } else if (lowerText.includes('bisnis') || lowerText.includes('tumbuh')) {
            return "Dengan teknologi AI kami, Rana dapat memprediksi tren penjualan dan menyarankan stok yang tepat, membantu bisnis Anda tumbuh lebih cepat dan efisien.";
        } else if (lowerText.includes('kontak') || lowerText.includes('hubungi')) {
            return "Anda bisa menghubungi tim support kami melalui halaman Contact atau email ke support@rana.id.";
        } else {
            return "Pertanyaan yang menarik! Saya bisa menjelaskan lebih lanjut tentang fitur, harga, atau cara Rana membantu bisnis Anda berkembang.";
        }
    };

    return (
        <div className="fixed bottom-28 md:bottom-6 right-6 z-[60] flex flex-col items-end pointer-events-none">
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, y: 20, scale: 0.9 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: 20, scale: 0.9 }}
                        className="pointer-events-auto bg-[#0f172a]/95 backdrop-blur-xl border border-indigo-500/30 rounded-2xl shadow-2xl w-[350px] md:w-[400px] overflow-hidden mb-4"
                    >
                        {/* Header */}
                        <div className="bg-gradient-to-r from-indigo-600 to-violet-600 p-4 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="bg-white/20 p-2 rounded-lg">
                                    <Bot size={20} className="text-white" />
                                </div>
                                <div>
                                    <h3 className="font-bold text-white text-sm">Rana AI Assistant</h3>
                                    <div className="flex items-center gap-1.5">
                                        <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                                        <span className="text-xs text-indigo-100">Online & Ready</span>
                                    </div>
                                </div>
                            </div>
                            <button 
                                onClick={() => setIsOpen(false)}
                                className="text-white/80 hover:text-white transition-colors"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Chat Area */}
                        <div className="h-[400px] overflow-y-auto p-4 space-y-4 custom-scrollbar">
                            {messages.map((msg, idx) => (
                                <div
                                    key={idx}
                                    className={`flex ${msg.type === 'user' ? 'justify-end' : 'justify-start'}`}
                                >
                                    <div
                                        className={`max-w-[80%] p-3 rounded-2xl text-sm leading-relaxed ${
                                            msg.type === 'user'
                                                ? 'bg-indigo-600 text-white rounded-br-none'
                                                : 'bg-slate-700/50 text-slate-200 rounded-bl-none border border-slate-600/50'
                                        }`}
                                    >
                                        {msg.text}
                                    </div>
                                </div>
                            ))}
                            {isTyping && (
                                <div className="flex justify-start">
                                    <div className="bg-slate-700/50 p-3 rounded-2xl rounded-bl-none border border-slate-600/50 flex gap-1">
                                        <span className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                                        <span className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                                        <span className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                                    </div>
                                </div>
                            )}
                            <div ref={messagesEndRef} />
                        </div>

                        {/* Input Area */}
                        <div className="p-4 bg-slate-800/50 border-t border-indigo-500/20">
                            <form 
                                onSubmit={(e) => { e.preventDefault(); handleSend(); }}
                                className="flex gap-2"
                            >
                                <input
                                    type="text"
                                    value={input}
                                    onChange={(e) => setInput(e.target.value)}
                                    placeholder="Tanya tentang perkembangan bisnis..."
                                    className="flex-1 bg-slate-900/50 border border-slate-600 text-slate-200 text-sm rounded-xl px-4 py-2.5 focus:outline-none focus:border-indigo-500 transition-colors"
                                />
                                <button
                                    type="submit"
                                    disabled={!input.trim() || isTyping}
                                    className="bg-indigo-600 hover:bg-indigo-500 text-white p-2.5 rounded-xl transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    <Send size={18} />
                                </button>
                            </form>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>

            {/* Toggle Button */}
            <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => setIsOpen(!isOpen)}
                className="pointer-events-auto group relative flex items-center justify-center w-14 h-14 bg-gradient-to-br from-indigo-600 to-violet-600 rounded-full shadow-lg hover:shadow-indigo-500/25 transition-all duration-300"
            >
                {/* Glow Effect */}
                <div className="absolute inset-0 rounded-full bg-indigo-400 opacity-0 group-hover:opacity-20 blur-md transition-opacity duration-300" />
                
                {isOpen ? (
                    <X className="text-white" size={24} />
                ) : (
                    <Sparkles className="text-white animate-pulse" size={24} />
                )}
            </motion.button>
        </div>
    );
};

export default AIAssistant;
