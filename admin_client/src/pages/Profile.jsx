import React from 'react';
import AdminLayout from '../components/AdminLayout';
import Card from '../components/ui/Card';
import { User, Mail, Shield, Key } from 'lucide-react';
import Input from '../components/ui/Input';
import Button from '../components/ui/Button';

const Profile = () => {
    // In a real app, fetch this from API or Context
    const user = {
        name: 'Admin User',
        email: 'admin@rana.id',
        role: 'Super Admin',
        joined: 'December 2024'
    };

    return (
        <AdminLayout>
            <div className="mb-8">
                <h1 className="text-2xl font-semibold text-slate-900">My Profile</h1>
                <p className="text-slate-500 mt-1">Manage your account information and security.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Profile Card */}
                <Card className="p-6 md:col-span-1">
                    <div className="flex flex-col items-center text-center">
                        <div className="h-24 w-24 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-600 mb-4">
                            <span className="text-3xl font-bold">A</span>
                        </div>
                        <h2 className="text-xl font-bold text-slate-900">{user.name}</h2>
                        <p className="text-slate-500 text-sm mb-4">{user.role}</p>
                        <div className="w-full border-t border-slate-100 pt-4 text-left space-y-3">
                            <div className="flex items-center text-sm text-slate-600">
                                <Mail size={16} className="mr-3 text-slate-400" />
                                {user.email}
                            </div>
                            <div className="flex items-center text-sm text-slate-600">
                                <Shield size={16} className="mr-3 text-slate-400" />
                                {user.role}
                            </div>
                        </div>
                    </div>
                </Card>

                {/* Edit Form */}
                <Card className="p-6 md:col-span-2">
                    <h3 className="font-semibold text-lg text-slate-900 mb-6 flex items-center">
                        <User size={20} className="mr-2 text-indigo-600" />
                        Account Details
                    </h3>
                    <div className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <Input label="Full Name" value={user.name} readOnly />
                            <Input label="Email Address" value={user.email} readOnly />
                        </div>
                        <div className="pt-4 border-t border-slate-100 mt-4">
                            <h3 className="font-semibold text-lg text-slate-900 mb-4 flex items-center">
                                <Key size={20} className="mr-2 text-indigo-600" />
                                Security
                            </h3>
                            <Button variant="outline">Change Password</Button>
                        </div>
                    </div>
                </Card>
            </div>
        </AdminLayout>
    );
};

export default Profile;
