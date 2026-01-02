import 'package:flutter/foundation.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> syncTransactions() async {
    if (_isSyncing) return;
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
           'items': items.map((i) => {
             'productId': i['productId'],
             'quantity': i['quantity'],
             'price': i['price']
           }).toList()
        };

        // Send to Server
        await api.uploadTransaction(payload); 
        
        await db.markSynced(offlineId);
      }

      // After all transactions are synced, refresh products from server
      await api.fetchAndSaveProducts();
      
    } catch (e) {
      if (kDebugMode) debugPrint('Sync Error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
}
