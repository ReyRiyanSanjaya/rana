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
import AuditLogs from './pages/AuditLogs'; // [NEW]
import ContentManager from './pages/ContentManager'; // [NEW]
import Billing from './pages/Billing'; // [NEW]
import AppMenus from './pages/AppMenus'; // [NEW]
import MerchantDetail from './pages/MerchantDetail'; // [NEW]
import AdminUsers from './pages/AdminUsers'; // [NEW]
import TopUps from './pages/TopUps'; // [NEW]
import Transactions from './pages/Transactions'; // [NEW]
import ManageMenu from './pages/ManageMenu'; // [NEW]
import AdminLayout from './components/AdminLayout';

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('adminToken');
  if (!token) return <Navigate to="/login" replace />;
  return children;
};

import Dashboard from './pages/Dashboard';
import BlogManager from './pages/BlogManager'; // [NEW]
import Announcements from './pages/Announcements'; // [NEW]

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />

        {/* Admin Layout for authenticated routes */}
        <Route path="/admin" element={<ProtectedRoute><AdminLayout /></ProtectedRoute>}>
          <Route index element={<Dashboard />} /> {/* Default route for /admin */}
          <Route path="users" element={<AdminUsers />} />
          <Route path="audit-logs" element={<AuditLogs />} />
          <Route path="content" element={<ContentManager />} />
          <Route path="blog" element={<BlogManager />} /> {/* [NEW] */}

          // ...

          <Route path="billing" element={<Billing />} />
          {/* Add other routes that should be under AdminLayout here */}
          <Route path="withdrawals" element={<Withdrawals />} />
          <Route path="topups" element={<TopUps />} /> {/* [NEW] */}
          <Route path="merchants" element={<Merchants />} />
          <Route path="merchants/:id" element={<MerchantDetail />} />
          <Route path="merchants/:storeId/menu" element={<ManageMenu />} />
          <Route path="subscriptions" element={<SubscriptionRequests />} />
          <Route path="map" element={<AcquisitionMap />} />
          <Route path="reports" element={<Reports />} />
          <Route path="kulakan" element={<Kulakan />} />
          <Route path="profile" element={<Profile />} />
          <Route path="packages" element={<Packages />} />
          <Route path="broadcasts" element={<Broadcasts />} />
          <Route path="support" element={<Support />} />
          <Route path="settings" element={<Settings />} />
          <Route path="app-menus" element={<AppMenus />} />
          <Route path="announcements" element={<Announcements />} />
        </Route>

        {/* Old routes, potentially to be removed or moved under /admin */}
        <Route path="/" element={
          <ProtectedRoute><Dashboard /></ProtectedRoute>
        } />

        <Route path="/withdrawals" element={
          <ProtectedRoute><Withdrawals /></ProtectedRoute>
        } />

        <Route path="/merchants" element={
          <ProtectedRoute><Merchants /></ProtectedRoute>
        } />

        <Route path="/merchants/:id" element={<ProtectedRoute><MerchantDetail /></ProtectedRoute>} /> {/* [NEW] */}

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

        <Route path="/audit-logs" element={
          <ProtectedRoute><AuditLogs /></ProtectedRoute>
        } />

        <Route path="/content-manager" element={
          <ProtectedRoute><ContentManager /></ProtectedRoute>
        } />

        <Route path="/app-menus" element={
          <ProtectedRoute><AppMenus /></ProtectedRoute>
        } />

        <Route path="/admins" element={
          <ProtectedRoute><AdminUsers /></ProtectedRoute>
        } />

        <Route path="/transactions" element={
          <ProtectedRoute><Transactions /></ProtectedRoute>
        } />

        <Route path="/topups" element={
          <ProtectedRoute><TopUps /></ProtectedRoute>
        } />

        <Route path="/announcements" element={
          <ProtectedRoute><Announcements /></ProtectedRoute>
        } />
      </Routes>
    </Router>
  );
}

export default App;
