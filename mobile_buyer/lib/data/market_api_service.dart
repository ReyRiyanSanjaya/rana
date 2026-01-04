import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rana_market/config/api_config.dart';

class MarketApiService {
  static final MarketApiService _instance = MarketApiService._internal();
  factory MarketApiService() => _instance;

  late Dio _dio;

  // Uses ApiConfig for base URL resolution
  final String _baseUrl = ApiConfig.baseUrl;

  MarketApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
    ));

    _dio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Dio get dio => _dio;

  String resolveFileUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = ApiConfig.serverUrl;
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

  String _messageFromBody(dynamic body,
      {String fallback = 'Terjadi kesalahan'}) {
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
        fallback:
            e.message?.trim().isNotEmpty == true ? e.message!.trim() : fallback,
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

  Future<Map<String, dynamic>> addProductReview(String productId,
      {required int rating, required String comment}) async {
    try {
      final response =
          await _dio.post('/market/product/$productId/reviews', data: {
        'rating': rating,
        'comment': comment,
      });
      if (!_isSuccess(response.data)) {
        throw Exception(_messageFromBody(response.data,
            fallback: 'Gagal menambahkan ulasan'));
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
      final response = await _dio.post('/auth/login',
          data: {'email': email, 'password': password, 'role': 'BUYER'});

      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(_messageFromBody(response.data, fallback: 'Login gagal'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Login gagal');
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String phone, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'BUYER'
      });

      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(
          _messageFromBody(response.data, fallback: 'Daftar gagal'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Daftar gagal');
    }
  }

  Future<List<dynamic>> searchGlobal({
    String? query,
    String? category,
    String? sort,
    int? limit,
    double? lat,
    double? long,
  }) async {
    try {
      final response = await _dio.get('/market/search', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category != 'Semua') 'category': category,
        if (sort != null) 'sort': sort,
        if (limit != null) 'limit': limit,
        if (lat != null) 'lat': lat,
        if (long != null) 'long': long,
      });
      return response.data['data'] as List<dynamic>? ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleFavorite(String phone, String productId) async {
    try {
      final response = await _dio.post('/market/favorites', data: {
        'phone': phone,
        'productId': productId,
      });
      return response.data['data']['isFavorite'] ?? false;
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal update favorit');
    }
  }

  Future<List<dynamic>> getFavorites(String phone) async {
    try {
      final response = await _dio.get('/market/favorites', queryParameters: {
        'phone': phone,
      });
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getNearbyStores(double lat, double long) async {
    try {
      final response = await _dio
          .get('/market/nearby', queryParameters: {'lat': lat, 'long': long});

      if (_isSuccess(response.data)) return response.data['data'] ?? [];
      throw Exception(_messageFromBody(response.data,
          fallback: 'Gagal memuat toko terdekat'));
    } catch (e) {
      debugPrint('Nearby Error: $e');
      return []; // Return empty on error for fail-soft
    }
  }

  Future<Map<String, dynamic>> getStoreReviews(String storeId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/market/store/$storeId/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      return {};
    } catch (e) {
      debugPrint('Store Reviews Error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStoreCatalog(String storeId,
      {String? search}) async {
    try {
      final response = await _dio.get(
        '/market/store/$storeId/catalog',
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search
        },
      );
      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(_messageFromBody(response.data,
          fallback: 'Gagal memuat katalog toko'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal memuat katalog toko');
    }
  }

  Future<Map<String, dynamic>> createOrder(
      {required String storeId,
      required List<Map<String, dynamic>> items,
      required String customerName,
      required String customerPhone,
      required String deliveryAddress,
      required String fulfillmentType,
      double deliveryFee = 0}) async {
    try {
      final response = await _dio.post('/market/order', data: {
        'storeId': storeId,
        'items': items,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'fulfillmentType': fulfillmentType,
        'deliveryFee': deliveryFee
      });

      if (!_isSuccess(response.data)) {
        throw Exception(
            _messageFromBody(response.data, fallback: 'Gagal membuat pesanan'));
      }
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal membuat pesanan');
    }
  }

  Future<Map<String, dynamic>> getPaymentInfo() async {
    try {
      final response = await _dio.get('/market/config/payment');
      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(_messageFromBody(response.data,
          fallback: 'Gagal memuat konfigurasi pembayaran'));
    } catch (e) {
      throw _toApiException(e, fallback: 'Gagal memuat konfigurasi pembayaran');
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
    try {
      final response =
          await _dio.post('/market/order/confirm', data: {'orderId': orderId});
      if (!_isSuccess(response.data)) {
        throw Exception(_messageFromBody(response.data,
            fallback: 'Gagal konfirmasi pembayaran'));
      }
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

  Future<List<dynamic>> getFlashSaleProducts(double lat, double long,
      {String? storeId}) async {
    try {
      final params = <String, dynamic>{};
      if (storeId != null) params['storeId'] = storeId;

      final response =
          await _dio.get('/market/flashsales', queryParameters: params);
      if (!_isSuccess(response.data)) return [];

      final sales = response.data['data'] as List<dynamic>;
      final allProducts = <Map<String, dynamic>>[];

      for (final sale in sales) {
        if (sale is! Map) continue;
        final storeName = sale['store']?['name'] ?? 'Toko';
        final storeAddress = sale['store']?['location'];
        final storeLat = sale['store']?['latitude'];
        final storeLong = sale['store']?['longitude'];
        final storeId = sale['storeId'];
        final endAt = sale['endAt']; // Get endAt from flash sale
        final items = sale['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          if (item is! Map) continue;
          final product = item['product'];
          if (product is! Map) continue;

          final originalPrice = (product['sellingPrice'] as num).toDouble();
          final salePrice = (item['salePrice'] as num).toDouble();

          final map = <String, dynamic>{
            'id': item['productId'], // Use productId as the ID for navigation
            'name': product['name'],
            'imageUrl': product['imageUrl'],
            'originalPrice': originalPrice,
            'sellingPrice': salePrice,
            'discountPercentage': originalPrice > 0
                ? ((originalPrice - salePrice) / originalPrice * 100).round()
                : 0,
            'storeId': storeId,
            'storeName': storeName,
            'storeAddress': storeAddress,
            'storeLat': storeLat,
            'storeLong': storeLong,
            'flashSaleEndAt': endAt, // Add endAt to product map
            // Add other fields needed for ProductDetailScreen if missing
            'description': product['description'] ?? '',
            'stock': item['saleStock'] ?? 0, // Flash sale stock
          };

          allProducts.add(map);
        }
      }

      allProducts.shuffle();
      return allProducts;
    } catch (e) {
      debugPrint('Flash Sale Error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMyOrders({String? phone}) async {
    try {
      final normalized = phone?.toString().trim();
      if (normalized == null || normalized.isEmpty) return [];
      final response = await _dio
          .get('/market/orders', queryParameters: {'phone': normalized});
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await _dio.get('/system/config');
      if (_isSuccess(response.data)) {
        return response.data['data'];
      }
      return {};
    } catch (e) {
      debugPrint('Config Error: $e');
      return {};
    }
  }
}
