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
        <div className="min-h-screen flex items-center justify-center bg-[#e0e5ec] p-4 font-sans text-slate-800">
            <div className="bg-[#e0e5ec] p-8 md:p-12 rounded-[3rem] shadow-[20px_20px_60px_#bebebe,-20px_-20px_60px_#ffffff] max-w-md w-full">

                <div className="text-center mb-10">
                    <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center text-white font-bold text-3xl mx-auto mb-6 shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff]">R</div>
                    <h1 className="text-3xl font-bold text-[#303346] mb-2">Welcome Back</h1>
                    <p className="text-gray-500">Enter your credentials to access your account.</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {error && (
                        <div className="p-4 bg-red-100 text-red-700 rounded-xl text-sm border-l-4 border-red-500 text-center">
                            {error}
                        </div>
                    )}

                    <InputGroup
                        icon={<Mail size={20} />}
                        type="email"
                        placeholder="Email Address"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                    />

                    <InputGroup
                        icon={<Lock size={20} />}
                        type="password"
                        placeholder="Password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                    />

                    <div className="flex justify-end">
                        <a href="#" className="text-sm text-primary font-bold hover:underline">Forgot Password?</a>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full py-4 bg-primary text-white font-bold rounded-2xl shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff] hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-all duration-300 flex items-center justify-center gap-2 group disabled:opacity-70"
                    >
                        {loading ? 'Logging In...' : 'Log In'}
                        {!loading && <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />}
                    </button>

                    <p className="text-center text-gray-500 text-sm">
                        Don't have an account? <Link to="/register" className="text-primary font-bold hover:underline">Sign Up</Link>
                    </p>
                </form>
            </div>
        </div>
    );
};

const InputGroup = ({ icon, ...props }) => (
    <div className="relative">
        <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
            {icon}
        </div>
        <input
            {...props}
            className="w-full bg-[#e0e5ec] border-none rounded-xl py-4 pl-12 pr-4 text-slate-700 placeholder-gray-400 shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all font-medium"
            required
        />
    </div>
);

export default Login;
