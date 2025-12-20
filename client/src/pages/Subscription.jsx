import React, { useEffect, useState } from 'react';
import DashboardLayout from '../components/layout/DashboardLayout';
import api from '../services/api';
import { Check, Star, Zap, Shield } from 'lucide-react';

const Subscription = () => {
    const [packages, setPackages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [currentPlan, setCurrentPlan] = useState('FREE'); // Needs to come from user profile really

    useEffect(() => {
        const fetchPackages = async () => {
            try {
                const res = await api.get('/subscriptions/packages');
                setPackages(res.data.data);
            } catch (error) {
                console.error("Failed to fetch packages", error);
            } finally {
                setLoading(false);
            }
        };
        fetchPackages();
    }, []);

    const handleSubscribe = (pkg) => {
        alert(`Request to upgrade to ${pkg.name} sent! (Demo)`);
    };

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val);

    return (
        <DashboardLayout title="Subscription Plan">
            <div className="max-w-6xl mx-auto px-4 py-8">
                <div className="text-center mb-12">
                    <h2 className="text-3xl font-bold text-slate-900">Upgrade your Business</h2>
                    <p className="text-slate-500 mt-2">Choose a plan that fits your growth.</p>
                </div>

                {loading ? (
                    <div className="text-center py-12 text-slate-400">Loading plans...</div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                        {packages.map((pkg) => (
                            <div key={pkg.id} className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden hover:shadow-lg transition-shadow flex flex-col">
                                <div className="p-6 flex-grow">
                                    <h3 className="text-xl font-bold text-slate-900 mb-2">{pkg.name}</h3>
                                    <div className="flex items-baseline mb-4">
                                        <span className="text-3xl font-extrabold text-slate-900">{formatCurrency(pkg.price)}</span>
                                        <span className="text-slate-500 ml-1">/{pkg.durationDays} days</span>
                                    </div>
                                    <p className="text-slate-500 text-sm mb-6">{pkg.description}</p>

                                    <div className="space-y-3">
                                        {['Unlimited Transactions', 'Priority Support', 'Advanced Analytics', 'Custom Reports'].map((feature, idx) => (
                                            <div key={idx} className="flex items-center text-sm text-slate-700">
                                                <div className="bg-green-100 text-green-600 p-1 rounded-full mr-3">
                                                    <Check size={14} />
                                                </div>
                                                {feature}
                                            </div>
                                        ))}
                                    </div>
                                </div>
                                <div className="p-6 bg-slate-50 border-t border-slate-100">
                                    <button
                                        onClick={() => handleSubscribe(pkg)}
                                        className="w-full py-3 px-4 bg-primary-600 hover:bg-primary-700 text-white font-medium rounded-lg transition shadow-sm hover:shadow-md active:scale-95 transform"
                                    >
                                        Choose Plan
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </DashboardLayout>
    );
};

export default Subscription;
