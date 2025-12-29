import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import { Mail, Lock, ArrowRight } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState(''); // Default empty
    const [password, setPassword] = useState('');
    const { login } = useAuth();
    const navigate = useNavigate();
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setLoading(true);
        try {
            await login(email, password);
            // Navigation handled by AuthContext or protected route redirect usually, 
            // but here we force dashboard if successful and not handled inside login
            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.message || "Login failed");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] p-4 font-sans text-slate-200">
            <div className="bg-white/5 border border-white/10 p-8 md:p-12 rounded-[2rem] max-w-md w-full backdrop-blur-md">

                <div className="text-center mb-10">
                    <div className="w-16 h-16 bg-gradient-to-br from-indigo-600 to-violet-600 rounded-2xl flex items-center justify-center text-white font-bold text-3xl mx-auto mb-6">R</div>
                    <h1 className="text-3xl font-bold text-white mb-2">Selamat Datang Kembali</h1>
                    <p className="text-slate-400">Masukkan kredensial Anda untuk mengakses akun.</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {error && (
                        <div className="p-4 bg-red-500/10 text-red-300 rounded-xl text-sm border border-red-500/30 text-center">
                            {error}
                        </div>
                    )}

                    <InputGroup
                        icon={<Mail size={20} />}
                        type="email"
                        placeholder="Alamat Email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                    />

                    <InputGroup
                        icon={<Lock size={20} />}
                        type="password"
                        placeholder="Kata Sandi"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                    />

                    <div className="flex justify-end">
                        <a href="#" className="text-sm text-indigo-300 font-bold hover:underline">Lupa Kata Sandi?</a>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full py-4 bg-gradient-to-r from-indigo-600 to-violet-600 text-white font-bold rounded-2xl shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)] transition-all duration-300 flex items-center justify-center gap-2 group disabled:opacity-70"
                    >
                        {loading ? 'Masuk...' : 'Masuk'}
                        {!loading && <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />}
                    </button>

                    <p className="text-center text-slate-400 text-sm">
                        Belum punya akun? <Link to="/register" className="text-indigo-300 font-bold hover:underline">Daftar</Link>
                    </p>
                </form>
            </div>
        </div>
    );
};

const InputGroup = ({ icon, ...props }) => (
    <div className="relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
            {icon}
        </div>
        <input
            {...props}
            className="w-full bg-white/10 border border-white/10 rounded-xl py-4 pl-12 pr-4 text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 transition-all font-medium"
            required
        />
    </div>
);

export default Login;
