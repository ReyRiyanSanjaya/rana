import React, { useEffect, useState } from 'react';
import api from '../api';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import Button from '../components/ui/button';
import Input from '../components/ui/Input';
import { Layout, Image, Type, Save, Globe, Users, Star, List } from 'lucide-react';

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

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            const res = await api.get('/admin/settings');
            const settingsMap = {};
            res.data.data.forEach(s => settingsMap[s.key] = s.value);
            setSettings(prev => ({ ...prev, ...settingsMap }));
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
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
                            ? 'text-pink-600 border-b-2 border-pink-600'
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
                        <h3 className="text-lg font-bold mb-4">Advanced Config (JSON)</h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <label className="block text-sm font-medium mb-1">Core Values (JSON Array)</label>
                                <p className="text-xs text-gray-500 mb-2">Example: {`[{"title": "Speed", "desc": "Fast..." }]`}</p>
                                <textarea
                                    className="w-full h-60 border rounded p-2 font-mono text-xs"
                                    value={settings.CMS_CORE_VALUES}
                                    onChange={e => setSettings({ ...settings, CMS_CORE_VALUES: e.target.value })}
                                />
                                <div className="mt-2">
                                    <Button onClick={() => handleJsonSave('CMS_CORE_VALUES', settings.CMS_CORE_VALUES)}>Save Core Values</Button>
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium mb-1">Features List (JSON Array)</label>
                                <textarea
                                    className="w-full h-60 border rounded p-2 font-mono text-xs"
                                    value={settings.CMS_FEATURES_LIST}
                                    onChange={e => setSettings({ ...settings, CMS_FEATURES_LIST: e.target.value })}
                                />
                                <div className="mt-2">
                                    <Button onClick={() => handleJsonSave('CMS_FEATURES_LIST', settings.CMS_FEATURES_LIST)}>Save Features</Button>
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
