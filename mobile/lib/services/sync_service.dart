import 'dart:async'; // [NEW]
import 'package:flutter/foundation.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/services/connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // [NEW] Data Change Stream
  final _dataChangeController = StreamController<void>.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;
  Timer? _autoTimer;
  StreamSubscription<bool>? _connSub;
  bool _autoEnabled = false;
  DateTime? _lastSyncAt;
  bool _online = false;
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get isOnline => _online;

  Future<void> syncTransactions() async {
    if (_isSyncing) return;
    _isSyncing = true; // [FIX] Lock immediately to prevent race conditions

    try {
      // [NEW] Check connectivity first
      final hasInternet = await ConnectivityService().hasInternetConnection();
      if (!hasInternet) {
        if (kDebugMode) debugPrint('No internet connection. Skipping sync.');
        return;
      }

      final db = DatabaseHelper.instance;
      final pendingTxns = await db.getPendingTransactions();

      if (pendingTxns.isEmpty) {
        if (kDebugMode) debugPrint('No pending transactions to sync.');
        return;
      }

      final api = ApiService();

      for (var txn in pendingTxns) {
        final offlineId = txn['offlineId'];
        final items = await db.getItemsForTransaction(offlineId);

        final payload = {
          'offlineId': offlineId,
          'cashierId': txn['cashierId'],
          'totalAmount': txn['totalAmount'],
          'paymentMethod': txn['paymentMethod'] ?? 'CASH',
          'occurredAt': txn['occurredAt'],
          'items': items
              .map((i) => {
                    'productId': i['productId'],
                    'quantity': i['quantity'],
                    'price': i['price'],
                    // [NEW] Enriched Data
                    'productName': i['name'],
                    'productSku': i['sku'],
                    'productImage': i['imageUrl'],
                    'basePrice': i['costPrice']
                  })
              .toList()
        };

        // Send to Server
        await api.uploadTransaction(payload);

        await db.markSynced(offlineId);
      }

      // After all transactions are synced, refresh products from server
      await api.fetchAndSaveProducts();

      // [NEW] Sync Pending Expenses
      Future<void> syncExpenses() async {
        try {
          final db = DatabaseHelper.instance;
          final pendingExpenses = await db.getPendingExpenses();

          if (pendingExpenses.isEmpty) return;

          final api = ApiService();

          for (var expense in pendingExpenses) {
            String category = expense['category'];
            String description = expense['description'] ?? '';

            final Map<String, String> categoryMapping = {
              'EXPENSE_SALARY': 'EXPENSE_OPERATIONAL',
              'EXPENSE_MARKETING': 'EXPENSE_OPERATIONAL',
              'EXPENSE_RENT': 'EXPENSE_OPERATIONAL',
              'EXPENSE_MAINTENANCE': 'EXPENSE_OPERATIONAL',
              'EXPENSE_OTHER': 'OTHER',
            };

            if (categoryMapping.containsKey(category)) {
              // Prepend original category if not already there (simple check)
              if (!description.contains('[')) {
                description = '[${expense['category']}] $description';
              }
              category = categoryMapping[category]!;
            }

            // Prepare payload
            final payload = {
              'storeId':
                  expense['storeId'], // Ensure this is set or handled by server
              'amount': expense['amount'],
              'category': category,
              'description': description,
              'date': expense['date'],
              // Image handling is complex (multipart), for now let's sync text data
              // If server supports image, we need to upload it.
              // Assuming uploadExpense handles JSON for now.
            };

            await api.uploadExpense(payload);
            await db.markExpenseSynced(expense['id']);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Expense Sync Error: $e');
          // Don't rethrow to avoid blocking transaction sync
        }
      }

      await syncExpenses();

      // [NEW] Sync Transaction History from server to local for reporting
      await syncTransactionHistory();

      // [NEW] Notify listeners
      _dataChangeController.add(null);
      _lastSyncAt = DateTime.now();
      _statusController.add(
          {'online': _online, 'lastSyncAt': _lastSyncAt?.toIso8601String()});
    } catch (e) {
      if (kDebugMode) debugPrint('Sync Error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // [NEW] Sync Transaction History from server
  Future<void> syncTransactionHistory() async {
    try {
      final api = ApiService();
      final db = DatabaseHelper.instance;

      // Fetch last 30 days history (or more if needed)
      final history = await api.fetchTransactionHistory();

      for (var txnData in history) {
        final itemsData = txnData['items'] as List<dynamic>? ?? [];

        final txn = {
          'offlineId': txnData['offlineId'] ?? txnData['id'].toString(),
          'cashierId': txnData['cashierId'],
          'totalAmount': txnData['totalAmount'],
          'paymentMethod': txnData['paymentMethod'] ?? 'CASH',
          'status':
              (txnData['status'] == 'VOID' || txnData['status'] == 'CANCELLED')
                  ? 'VOID'
                  : 'SYNCED',
          'occurredAt': (txnData['occurredAt'] ?? txnData['createdAt']) != null
              ? DateTime.parse(txnData['occurredAt'] ?? txnData['createdAt'])
                  .toLocal()
                  .toIso8601String()
              : DateTime.now().toIso8601String(),
          'syncedAt': DateTime.now().toIso8601String(),
        };

        final items = itemsData
            .map((i) => {
                  'transactionOfflineId': txn['offlineId'],
                  'productId': i['productId'],
                  'quantity': i['quantity'],
                  'price': i['price'],
                  'costPrice': i['basePrice'] ?? i['costPrice'] ?? 0, // Map server basePrice to local costPrice
                  'name': i['productName'] ?? '',
                  'sku': i['productSku'],
                  'imageUrl': i['productImage']
                })
            .toList();

        await db.upsertSyncedTransaction(txn, items);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('History Sync Error: $e');
    }
  }

  // [NEW] Allow external services to trigger update notification
  void notifyDataChanged() {
    _dataChangeController.add(null);
  }

  // [NEW] Sync Products only
  Future<void> syncProducts() async {
    try {
      await ApiService().fetchAndSaveProducts();
      notifyDataChanged();
    } catch (e) {
      if (kDebugMode) debugPrint('Product Sync Error: $e');
    }
  }

  void startAutoSync({Duration interval = const Duration(seconds: 15)}) {
    if (_autoEnabled) return;
    _autoEnabled = true;
    ConnectivityService().startMonitoring();
    _connSub?.cancel();
    _connSub = ConnectivityService().onStatusChanged.listen((online) async {
      _online = online;
      _statusController.add(
          {'online': _online, 'lastSyncAt': _lastSyncAt?.toIso8601String()});
      if (online) {
        try {
          await syncTransactions();
        } catch (_) {}
      }
    });
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(interval, (_) async {
      final online = await ConnectivityService().hasInternetConnection();
      _online = online;
      _statusController.add(
          {'online': _online, 'lastSyncAt': _lastSyncAt?.toIso8601String()});
      if (!online) return;
      try {
        await syncTransactions();
      } catch (_) {}
    });
  }

  void stopAutoSync() {
    _autoEnabled = false;
    _autoTimer?.cancel();
    _autoTimer = null;
    _connSub?.cancel();
    _connSub = null;
    _statusController
        .add({'online': _online, 'lastSyncAt': _lastSyncAt?.toIso8601String()});
  }
}
