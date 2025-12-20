import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rana_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Products Table (Cache for Offline)
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        tenantId TEXT,
        sku TEXT,
        name TEXT,
        sellingPrice REAL,
        costPrice REAL,
        trackStock INTEGER
      )
    ''');

    // 2. Transactions Table (Offline Queue)
    await db.execute('''
      CREATE TABLE transactions (
        offlineId TEXT PRIMARY KEY,
        tenantId TEXT,
        storeId TEXT,
        cashierId TEXT,
        total REAL,
        occurredAt TEXT,
        status TEXT, -- PENDING_SYNC, SYNCED
        syncedAt TEXT,
        paymentMethod TEXT,
        customerName TEXT,
        notes TEXT,
        discount REAL,       -- [NEW]
        tax REAL             -- [NEW]
      )
    ''');

    // 3. Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transactionOfflineId TEXT,
        productId TEXT,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (transactionOfflineId) REFERENCES transactions (offlineId)
      )
    ''');
  }

  // --- CRUD Operations ---
  
  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  Future<void> queueTransaction(Map<String, dynamic> txn, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    await db.transaction((txnObj) async {
      await txnObj.insert('transactions', txn);
      for (var item in items) {
        await txnObj.insert('transaction_items', item);
      }
    });
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
      return await db.query('transactions');
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
}
