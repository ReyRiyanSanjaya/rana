require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const path = require('path'); // [FIX] Added path module
const bcrypt = require('bcrypt');

const compression = require('compression');
const rateLimit = require('express-rate-limit');
const reportRoutes = require('./routes/reportRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const authRoutes = require('./routes/authRoutes');
const referralRoutes = require('./routes/referralRoutes');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
// Middleware
app.use(cors({ origin: true, credentials: true })); // [FIX] Allow all origins dynamically
app.options('*', cors({ origin: true, credentials: true })); // [FIX] Enable Pre-Flight for all routes with credentials

app.use(helmet({
    crossOriginResourcePolicy: false, // [FIX] Allow resources to be loaded cross-origin
}));
app.use(compression()); // Gzip Compression

// Rate Limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 3000, // Limit each IP to 3000 requests per windowMs
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use(limiter);

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
app.use('/api/referral', referralRoutes);

// Error Handler
app.use((err, req, res, next) => {
    console.error('[Global Error]', err);
    res.status(500).json({ error: 'Internal Server Error' });
});

const http = require('http');
const { initSocket } = require('./socket');

const server = http.createServer(app);
initSocket(server);

async function ensureBlogSeed() {
    const count = await prisma.blogPost.count();
    if (count === 0) {
        await prisma.blogPost.createMany({
            data: [
                {
                    title: 'Memperkenalkan Rana POS: Kecerdasan Keuangan untuk UMKM',
                    slug: 'memperkenalkan-rana-pos',
                    summary: 'Platform POS modern dengan laporan keuangan otomatis dan manajemen stok real-time.',
                    content: '<h2>Kenapa Rana POS?</h2><p>Rana POS membantu UMKM mengambil keputusan berdasarkan data dengan laporan otomatis, manajemen stok, dan integrasi pembayaran.</p><p>Kami fokus pada kemudahan penggunaan dan performa.</p>',
                    imageUrl: 'https://images.unsplash.com/photo-1556742041-4b8b5cc5253f?q=80&w=1200&auto=format&fit=crop',
                    author: 'Tim Rana',
                    tags: ['product', 'umkm', 'pos'],
                    status: 'PUBLISHED',
                    publishedAt: new Date()
                },
                {
                    title: 'Tips Mengelola Stok Agar Tidak Kehabisan',
                    slug: 'tips-mengelola-stok',
                    summary: 'Strategi praktis untuk menjaga ketersediaan stok dan mengurangi dead stock.',
                    content: '<h2>Strategi Stok</h2><ul><li>Tetapkan min stock</li><li>Pantau pergerakan stok</li><li>Gunakan laporan harian</li></ul><p>Dengan Rana, semua insight tersedia secara otomatis.</p>',
                    imageUrl: 'https://images.unsplash.com/photo-1556767576-cfba2f8e7df5?q=80&w=1200&auto=format&fit=crop',
                    author: 'Operasional Rana',
                    tags: ['inventory', 'tips'],
                    status: 'PUBLISHED',
                    publishedAt: new Date()
                },
                {
                    title: 'Laporan Laba Rugi: Cara Membacanya untuk Aksi',
                    slug: 'laporan-laba-rugi',
                    summary: 'Memahami profit & loss agar bisa mengambil keputusan bisnis yang tepat.',
                    content: '<h2>Laba Rugi</h2><p>Ketahui pendapatan, biaya, dan margin. Rana menyediakan grafik dan ringkasan otomatis yang mudah dipahami.</p>',
                    imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=1200&auto=format&fit=crop',
                    author: 'Finance Rana',
                    tags: ['finance', 'reports'],
                    status: 'PUBLISHED',
                    publishedAt: new Date()
                }
            ]
        });
    }
}

async function ensureSuperAdminSeed() {
    const existing = await prisma.user.count({ where: { role: 'SUPER_ADMIN' } });
    if (existing > 0) return;
    const email = (process.env.ADMIN_EMAIL || 'admin@rana.id').toLowerCase();
    const password = process.env.ADMIN_PASSWORD || 'Admin!12345';
    const hashed = await bcrypt.hash(password, 10);
    const adminTenant = await prisma.tenant.upsert({
        where: { id: 'rana_admin_tenant' },
        update: {},
        create: {
            id: 'rana_admin_tenant',
            name: 'Rana Platform',
            plan: 'ENTERPRISE',
            subscriptionStatus: 'ACTIVE'
        }
    });
    await prisma.user.create({
        data: {
            email,
            passwordHash: hashed,
            name: 'Platform Admin',
            role: 'SUPER_ADMIN',
            tenantId: adminTenant.id,
            storeId: null
        }
    });
    console.log(`[Seed] SUPER_ADMIN created: ${email}`);
}

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
    ensureBlogSeed().catch((e) => console.error(e));
    ensureSuperAdminSeed().catch((e) => console.error(e));
});
