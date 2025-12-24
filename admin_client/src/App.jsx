import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
// import Dashboard from './pages/Dashboard';
import Withdrawals from './pages/Withdrawals';
import Merchants from './pages/Merchants';
import AcquisitionMap from './pages/AcquisitionMap';
import Packages from './pages/Packages';
import Broadcasts from './pages/Broadcasts'; // [UPDATED]
import Support from './pages/Support'; // [NEW]
import Settings from './pages/Settings';
import SubscriptionRequests from './pages/SubscriptionRequests';
import Reports from './pages/Reports'; // [NEW]
import Kulakan from './pages/Kulakan'; // [NEW]
import Profile from './pages/Profile'; // [NEW]
import Billing from './pages/Billing'; // [NEW]
import AdminLayout from './components/AdminLayout';

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('adminToken');
  if (!token) return <Navigate to="/login" replace />;
  return children;
};

import Dashboard from './pages/Dashboard';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route path="/" element={
          <ProtectedRoute><Dashboard /></ProtectedRoute>
        } />

        <Route path="/withdrawals" element={
          <ProtectedRoute><Withdrawals /></ProtectedRoute>
        } />

        <Route path="/merchants" element={
          <ProtectedRoute><Merchants /></ProtectedRoute>
        } />

        <Route path="/subscriptions" element={
          <ProtectedRoute><SubscriptionRequests /></ProtectedRoute>
        } />

        <Route path="/map" element={
          <ProtectedRoute><AcquisitionMap /></ProtectedRoute>
        } />

        <Route path="/reports" element={
          <ProtectedRoute><Reports /></ProtectedRoute>
        } />

        <Route path="/kulakan" element={
          <ProtectedRoute><Kulakan /></ProtectedRoute>
        } />

        <Route path="/profile" element={
          <ProtectedRoute><Profile /></ProtectedRoute>
        } />

        <Route path="/billing" element={
          <ProtectedRoute><Billing /></ProtectedRoute>
        } />

        <Route path="/packages" element={
          <ProtectedRoute><Packages /></ProtectedRoute>
        } />

        <Route path="/broadcasts" element={
          <ProtectedRoute><Broadcasts /></ProtectedRoute>
        } />

        <Route path="/support" element={
          <ProtectedRoute><Support /></ProtectedRoute>
        } />

        <Route path="/settings" element={
          <ProtectedRoute><Settings /></ProtectedRoute>
        } />
      </Routes>
    </Router>
  );
}

export default App;
