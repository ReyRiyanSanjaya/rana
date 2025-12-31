import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MarketApiService {
  static final MarketApiService _instance = MarketApiService._internal();
  factory MarketApiService() => _instance;
  
  late Dio _dio;
  static const bool _isProduction = bool.fromEnvironment('RANA_PROD', defaultValue: kReleaseMode);
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

  String resolveFileUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = _baseUrl.endsWith('/api') ? _baseUrl.substring(0, _baseUrl.length - 4) : _baseUrl;
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }

  bool _isSuccess(dynamic body) {
    if (body is! Map) return false;
    final dynamic success = body['success'];
    if (success is bool) return success;
    final dynamic status = body['status'];
    if (status is String) return status.toLowerCase() == 'success';
    return false;
  }

  String _messageFromBody(dynamic body, {String fallback = 'Terjadi kesalahan'}) {
    if (body is Map) {
      final dynamic msg = body['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
      final dynamic error = body['error'];
      if (error is String && error.trim().isNotEmpty) return error;
    }
    if (body is String && body.trim().isNotEmpty) return body;
    return fallback;
  }

  Exception _toApiException(Object e, {String fallback = 'Terjadi kesalahan'}) {
    if (e is DioException) {
      final responseData = e.response?.data;
      final msg = _messageFromBody(
        responseData,
        fallback: e.message?.trim().isNotEmpty == true ? e.message!.trim() : fallback,
      );
      return Exception(msg);
    }
    return Exception(e.toString());
  }
 
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
       if (!_isSuccess(response.data)) {
         throw Exception(_messageFromBody(response.data, fallback: 'Gagal menambahkan ulasan'));
       }
       return response.data['data'] ?? {};
     } catch (e) {
       throw _toApiException(e, fallback: 'Gagal menambahkan ulasan');
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
      
      if (_isSuccess(response.data)) return Map<String, dynamic>.from(response.data['data'] ?? {});
      throw Exception(_messageFromBody(response.data, fallback: 'Login gagal'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Login gagal');
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
      
      if (_isSuccess(response.data)) return Map<String, dynamic>.from(response.data['data'] ?? {});
      throw Exception(_messageFromBody(response.data, fallback: 'Daftar gagal'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Daftar gagal');
    }
  }

  Future<List<dynamic>> getNearbyStores(double lat, double long) async {
    try {
      final response = await _dio.get('/market/nearby', queryParameters: {
        'lat': lat,
        'long': long
      });
      
      if (_isSuccess(response.data)) return response.data['data'] ?? [];
      throw Exception(_messageFromBody(response.data, fallback: 'Gagal memuat toko terdekat'));
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
      
      if (!_isSuccess(response.data)) {
        throw Exception(_messageFromBody(response.data, fallback: 'Gagal membuat pesanan'));
      }
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal membuat pesanan');
    }
  }

  Future<Map<String, dynamic>> getPaymentInfo() async {
    try {
      final response = await _dio.get('/market/config/payment');
      if (_isSuccess(response.data)) return Map<String, dynamic>.from(response.data['data'] ?? {});
      throw Exception(_messageFromBody(response.data, fallback: 'Gagal memuat konfigurasi pembayaran'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal memuat konfigurasi pembayaran');
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
     try {
      final response = await _dio.post('/market/order/confirm', data: {'orderId': orderId});
      if (!_isSuccess(response.data)) throw Exception(_messageFromBody(response.data, fallback: 'Gagal konfirmasi pembayaran'));
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal konfirmasi pembayaran');
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

  Future<List<dynamic>> getAnnouncements() async {
    try {
      final response = await _dio.get('/system/announcements');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMyOrders({String? phone}) async {
    try {
      final normalized = phone?.toString().trim();
      if (normalized == null || normalized.isEmpty) return [];
      final response = await _dio.get('/market/orders', queryParameters: {
        'phone': normalized
      });
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
