import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import { Lock } from 'lucide-react';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import Card from '../components/ui/Card';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            const res = await api.post('/auth/login', { email, password });
            if (res.data.data.user.role !== 'SUPER_ADMIN') {
                setError("Access Denied: Not a Super Admin account");
                setLoading(false);
                return;
            }
            localStorage.setItem('adminToken', res.data.data.token);
            localStorage.setItem('adminUser', JSON.stringify(res.data.data.user));
            navigate('/');
        } catch (err) {
            setError(err.response?.data?.message || 'Login failed');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen grid lg:grid-cols-2">
            {/* Left: Login Form */}
            <div className="flex flex-col justify-center items-center p-8 lg:p-12 bg-white">
                <div className="w-full max-w-md space-y-8">
                    {/* Header */}
                    <div className="space-y-2">
                        <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-primary-100 text-primary-600 mb-4">
                            <Lock size={24} />
                        </div>
                        <h1 className="text-3xl font-semibold tracking-tight text-slate-900">Sign in to Rana</h1>
                        <p className="text-slate-500">Welcome back! Please enter your details.</p>
                    </div>

                    {/* Error Alert */}
                    {error && (
                        <div className="bg-red-50 text-red-600 p-4 rounded-lg text-sm border border-red-100 flex items-start">
                            <span className="font-medium mr-2">Error:</span> {error}
                        </div>
                    )}

                    {/* Form */}
                    <form onSubmit={handleLogin} className="space-y-5">
                        <div className="space-y-1.5">
                            <Input
                                label="Email"
                                type="email"
                                placeholder="Enter your email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>
                        <div className="space-y-1.5">
                            <Input
                                label="Password"
                                type="password"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="flex items-center">
                                <input type="checkbox" id="remember" className="h-4 w-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500" />
                                <label htmlFor="remember" className="ml-2 block text-sm text-slate-700">Remember for 30 days</label>
                            </div>
                            <a href="#" className="text-sm font-medium text-primary-600 hover:text-primary-700">Forgot password?</a>
                        </div>

                        <Button
                            type="submit"
                            className="w-full py-3" // Taller button
                            isLoading={loading}
                        >
                            Sign in
                        </Button>
                    </form>

                    <div className="text-center text-sm text-slate-500 mt-6">
                        Don't have an account? <span className="font-medium text-slate-900">Contact Support</span>
                    </div>
                </div>
            </div>

            {/* Right: Feature Image */}
            <div className="hidden lg:block bg-slate-50 relative overflow-hidden">
                <div className="absolute inset-0 bg-primary-600/10 mix-blend-multiply" />
                <img
                    src="https://images.unsplash.com/photo-1556761175-5973dc0f32e7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1632&q=80"
                    alt="Rana Dashboard"
                    className="absolute inset-0 w-full h-full object-cover"
                />
                <div className="absolute bottom-0 left-0 right-0 p-12 bg-gradient-to-t from-slate-900/80 to-transparent text-white">
                    <blockquote className="text-xl font-medium mb-4">
                        "Rana has completely transformed how we manage our multi-branch retail operations. The analytics are game-changing."
                    </blockquote>
                    <div className="font-semibold">Putri Sarah</div>
                    <div className="text-slate-300 text-sm">CEO, Kopi Kenangan Demo</div>
                </div>
            </div>
        </div>
    );
};

export default Login;
