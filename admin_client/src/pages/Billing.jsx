import React from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import { CreditCard, CheckCircle } from 'lucide-react';
import Badge from '../components/ui/Badge';

const Billing = () => {
    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">Billing & Subscription</h1>
                <p className="text-slate-500 mt-1">Manage platform subscription and payment methods.</p>
            </div>

            <Card className="p-8 max-w-3xl mx-auto border-l-4 border-l-indigo-600">
                <div className="flex items-start justify-between">
                    <div>
                        <div className="flex items-center mb-2">
                            <h2 className="text-xl font-bold text-slate-900 mr-3">Enterprise Plan</h2>
                            <Badge variant="success">Active</Badge>
                        </div>
                        <p className="text-slate-500 mb-6">You are on the top-tier plan for Rana Platform Supervisors.</p>

                        <div className="space-y-2 mb-6">
                            <div className="flex items-center text-sm text-slate-700">
                                <CheckCircle size={16} className="text-green-500 mr-2" />
                                Unlimited Merchants
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <CheckCircle size={16} className="text-green-500 mr-2" />
                                Advanced Analytics
                            </div>
                            <div className="flex items-center text-sm text-slate-700">
                                <CheckCircle size={16} className="text-green-500 mr-2" />
                                Priority Support
                            </div>
                        </div>
                    </div>
                    <div className="p-4 bg-indigo-50 rounded-full text-indigo-600">
                        <CreditCard size={32} />
                    </div>
                </div>

                <div className="pt-6 border-t border-slate-100 flex justify-between items-center text-sm">
                    <span className="text-slate-500">Next billing date: <span className="font-medium text-slate-900">Lifetime Access</span></span>
                    <button className="text-indigo-600 font-medium hover:underline">Manage Payment Method</button>
                </div>
            </Card>
        </AdminLayout>
    );
};

export default Billing;
