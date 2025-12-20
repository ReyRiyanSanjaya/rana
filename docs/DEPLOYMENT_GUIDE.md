# Rana POS - Deployment & Scaling Guide

## 1. Architecture Overview
Rana uses a split Client/Server architecture optimized for offline-first operations.

* **Client (Mobile/Web)**: React/Vite. Running on Vercel. Uses LocalStorage/IndexedDB (to be implemented) for offline queuing.
* **Server**: Node.js/Express. Running on Railway. Handles Sync Batches and Aggregation.
* **Database**: PostgreSQL on Railway.

## 2. Sync Logic & Scaling
The critical bottleneck in a sync-based POS is the "Monday Morning Spike" (many devices syncing at once).

### Strategy:
1.  **Batch Ingestion**: Transactions are sent in batches (e.g., 50 at a time).
2.  **Async Processing**:
    *   API endpoint `/sync/upload` dumps raw JSON into a minimal `SyncJob` queue/table immediately.
    *   A background worker (or scheduled cron) picks up `SyncJob`, inserts into `Transaction` table, and runs `AggregationService`.
    *   **Reasoning**: Prevents HTTP timeouts on the client.

## 3. Deployment Steps

### Backend (Railway)
1.  Connect GitHub Repo to Railway.
2.  Set Environment Variables:
    *   `DATABASE_URL`: Postgres Connection String
    *   `JWT_SECRET`: Secure Key
    *   `NODE_ENV`: `production`
3.  Add Start Command:
    *   `npm run start` (ensure `prisma migrate deploy` is run before start)

### Frontend (Vercel)
1.  Connect GitHub Repo.
2.  Set Build Command: `npm run build`
3.  Set Output Directory: `dist`
4.  Configure `vite.config.js` proxy or use Vercel Rewrites to point `/api` to the Railway Backend Key.

## 4. Database Tuning (PostgreSQL)
For Reporting Performance:
```sql
-- Ensure Index on Date + Store for fast aggregation lookups
CREATE INDEX "idx_daily_sales_store_date" ON "DailySalesSummary"("storeId", "date");

-- Ensure Index on Tenant + SKU for product lookups
CREATE INDEX "idx_product_tenant_sku" ON "Product"("tenantId", "sku");
```
(These are already handled by Prisma Schema `@index`).

## 5. Security Checklist
*   [ ] Enable Row Level Security (RLS) if possible, or ensure Prisma Middleware strictly enforces `where: { tenantId }`.
*   [ ] Rotate JWT Secrets.
*   [ ] Rate limit the `/sync` endpoint.
