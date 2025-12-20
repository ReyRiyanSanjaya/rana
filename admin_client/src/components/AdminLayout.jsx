import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Wallet, Settings, LogOut, Store, Map, Package, Megaphone } from 'lucide-react';

const SidebarItem = ({ to, icon: Icon, label }) => {
    const location = useLocation();
    const isActive = location.pathname === to;

    return (
        <Link
            to={to}
            className={`group flex items-center space-x-3 px-3 py-2.5 rounded-lg mb-1 transition-all duration-200 ${isActive
                ? 'bg-slate-800 text-white shadow-inner'
                : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
        >
            <Icon size={20} className={`${isActive ? 'text-primary-400' : 'text-slate-500 group-hover:text-slate-300'}`} />
            <span className="font-medium text-sm">{label}</span>
        </Link>
    );
};

const AdminLayout = ({ children }) => {
    const navigate = useNavigate();
    const user = JSON.parse(localStorage.getItem('adminUser') || '{}');

    const handleLogout = () => {
        localStorage.clear();
        navigate('/login');
    };

    return (
        <div className="flex h-screen bg-slate-50 font-sans">
            {/* Sidebar */}
            <div className="w-72 bg-slate-900 border-r border-slate-800 text-white p-6 flex flex-col">
                <div className="mb-10 px-2 flex items-center space-x-3">
                    <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-primary-700 rounded-lg shadow-lg flex-shrink-0"></div>
                    <div>
                        <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">
                            Rana Admin
                        </h1>
                    </div>
                </div>

                <nav className="flex-1 space-y-1">
                    <SidebarItem to="/" icon={LayoutDashboard} label="Dashboard" />
                    <SidebarItem to="/withdrawals" icon={Wallet} label="Withdrawals" />
                    <SidebarItem to="/merchants" icon={Store} label="Merchants" />
                    <SidebarItem to="/map" icon={Map} label="Acquisition Map" />
                    <SidebarItem to="/packages" icon={Package} label="Packages" />
                    <SidebarItem to="/announcements" icon={Megaphone} label="Announcements" />
                    <SidebarItem to="/settings" icon={Settings} label="System Settings" />
                </nav>

                <div className="pt-6 border-t border-slate-800">
                    <div className="flex items-center mb-5 px-2">
                        <div className="w-10 h-10 rounded-full bg-slate-700 border border-slate-600 flex items-center justify-center font-bold text-white shadow-sm">
                            {user.name?.[0] || 'A'}
                        </div>
                        <div className="ml-3">
                            <p className="text-sm font-semibold text-white">{user.name || 'Admin'}</p>
                            <p className="text-xs text-slate-400 truncate w-32">{user.email || 'super@admin.com'}</p>
                        </div>
                    </div>
                    <button
                        onClick={handleLogout}
                        className="flex items-center space-x-2 text-slate-400 hover:text-red-400 transition-colors text-sm w-full px-2 py-2 rounded-lg hover:bg-slate-800"
                    >
                        <LogOut size={18} />
                        <span className="font-medium">Sign Out</span>
                    </button>
                </div>
            </div>

            {/* Main Content */}
            <div className="flex-1 overflow-auto bg-slate-50">
                <main className="max-w-7xl mx-auto p-8">
                    {children}
                </main>
            </div>
        </div>
    );
};

export default AdminLayout;
