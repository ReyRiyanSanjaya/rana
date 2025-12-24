import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Store, Map, BarChart, ShoppingBag, LogOut, Search, Bell, Settings, Command, Wallet, CreditCard, Package, Megaphone, MessageSquare } from 'lucide-react';
import { cn } from '../lib/utils';
import { Button } from './ui/button';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { Separator } from './ui/separator';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from './ui/dropdown-menu';

const SidebarItem = ({ icon: Icon, label, to, isActive }) => {
    return (
        <Link to={to}>
            <Button
                variant={isActive ? "secondary" : "ghost"}
                className={cn(
                    "w-full justify-start",
                    isActive ? "bg-slate-100 text-slate-900 font-semibold" : "text-slate-600 hover:text-slate-900"
                )}
            >
                <Icon className="mr-2 h-4 w-4" />
                {label}
            </Button>
        </Link>
    );
};

const AdminLayout = ({ children }) => {
    const location = useLocation();

    const navItems = [
        { icon: LayoutDashboard, label: 'Dashboard', to: '/' },
        { icon: Map, label: 'Acquisition Map', to: '/map' },
        { icon: Store, label: 'Merchants', to: '/merchants' },
        { icon: ShoppingBag, label: 'Kulakan (Wholesale)', to: '/kulakan' },
        { icon: BarChart, label: 'Reports', to: '/reports' },
    ];

    const financeItems = [
        { icon: Wallet, label: 'Withdrawals', to: '/withdrawals' },
        { icon: CreditCard, label: 'Subscriptions', to: '/subscriptions' },
    ];

    const systemItems = [
        { icon: Package, label: 'Packages', to: '/packages' },
        { icon: Megaphone, label: 'Broadcasts', to: '/broadcasts' },
        { icon: MessageSquare, label: 'Support', to: '/support' }, // [NEW]
    ];

    return (
        <div className="min-h-screen bg-slate-50/50 flex">
            {/* Sidebar */}
            <aside className="hidden md:flex flex-col w-64 bg-white border-r border-slate-200 fixed inset-y-0 left-0 z-50">
                {/* Sidebar Header */}
                <div className="h-14 flex items-center px-4 border-b border-slate-200">
                    <div className="flex items-center gap-2 font-bold text-lg tracking-tight">
                        <div className="h-6 w-6 rounded-md bg-slate-900 flex items-center justify-center text-white">
                            <Command size={14} />
                        </div>
                        <span>Rana Admin</span>
                    </div>
                </div>

                {/* Sidebar Content */}
                <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
                    <div className="px-2 mb-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        Platform
                    </div>
                    {navItems.map((item) => (
                        <SidebarItem
                            key={item.to}
                            icon={item.icon}
                            label={item.label}
                            to={item.to}
                            isActive={location.pathname === item.to}
                        />
                    ))}

                    <div className="mt-6 px-2 mb-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        Finance
                    </div>
                    {financeItems.map((item) => (
                        <SidebarItem
                            key={item.to}
                            icon={item.icon}
                            label={item.label}
                            to={item.to}
                            isActive={location.pathname === item.to}
                        />
                    ))}

                    <div className="mt-6 px-2 mb-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        System
                    </div>
                    {systemItems.map((item) => (
                        <SidebarItem
                            key={item.to}
                            icon={item.icon}
                            label={item.label}
                            to={item.to}
                            isActive={location.pathname === item.to}
                        />
                    ))}

                    <div className="mt-6 px-2 mb-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        Settings
                    </div>
                    <SidebarItem icon={Settings} label="General Settings" to="/settings" isActive={location.pathname === '/settings'} />
                </div>

                {/* Sidebar Footer */}
                <div className="p-4 border-t border-slate-200">
                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="w-full justify-start pl-0 hover:bg-slate-100">
                                <div className="flex items-center gap-3 text-left">
                                    <Avatar className="h-8 w-8">
                                        <AvatarImage src="https://github.com/shadcn.png" alt="@shadcn" />
                                        <AvatarFallback>AD</AvatarFallback>
                                    </Avatar>
                                    <div className="flex flex-col flex-1 overflow-hidden">
                                        <span className="text-sm font-medium leading-none truncate">Admin User</span>
                                        <span className="text-xs text-slate-500 truncate">admin@rana.id</span>
                                    </div>
                                </div>
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent className="w-56" align="end" forceMount>
                            <DropdownMenuLabel className="font-normal">
                                <div className="flex flex-col space-y-1">
                                    <p className="text-sm font-medium leading-none">Admin User</p>
                                    <p className="text-xs leading-none text-muted-foreground">
                                        admin@rana.id
                                    </p>
                                </div>
                            </DropdownMenuLabel>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem asChild>
                                <Link to="/profile" className="cursor-pointer w-full">Profile</Link>
                            </DropdownMenuItem>
                            <DropdownMenuItem asChild>
                                <Link to="/billing" className="cursor-pointer w-full">Billing</Link>
                            </DropdownMenuItem>
                            <DropdownMenuItem asChild>
                                <Link to="/settings" className="cursor-pointer w-full">Settings</Link>
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                                className="text-red-500 focus:text-red-500 cursor-pointer"
                                onClick={() => {
                                    localStorage.removeItem('adminToken');
                                    window.location.href = '/login';
                                }}
                            >
                                <LogOut className="mr-2 h-4 w-4" />
                                Log out
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </aside>

            {/* Main Layout (Header + Content) */}
            <div className="flex-1 md:ml-64 flex flex-col min-h-screen transition-all duration-300 ease-in-out">
                {/* Header */}
                <header className="sticky top-0 z-40 w-full h-14 bg-white/80 backdrop-blur-md border-b border-slate-200 flex items-center justify-between px-6">
                    <div className="flex items-center gap-4 text-sm text-slate-500">
                        <span className="cursor-pointer hover:text-slate-900">Dashboard</span>
                        <span>/</span>
                        <span className="font-medium text-slate-900 capitalize">{location.pathname === '/' ? 'Overview' : location.pathname.substring(1)}</span>
                    </div>

                    <div className="flex items-center gap-4">
                        <div className="relative hidden sm:block">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
                            <input
                                type="text"
                                placeholder="Search..."
                                className="h-9 w-64 rounded-md border border-slate-200 bg-slate-50 pl-9 text-sm outline-none focus:ring-1 focus:ring-slate-900 transition-all"
                            />
                        </div>
                        <Button variant="ghost" size="icon" className="text-slate-500">
                            <Bell className="h-5 w-5" />
                        </Button>
                    </div>
                </header>

                {/* Content Area */}
                <main className="flex-1 p-6 overflow-x-hidden">
                    {children}
                </main>
            </div>
        </div>
    );
};

export default AdminLayout;
