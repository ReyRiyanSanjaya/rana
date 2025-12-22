import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
// import Dashboard from './pages/Dashboard';
import Withdrawals from './pages/Withdrawals';
import Merchants from './pages/Merchants';
import AcquisitionMap from './pages/AcquisitionMap';
import Packages from './pages/Packages';
import Announcements from './pages/Announcements';
import Settings from './pages/Settings';
import SubscriptionRequests from './pages/SubscriptionRequests'; // [NEW]
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

        <Route path="/packages" element={
          <ProtectedRoute><Packages /></ProtectedRoute>
        } />

        <Route path="/announcements" element={
          <ProtectedRoute><Announcements /></ProtectedRoute>
        } />

        <Route path="/settings" element={
          <ProtectedRoute><Settings /></ProtectedRoute>
        } />
      </Routes>
    </Router>
  );
}

export default App;
