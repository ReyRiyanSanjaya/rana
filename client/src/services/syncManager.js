import RanaDB from './db';
import api from './api'; // Our axios instance

/**
 * SyncManager
 * Handles the background synchronization of offline data to the server.
 */

const SyncManager = {
    isSyncing: false,
    intervalId: null,

    startBackgroundSync(intervalMs = 60000) { // Default 1 min
        if (this.intervalId) return;

        console.log('[SyncManager] Started background sync');
        this.intervalId = setInterval(() => {
            this.pushChanges();
        }, intervalMs);
    },

    stopBackgroundSync() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
    },

    async pushChanges() {
        if (this.isSyncing) return;
        if (!navigator.onLine) {
            console.log('[SyncManager] Offline, skipping sync');
            return;
        }

        this.isSyncing = true;
        try {
            const pendingItems = await RanaDB.getPendingSync();
            if (pendingItems.length === 0) {
                this.isSyncing = false;
                return;
            }

            console.log(`[SyncManager] Found ${pendingItems.length} items to sync`);

            // Batch Send (Naive implementation: 1 by 1 or bulk)
            // For MVP let's do bulky if API supports, or loop.
            // We'll loop for safety.

            const syncedIds = [];

            for (const item of pendingItems) {
                try {
                    if (item.type === 'NEW_TRANSACTION') {
                        // POST to server
                        await api.post('/transactions/sync', item.payload);

                        console.log('Synced:', item.payload.offlineId);
                        syncedIds.push(item.id);
                    }
                } catch (err) {
                    console.error('Failed to sync item', item.id, err);
                    // Keep in queue to retry later
                }
            }

            if (syncedIds.length > 0) {
                await RanaDB.clearSyncQueue(syncedIds);
                console.log(`[SyncManager] Successfully synced ${syncedIds.length} items`);
                // Trigger global refresh/re-fetch if needed
                window.dispatchEvent(new Event('rana:synced'));
            }

        } catch (error) {
            console.error('[SyncManager] Critical error during sync', error);
        } finally {
            this.isSyncing = false;
        }
    }
};

export default SyncManager;
