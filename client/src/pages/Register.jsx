import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { Building2, Mail, Lock, Phone, MapPin, ArrowRight, CheckCircle } from 'lucide-react';

const Register = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        businessName: '',
        email: '',
        password: '',
        waNumber: '',
        address: ''
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        try {
            await axios.post('http://localhost:4000/api/auth/register', formData);
            navigate('/login');
        } catch (err) {
            setError(err.response?.data?.message || 'Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] p-4 font-sans text-slate-200">
            <div className="bg-white/5 border border-white/10 p-8 md:p-12 rounded-[2rem] max-w-4xl w-full flex flex-col md:flex-row gap-12 items-center backdrop-blur-md">

                {/* Left Side: Hero/Info */}
                <div className="w-full md:w-1/2 space-y-8">
                    <div>
                        <div className="w-12 h-12 bg-gradient-to-br from-indigo-600 to-violet-600 rounded-2xl flex items-center justify-center text-white font-bold text-2xl mb-6">R</div>
                        <h1 className="text-4xl font-bold mb-4 text-white">Gabung Sekarang</h1>
                        <p className="text-slate-400 text-lg leading-relaxed">
                            Kelola bisnis Anda dengan teknologi modern. Daftar hari ini dan transformasikan operasional Anda.
                        </p>
                    </div>

                    <div className="space-y-4">
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-indigo-300" size={24} />
                            <span className="text-slate-300 font-medium">Gratis 14 hari</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-indigo-300" size={24} />
                            <span className="text-slate-300 font-medium">Tanpa kartu kredit</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-indigo-300" size={24} />
                            <span className="text-slate-300 font-medium">Setup instan</span>
                        </div>
                    </div>
                </div>

                {/* Right Side: Form */}
                <div className="w-full md:w-1/2">
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {error && (
                            <div className="p-4 bg-red-500/10 text-red-300 rounded-xl text-sm border border-red-500/30">
                                {error}
                            </div>
                        )}

                        <div className="space-y-4">
                            <InputGroup icon={<Building2 size={20} />} name="businessName" placeholder="Nama Bisnis" value={formData.businessName} onChange={handleChange} />
                            <InputGroup icon={<Mail size={20} />} name="email" type="email" placeholder="Alamat Email" value={formData.email} onChange={handleChange} />
                            <InputGroup icon={<Lock size={20} />} name="password" type="password" placeholder="Kata Sandi" value={formData.password} onChange={handleChange} />
                            <InputGroup icon={<Phone size={20} />} name="waNumber" placeholder="Nomor WhatsApp" value={formData.waNumber} onChange={handleChange} />
                            <InputGroup icon={<MapPin size={20} />} name="address" placeholder="Alamat Bisnis" value={formData.address} onChange={handleChange} />
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full py-4 bg-gradient-to-r from-indigo-600 to-violet-600 text-white font-bold rounded-2xl shadow-[0_10px_30px_rgba(79,70,229,0.35)] hover:shadow-[0_15px_40px_rgba(124,58,237,0.45)] transition-all duration-300 flex items-center justify-center gap-2 group disabled:opacity-70"
                        >
                            {loading ? 'Membuat Akun...' : 'Buat Akun'}
                            {!loading && <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />}
                        </button>

                        <p className="text-center text-slate-400 text-sm">
                            Sudah punya akun? <Link to="/login" className="text-indigo-300 font-bold hover:underline">Masuk</Link>
                        </p>
                    </form>
                </div>

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

export default Register;
