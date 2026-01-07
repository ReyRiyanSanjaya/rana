import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import Input from '../components/ui/Input';
import { Layout, Image, Type, Save, Globe, Users, Star, List, Percent, Wallet } from 'lucide-react';

const ContentManager = () => {
    const [activeTab, setActiveTab] = useState('general');
    const [settings, setSettings] = useState({
        CMS_LOGIN_BANNER: '',
        CMS_WELCOME_TEXT: '',
        CMS_HERO_TITLE: 'Elevate Your Business Beyond Limits',
        CMS_HERO_SUBTITLE: 'Experience the perfect fusion of aesthetic design and powerful technology.',
        CMS_ABOUT_US: '',
        CMS_CONTACT_EMAIL: '',
        CMS_CONTACT_PHONE: '',
        CMS_CORE_VALUES: '[]', // JSON String
        CMS_FEATURES_LIST: '[]' // JSON String
    });
    const [loading, setLoading] = useState(true);
    const [flashSales, setFlashSales] = useState([]);
    const [preview, setPreview] = useState({
        buyerSubtotal: 0,
        wholesaleSubtotal: 0,
        withdrawalAmount: 0
    });
    const [coreValuesList, setCoreValuesList] = useState([]);
    const [featuresList, setFeaturesList] = useState([]);
    const [publicCms, setPublicCms] = useState({});

    useEffect(() => {
        fetchSettings();
        fetchPublic();
    }, []);

    const fetchSettings = async () => {
        try {
            const res = await api.get('/admin/settings');
            const payload = res?.data?.data;
            const settingsMap = Array.isArray(payload)
                ? payload.reduce((acc, s) => { acc[s.key] = s.value; return acc; }, {})
                : (typeof payload === 'object' && payload !== null ? payload : {});
            setSettings(prev => ({ ...prev, ...settingsMap }));
            try {
                const cv = settingsMap.CMS_CORE_VALUES ? JSON.parse(settingsMap.CMS_CORE_VALUES) : [];
                setCoreValuesList(Array.isArray(cv) ? cv : []);
            } catch {
                setCoreValuesList([]);
            }
            try {
                const fl = settingsMap.CMS_FEATURES_LIST ? JSON.parse(settingsMap.CMS_FEATURES_LIST) : [];
                setFeaturesList(Array.isArray(fl) ? fl : []);
            } catch {
                setFeaturesList([]);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };
    const fetchPublic = async () => {
        try {
            const res = await api.get('/system/cms-content');
            setPublicCms(res.data.data || {});
        } catch {
            setPublicCms({});
        }
    };

    const handleSave = async (key, value) => {
        try {
            await api.post('/admin/settings', { key, value });
            alert("Content updated!");
        } catch (error) {
            alert("Failed to save content");
        }
    };

    // Helper for JSON fields
    const handleJsonSave = (key, jsonString) => {
        try {
            JSON.parse(jsonString); // Validate
            handleSave(key, jsonString);
        } catch (e) {
            alert("Invalid JSON format");
        }
    };

    const tabs = [
        { id: 'general', label: 'General & Hero', icon: <Layout size={18} /> },
        { id: 'company', label: 'Company Profile', icon: <Users size={18} /> },
        { id: 'values', label: 'Core Values & Features', icon: <Star size={18} /> },
        { id: 'fees', label: 'Fee Settings', icon: <Percent size={18} /> },
    ];

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">Content Manager</h1>
                <p className="text-slate-500 mt-1">Customize public pages and company profile.</p>
            </div>

            {/* Tabs */}
            <div className="flex space-x-4 mb-8 border-b border-gray-200">
                {tabs.map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`pb-4 px-4 flex items-center gap-2 font-medium transition-colors relative ${activeTab === tab.id
                            ? 'text-indigo-600 border-b-2 border-indigo-600'
                            : 'text-slate-500 hover:text-slate-700'
                            }`}
                    >
                        {tab.icon}
                        {tab.label}
                    </button>
                ))}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                {activeTab === 'general' && (
                    <>
                        <Card className="p-6">
                            <h3 className="text-lg font-bold mb-4">Login Page</h3>
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1">Banner Image URL</label>
                                    <div className="flex gap-2">
                                        <Input
                                            value={settings.CMS_LOGIN_BANNER}
                                            onChange={e => setSettings({ ...settings, CMS_LOGIN_BANNER: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_LOGIN_BANNER', settings.CMS_LOGIN_BANNER)}><Save size={16} /></Button>
                                    </div>
                                    {settings.CMS_LOGIN_BANNER && <img src={settings.CMS_LOGIN_BANNER} className="mt-2 h-20 rounded" />}
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Welcome Text</label>
                                    <div className="flex gap-2">
                                        <Input
                                            value={settings.CMS_WELCOME_TEXT}
                                            onChange={e => setSettings({ ...settings, CMS_WELCOME_TEXT: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_WELCOME_TEXT', settings.CMS_WELCOME_TEXT)}><Save size={16} /></Button>
                                    </div>
                                </div>
                            </div>
                        </Card>
                        <Card className="p-6">
                            <h3 className="text-lg font-bold mb-4">Landing Hero</h3>
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1">Hero Title</label>
                                    <div className="flex gap-2">
                                        <Input
                                            value={settings.CMS_HERO_TITLE}
                                            onChange={e => setSettings({ ...settings, CMS_HERO_TITLE: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_HERO_TITLE', settings.CMS_HERO_TITLE)}><Save size={16} /></Button>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Hero Subtitle</label>
                                    <div className="flex gap-2">
                                        <textarea
                                            className="w-full border rounded p-2"
                                            value={settings.CMS_HERO_SUBTITLE}
                                            onChange={e => setSettings({ ...settings, CMS_HERO_SUBTITLE: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_HERO_SUBTITLE', settings.CMS_HERO_SUBTITLE)}><Save size={16} /></Button>
                                    </div>
                                </div>
                            </div>
                        </Card>
                    </>
                )}

                {activeTab === 'company' && (
                    <Card className="p-6 col-span-2">
                        <h3 className="text-lg font-bold mb-4">Company Details</h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium mb-1">About Us (HTML/Markdown)</label>
                                <textarea
                                    className="w-full h-40 border rounded p-2 font-mono text-sm"
                                    value={settings.CMS_ABOUT_US}
                                    onChange={e => setSettings({ ...settings, CMS_ABOUT_US: e.target.value })}
                                    placeholder="<p>We are...</p>"
                                />
                                <div className="mt-2">
                                    <Button onClick={() => handleSave('CMS_ABOUT_US', settings.CMS_ABOUT_US)}>Save About Us</Button>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1">Contact Email</label>
                                    <div className="flex gap-2">
                                        <Input
                                            value={settings.CMS_CONTACT_EMAIL}
                                            onChange={e => setSettings({ ...settings, CMS_CONTACT_EMAIL: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_CONTACT_EMAIL', settings.CMS_CONTACT_EMAIL)}><Save size={16} /></Button>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Contact Phone</label>
                                    <div className="flex gap-2">
                                        <Input
                                            value={settings.CMS_CONTACT_PHONE}
                                            onChange={e => setSettings({ ...settings, CMS_CONTACT_PHONE: e.target.value })}
                                        />
                                        <Button onClick={() => handleSave('CMS_CONTACT_PHONE', settings.CMS_CONTACT_PHONE)}><Save size={16} /></Button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </Card>
                )}

                {activeTab === 'values' && (
                    <Card className="p-6 col-span-2">
                        <h3 className="text-lg font-bold mb-4">Core Values & Features</h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <div className="flex justify-between items-center mb-2">
                                    <label className="block text-sm font-medium">Core Values</label>
                                    <Button size="sm" onClick={() => setCoreValuesList([...coreValuesList, { title: '', desc: '' }])}>Add</Button>
                                </div>
                                <div className="space-y-3">
                                    {coreValuesList.map((item, idx) => (
                                        <div key={idx} className="border rounded p-3 space-y-2">
                                            <Input value={item.title} onChange={e => {
                                                const arr = [...coreValuesList]; arr[idx] = { ...arr[idx], title: e.target.value }; setCoreValuesList(arr);
                                            }} placeholder="Title" />
                                            <Input value={item.desc} onChange={e => {
                                                const arr = [...coreValuesList]; arr[idx] = { ...arr[idx], desc: e.target.value }; setCoreValuesList(arr);
                                            }} placeholder="Description" />
                                            <div className="flex justify-end">
                                                <Button variant="destructive" size="sm" onClick={() => setCoreValuesList(coreValuesList.filter((_, i) => i !== idx))}>Remove</Button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-3">
                                    <Button onClick={() => handleJsonSave('CMS_CORE_VALUES', JSON.stringify(coreValuesList))}>Save Core Values</Button>
                                </div>
                            </div>
                            <div>
                                <div className="flex justify-between items-center mb-2">
                                    <label className="block text-sm font-medium">Features</label>
                                    <Button size="sm" onClick={() => setFeaturesList([...featuresList, { title: '', desc: '' }])}>Add</Button>
                                </div>
                                <div className="space-y-3">
                                    {featuresList.map((item, idx) => (
                                        <div key={idx} className="border rounded p-3 space-y-2">
                                            <Input value={item.title} onChange={e => {
                                                const arr = [...featuresList]; arr[idx] = { ...arr[idx], title: e.target.value }; setFeaturesList(arr);
                                            }} placeholder="Title" />
                                            <Input value={item.desc} onChange={e => {
                                                const arr = [...featuresList]; arr[idx] = { ...arr[idx], desc: e.target.value }; setFeaturesList(arr);
                                            }} placeholder="Description" />
                                            <div className="flex justify-end">
                                                <Button variant="destructive" size="sm" onClick={() => setFeaturesList(featuresList.filter((_, i) => i !== idx))}>Remove</Button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-3">
                                    <Button onClick={() => handleJsonSave('CMS_FEATURES_LIST', JSON.stringify(featuresList))}>Save Features</Button>
                                </div>
                            </div>
                        </div>
                    </Card>
                )}
                <Card className="p-6 col-span-2">
                    <h3 className="text-lg font-bold mb-4">Public Preview</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div className="border rounded p-4">
                            <div className="font-semibold mb-2">Hero Title</div>
                            <div className="text-slate-700">{publicCms.CMS_HERO_TITLE || settings.CMS_HERO_TITLE}</div>
                        </div>
                        <div className="border rounded p-4">
                            <div className="font-semibold mb-2">Hero Subtitle</div>
                            <div className="text-slate-700">{publicCms.CMS_HERO_SUBTITLE || settings.CMS_HERO_SUBTITLE}</div>
                        </div>
                        <div className="border rounded p-4">
                            <div className="font-semibold mb-2">Contact</div>
                            <div className="text-slate-700">{(publicCms.CMS_CONTACT_EMAIL || settings.CMS_CONTACT_EMAIL) + ' • ' + (publicCms.CMS_CONTACT_PHONE || settings.CMS_CONTACT_PHONE)}</div>
                        </div>
                    </div>
                </Card>
                {activeTab === 'fees' && (
                    <Card className="p-6 col-span-2">
                        <h3 className="text-lg font-bold mb-4">Fee Settings</h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <div className="space-y-4">
                                <div className="font-semibold text-slate-900">Buyer Fee</div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Type</label>
                                    <select
                                        className="w-full border rounded p-2"
                                        value={settings.BUYER_SERVICE_FEE_TYPE || 'FLAT'}
                                        onChange={e => setSettings({ ...settings, BUYER_SERVICE_FEE_TYPE: e.target.value })}
                                    >
                                        <option value="FLAT">Flat</option>
                                        <option value="PERCENT">Percent</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Value</label>
                                    <Input
                                        value={settings.BUYER_SERVICE_FEE || ''}
                                        onChange={e => setSettings({ ...settings, BUYER_SERVICE_FEE: e.target.value })}
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Min Cap</label>
                                        <Input
                                            value={settings.BUYER_FEE_CAP_MIN || ''}
                                            onChange={e => setSettings({ ...settings, BUYER_FEE_CAP_MIN: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Max Cap</label>
                                        <Input
                                            value={settings.BUYER_FEE_CAP_MAX || ''}
                                            onChange={e => setSettings({ ...settings, BUYER_FEE_CAP_MAX: e.target.value })}
                                        />
                                    </div>
                                </div>
                                <Button onClick={async () => {
                                    await handleSave('BUYER_SERVICE_FEE_TYPE', settings.BUYER_SERVICE_FEE_TYPE || 'FLAT');
                                    await handleSave('BUYER_SERVICE_FEE', settings.BUYER_SERVICE_FEE || '0');
                                    await handleSave('BUYER_FEE_CAP_MIN', settings.BUYER_FEE_CAP_MIN || '');
                                    await handleSave('BUYER_FEE_CAP_MAX', settings.BUYER_FEE_CAP_MAX || '');
                                }}>Save Buyer Fee</Button>
                            </div>
                            <div className="space-y-4">
                                <div className="font-semibold text-slate-900">Merchant Payout Fee</div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Type</label>
                                    <select
                                        className="w-full border rounded p-2"
                                        value={settings.MERCHANT_SERVICE_FEE_TYPE || 'FLAT'}
                                        onChange={e => setSettings({ ...settings, MERCHANT_SERVICE_FEE_TYPE: e.target.value })}
                                    >
                                        <option value="FLAT">Flat</option>
                                        <option value="PERCENT">Percent</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Value</label>
                                    <Input
                                        value={settings.MERCHANT_SERVICE_FEE || ''}
                                        onChange={e => setSettings({ ...settings, MERCHANT_SERVICE_FEE: e.target.value })}
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Min Cap</label>
                                        <Input
                                            value={settings.MERCHANT_FEE_CAP_MIN || ''}
                                            onChange={e => setSettings({ ...settings, MERCHANT_FEE_CAP_MIN: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Max Cap</label>
                                        <Input
                                            value={settings.MERCHANT_FEE_CAP_MAX || ''}
                                            onChange={e => setSettings({ ...settings, MERCHANT_FEE_CAP_MAX: e.target.value })}
                                        />
                                    </div>
                                </div>
                                <Button onClick={async () => {
                                    await handleSave('MERCHANT_SERVICE_FEE_TYPE', settings.MERCHANT_SERVICE_FEE_TYPE || 'FLAT');
                                    await handleSave('MERCHANT_SERVICE_FEE', settings.MERCHANT_SERVICE_FEE || '0');
                                    await handleSave('MERCHANT_FEE_CAP_MIN', settings.MERCHANT_FEE_CAP_MIN || '');
                                    await handleSave('MERCHANT_FEE_CAP_MAX', settings.MERCHANT_FEE_CAP_MAX || '');
                                }}>Save Merchant Fee</Button>
                            </div>
                            <div className="space-y-4">
                                <div className="font-semibold text-slate-900">Wholesale Service Fee</div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Type</label>
                                    <select
                                        className="w-full border rounded p-2"
                                        value={settings.WHOLESALE_SERVICE_FEE_TYPE || 'FLAT'}
                                        onChange={e => setSettings({ ...settings, WHOLESALE_SERVICE_FEE_TYPE: e.target.value })}
                                    >
                                        <option value="FLAT">Flat</option>
                                        <option value="PERCENT">Percent</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1">Value</label>
                                    <Input
                                        value={settings.WHOLESALE_SERVICE_FEE || ''}
                                        onChange={e => setSettings({ ...settings, WHOLESALE_SERVICE_FEE: e.target.value })}
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Min Cap</label>
                                        <Input
                                            value={settings.WHOLESALE_FEE_CAP_MIN || ''}
                                            onChange={e => setSettings({ ...settings, WHOLESALE_FEE_CAP_MIN: e.target.value })}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Max Cap</label>
                                        <Input
                                            value={settings.WHOLESALE_FEE_CAP_MAX || ''}
                                            onChange={e => setSettings({ ...settings, WHOLESALE_FEE_CAP_MAX: e.target.value })}
                                        />
                                    </div>
                                </div>
                                <Button onClick={async () => {
                                    await handleSave('WHOLESALE_SERVICE_FEE_TYPE', settings.WHOLESALE_SERVICE_FEE_TYPE || 'FLAT');
                                    await handleSave('WHOLESALE_SERVICE_FEE', settings.WHOLESALE_SERVICE_FEE || '0');
                                    await handleSave('WHOLESALE_FEE_CAP_MIN', settings.WHOLESALE_FEE_CAP_MIN || '');
                                    await handleSave('WHOLESALE_FEE_CAP_MAX', settings.WHOLESALE_FEE_CAP_MAX || '');
                                }}>Save Wholesale Fee</Button>
                            </div>
                        </div>

                        <div className="mt-8">
                            <h4 className="text-md font-semibold mb-4 flex items-center gap-2"><Wallet size={18} /> Preview Impact</h4>
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                <div className="space-y-3">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Buyer Subtotal</label>
                                        <Input
                                            value={preview.buyerSubtotal}
                                            onChange={e => setPreview({ ...preview, buyerSubtotal: parseFloat(e.target.value || 0) })}
                                        />
                                    </div>
                                    <div className="text-sm text-slate-600">
                                        Buyer Fee: {(() => {
                                            const type = settings.BUYER_SERVICE_FEE_TYPE || 'FLAT';
                                            const val = parseFloat(settings.BUYER_SERVICE_FEE || 0);
                                            let fee = type === 'PERCENT' ? (preview.buyerSubtotal * val) / 100 : val;
                                            const minCap = parseFloat(settings.BUYER_FEE_CAP_MIN || NaN);
                                            const maxCap = parseFloat(settings.BUYER_FEE_CAP_MAX || NaN);
                                            if (!isNaN(minCap) && fee < minCap) fee = minCap;
                                            if (!isNaN(maxCap) && fee > maxCap) fee = maxCap;
                                            return `Rp ${Math.round(fee).toLocaleString()}`;
                                        })()}
                                    </div>
                                </div>
                                <div className="space-y-3">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Wholesale Subtotal</label>
                                        <Input
                                            value={preview.wholesaleSubtotal}
                                            onChange={e => setPreview({ ...preview, wholesaleSubtotal: parseFloat(e.target.value || 0) })}
                                        />
                                    </div>
                                    <div className="text-sm text-slate-600">
                                        Wholesale Fee: {(() => {
                                            const type = settings.WHOLESALE_SERVICE_FEE_TYPE || 'FLAT';
                                            const val = parseFloat(settings.WHOLESALE_SERVICE_FEE || 0);
                                            let fee = type === 'PERCENT' ? (preview.wholesaleSubtotal * val) / 100 : val;
                                            const minCap = parseFloat(settings.WHOLESALE_FEE_CAP_MIN || NaN);
                                            const maxCap = parseFloat(settings.WHOLESALE_FEE_CAP_MAX || NaN);
                                            if (!isNaN(minCap) && fee < minCap) fee = minCap;
                                            if (!isNaN(maxCap) && fee > maxCap) fee = maxCap;
                                            return `Rp ${Math.round(fee).toLocaleString()}`;
                                        })()}
                                    </div>
                                </div>
                                <div className="space-y-3">
                                    <div>
                                        <label className="block text-sm font-medium mb-1">Withdrawal Amount</label>
                                        <Input
                                            value={preview.withdrawalAmount}
                                            onChange={e => setPreview({ ...preview, withdrawalAmount: parseFloat(e.target.value || 0) })}
                                        />
                                    </div>
                                    <div className="text-sm text-slate-600">
                                        Merchant Fee: {(() => {
                                            const type = settings.MERCHANT_SERVICE_FEE_TYPE;
                                            const val = parseFloat(settings.MERCHANT_SERVICE_FEE || 0);
                                            let fee = 0;
                                            if (type === 'PERCENT') fee = (preview.withdrawalAmount * val) / 100;
                                            else if (type === 'FLAT') fee = val;
                                            else {
                                                const percentFallback = parseFloat(settings.PLATFORM_FEE_PERCENTAGE || 0);
                                                fee = (preview.withdrawalAmount * percentFallback) / 100;
                                            }
                                            const minCap = parseFloat(settings.MERCHANT_FEE_CAP_MIN || NaN);
                                            const maxCap = parseFloat(settings.MERCHANT_FEE_CAP_MAX || NaN);
                                            if (!isNaN(minCap) && fee < minCap) fee = minCap;
                                            if (!isNaN(maxCap) && fee > maxCap) fee = maxCap;
                                            const net = Math.max(0, preview.withdrawalAmount - fee);
                                            return `Rp ${Math.round(fee).toLocaleString()} | Net: Rp ${Math.round(net).toLocaleString()}`;
                                        })()}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </Card>
                )}

                

            </div>
        </AdminLayout>
    );
};

export default ContentManager;
