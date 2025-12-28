require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path'); // [FIX] Added path module

const compression = require('compression');
const reportRoutes = require('./routes/reportRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
// Middleware
app.use(cors({ origin: true, credentials: true })); // [FIX] Allow all origins dynamically
app.options('*', cors()); // [FIX] Enable Pre-Flight for all routes

app.use(helmet({
    crossOriginResourcePolicy: false, // [FIX] Allow resources to be loaded cross-origin
}));
app.use(compression()); // Gzip Compression
app.use(express.json({ limit: '50mb' })); // [FIX] Increase limit for Base64 uploads
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(morgan('dev'));

// Static Files
app.use('/uploads', express.static(path.join(__dirname, '../uploads'))); // [FIX] Serve server/uploads

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
app.use('/api/tickets', require('./routes/merchantTicketRoutes')); // [NEW] Merchant Tickets

const wholesaleRoutes = require('./routes/wholesaleRoutes');
app.use('/api/wholesale', wholesaleRoutes); // [NEW]
app.use('/api/ppob', require('./routes/ppobRoutes')); // [NEW] Digital Products
app.use('/api/blog', require('./routes/blogRoutes')); // [NEW] Blog System

// Error Handler
app.use((err, req, res, next) => {
    console.error('[Global Error]', err);
    res.status(500).json({ error: 'Internal Server Error' });
});

const http = require('http');
const { initSocket } = require('./socket');

const server = http.createServer(app);
initSocket(server);

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
});
