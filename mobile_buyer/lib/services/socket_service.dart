import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rana_market/config/api_config.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;

  String? _currentToken;
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;

  void init(String token) {
    if (_currentToken == token && _isConnected) return;

    if (_socket != null) {
      if (_socket!.connected) _socket!.disconnect();
    }

    _currentToken = token;
    final url = ApiConfig.serverUrl;

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('order_status', (data) {
      if (data is Map) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void joinOrder(String orderId) {
    if (_socket != null) {
      if (_socket!.connected) {
        _socket!.emit('join_order', orderId);
      } else {
        _socket!.onConnect((_) {
          _socket!.emit('join_order', orderId);
        });
      }
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _currentToken = null;
    notifyListeners();
  }
}
