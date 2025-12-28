import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rana_pos_fixed.db'); // [FIX] Force fresh DB to avoid migration issues
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // [FIX] Increment version for migration - add originalPrice
      onCreate: _createDB,
      onUpgrade: _onUpgrade, 
    );
  }

  // [NEW] Migration Logic
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
       // Add missing columns to 'transactions'
       final columnsToAdd = [
         'storeId TEXT', 
         'cashierId TEXT', 
         'discount REAL DEFAULT 0', 
         'tax REAL DEFAULT 0',
         'customerName TEXT',
         'notes TEXT',
         'paymentMethod TEXT' // Ensure this exists too
       ];

       for (var col in columnsToAdd) {
         try {
           await db.execute('ALTER TABLE transactions ADD COLUMN $col');
         } catch (e) {
           // Column likely exists
         }
       }
       
       // Also ensure costPrice in items
       try {
        await db.execute('ALTER TABLE transaction_items ADD COLUMN costPrice REAL DEFAULT 0');
       } catch (e) {}
    }
    
    // [NEW] Migration for version 7 - Add promo fields to products
    if (oldVersion < 7) {
       final productColumnsToAdd = [
         'originalPrice REAL',       // Store price before discount
         'promoEndsAt TEXT',          // When promo expires (ISO8601)
       ];
       
       for (var col in productColumnsToAdd) {
         try {
           await db.execute('ALTER TABLE products ADD COLUMN $col');
         } catch (e) {
           // Column likely exists
         }
       }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tenants (For Multi-User / Store Support later)
    await db.execute('''
      CREATE TABLE tenants (
        id TEXT PRIMARY KEY,
        businessName TEXT,
        email TEXT,
        phone TEXT,
        address TEXT
      )
    ''');

    // 2. Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        tenantId TEXT,
        sku TEXT,
        name TEXT,
        description TEXT,
        costPrice REAL DEFAULT 0,
        sellingPrice REAL,
        stock INTEGER DEFAULT 0,
        trackStock INTEGER DEFAULT 1,
        category TEXT,
        imageUrl TEXT,
        syncStatus INTEGER DEFAULT 0, -- 0: Pending, 1: Synced
        lastUpdated INTEGER
      )
    ''');

    // 3. Transactions (Offline First)
    await db.execute('''
      CREATE TABLE transactions (
        offlineId TEXT PRIMARY KEY,
        tenantId TEXT,
        storeId TEXT,       -- [NEW]
        cashierId TEXT,     -- [NEW]
        totalAmount REAL,
        discount REAL DEFAULT 0, -- [NEW]
        tax REAL DEFAULT 0,      -- [NEW]
        paymentMethod TEXT, -- CASH, QRIS
        customerName TEXT,  -- [NEW]
        notes TEXT,         -- [NEW]
        status TEXT, -- PENDING, COMPLETED, VOID
        occurredAt TEXT,
        syncStatus INTEGER DEFAULT 0 
      )
    ''');

    // 4. Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionOfflineId TEXT,
        productId TEXT,
        name TEXT,
        quantity INTEGER,
        price REAL,
        costPrice REAL DEFAULT 0,
        FOREIGN KEY (transactionOfflineId) REFERENCES transactions (offlineId) ON DELETE CASCADE
      )
    ''');

    // 5. Expenses (Offline First)
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storeId TEXT,
        amount REAL,
        category TEXT, -- EXPENSE_PETTY, EXPENSE_OPERATIONAL
        description TEXT,
        date TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // --- CRUD Operations ---
  
  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductDetails(String id, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  Future<void> queueTransaction(Map<String, dynamic> txn, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    await db.transaction((txnObj) async {
      // 1. Save Transaction Header
      await txnObj.insert('transactions', txn);
      
      // 2. Save Items and Decrement Stock
      for (var item in items) {
        // [UPDATED] Ensure costPrice is saved
        if (!item.containsKey('costPrice')) {
           // Fallback: fetch current cost from product if not provided in item object
           final productRes = await txnObj.query('products', columns: ['costPrice'], where: 'id = ?', whereArgs: [item['productId']]);
           if (productRes.isNotEmpty) {
             item['costPrice'] = productRes.first['costPrice'] ?? 0;
           } else {
             item['costPrice'] = 0;
           }
        }
        
        await txnObj.insert('transaction_items', item);
        
        // Decrement stock for the product
        // We use rawQuery/execute for update
        await txnObj.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item['quantity'], item['productId']]
        );
      }
    });
  }

  // Used by Stock Opname Screen
  Future<void> updateProductStock(String productId, int newStock) async {
    final db = await instance.database;
    await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId]
    );
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await instance.database;
    // Join logic needed in real app, simplified here
    return await db.query('transactions', where: 'status = ?', whereArgs: ['PENDING_SYNC']);
  }
  
  Future<List<Map<String, dynamic>>> getItemsForTransaction(String offlineId) async {
      final db = await instance.database;
      return await db.query('transaction_items', where: 'transactionOfflineId = ?', whereArgs: [offlineId]);
  }
  
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
      final db = await instance.database;
      return await db.query('transactions', orderBy: 'occurredAt DESC');
  }

  Future<void> markSynced(String offlineId) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      {'status': 'SYNCED', 'syncedAt': DateTime.now().toIso8601String()},
      where: 'offlineId = ?',
      whereArgs: [offlineId],
    );
  }

  // --- EXPENSE OPERATIONS ---

  Future<void> insertExpense(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getExpenses({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
     final startDate = start ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = end ?? DateTime.now();

    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()]
    );
  }

  // --- REPORTING QUERIES ---

  Future<Map<String, dynamic>> getSalesReport({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    
    // Default to last 30 days if null
    final startDate = start ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = end ?? DateTime.now();

    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    // 1. Transaction Stats (Revenue, Count)
    final txnRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalTransactions, 
        SUM(totalAmount) as grossSales
      FROM transactions 
      WHERE occurredAt BETWEEN ? AND ?
    ''', [startStr, endStr]);

    final totalTransactions = Sqflite.firstIntValue(txnRes) ?? 0;
    final grossSales = (txnRes.first['grossSales'] as num?)?.toDouble() ?? 0.0;

    // 2. Profit Calculation (Gross Sales - Total Cost)
    // We join transaction_items with transactions to filter by date
    final profitRes = await db.rawQuery('''
      SELECT 
        SUM((ti.price - ti.costPrice) * ti.quantity) as totalProfit
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionOfflineId = t.offlineId
      WHERE t.occurredAt BETWEEN ? AND ?
    ''', [startStr, endStr]);

    final totalProfit = (profitRes.first['totalProfit'] as num?)?.toDouble() ?? 0.0;

    // 3. Sales Trend (Daily)
    final trendRes = await db.rawQuery('''
      SELECT 
        substr(occurredAt, 1, 10) as date, 
        SUM(totalAmount) as dailyTotal
      FROM transactions
      WHERE occurredAt BETWEEN ? AND ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startStr, endStr]);

    // [NEW] 4. Total Expenses
    final expRes = await db.rawQuery('''
      SELECT SUM(amount) as totalExpenses 
      FROM expenses 
      WHERE date BETWEEN ? AND ?
    ''', [startStr, endStr]);

    final totalExpenses = (expRes.first['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    
    // Net Profit = (Sales - COGS) - Expenses
    final netProfit = totalProfit - totalExpenses;

    return {
      'totalTransactions': totalTransactions,
      'grossSales': grossSales,
      'netProfit': netProfit,
      'totalExpenses': totalExpenses, // [NEW] Return this too
      'averageOrderValue': totalTransactions > 0 ? grossSales / totalTransactions : 0,
      'trend': trendRes
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        p.name, 
        SUM(ti.quantity) as totalQty,
        SUM(ti.price * ti.quantity) as totalRevenue
      FROM transaction_items ti
      JOIN products p ON ti.productId = p.id
      GROUP BY p.name
      ORDER BY totalQty DESC
      LIMIT ?
    ''', [limit]);
  }

  // [NEW] Category Breakdown
  Future<List<Map<String, dynamic>>> getSalesByCategory({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    final startDate = start ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = end ?? DateTime.now();

    return await db.rawQuery('''
      SELECT 
        p.category, 
        SUM(ti.price * ti.quantity) as totalSales
      FROM transaction_items ti
      JOIN products p ON ti.productId = p.id
      JOIN transactions t ON ti.transactionOfflineId = t.offlineId
      WHERE t.occurredAt BETWEEN ? AND ?
      GROUP BY p.category
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
  }

  // [NEW] Payment Method Breakdown
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    final startDate = start ?? DateTime.now().subtract(const Duration(days: 30));
    final endDate = end ?? DateTime.now();

    return await db.rawQuery('''
      SELECT 
        paymentMethod, 
        COUNT(*) as count,
        SUM(totalAmount) as totalAmount
      FROM transactions
      WHERE occurredAt BETWEEN ? AND ?
      GROUP BY paymentMethod
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
  }

  // [NEW] Low Stock Alert
  Future<List<Map<String, dynamic>>> getLowStockProducts({int threshold = 5}) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'trackStock = 1 AND stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC'
    );
  }
  // [NEW] Get Tenant Info
  Future<Map<String, dynamic>?> getTenantInfo() async {
    final db = await instance.database;
    final res = await db.query('tenants', limit: 1);
    if (res.isNotEmpty) return res.first;
    return null;
  }
}
