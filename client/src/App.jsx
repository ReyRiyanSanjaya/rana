import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import ProfitLoss from './pages/ProfitLoss';
import Inventory from './pages/Inventory';
import POSMode from './pages/POSMode';
import CashManagement from './pages/CashManagement';
import Subscription from './pages/Subscription';
import ProtectedRoute from './components/ProtectedRoute';
import { AuthProvider } from './context/AuthContext';
import Login from './pages/Login';
import Register from './pages/Register'; // [NEW]
import Stores from './pages/Stores';
import Reports from './pages/Reports';
import Landing from './pages/Landing'; // [NEW]
import BlogList from './pages/BlogList'; // [NEW]
import BlogDetail from './pages/BlogDetail'; // [NEW]
import About from './pages/About'; // [NEW]
import Features from './pages/Features'; // [NEW]
import Contact from './pages/Contact'; // [NEW]
import Support from './pages/Support'; // [NEW]
import FlashSales from './pages/FlashSales';
import Transactions from './pages/Transactions';

// Placeholders for other routes
const Placeholder = ({ title }) => (
    <div className="p-8">
        <h1 className="text-2xl font-bold">{title}</h1>
        <p className="mt-4 text-slate-500">Module under construction...</p>
    </div>
);

function App() {
    return (
        <AuthProvider>
            <Router>
                <Routes>
                    {/* Public Routes - Portal */}
                    <Route path="/" element={<Landing />} />
                    <Route path="/blog" element={<BlogList />} />
                    <Route path="/blog/:slug" element={<BlogDetail />} />
                    <Route path="/about" element={<About />} />
                    <Route path="/features" element={<Features />} />
                    <Route path="/contact" element={<Contact />} />
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />

                    {/* Protected Merchant Routes */}
                    <Route path="/dashboard" element={<Dashboard />} />

                    <Route path="/pos" element={
                        <ProtectedRoute>
                            <POSMode />
                        </ProtectedRoute>
                    } />
                    <Route path="/profit-loss" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <ProfitLoss />
                        </ProtectedRoute>
                    } />
                    <Route path="/inventory" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <Inventory />
                        </ProtectedRoute>
                    } />
                    <Route path="/transactions" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <Transactions />
                        </ProtectedRoute>
                    } />

                    <Route path="/cash-management" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <CashManagement />
                        </ProtectedRoute>
                    } />
                    <Route path="/reports" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <Reports />
                        </ProtectedRoute>
                    } />
                    <Route path="/flashsales" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <FlashSales />
                        </ProtectedRoute>
                    } />
                    <Route path="/subscription" element={
                        <ProtectedRoute allowedRoles={['SUPER_ADMIN']}>
                            <Subscription />
                        </ProtectedRoute>
                    } />

                    <Route path="/cash-ops" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <CashManagement />
                        </ProtectedRoute>
                    } />

                    <Route path="/stores" element={
                        <ProtectedRoute allowedRoles={['SUPER_ADMIN']}>
                            <Stores />
                        </ProtectedRoute>
                    } />
                    <Route path="/settings" element={
                        <ProtectedRoute>
                            <Placeholder title="Settings" />
                        </ProtectedRoute>
                    } />
                    <Route path="/support" element={
                        <ProtectedRoute>
                            <Support />
                        </ProtectedRoute>
                    } />
                </Routes>
            </Router>
        </AuthProvider>
    );
}

export default App;
