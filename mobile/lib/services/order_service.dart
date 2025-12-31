import 'package:rana_merchant/data/remote/api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getIncomingOrders() async {
    return _api.getIncomingMarketOrders();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    return _api.updateMarketOrderStatus(orderId, status);
  }

  Future<Map<String, dynamic>> scanQrOrder(String pickupCode) async {
    return _api.scanMarketOrderPickup(pickupCode);
  }
}
