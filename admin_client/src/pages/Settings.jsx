import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Save, AlertCircle } from 'lucide-react';
import Card from '../components/ui/Card';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';

const Settings = () => {
    const [settings, setSettings] = useState({
        PLATFORM_QRIS_URL: '',
        BANK_NAME: '',
        BANK_ACCOUNT_NUMBER: '',
        BANK_ACCOUNT_NAME: '',
        PLATFORM_FEE_PERCENTAGE: ''
    });
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        api.get('/admin/settings').then(res => {
            if (res.data.data) {
                setSettings(prev => ({ ...prev, ...res.data.data }));
            }
        });
    }, []);

    const handleChange = (name, value) => {
        setSettings(prev => ({ ...prev, [name]: value }));
    };

    const handleSave = async (key, description) => {
        setLoading(true);
        try {
            await api.post('/admin/settings', {
                key,
                value: String(settings[key]),
                description
            });
            alert("Setting saved!");
        } catch (error) {
            console.error(error);
            alert("Failed to save");
        } finally {
            setLoading(false);
        }
    };

    const handleSaveBankInfo = async () => {
        setLoading(true);
        try {
            await Promise.all([
                api.post('/admin/settings', { key: 'BANK_NAME', value: settings.BANK_NAME, description: 'Bank Name' }),
                api.post('/admin/settings', { key: 'BANK_ACCOUNT_NUMBER', value: settings.BANK_ACCOUNT_NUMBER, description: 'Account Number' }),
                api.post('/admin/settings', { key: 'BANK_ACCOUNT_NAME', value: settings.BANK_ACCOUNT_NAME, description: 'Account Name' }),
                api.post('/admin/settings', { key: 'PLATFORM_FEE_PERCENTAGE', value: settings.PLATFORM_FEE_PERCENTAGE, description: 'Platform Fee %' }),
            ]);
            alert("Bank & Fee Settings Saved!");
        } catch (error) {
            console.error(error);
            alert("Failed to save some settings");
        } finally {
            setLoading(false);
        }
    };

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">Settings</h1>
                <p className="text-slate-500 mt-1">Manage global platform configurations.</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {/* QRIS Config */}
                <Card className="p-6 h-fit">
                    <div className="flex items-start justify-between mb-6">
                        <div>
                            <h3 className="font-semibold text-slate-900">Payment Configuration (QRIS)</h3>
                            <p className="text-sm text-slate-500 mt-1">Setup the central QRIS image for the platform.</p>
                        </div>
                        <div className="p-2 bg-indigo-50 rounded-lg text-indigo-600">
                            <Save size={20} />
                        </div>
                    </div>

                    <div className="space-y-4">
                        <Input
                            label="Central QRIS Image URL"
                            helperText="Paste the direct URL to the QRIS image file."
                            name="PLATFORM_QRIS_URL"
                            value={settings.PLATFORM_QRIS_URL}
                            onChange={(e) => handleChange('PLATFORM_QRIS_URL', e.target.value)}
                            placeholder="https://example.com/images/qris.png"
                        />

                        {settings.PLATFORM_QRIS_URL && (
                            <div className="p-4 bg-slate-50 rounded-lg border border-dashed border-slate-300 flex justify-center items-center">
                                <img src={settings.PLATFORM_QRIS_URL} alt="QRIS Preview" className="max-h-48 object-contain shadow-sm rounded-md" />
                            </div>
                        )}

                        <div className="pt-2">
                            <Button
                                onClick={() => handleSave('PLATFORM_QRIS_URL', 'Central QRIS Image URL')}
                                isLoading={loading}
                                className="w-full sm:w-auto"
                            >
                                Save QRIS Settings
                            </Button>
                        </div>
                    </div>
                </Card>

                {/* Bank Info */}
                <Card className="p-6 h-fit">
                    <div className="flex items-start justify-between mb-6">
                        <div>
                            <h3 className="font-semibold text-slate-900">Bank Transfer Details</h3>
                            <p className="text-sm text-slate-500 mt-1">Information displayed to merchants for manual transfers.</p>
                        </div>
                        <div className="p-2 bg-indigo-50 rounded-lg text-indigo-600">
                            <AlertCircle size={20} />
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Bank Name</label>
                            <Input
                                placeholder="BCA"
                                value={settings.BANK_NAME || ''}
                                onChange={(e) => handleChange('BANK_NAME', e.target.value)}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Account Number</label>
                            <Input
                                placeholder="1234567890"
                                value={settings.BANK_ACCOUNT_NUMBER || ''}
                                onChange={(e) => handleChange('BANK_ACCOUNT_NUMBER', e.target.value)}
                            />
                        </div>
                        <div className="md:col-span-2">
                            <label className="block text-sm font-medium text-slate-700 mb-1">Account Holder Name</label>
                            <Input
                                placeholder="PT Rana Tech"
                                value={settings.BANK_ACCOUNT_NAME || ''}
                                onChange={(e) => handleChange('BANK_ACCOUNT_NAME', e.target.value)}
                            />
                        </div>
                    </div>
                    <div className="mt-4 pt-4 border-t border-slate-100">
                        <h4 className="font-semibold text-slate-900 mb-3">Revenue & Fees</h4>
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Platform Fee (%)</label>
                            <div className="relative">
                                <Input
                                    type="number"
                                    placeholder="5"
                                    className="pr-8"
                                    value={settings.PLATFORM_FEE_PERCENTAGE || ''}
                                    onChange={(e) => handleChange('PLATFORM_FEE_PERCENTAGE', e.target.value)}
                                />
                                <span className="absolute right-3 top-2.5 text-slate-400 text-sm">%</span>
                            </div>
                            <p className="text-xs text-slate-500 mt-1">This percentage will be automatically deducted from every approved withdrawal.</p>
                        </div>
                    </div>

                    <div className="pt-4 mt-2">
                        <Button
                            onClick={handleSaveBankInfo}
                            isLoading={loading}
                            className="w-full sm:w-auto"
                        >
                            Save Bank & Fees
                        </Button>
                    </div>
                </Card>
            </div>
        </AdminLayout>
    );
};

export default Settings;
