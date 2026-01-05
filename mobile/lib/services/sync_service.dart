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

  Future<void> syncTransactions() async {
    if (_isSyncing) return;

    // [NEW] Check connectivity first
    final hasInternet = await ConnectivityService().hasInternetConnection();
    if (!hasInternet) {
      if (kDebugMode) debugPrint('No internet connection. Skipping sync.');
      return;
    }

    _isSyncing = true;

    try {
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
                    'price': i['price']
                  })
              .toList()
        };

        // Send to Server
        await api.uploadTransaction(payload);

        await db.markSynced(offlineId);
      }

      // After all transactions are synced, refresh products from server
      await api.fetchAndSaveProducts();

      // [NEW] Sync Transaction History from server to local for reporting
      await syncTransactionHistory();

      // [NEW] Notify listeners
      _dataChangeController.add(null);
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
          'occurredAt': txnData['occurredAt'] ?? txnData['createdAt'],
          'syncedAt': DateTime.now().toIso8601String(),
        };

        final items = itemsData
            .map((i) => {
                  'transactionOfflineId': txn['offlineId'],
                  'productId': i['productId'],
                  'quantity': i['quantity'],
                  'price': i['price'],
                  'costPrice':
                      i['costPrice'] ?? 0, // Server should provide this
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
}
