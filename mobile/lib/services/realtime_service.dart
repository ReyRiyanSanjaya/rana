import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rana_merchant/constants.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/services/notification_service.dart';

typedef TransactionEventHandler = void Function(Map<String, dynamic> data);

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  io.Socket? _socket;
  bool _initialized = false;

  final List<TransactionEventHandler> _transactionListeners = [];

  io.Socket _ensureConnected() {
    if (_socket != null && _socket!.connected) return _socket!;
    final token = ApiService().token ?? '';
    final origin = AppConstants.baseUrl;

    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .build(),
    );

    return _socket!;
  }

  void init() {
    if (_initialized) return;
    final s = _ensureConnected();

    s.on('inventory:changed', (payload) async {
      if (payload is! Map) return;
      final dynamic changesRaw = payload['changes'];
      if (changesRaw is! List) return;

      final db = DatabaseHelper.instance;
      for (final item in changesRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final productId = map['productId']?.toString();
        final dynamic storeStockRaw = map['storeStock'] ?? map['stock'];
        if (productId == null) continue;
        if (storeStockRaw is! num) continue;
        final newStock = storeStockRaw.toInt();
        await db.updateProductStock(productId, newStock);
      }
    });

    s.on('transactions:created', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      for (final handler in List<TransactionEventHandler>.from(_transactionListeners)) {
        unawaited(Future<void>.microtask(() => handler(data)));
      }

      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Transaksi baru',
        body: 'Transaksi baru berhasil tersimpan.',
      );
    });

    s.on('orders:updated', (payload) {
      if (payload is! Map) return;
      final data = Map<String, dynamic>.from(payload);
      for (final handler in List<TransactionEventHandler>.from(_transactionListeners)) {
        unawaited(Future<void>.microtask(() => handler(data)));
      }

      final status = data['orderStatus']?.toString();
      final title = status == null || status.isEmpty ? 'Pesanan diperbarui' : 'Status pesanan: $status';

      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: 'Pesanan marketplace diperbarui.',
      );
    });

    _initialized = true;
  }

  void addTransactionListener(TransactionEventHandler handler) {
    if (!_transactionListeners.contains(handler)) {
      _transactionListeners.add(handler);
    }
    _ensureConnected();
  }

  void removeTransactionListener(TransactionEventHandler handler) {
    _transactionListeners.remove(handler);
  }

  void dispose() {
    _transactionListeners.clear();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}
