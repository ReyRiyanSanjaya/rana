library io;

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rana_market/data/market_api_service.dart';
import 'notification_service.dart';

typedef OrderUpdateHandler = void Function(Map<String, dynamic> data);

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();

  factory RealtimeService() {
    return _instance;
  }

  RealtimeService._internal();

  io.Socket? _socket;

  io.Socket _ensureConnected() {
    if (_socket != null && _socket!.connected) return _socket!;
    final origin = Uri.parse(MarketApiService().dio.options.baseUrl)
        .replace(path: '')
        .toString();

    // Prevent multiple socket instances if one is already connecting
    if (_socket != null) return _socket!;

    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setReconnectionAttempts(double.infinity) // Retry forever
          .build(),
    );
    _socket!.connect();
    return _socket!;
  }

  // Returns a dispose function to remove listeners
  void Function() watchOrderStatus(String orderId,
      {OrderUpdateHandler? onUpdate}) {
    final s = _ensureConnected();

    if (!s.hasListeners('connect')) {
      s.onConnect((_) {
        // Re-join rooms on reconnect?
        // We might need to track joined rooms.
        // For now, simple emit.
      });
    }

    // Always emit join when watching
    s.emit('join_order', orderId);

    void handler(dynamic data) {
      final Map<String, dynamic> payload =
          Map<String, dynamic>.from(data ?? {});

      // Filter by ID if present to avoid cross-talk
    if (payload.containsKey('id') && payload['id'].toString() != orderId) {
      return;
    }

      final status = payload['orderStatus'] ?? payload['status'] ?? 'UPDATED';

      // Only show notification for significant updates
      NotificationService().show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Status Pesanan Diperbarui',
        body: 'Order ${orderId.substring(0, 8)}: $status',
        payload: orderId,
      );

      if (onUpdate != null) onUpdate(payload);
    }

    s.on('order_status', handler);
    s.on('order_update', handler);
    s.on('payment_status', handler);

    return () {
      s.off('order_status', handler);
      s.off('order_update', handler);
      s.off('payment_status', handler);
    };
  }

  void dispose() {
    // Do not close socket as it is a singleton shared service
  }
}
