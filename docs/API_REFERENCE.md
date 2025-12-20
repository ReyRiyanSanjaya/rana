# Rana POS - API Reference

## Base URL
`http://localhost:4000/api`

## Authentication
All endpoints require a JWT token in the header (simulated in `mockAuth` middleware for MVP).
`Authorization: Bearer <token>`

---

## 📊 Reporting Endpoints

### 1. Get Dashboard Statistics
Returns aggregated financial data for a specific day.
* **GET** `/reports/dashboard`
* **Query Params**:
    * `date` (Required): `YYYY-MM-DD`
    * `storeId` (Optional): Filter by specific store.
* **Response**:
```json
{
  "status": "success",
  "data": {
    "financials": {
      "grossSales": 100000,
      "netSales": 95000,
      "grossProfit": 40000,
      "transactionCount": 12
    },
    "topProducts": [
      { "product": { "name": "Coffee" }, "revenue": 5000 }
    ]
  }
}
```

### 2. Profit & Loss Report
Returns summed financial data over a period.
* **GET** `/reports/profit-loss`
* **Query Params**:
    * `startDate`: `YYYY-MM-DD`
    * `endDate`: `YYYY-MM-DD`
* **Response**:
```json
{
  "status": "success",
  "data": {
    "period": { "start": "...", "end": "..." },
    "pnl": {
      "revenue": 5000000,
      "cogs": 2000000,
      "grossProfit": 3000000,
      "margin": "60.00"
    }
  }
}
```

### 3. Inventory Intelligence
Returns low stock and slow-moving items.
* **GET** `/reports/inventory-intelligence`
* **Response**:
```json
{
  "status": "success",
  "data": {
    "alerts": {
      "lowStockCount": 5,
      "items": [...]
    }
  }
}
```
