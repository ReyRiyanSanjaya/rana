import 'dart:async';
import 'package:rana_merchant/data/remote/api_service.dart';

class ShopeeService {
  // Singleton pattern
  static final ShopeeService _instance = ShopeeService._internal();
  factory ShopeeService() => _instance;
  ShopeeService._internal();

  final ApiService _api = ApiService();

  /// Get Product List based on Service Type from Server
  Future<List<Map<String, dynamic>>> getProducts(String category) async {
    try {
      final List<dynamic> result = await _api.getDigitalProducts(category);
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Inquiry Bill (Check Tagihan) from Server
  Future<Map<String, dynamic>> checkBill(String customerId, String type) async {
    try {
      return await _api.checkDigitalBill(customerId, type);
    } catch (e) {
      return {
        'status': 'FAILED',
        'message': e.toString()
      };
    }
  }
}
