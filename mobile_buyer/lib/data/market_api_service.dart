import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MarketApiService {
  static final MarketApiService _instance = MarketApiService._internal();
  factory MarketApiService() => _instance;
  
  late Dio _dio;
  // Note: For Emulator use 10.0.2.2, Real Device use IP Address
  // Change this to your Server IP for real device testing!
  // Note: For Emulator use 10.0.2.2, Real Device use IP Address
  // Change this to your Server IP for real device testing!
  final String _baseUrl = 'http://10.0.2.2:4000/api'; 

  MarketApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Future<List<dynamic>> getNearbyStores(double lat, double long) async {
    try {
      final response = await _dio.get('/market/nearby', queryParameters: {
        'lat': lat,
        'long': long
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      print('Nearby Error: $e');
      return []; // Return empty on error for fail-soft
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String storeId,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required String fulfillmentType
  }) async {
    try {
      final response = await _dio.post('/market/order', data: {
        'storeId': storeId,
        'items': items,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'fulfillmentType': fulfillmentType
      });
      
      if (!response.data['success']) {
         throw Exception(response.data['message']);
      }
      return response.data['data']; // Return Order Data (ID, Amount)
    } catch (e) {
      throw Exception('Order Failed: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentInfo() async {
    try {
      final response = await _dio.get('/market/config/payment');
      if (response.data['success']) return response.data['data'];
      throw Exception('Failed to get config');
    } catch (e) {
      throw Exception('Payment Config Error: $e');
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
     try {
      final response = await _dio.post('/market/order/confirm', data: {'orderId': orderId});
      if (!response.data['success']) throw Exception(response.data['message']);
      return response.data['data'];
    } catch (e) {
      throw Exception('Confirm Failed: $e');
    }
  }
}
