import axios from 'axios';

const api = axios.create({
    baseURL: '/api',
    headers: {
        'Content-Type': 'application/json',
    },
});

// --- MOCK DATA GENERATORS ---

const MOCK_DASHBOARD = {
    financials: {
        grossSales: 5400000,
        netSales: 5150000,
        grossProfit: 2100000,
        transactionCount: 142
    },
    topProducts: [
        { product: { name: 'Kopi Susu Gula Aren' }, revenue: 1500000 },
        { product: { name: 'Croissant Butter' }, revenue: 850000 },
        { product: { name: 'Americano Ice' }, revenue: 720000 },
        { product: { name: 'Latte Hot' }, revenue: 600000 },
        { product: { name: 'Espresso' }, revenue: 450000 },
    ]
};

const MOCK_PNL = {
    period: { start: '2023-11-01', end: '2023-11-30' },
    pnl: {
        revenue: 45000000,
        cogs: 20000000,
        grossProfit: 25000000,
        margin: 55.55,
        taxCollected: 4500000,
        discountsGiven: 1000000,
        expenses: 5000000, // Operational (Rent, Salaries) - Simulated
        netProfit: 20000000
    },
    chartData: Array.from({ length: 30 }, (_, i) => ({
        date: `2023-11-${i + 1}`,
        revenue: Math.floor(Math.random() * 2000000) + 1000000,
        profit: Math.floor(Math.random() * 1000000) + 500000,
    }))
};

const MOCK_INVENTORY = {
    alerts: {
        lowStockCount: 4,
        items: [
            { id: 1, name: 'Fresh Milk 1L', sku: 'MILK-001', stock: 2, threshold: 5, status: 'CRITICAL' },
            { id: 2, name: 'Vanilla Syrup', sku: 'SYR-VAN', stock: 4, threshold: 5, status: 'WARNING' },
            { id: 3, name: 'Paper Cups 12oz', sku: 'CUP-12', stock: 15, threshold: 20, status: 'WARNING' },
            { id: 4, name: 'Hazelnut Syrup', sku: 'SYR-HAZ', stock: 3, threshold: 5, status: 'CRITICAL' },
        ]
    },
    slowMoving: [
        { id: 5, name: 'Green Tea Powder', sku: 'MATCHA-PREM', lastSold: '2023-10-15', daysInactive: 45 },
        { id: 6, name: 'Caramel Sauce', sku: 'SAUCE-CAR', lastSold: '2023-11-01', daysInactive: 28 },
    ]
};

// --- API METHODS ---

export const fetchDashboardStats = async (date) => {
    try {
        const response = await api.get(`/reports/dashboard?date=${date}`);
        return response.data.data;
    } catch (error) {
        console.warn("API Error (Dashboard), falling back to mock data");
        return MOCK_DASHBOARD;
    }
};

export const fetchProfitLoss = async (startDate, endDate) => {
    try {
        const response = await api.get(`/reports/profit-loss?startDate=${startDate}&endDate=${endDate}`);
        return response.data.data;
    } catch (error) {
        console.warn("API Error (P&L), falling back to mock data");
        return MOCK_PNL;
    }
};

export const fetchInventoryIntelligence = async () => {
    try {
        const response = await api.get('/reports/inventory-intelligence');
        return response.data.data;
    } catch (error) {
        console.warn("API Error (Inventory), falling back to mock data");
        return MOCK_INVENTORY;
    }
}

// [NEW] Cash Management APIs
export const recordExpense = async (data) => {
    // data: { storeId, amount, category, description, date }
    return api.post('/reports/expenses', data);
};

export const recordDebt = async (data) => {
    // data: { storeId, borrowerName, amount, notes, date }
    return api.post('/reports/debts', data);
};

export const triggerDailyReport = async (storeId, date) => {
    return api.post('/reports/trigger-wa-report', { storeId, date });
};

// [NEW] Wallet & Withdrawal
export const fetchWalletData = async () => {
    const response = await api.get('/wallet');
    return response.data.data;
};

export const requestWithdrawal = async (data) => {
    // data: { amount, bankName, accountNumber }
    return api.post('/wallet/withdraw', data);
};

// [NEW] Inventory
export const fetchProducts = async () => {
    const response = await api.get('/products');
    return response.data.data;
};

export const fetchProductLogs = async (productId) => {
    return api.get(`/inventory/${productId}/logs`);
};

export const adjustStock = async (data) => {
    // data: { productId, quantity, type, reason }
    return api.post('/inventory/adjust', data);
};



// [NEW] Product CRUD
export const createProduct = async (data) => {
    return api.post('/products', data);
};

export const updateProduct = async (id, data) => {
    return api.put(`/products/${id}`, data);
};

export const deleteProduct = async (id) => {
    return api.delete(`/products/${id}`);
};

// [NEW] Store/Merchant Management (Admin)
export const fetchMerchants = async () => {
    const response = await api.get('/admin/merchants');
    return response.data.data;
};

export const createMerchant = async (data) => {
    // data: { businessName, ownerName, email, password, phone, address }
    return api.post('/admin/merchants', data);
};

export const deleteMerchant = async (id) => {
    return api.delete(`/admin/merchants/${id}`);
};

export default api;
