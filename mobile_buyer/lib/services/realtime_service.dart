library io;

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rana_market/data/market_api_service.dart';
import 'notification_service.dart';

typedef OrderUpdateHandler = void Function(Map<String, dynamic> data);

class RealtimeService {
  io.Socket? _socket;

  io.Socket _ensureConnected() {
    if (_socket != null && _socket!.connected) return _socket!;
    final origin = Uri.parse(MarketApiService().dio.options.baseUrl).replace(path: '').toString();
    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .build(),
    );
    return _socket!;
  }

  void watchOrderStatus(String orderId, {OrderUpdateHandler? onUpdate}) {
    final s = _ensureConnected();

    s.onConnect((_) {
      s.emit('join_order', orderId);
    });

    void handler(dynamic data) {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(data ?? {});
      final status = payload['orderStatus'] ?? payload['status'] ?? 'UPDATED';
      NotificationService().show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Status Pesanan Diperbarui',
        body: 'Order $orderId: $status',
        payload: orderId,
      );
      if (onUpdate != null) onUpdate(payload);
    }

    s.on('order_status', handler);
    s.on('order_update', handler);
    s.on('payment_status', handler);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
