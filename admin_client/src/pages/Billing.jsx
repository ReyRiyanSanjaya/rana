import React from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { CreditCard, CheckCircle } from 'lucide-react';
import Badge from '../components/ui/Badge';

const Billing = () => {
    const [billing, setBilling] = React.useState(null);
    const [loading, setLoading] = React.useState(true);

    React.useEffect(() => {
        api.get('/admin/billing/subscription')
            .then(res => setBilling(res.data.data))
            .catch(err => console.error(err))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <AdminLayout><div className="p-10 text-center">Loading billing info...</div></AdminLayout>;
    if (!billing) return <AdminLayout><div className="p-10 text-center">Failed to load billing info.</div></AdminLayout>;

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
                            <h2 className="text-xl font-bold text-slate-900 mr-3">{billing.plan} Plan</h2>
                            <Badge variant={billing.status === 'ACTIVE' ? 'success' : 'warning'}>{billing.status}</Badge>
                        </div>
                        <p className="text-slate-500 mb-6">You are on the top-tier plan for Rana Platform Supervisors.</p>

                        <div className="space-y-2 mb-6">
                            {billing.features?.map((feature, idx) => (
                                <div key={idx} className="flex items-center text-sm text-slate-700">
                                    <CheckCircle size={16} className="text-green-500 mr-2" />
                                    {feature}
                                </div>
                            ))}
                        </div>
                    </div>
                    <div className="p-4 bg-indigo-50 rounded-full text-indigo-600">
                        <CreditCard size={32} />
                    </div>
                </div>

                <div className="pt-6 border-t border-slate-100 flex justify-between items-center text-sm">
                    <span className="text-slate-500">Next billing date: <span className="font-medium text-slate-900">{billing.nextBillingDate}</span></span>
                    <Button variant="link" className="text-indigo-600">Manage Payment Method</Button>
                </div>
            </Card>
        </AdminLayout>
    );
};

export default Billing;
