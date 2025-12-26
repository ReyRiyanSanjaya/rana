import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
    LayoutDashboard,
    TrendingUp,
    Package,
    Settings,
    Menu,
    LogOut,
    Store,
    Zap,
    BarChart3
} from 'lucide-react';
import ThemeToggle from '../ThemeToggle';
import { useAuth } from '../../context/AuthContext';

const SidebarItem = ({ icon: Icon, label, path, active }) => (
    <Link
        to={path}
        className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${active
            ? 'bg-primary/10 text-primary font-medium dark:bg-primary/20 dark:text-primary-400'
            : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800'
            }`}
    >
        <Icon size={20} />
        <span>{label}</span>
    </Link>
);

const DashboardLayout = ({ children }) => {
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
    const location = useLocation();
    const { user } = useAuth();

    const role = user?.role || 'CASHIER'; // Default safe

    const ALL_NAV_ITEMS = {
        dashboard: { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
        pos: { icon: Store, label: 'POS System', path: '/pos' },
        pnl: { icon: TrendingUp, label: 'Profit & Loss', path: '/profit-loss' },
        inventory: { icon: Package, label: 'Inventory', path: '/inventory' },
        cashOps: { icon: Package, label: 'Cash & Ops', path: '/cash-ops' },
        subscription: { icon: Zap, label: 'Subscription', path: '/subscription' },
        stores: { icon: Store, label: 'Stores / Tenants', path: '/stores' },
        reports: { icon: BarChart3, label: 'Advanced Reports', path: '/reports' },
        support: { icon: Menu, label: 'Help & Support', path: '/support' }, // Using Menu icon as placeholder or find HelpCircle
        settings: { icon: Settings, label: 'Settings', path: '/settings' },
    };

    let navItems = [];

    if (role === 'SUPER_ADMIN') {
        navItems = [
            ALL_NAV_ITEMS.dashboard,
            ALL_NAV_ITEMS.stores,
            ALL_NAV_ITEMS.subscription,
            ALL_NAV_ITEMS.settings
        ];
    } else if (role === 'OWNER' || role === 'STORE_MANAGER') {
        navItems = [
            ALL_NAV_ITEMS.dashboard,
            ALL_NAV_ITEMS.pos,
            ALL_NAV_ITEMS.reports,
            ALL_NAV_ITEMS.pnl,
            ALL_NAV_ITEMS.inventory,
            ALL_NAV_ITEMS.cashOps,
            // ALL_NAV_ITEMS.subscription, // Maybe owner wants to see sub status?
            ALL_NAV_ITEMS.support,
            ALL_NAV_ITEMS.settings
        ];
    } else {
        // Cashier or others
        navItems = [
            ALL_NAV_ITEMS.pos,
            // ALL_NAV_ITEMS.settings // Maybe limited settings?
        ];
    }

    return (
        <div className="flex h-screen bg-slate-50 dark:bg-slate-950 transition-colors duration-200">
            {/* Sidebar */}
            <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-slate-900 border-r border-slate-200 dark:border-slate-800 transform transition-transform duration-200 ease-in-out
        ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'}
        md:relative md:translate-x-0
      `}>
                <div className="p-6 border-b border-slate-100 dark:border-slate-800">
                    <h1 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-primary to-indigo-800 dark:from-primary-400 dark:to-indigo-500">
                        Rana POS
                    </h1>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">SaaS Financial Intelligence</p>
                </div>

                <nav className="p-4 space-y-1">
                    {navItems.map((item) => (
                        <SidebarItem
                            key={item.path}
                            {...item}
                            active={location.pathname === item.path}
                        />
                    ))}
                </nav>

                <div className="absolute bottom-0 w-full p-4 border-t border-slate-100 dark:border-slate-800">
                    <button
                        onClick={() => {
                            localStorage.removeItem('token');
                            localStorage.removeItem('user');
                            window.location.href = '/login';
                        }}
                        className="flex items-center space-x-3 px-4 py-3 text-slate-600 hover:text-danger dark:text-slate-400 dark:hover:text-red-400 w-full"
                    >
                        <LogOut size={20} />
                        <span>Logout</span>
                    </button>
                    <div className="mt-4 flex justify-center">
                        <ThemeToggle />
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <div className="flex-1 flex flex-col overflow-hidden">
                {/* Header */}
                <header className="bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 h-16 flex items-center justify-between px-6 transition-colors duration-200">
                    <button
                        className="md:hidden text-slate-600 dark:text-slate-300"
                        onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                    >
                        <Menu />
                    </button>

                    <div className="flex items-center space-x-4 ml-auto">
                        <div className="text-right hidden sm:block">
                            <p className="text-sm font-medium text-slate-900 dark:text-white">John Doe (Owner)</p>
                            <p className="text-xs text-slate-500 dark:text-slate-400">Tenant: Kopi Kenangan</p>
                        </div>
                        <div className="h-8 w-8 rounded-full bg-indigo-100 dark:bg-indigo-900 flex items-center justify-center text-primary dark:text-primary-300 font-bold">
                            JD
                        </div>
                    </div>
                </header>

                {/* Page Content */}
                <main className="flex-1 overflow-auto p-6 text-slate-900 dark:text-slate-100">
                    {children}
                </main>
            </div>
        </div>
    );
};

export default DashboardLayout;
