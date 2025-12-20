require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');

const compression = require('compression');
const reportRoutes = require('./routes/reportRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(helmet());
app.use(compression()); // Gzip Compression
app.use(cors());
app.use(express.json()); // For parsing application/json
app.use(morgan('dev'));

// Routes
app.get('/', (req, res) => {
    res.send('Rana POS Server is Running');
});

// Public Routes
app.use('/api/auth', authRoutes);

// Protected Routes
// Mount Modules
app.use('/api/reports', reportRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/subscriptions', require('./routes/subscriptionRoutes'));
app.use('/api/purchases', require('./routes/purchaseRoutes'));
app.use('/api/orders', require('./routes/orderRoutes')); // [NEW] Merchant Order Management
app.use('/api/market', require('./routes/marketRoutes')); // [NEW] Public Market API
app.use('/api/system', require('./routes/systemRoutes')); // [NEW] System Info
app.use('/api/admin', require('./routes/adminRoutes')); // [NEW] Super Admin API
app.use('/api/wallet', require('./routes/walletRoutes')); // [NEW] Merchant Wallet API
app.use('/api/inventory', require('./routes/inventoryRoutes')); // [NEW] Inventory API
app.use('/api/products', require('./routes/productRoutes')); // [NEW] Product CRUD API

// Error Handler
app.use((err, req, res, next) => {
    console.error('[Global Error]', err);
    res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
});
