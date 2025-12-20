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
import Stores from './pages/Stores';

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
                    <Route path="/login" element={<Login />} />
                    <Route path="/" element={<Dashboard />} />
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

                    {/* Protected Routes */}

                    <Route path="/cash-management" element={
                        <ProtectedRoute allowedRoles={['OWNER', 'STORE_MANAGER']}>
                            <CashManagement />
                        </ProtectedRoute>
                    } />
                    <Route path="/subscription" element={
                        <ProtectedRoute allowedRoles={['SUPER_ADMIN']}>
                            <Subscription />
                        </ProtectedRoute>
                    } />

                    {/* Backwards compatibility / other routes */}

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
                </Routes>
            </Router>
        </AuthProvider>
    );
}

export default App;
