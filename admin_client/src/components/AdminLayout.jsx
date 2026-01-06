import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Store, Map, BarChart, ShoppingBag, LogOut, Search, Bell, Settings, Command, Wallet, CreditCard, Package, Megaphone, MessageSquare, Smartphone, Shield, Layout, FileText, List, Gift } from 'lucide-react';
import { cn } from '../lib/utils';
import { getRole, getUser, logout } from '../lib/auth';
import { Button } from './ui/Button';
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

// [NEW] Search Result Helpers
const SearchResultItem = ({ to, title, subtitle, icon: Icon, onClick }) => (
    <Link to={to} onClick={onClick} className="flex items-center p-3 hover:bg-slate-50 transition border-b border-slate-100 last:border-0">
        <div className="p-2 bg-indigo-50 text-indigo-600 rounded mr-3">
            <Icon size={16} />
        </div>
        <div>
            <p className="text-sm font-medium text-slate-900">{title}</p>
            <p className="text-xs text-slate-500">{subtitle}</p>
        </div>
    </Link>
);

const AdminLayout = ({ children }) => {
    const location = useLocation();
    const navigate = useNavigate();

    // [NEW] Search State
    const [searchQuery, setSearchQuery] = React.useState('');
    const [searchResults, setSearchResults] = React.useState(null);
    const [isSearching, setIsSearching] = React.useState(false);

    // Debounced Search
    React.useEffect(() => {
        const timer = setTimeout(async () => {
            if (searchQuery.length >= 3) {
                setIsSearching(true);
                try {
                    // Import api internally to avoid circular dep issues if any, or just use global
                    const { default: api } = await import('../api');
                    const res = await api.get(`/admin/search?q=${searchQuery}`);
                    setSearchResults(res.data.data);
                } catch (e) {
                    console.error("Search error", e);
                } finally {
                    setIsSearching(false);
                }
            } else {
                setSearchResults(null);
            }
        }, 500);
        return () => clearTimeout(timer);
    }, [searchQuery]);

    const [roleAccess, setRoleAccess] = React.useState(null);
    const currentRole = React.useMemo(() => {
        const r = getRole();
        return r || null;
    }, []);
    React.useEffect(() => {
        (async () => {
            try {
                const { default: api } = await import('../api');
                const res = await api.get('/admin/settings');
                const map = {};
                (res.data.data || []).forEach(s => map[s.key] = s.value);
                const parsed = map.ADMIN_ROLE_MENU_ACCESS ? JSON.parse(map.ADMIN_ROLE_MENU_ACCESS) : null;
                setRoleAccess(parsed);
            } catch {
                setRoleAccess(null);
            }
        })();
    }, []);
    const isAllowed = React.useCallback((path) => {
        if (!currentRole) return false;
        if (!roleAccess || !roleAccess[currentRole]) return true;
        return roleAccess[currentRole].includes(path);
    }, [roleAccess, currentRole]);
    React.useEffect(() => {
        const user = getUser();
        if (!user || !currentRole) navigate('/login');
        else if (roleAccess && roleAccess[currentRole] && !isAllowed(location.pathname)) navigate('/');
    }, [roleAccess, currentRole, location.pathname, isAllowed, navigate]);
    const navItems = [
        { icon: LayoutDashboard, label: 'Dashboard', to: '/' },
        { icon: Map, label: 'Acquisition Map', to: '/map' },
        { icon: Store, label: 'Merchants', to: '/merchants' },
        { icon: ShoppingBag, label: 'Kulakan (Wholesale)', to: '/kulakan' },
        { icon: BarChart, label: 'Reports', to: '/reports' },
        { icon: FileText, label: 'Transactions', to: '/transactions' },

    ];

    const financeItems = [
        { icon: Wallet, label: 'Withdrawals', to: '/withdrawals' },
        { icon: CreditCard, label: 'Top Ups', to: '/topups' }, // [NEW]
        { icon: CreditCard, label: 'Subscriptions', to: '/subscriptions' },
        { icon: Gift, label: 'Referrals', to: '/referrals' },
    ];

    const systemItems = [
        { icon: Package, label: 'Packages', to: '/packages' },
        { icon: Megaphone, label: 'Broadcasts', to: '/broadcasts' },
        { icon: Smartphone, label: 'App Menus', to: '/app-menus' },
        { icon: Shield, label: 'Admins', to: '/admins' },
        { icon: Shield, label: 'Audit Logs', to: '/audit-logs' }, // [NEW]
        { icon: Layout, label: 'Content CMS', to: '/content-manager' }, // [NEW]
        { icon: FileText, label: 'Blog Manager', to: '/blog' }, // [NEW]
        { icon: List, label: 'Flash Sales', to: '/flashsales' },
        { icon: MessageSquare, label: 'Support', to: '/support' },
    ];

    const clearSearch = () => {
        setSearchQuery('');
        setSearchResults(null);
    };

    return (
        <div className="min-h-screen bg-slate-50/50 flex overflow-x-hidden">
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
                    {navItems.filter(i => isAllowed(i.to)).map((item) => (
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
                    {financeItems.filter(i => isAllowed(i.to)).map((item) => (
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
                    {systemItems.filter(i => isAllowed(i.to)).map((item) => (
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
                                onClick={() => logout()}
                            >
                                <LogOut className="mr-2 h-4 w-4" />
                                Log out
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </aside>

            {/* Main Layout (Header + Content) */}
            <div className="flex-1 md:ml-64 flex flex-col min-h-screen transition-all duration-300 ease-in-out min-w-0">
                {/* Header */}
                <header className="sticky top-0 z-40 w-full h-14 bg-white/80 backdrop-blur-md border-b border-slate-200 flex items-center justify-between px-6">
                    <div className="flex items-center gap-4 text-sm text-slate-500">
                        <span className="cursor-pointer hover:text-slate-900">Dashboard</span>
                        <span>/</span>
                        <span className="font-medium text-slate-900 capitalize">{location.pathname === '/' ? 'Overview' : location.pathname.substring(1)}</span>
                    </div>

                    <div className="flex items-center gap-4 relative">
                        {/* Search Bar */}
                        <div className="relative hidden sm:block">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-slate-400" />
                            <input
                                type="text"
                                placeholder="Search merchants, users..."
                                className="h-9 w-64 rounded-md border border-slate-200 bg-slate-50 pl-9 text-sm outline-none focus:ring-1 focus:ring-slate-900 transition-all focus:w-80"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                            {/* Search Dropdown */}
                            {searchQuery.length >= 3 && (
                                <div className="absolute top-10 right-0 w-80 bg-white rounded-lg shadow-xl border border-slate-200 overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-200">
                                    {isSearching ? (
                                        <div className="p-4 text-center text-xs text-slate-500">Searching...</div>
                                    ) : searchResults ? (
                                        <>
                                            {searchResults.merchants.length === 0 && searchResults.users.length === 0 && searchResults.products.length === 0 && (
                                                <div className="p-4 text-center text-xs text-slate-500">No results found.</div>
                                            )}

                                            {searchResults.merchants.length > 0 && (
                                                <div>
                                                    <div className="bg-slate-50 px-3 py-1 text-[10px] font-bold uppercase text-slate-400">Merchants</div>
                                                    {searchResults.merchants.map(m => (
                                                        <SearchResultItem
                                                            key={m.id} to={`/merchants`} onClick={clearSearch}
                                                            title={m.name} subtitle={m.plan} icon={Store}
                                                        />
                                                    ))}
                                                </div>
                                            )}

                                            {searchResults.users.length > 0 && (
                                                <div>
                                                    <div className="bg-slate-50 px-3 py-1 text-[10px] font-bold uppercase text-slate-400">Users</div>
                                                    {searchResults.users.map(u => (
                                                        <SearchResultItem
                                                            key={u.id} to={`/settings`} onClick={clearSearch}
                                                            title={u.name} subtitle={u.role} icon={LayoutDashboard}
                                                        />
                                                    ))}
                                                </div>
                                            )}

                                            {searchResults.products.length > 0 && (
                                                <div>
                                                    <div className="bg-slate-50 px-3 py-1 text-[10px] font-bold uppercase text-slate-400">Products</div>
                                                    {searchResults.products.map(p => (
                                                        <SearchResultItem
                                                            key={p.id} to={`/merchants`} onClick={clearSearch}
                                                            title={p.name} subtitle={`Rp ${p.sellingPrice}`} icon={Package}
                                                        />
                                                    ))}
                                                </div>
                                            )}
                                        </>
                                    ) : null}
                                </div>
                            )}
                        </div>
                        <Button variant="ghost" size="icon" className="text-slate-500">
                            <Bell className="h-5 w-5" />
                        </Button>
                    </div>
                </header>

                {/* Content Area */}
                <main className="flex-1 p-6 overflow-x-hidden">
                    <div className="max-w-7xl mx-auto w-full">
                        {children}
                    </div>
                </main>
            </div>
        </div>
    );
};

export default AdminLayout;
