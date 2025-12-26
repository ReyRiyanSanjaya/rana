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
        <div className="min-h-screen flex items-center justify-center bg-[#e0e5ec] p-4 font-sans text-slate-800">
            <div className="bg-[#e0e5ec] p-8 md:p-12 rounded-[3rem] shadow-[20px_20px_60px_#bebebe,-20px_-20px_60px_#ffffff] max-w-4xl w-full flex flex-col md:flex-row gap-12 items-center">

                {/* Left Side: Hero/Info */}
                <div className="w-full md:w-1/2 space-y-8">
                    <div>
                        <div className="w-12 h-12 bg-primary rounded-2xl flex items-center justify-center text-white font-bold text-2xl mb-6 shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff]">R</div>
                        <h1 className="text-4xl font-bold mb-4 text-[#303346]">Join the Revolution</h1>
                        <p className="text-gray-500 text-lg leading-relaxed">
                            Start managing your business with the power of modern technology. Sign up today and transform your operations.
                        </p>
                    </div>

                    <div className="space-y-4">
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-primary" size={24} />
                            <span className="text-gray-600 font-medium">Free 14-day trial</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-primary" size={24} />
                            <span className="text-gray-600 font-medium">No credit card required</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <CheckCircle className="text-primary" size={24} />
                            <span className="text-gray-600 font-medium">Instant setup</span>
                        </div>
                    </div>
                </div>

                {/* Right Side: Form */}
                <div className="w-full md:w-1/2">
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {error && (
                            <div className="p-4 bg-red-100 text-red-700 rounded-xl text-sm border-l-4 border-red-500">
                                {error}
                            </div>
                        )}

                        <div className="space-y-4">
                            <InputGroup icon={<Building2 size={20} />} name="businessName" placeholder="Business Name" value={formData.businessName} onChange={handleChange} />
                            <InputGroup icon={<Mail size={20} />} name="email" type="email" placeholder="Email Address" value={formData.email} onChange={handleChange} />
                            <InputGroup icon={<Lock size={20} />} name="password" type="password" placeholder="Password" value={formData.password} onChange={handleChange} />
                            <InputGroup icon={<Phone size={20} />} name="waNumber" placeholder="WhatsApp Number" value={formData.waNumber} onChange={handleChange} />
                            <InputGroup icon={<MapPin size={20} />} name="address" placeholder="Business Address" value={formData.address} onChange={handleChange} />
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full py-4 bg-primary text-white font-bold rounded-2xl shadow-[5px_5px_10px_#bebebe,-5px_-5px_10px_#ffffff] hover:shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] transition-all duration-300 flex items-center justify-center gap-2 group disabled:opacity-70"
                        >
                            {loading ? 'Creating Account...' : 'Create Account'}
                            {!loading && <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />}
                        </button>

                        <p className="text-center text-gray-500 text-sm">
                            Already have an account? <Link to="/login" className="text-primary font-bold hover:underline">Log In</Link>
                        </p>
                    </form>
                </div>

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

export default Register;
