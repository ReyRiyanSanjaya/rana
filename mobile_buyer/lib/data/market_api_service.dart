import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MarketApiService {
  static final MarketApiService _instance = MarketApiService._internal();
  factory MarketApiService() => _instance;
  
  late Dio _dio;
  static const bool _isProduction = false;
  final String _baseUrl = _isProduction
      ? 'https://api.rana-app.com/api'
      : (kIsWeb ? 'http://localhost:4000/api' : 'http://10.0.2.2:4000/api');

  MarketApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Dio get dio => _dio;
 
  Future<List<dynamic>> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 10,
    String sort = 'newest', // or 'rating_desc'
  }) async {
    try {
      final response = await _dio.get(
        '/market/product/$productId/reviews',
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
        },
      );
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
 
   Future<Map<String, dynamic>> addProductReview(String productId, {required int rating, required String comment}) async {
     try {
       final response = await _dio.post('/market/product/$productId/reviews', data: {
         'rating': rating,
         'comment': comment,
       });
       if (!(response.data['success'] ?? false)) {
         throw Exception(response.data['message'] ?? 'Failed');
       }
       return response.data['data'] ?? {};
     } catch (e) {
       throw Exception('Add Review Failed: $e');
     }
   }

  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'role': 'BUYER'
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String phone, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'BUYER'
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Register Failed: $e');
    }
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
      debugPrint('Nearby Error: $e');
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

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/system/notifications');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMyOrders({String? customerPhone}) async {
    try {
      final response = await _dio.get('/market/orders', queryParameters: {
        if (customerPhone != null) 'customerPhone': customerPhone
      });
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
