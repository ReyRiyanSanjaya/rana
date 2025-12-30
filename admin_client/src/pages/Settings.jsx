import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import { Save, AlertCircle, Truck } from 'lucide-react';
import Card from '../components/ui/Card';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';

const Settings = () => {
    const [settings, setSettings] = useState({
        PLATFORM_QRIS_URL: '',
        BANK_NAME: '',
        BANK_ACCOUNT_NUMBER: '',
        BANK_ACCOUNT_NAME: '',
        PLATFORM_FEE_PERCENTAGE: '',
        DIGIFLAZZ_USERNAME: '',
        DIGIFLAZZ_MODE: 'production',
        DIGIFLAZZ_BASE_URL: '',
        DIGIFLAZZ_MARKUP_FLAT: '0',
        DIGIFLAZZ_MARKUP_PERCENT: '0',
        DIGIFLAZZ_API_KEY: '',
        DIGIFLAZZ_API_KEY_IS_SET: 'false',
        DIGIFLAZZ_WEBHOOK_SECRET: '',
        DIGIFLAZZ_WEBHOOK_SECRET_IS_SET: 'false',
        WHOLESALE_SERVICE_FEE: '2500',
        WHOLESALE_SHIPPING_COST_PER_KM: '3000',
        WHOLESALE_PAYMENT_METHODS: 'Transfer Bank (BCA),Transfer Bank (Mandiri),Bayar di Tempat (COD)'
    });
    const [loading, setLoading] = useState(false);
    const [digiflazzApiKeyInput, setDigiflazzApiKeyInput] = useState('');
    const [digiflazzWebhookSecretInput, setDigiflazzWebhookSecretInput] = useState('');

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

    const handleSaveWholesale = async () => {
        setLoading(true);
        try {
            await Promise.all([
                api.post('/admin/settings', { key: 'WHOLESALE_SERVICE_FEE', value: settings.WHOLESALE_SERVICE_FEE, description: 'Service Fee (Biaya Layanan)' }),
                api.post('/admin/settings', { key: 'WHOLESALE_SHIPPING_COST_PER_KM', value: settings.WHOLESALE_SHIPPING_COST_PER_KM, description: 'Shipping Cost per KM' }),
                api.post('/admin/settings', { key: 'WHOLESALE_PAYMENT_METHODS', value: settings.WHOLESALE_PAYMENT_METHODS, description: 'Payment Methods' }),
            ]);
            alert("Wholesale Settings Saved!");
        } catch (error) {
            console.error(error);
            alert("Failed to save wholesale settings");
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

    const handleSaveDigiflazz = async () => {
        setLoading(true);
        try {
            const requests = [
                api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_USERNAME',
                    value: String(settings.DIGIFLAZZ_USERNAME || ''),
                    description: 'Digiflazz Username'
                }),
                api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_MODE',
                    value: String(settings.DIGIFLAZZ_MODE || 'production'),
                    description: 'Digiflazz Mode'
                }),
                api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_BASE_URL',
                    value: String(settings.DIGIFLAZZ_BASE_URL || ''),
                    description: 'Digiflazz Base URL'
                }),
                api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_MARKUP_FLAT',
                    value: String(settings.DIGIFLAZZ_MARKUP_FLAT || '0'),
                    description: 'Digiflazz Markup Flat'
                }),
                api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_MARKUP_PERCENT',
                    value: String(settings.DIGIFLAZZ_MARKUP_PERCENT || '0'),
                    description: 'Digiflazz Markup Percent'
                }),
            ];

            if (digiflazzApiKeyInput.trim()) {
                requests.push(api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_API_KEY',
                    value: digiflazzApiKeyInput,
                    description: 'Digiflazz API Key'
                }));
            }
            if (digiflazzWebhookSecretInput.trim()) {
                requests.push(api.post('/admin/settings', {
                    key: 'DIGIFLAZZ_WEBHOOK_SECRET',
                    value: digiflazzWebhookSecretInput,
                    description: 'Digiflazz Webhook Secret'
                }));
            }

            await Promise.all(requests);

            setDigiflazzApiKeyInput('');
            setDigiflazzWebhookSecretInput('');

            const res = await api.get('/admin/settings');
            if (res.data.data) {
                setSettings(prev => ({ ...prev, ...res.data.data }));
            }

            alert("Digiflazz settings saved!");
        } catch (error) {
            console.error(error);
            alert("Failed to save Digiflazz settings");
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
                {/* Wholesale Config */}
                <Card className="p-6 h-fit">
                    <div className="flex items-start justify-between mb-6">
                        <div>
                            <h3 className="font-semibold text-slate-900">Wholesale (Kulakan) Configuration</h3>
                            <p className="text-sm text-slate-500 mt-1">Manage fees, shipping costs, and payment methods for merchants.</p>
                        </div>
                        <div className="p-2 bg-indigo-50 rounded-lg text-indigo-600">
                            <Truck size={20} />
                        </div>
                    </div>

                    <div className="grid grid-cols-1 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Service Fee (Biaya Layanan)</label>
                            <Input
                                type="number"
                                placeholder="2500"
                                value={settings.WHOLESALE_SERVICE_FEE || ''}
                                onChange={(e) => handleChange('WHOLESALE_SERVICE_FEE', e.target.value)}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Shipping Cost per KM (Ongkir)</label>
                            <Input
                                type="number"
                                placeholder="3000"
                                value={settings.WHOLESALE_SHIPPING_COST_PER_KM || ''}
                                onChange={(e) => handleChange('WHOLESALE_SHIPPING_COST_PER_KM', e.target.value)}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Payment Methods (Comma Separated)</label>
                            <Input
                                placeholder="Transfer Bank (BCA), COD"
                                value={settings.WHOLESALE_PAYMENT_METHODS || ''}
                                onChange={(e) => handleChange('WHOLESALE_PAYMENT_METHODS', e.target.value)}
                            />
                            <p className="text-xs text-slate-500 mt-1">Example: Transfer Bank (BCA),Bayar di Tempat (COD)</p>
                        </div>
                    </div>

                    <div className="pt-4 mt-2">
                        <Button
                            onClick={handleSaveWholesale}
                            isLoading={loading}
                            className="w-full sm:w-auto"
                        >
                            Save Wholesale Settings
                        </Button>
                    </div>
                </Card>

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

                {/* Digiflazz PPOB */}
                <Card className="p-6 h-fit">
                    <div className="flex items-start justify-between mb-6">
                        <div>
                            <h3 className="font-semibold text-slate-900">PPOB Configuration (Digiflazz)</h3>
                            <p className="text-sm text-slate-500 mt-1">Configure Digiflazz credentials and pricing markup.</p>
                        </div>
                        <div className="p-2 bg-indigo-50 rounded-lg text-indigo-600">
                            <Save size={20} />
                        </div>
                    </div>

                    <div className="space-y-4">
                        <Input
                            label="Digiflazz Username"
                            name="DIGIFLAZZ_USERNAME"
                            value={settings.DIGIFLAZZ_USERNAME || ''}
                            onChange={(e) => handleChange('DIGIFLAZZ_USERNAME', e.target.value)}
                            placeholder="username"
                        />

                        <Input
                            label="Digiflazz API Key"
                            type="password"
                            helperText={
                                settings.DIGIFLAZZ_API_KEY_IS_SET === 'true'
                                    ? `Sudah tersimpan (${settings.DIGIFLAZZ_API_KEY || '****'}). Isi untuk mengganti.`
                                    : 'Belum di-set.'
                            }
                            value={digiflazzApiKeyInput}
                            onChange={(e) => setDigiflazzApiKeyInput(e.target.value)}
                            placeholder="Masukkan API key baru jika ingin ganti"
                        />

                        <div>
                            <label className="block text-sm font-medium text-slate-700 mb-1">Mode</label>
                            <select
                                className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
                                value={settings.DIGIFLAZZ_MODE || 'production'}
                                onChange={(e) => handleChange('DIGIFLAZZ_MODE', e.target.value)}
                            >
                                <option value="production">production</option>
                                <option value="testing">testing</option>
                            </select>
                        </div>

                        <Input
                            label="Base URL (optional)"
                            helperText="Kosongkan untuk default https://api.digiflazz.com/v1"
                            name="DIGIFLAZZ_BASE_URL"
                            value={settings.DIGIFLAZZ_BASE_URL || ''}
                            onChange={(e) => handleChange('DIGIFLAZZ_BASE_URL', e.target.value)}
                            placeholder="https://api.digiflazz.com/v1"
                        />

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <Input
                                label="Markup Flat"
                                type="number"
                                value={settings.DIGIFLAZZ_MARKUP_FLAT || '0'}
                                onChange={(e) => handleChange('DIGIFLAZZ_MARKUP_FLAT', e.target.value)}
                                placeholder="0"
                            />
                            <Input
                                label="Markup Percent (%)"
                                type="number"
                                value={settings.DIGIFLAZZ_MARKUP_PERCENT || '0'}
                                onChange={(e) => handleChange('DIGIFLAZZ_MARKUP_PERCENT', e.target.value)}
                                placeholder="0"
                            />
                        </div>

                        <Input
                            label="Webhook Secret (optional)"
                            type="password"
                            helperText={
                                settings.DIGIFLAZZ_WEBHOOK_SECRET_IS_SET === 'true'
                                    ? `Sudah tersimpan (${settings.DIGIFLAZZ_WEBHOOK_SECRET || '****'}). Isi untuk mengganti.`
                                    : 'Kosongkan jika tidak memakai.'
                            }
                            value={digiflazzWebhookSecretInput}
                            onChange={(e) => setDigiflazzWebhookSecretInput(e.target.value)}
                            placeholder="Masukkan secret baru jika ingin ganti"
                        />

                        <div className="pt-2">
                            <Button
                                onClick={handleSaveDigiflazz}
                                isLoading={loading}
                                className="w-full sm:w-auto"
                            >
                                Save Digiflazz Settings
                            </Button>
                        </div>
                    </div>
                </Card>
            </div>
        </AdminLayout>
    );
};

export default Settings;
