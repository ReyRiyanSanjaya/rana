/**
 * RanaDB - Offline First Database Layer
 * Uses raw IndexedDB for zero-dependency handling of offline transactions.
 */

const DB_NAME = 'RanaPOS_DB';
const DB_VERSION = 1;
const STORES = {
    TRANSACTIONS: 'transactions',
    PRODUCTS: 'products', // Cache for offline lookup
    SYNC_QUEUE: 'sync_queue'
};

const openDB = () => {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onerror = (event) => reject('Database error: ' + event.target.error);

        request.onsuccess = (event) => resolve(event.target.result);

        request.onupgradeneeded = (event) => {
            const db = event.target.result;

            // Store for Completed Transactions (History)
            if (!db.objectStoreNames.contains(STORES.TRANSACTIONS)) {
                db.createObjectStore(STORES.TRANSACTIONS, { keyPath: 'offlineId' });
            }

            // Store for Product Catalog (Read-heavy)
            if (!db.objectStoreNames.contains(STORES.PRODUCTS)) {
                const productStore = db.createObjectStore(STORES.PRODUCTS, { keyPath: 'id' });
                productStore.createIndex('sku', 'sku', { unique: true });
            }

            // Store for Pending Sync Items
            if (!db.objectStoreNames.contains(STORES.SYNC_QUEUE)) {
                db.createObjectStore(STORES.SYNC_QUEUE, { keyPath: 'id', autoIncrement: true });
            }
        };
    });
};

const RanaDB = {
    // Add a transaction to the offline queue
    async queueTransaction(transactionData) {
        const db = await openDB();
        const tx = db.transaction([STORES.SYNC_QUEUE, STORES.TRANSACTIONS], 'readwrite');

        // 1. Save to History (UI display)
        const historyStore = tx.objectStore(STORES.TRANSACTIONS);
        historyStore.add({
            ...transactionData,
            status: 'PENDING_SYNC', // Local status
            syncedAt: null
        });

        // 2. Add to Sync Queue
        const queueStore = tx.objectStore(STORES.SYNC_QUEUE);
        queueStore.add({
            type: 'NEW_TRANSACTION',
            payload: transactionData,
            createdAt: new Date().toISOString()
        });

        return new Promise((resolve, reject) => {
            tx.oncomplete = () => resolve(true);
            tx.onerror = () => reject(tx.error);
        });
    },

    // Get all pending items to sync
    async getPendingSync() {
        const db = await openDB();
        return new Promise((resolve, reject) => {
            const tx = db.transaction(STORES.SYNC_QUEUE, 'readonly');
            const store = tx.objectStore(STORES.SYNC_QUEUE);
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    },

    // Clear synced items
    async clearSyncQueue(ids) {
        const db = await openDB();
        const tx = db.transaction(STORES.SYNC_QUEUE, 'readwrite');
        const store = tx.objectStore(STORES.SYNC_QUEUE);
        ids.forEach(id => store.delete(id));
        return new Promise((resolve) => {
            tx.oncomplete = () => resolve(true);
        });
    }
};

export default RanaDB;
