import 'package:dio/dio.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getIncomingOrders() async {
    try {
      final response = await _api.dio.get('/orders'); // Uses interceptors from ApiService
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _api.dio.put('/orders/status', data: {
        'orderId': orderId,
        'status': status
      });
      if (!response.data['success']) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  Future<Map<String, dynamic>> scanQrOrder(String pickupCode) async {
    try {
      final response = await _api.dio.post('/orders/scan', data: {
        'pickupCode': pickupCode
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
         throw Exception(e.response?.data['message'] ?? 'Scan failed');
      }
      throw Exception('Scan failed: $e');
    }
  }
}
