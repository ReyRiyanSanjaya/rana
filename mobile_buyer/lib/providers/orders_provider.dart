import 'package:flutter/foundation.dart';

class OrdersProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  void add(Map<String, dynamic> order) {
    _orders.removeWhere((o) => o['id'] == order['id']);
    _orders.insert(0, Map<String, dynamic>.from(order));
    notifyListeners();
  }

  void updateFromSocket(String orderId, Map<String, dynamic> data) {
    final idx = _orders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) {
      _orders[idx] = {..._orders[idx], ...data};
      notifyListeners();
    }
  }

  void setAll(List<dynamic> list) {
    _orders
      ..clear()
      ..addAll(list.map((e) => Map<String, dynamic>.from(e)));
    notifyListeners();
  }
}
