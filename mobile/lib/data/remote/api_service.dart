import 'package:dio/dio.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:flutter/foundation.dart'; // [NEW] For kIsWeb check

class ApiService {
  // Singleton Pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  // CONFIGURATION
  // static const String _prodUrl = 'https://api.yourdomain.com/api';
  static const String _devUrl = 'http://10.0.2.2:4000/api';

  // Set this to TRUE for production build
  static const bool _isProduction =
      bool.fromEnvironment('RANA_PROD', defaultValue: kReleaseMode);

  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  late final Dio _dio;

  ApiService._internal() {
    final resolvedBaseUrl = _resolveBaseUrl();
    _dio = Dio(BaseOptions(
      baseUrl: resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
          request: true,
          requestHeader: false,
          responseHeader: false,
          responseBody: true,
          error: true));
    }
  }

  Dio get dio => _dio;

  String _resolveBaseUrl() {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;

    if (_isProduction) return 'https://api.rana-app.com/api';

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isEmpty) return 'http://localhost:4000/api';
      return 'http://$host:4000/api';
    }

    return _devUrl;
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

  String? _token;
  String? get token => _token; // [NEW] Getter

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] =
        'Bearer $token'; // Set global header
  }

  String _messageFromApiBody(dynamic body, {required String fallback}) {
    if (body is Map) {
      final msg = body['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
    return fallback;
  }

  // --- Auth ---
  Future<void> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String password,
    required String waNumber,
    required String category,
    String? storeImageBase64,
    double? lat,
    double? long,
    String? address,
    String? referralCode,
  }) async {
    try {
      final payload = {
        'businessName': businessName,
        'ownerName': ownerName,
        'email': email,
        'password': password,
        'waNumber': waNumber,
        'category': category,
        'storeImageBase64': storeImageBase64,
        'latitude': lat,
        'longitude': long,
        'address': address,
        'referralCode': referralCode,
      };

      final response = await _dio.post('/auth/register', data: payload);

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      final message = _messageFromApiBody(
        e.response?.data,
        fallback: 'Registrasi gagal',
      );
      throw Exception(message);
    } catch (_) {
      throw Exception('Registrasi gagal');
    }
  }

  Future<dynamic> login(
      {required String phone, required String password}) async {
    try {
      final response = await _dio
          .post('/auth/login', data: {'phone': phone, 'password': password});
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials');
      }
      if (e.response?.statusCode == 402) {
        throw Exception('SUBSCRIPTION_EXPIRED'); // Magic string to catch in UI
      }
      rethrow; // Re-throw other DioErrors or network issues
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/auth/me',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (_isSuccess(response.data)) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> updateStoreProfile(
      {required String businessName,
      required String waNumber,
      required String address,
      String? storeImageBase64,
      String? latitude,
      String? longitude}) async {
    try {
      await _dio.put('/auth/store',
          data: {
            'businessName': businessName,
            'waNumber': waNumber,
            'address': address,
            'storeImageBase64': storeImageBase64,
            'latitude': latitude,
            'longitude': longitude
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.put('/auth/change-password',
          data: {
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));

      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      // Handle specific Dio errors if needed
      if (e is DioException && e.response != null) {
        throw Exception(
            e.response!.data['message'] ?? 'Gagal mengubah password');
      }
      throw Exception('Gagal mengubah password: $e');
    }
  }

  Future<void> createPurchase(
      {required String supplierName,
      required List<Map<String, dynamic>> items}) async {
    try {
      await _dio.post('/purchases',
          data: {'supplierName': supplierName, 'items': items});
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    try {
      final response = await _dio.get('/referral/me',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (_isSuccess(response.data)) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(_messageFromBody(response.data));
    } catch (e) {
      throw Exception('Gagal memuat data referral: $e');
    }
  }

  Future<List<dynamic>> getMyReferrals() async {
    try {
      final response = await _dio.get('/referral/me/referrals',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (_isSuccess(response.data)) {
        return List<dynamic>.from(response.data['data']['items'] ?? []);
      }
      throw Exception(_messageFromBody(response.data));
    } catch (e) {
      throw Exception('Gagal memuat daftar referral: $e');
    }
  }

  // --- Product Sync (Downlink) ---
  Future<void> fetchAndSaveProducts() async {
    try {
      // 1. Fetch from Server
      final response = await _dio.get('/products',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      final List<dynamic> serverProducts = response.data['data'];

      final db = DatabaseHelper.instance;

      // 2. Save to SQLite
      for (var p in serverProducts) {
        await db.insertProduct({
          'id': p['id'],
          'tenantId': p['tenantId'],
          'sku': p['sku'],
          'name': p['name'],
          'costPrice': p['basePrice'] ?? p['costPrice'] ?? 0,
          'sellingPrice': p['sellingPrice'],
          'trackStock': (p['trackStock'] == true)
              ? 1
              : 1, // Default to 1 (True) as we are enabling stock feature
          'stock': p['stock'] ?? 0,
          'category': (p['category'] is Map)
              ? (p['category']['name'] ?? 'All')
              : (p['category']?.toString() ?? 'All'),
          'imageUrl': p['imageUrl']
        });
      }
      print('Products Synced (Downlink): ${serverProducts.length}');
    } catch (e) {
      print('Product Sync Failed: $e');
    }
  }

  // --- Product Management ---
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    // data: {sku, name, sellingPrice, costPrice}
    final response = await _dio.post('/products', data: data);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/products/$id', data: data);
    return response.data['data'];
  }

  Future<void> applyDiscountToProduct(
    String productId,
    double newPrice,
    String promoType,
    String label,
    int durationDays,
  ) async {
    final response = await _dio.post(
      '/products/$productId/apply-discount',
      data: {
        'newPrice': newPrice,
        'promoType': promoType,
        'label': label,
        'durationDays': durationDays,
      },
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );

    if (response.data['status'] != 'success') {
      throw Exception(response.data['message'] ?? 'Failed to apply discount');
    }
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  // --- Upload Proof ---
  Future<String> uploadTransferProof(String filePath,
      {List<int>? fileBytes, String? fileName}) async {
    try {
      String name = fileName ?? filePath.split('/').last;
      FormData formData;

      if (fileBytes != null) {
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(fileBytes, filename: name),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: name),
        });
      }

      final response = await _dio.post('/wholesale/upload-proof',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));

      return response.data['url']; // Return the uploaded URL
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // --- Flash Sales (Merchant) ---
  Future<Map<String, dynamic>> createFlashSale({
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final response = await _dio.post(
      '/products/flashsales',
      data: {
        'title': title,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'items': items,
      },
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
    if (response.data['status'] != 'success') {
      throw Exception(
          response.data['message'] ?? 'Failed to create flash sale');
    }
    return response.data['data'];
  }

  Future<List<dynamic>> getMyFlashSales() async {
    final response = await _dio.get(
      '/products/flashsales',
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
    if (!_isSuccess(response.data)) {
      throw Exception(
          response.data['message'] ?? 'Failed to fetch flash sales');
    }
    return response.data['data'] ?? [];
  }

  Future<void> addFlashSaleItem({
    required String saleId,
    required String productId,
    required double salePrice,
    int? maxQtyPerOrder,
    int? saleStock,
  }) async {
    await _dio.post(
      '/products/flashsales/$saleId/items',
      data: {
        'productId': productId,
        'salePrice': salePrice,
        'maxQtyPerOrder': maxQtyPerOrder,
        'saleStock': saleStock,
      },
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
  }

  Future<void> deleteFlashSaleItem({
    required String saleId,
    required String itemId,
  }) async {
    await _dio.delete(
      '/products/flashsales/$saleId/items/$itemId',
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
  }

  Future<void> cancelFlashSale({required String saleId}) async {
    await _dio.put(
      '/products/flashsales/$saleId/status',
      data: {'action': 'CANCEL'},
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
  }

  Future<List<dynamic>> getSubscriptionPackages() async {
    try {
      final response = await _dio.get('/subscriptions/packages');
      return response.data['data'];
    } catch (e) {
      return []; // Return empty on error
    }
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscriptions/status',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to get subscription status');
    }
  }

  Future<void> requestSubscription(String proofUrl, {String? packageId}) async {
    try {
      await _dio.post('/subscriptions/request',
          data: {
            'proofUrl': proofUrl,
            'packageId': packageId // [NEW] Include selected package
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      throw Exception('Failed to request subscription: $e');
    }
  }

  // --- Sync ---
  // --- Wallet & O2O ---
  Future<Map<String, dynamic>> getWalletData() async {
    try {
      final response = await _dio.get('/wallet',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['status'] == 'success') return response.data['data'];
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Get Wallet Failed: $e');
    }
  }

  Future<void> requestWithdrawal(
      {required double amount,
      required String bankName,
      required String accountNumber}) async {
    try {
      final response = await _dio.post('/wallet/withdraw',
          data: {
            'amount': amount,
            'bankName': bankName,
            'accountNumber': accountNumber
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['status'] != 'success')
        throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Withdraw Request Failed: $e');
    }
  }

  Future<void> topUp(
      {required double amount, required String proofPath}) async {
    try {
      // Convert image to Base64 to avoid Multipart overhead issues on some servers/configs,
      // matching our simple backend implementation.
      // Actually backend accepts JSON with proofImage base64 string.
      // We need dart:io and dart:convert

      // Wait, I cannot import dart:io here easily if not already imported.
      // But this is a data layer, so passed argument `proofPath` implies I need to read it.
      // I will assume the caller passes Base64 string OR I handle file reading here.
      // Let's pass the path and handle reading here.
      // I need to add imports to the top of file.

      // Since replace_file_content is for contiguous blocks, I have to be careful about imports.
      // I will implement this method assuming `proofPath` is passed, but I'll use a hack or just ensure imports are there.
      // Actually `ApiService` uses `dio`. I can use `FormData` if I changed backend to `multer`.
      // But I chose Base64 in backend. So I must send Base64 string.

      // I will implement a helper or just inline it if imports exist.
      // `d:/rana/mobile/lib/data/remote/api_service.dart` does NOT have `dart:convert` or `dart:io`.
      // I will use `MultiReplace` to add imports AND methods.
      // But I am using `ReplaceFileContent` here. I should cancel and use MultiReplace.
      // Wait, I can just accept base64 string from Provider. That keeps ApiService clean of IO.
      // Yes, `topUp({required double amount, required String proofBase64})`.

      await _dio.post('/wallet/topup',
          data: {
            'amount': amount,
            'proofImage': proofPath // Expecting Base64 string here
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      throw Exception('Top Up Failed: $e');
    }
  }

  Future<void> transfer(
      {required String targetStoreId,
      required double amount,
      String? note}) async {
    try {
      await _dio.post('/wallet/transfer',
          data: {
            'targetStoreId': targetStoreId,
            'amount': amount,
            'note': note
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      if (e is DioException && e.response != null && e.response?.data != null) {
        // Extract message from server response if available
        final msg = e.response!.data['message'] ?? e.message;
        throw Exception(msg);
      }
      throw Exception('Transfer Failed: $e');
    }
  }

  Future<void> payTransaction(
      {required double amount,
      required String description,
      String category = 'PURCHASE'}) async {
    try {
      await _dio.post('/wallet/transaction',
          data: {
            'amount': amount,
            'description': description,
            'category': category
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      throw Exception('Payment Failed: $e');
    }
  }

  // --- Inventory ---
  Future<void> adjustStock(
      {required String productId,
      required int quantity,
      required String type,
      String? reason}) async {
    try {
      final response = await _dio.post('/inventory/adjust',
          data: {
            'productId': productId,
            'quantity': quantity,
            'type': type, // IN, OUT, ADJUSTMENT
            'reason': reason
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));

      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Stock Adjustment Failed: $e');
    }
  }

  Future<List<dynamic>> getIncomingMarketOrders() async {
    try {
      final response = await _dio.get(
        '/orders',
        options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
      );
      if (response.data['status'] == 'success') {
        return response.data['data'] ?? [];
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch orders');
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<void> updateMarketOrderStatus(String orderId, String status) async {
    try {
      final response = await _dio.put(
        '/orders/status',
        data: {'orderId': orderId, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
      );
      if (response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  Future<Map<String, dynamic>> scanMarketOrderPickup(String pickupCode) async {
    try {
      final response = await _dio.post(
        '/orders/scan',
        data: {'pickupCode': pickupCode},
        options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
      );
      if (!_isSuccess(response.data)) {
        throw Exception(response.data['message'] ?? 'Scan failed');
      }
      final data = response.data['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } catch (e) {
      throw Exception('Scan failed: $e');
    }
  }

  Future<Map<String, dynamic>> scanQrOrder(String code) async {
    try {
      final response = await _dio.post('/wholesale/orders/scan',
          data: {'pickupCode': code},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['status'] != 'success') {
        throw Exception(response.data['message']);
      }
      final data = response.data['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } catch (e) {
      throw Exception('Scan Order Failed: $e');
    }
  }

  Future<void> uploadTransaction(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/transactions/sync',
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['status'] != 'success')
        throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> syncOfflineTransactions() async {
    final db = DatabaseHelper.instance;
    final pending = await db.getPendingTransactions();

    for (var txn in pending) {
      try {
        final items = await db.getItemsForTransaction(txn['offlineId']);

        final payload = {...txn, 'items': items};

        await _dio.post('/transactions/sync', data: payload);

        // Mark as synced locally
        await db.markSynced(txn['offlineId']);
        print('Synced txn: ${txn['offlineId']}');
      } catch (e) {
        print('Failed to sync ${txn['offlineId']}: $e');
        // Keep pending
      }
    }
  }

  // --- Master Sync ---
  Future<void> syncAllData() async {
    // 1. Push Offline Transactions (Upstream)
    await syncOfflineTransactions();

    // 2. Fetch Latest Products & Stock (Downstream)
    await fetchAndSaveProducts();

    // 3. (Optional) Fetch other data like Reports/Wallet if needed
  }

  // --- Features: Broadcasts, Support, Settings ---

  // 1. Announcements
  Future<List<dynamic>> getAnnouncements() async {
    try {
      final response = await _dio.get('/system/announcements');
      return response.data['data'];
    } catch (e) {
      return [];
    }
  }

  // 2. Support Tickets
  Future<List<dynamic>> getTickets() async {
    try {
      final response = await _dio.get('/tickets');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch tickets');
    }
  }

  Future<void> createTicket(String subject, String message,
      {String priority = 'NORMAL'}) async {
    try {
      await _dio.post('/tickets',
          data: {'subject': subject, 'message': message, 'priority': priority});
    } catch (e) {
      if (e is DioException) {
        throw Exception(_messageFromBody(e.response?.data,
            fallback: 'Failed to create ticket'));
      }
      throw Exception('Failed to create ticket: $e');
    }
  }

  Future<dynamic> getTicketDetail(String id) async {
    try {
      final response = await _dio.get('/tickets/$id');
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to load ticket');
    }
  }

  Future<void> replyTicket(String id, String message) async {
    try {
      await _dio.post('/tickets/$id/reply', data: {'message': message});
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to send reply');
      }
      throw Exception('Failed to send reply: $e');
    }
  }

  // 3. System Settings (Bank Info)
  // 3. System Settings (Bank Info & CMS)
  Future<Map<String, String>> getSystemSettings() async {
    try {
      final Map<String, String> settings = {};

      // 1. Fetch CMS Content
      try {
        final cmsRes = await _dio.get('/system/cms-content');
        final Map<String, dynamic> cmsData = cmsRes.data['data'];
        cmsData.forEach((key, value) {
          settings[key] = value.toString();
        });
      } catch (_) {}

      // 2. Fetch Payment Info
      try {
        final payRes = await _dio.get('/system/payment-info');
        final Map<String, dynamic> payData = payRes.data['data'];
        settings['PLATFORM_QRIS_URL'] = payData['qrisUrl'] ?? '';
        settings['PLATFORM_BANK_INFO'] = payData['bankInfo'] ?? '';
      } catch (_) {}

      // 3. Fetch Global Settings (Wholesale, etc.)
      try {
        final settingsRes = await _dio.get('/system/settings');
        final Map<String, dynamic> settingsData = settingsRes.data['data'];
        settingsData.forEach((key, value) {
          settings[key] = value.toString();
        });
      } catch (_) {}

      return settings;
    } catch (e) {
      return {};
    }
  }

  // 4. Kulakan (Wholesale)
  Future<List<dynamic>> getWholesaleProducts(
      {String? category, String? search}) async {
    try {
      final response = await _dio.get('/wholesale/products',
          queryParameters: {'category': category, 'search': search});
      return response.data['data'] ?? [];
    } catch (e) {
      throw Exception('Failed to fetch wholesale products');
    }
  }

  Future<List<dynamic>> getWholesaleCategories() async {
    try {
      final response = await _dio.get('/wholesale/categories');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
      String code, double totalAmount) async {
    try {
      final response = await _dio.post('/wholesale/validate-coupon',
          data: {'code': code, 'totalAmount': totalAmount});
      return response.data['data'];
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to validate coupon');
    }
  }

  Future<void> createWholesaleOrder(
      {required String tenantId,
      required List<Map<String, dynamic>> items,
      required String paymentMethod,
      required String shippingAddress,
      required double shippingCost,
      double serviceFee = 0,
      String? couponCode,
      String? proofUrl}) async {
    try {
      await _dio.post('/wholesale/orders', data: {
        'tenantId': tenantId,
        'items': items,
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        'shippingCost': shippingCost,
        'serviceFee': serviceFee,
        'couponCode': couponCode,
        'proofUrl': proofUrl
      });
    } catch (e) {
      throw Exception('Failed to place wholesale order');
    }
  }

  Future<List<dynamic>> getWholesaleBanners() async {
    try {
      final response = await _dio.get('/wholesale/banners');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMyWholesaleOrders(String tenantId) async {
    try {
      final response = await _dio
          .get('/wholesale/orders', queryParameters: {'tenantId': tenantId});
      return response.data['data'] ?? [];
    } catch (e) {
      return []; // Return empty on error
    }
  }

  // 5. App Menus (Dynamic)
  Future<List<dynamic>> fetchAppMenus() async {
    try {
      final response = await _dio.get('/system/app-menus');
      return response.data['data'] ?? [];
    } catch (e) {
      print('Failed to fetch app menus: $e');
      return [];
    }
  }

  // 6. Notifications (Enterprise)
  Future<List<dynamic>> fetchNotifications() async {
    try {
      final response = await _dio.get('/system/notifications');
      return response.data['data'] ?? [];
    } catch (e) {
      print('Failed to fetch notifications: $e');
      return [];
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.post('/system/notifications/read-all',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      print('Failed to mark notifications as read: $e');
    }
  }

  Future<List<dynamic>> getBlogPosts() async {
    try {
      final response = await _dio.get('/blog'); // Public route
      return response.data['data']['posts'];
    } catch (e) {
      print('Failed to fetch blog posts: $e');
      return [];
    }
  }

  // 8. PPOB / Digital Products
  Future<List<dynamic>> getDigitalProducts(String category) async {
    try {
      final response = await _dio.get('/ppob/products',
          queryParameters: {'service': category},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return response.data['data'] ?? [];
    } catch (e) {
      print('PPOB Fetch Failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkDigitalBill(String customerId, String type,
      {String? productId, double? amount}) async {
    try {
      final response = await _dio.post('/ppob/inquiry',
          data: {
            'customerId': customerId,
            'type': type,
            if (productId != null) 'productId': productId,
            if (amount != null) 'amount': amount
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return response.data['data'];
    } catch (e) {
      throw Exception('Inquiry Failed');
    }
  }

  Future<Map<String, dynamic>> purchaseDigitalProduct(
      {String? sku,
      String? productId,
      double? amount,
      required String customerId,
      String? commands,
      String? refId}) async {
    try {
      final resolvedProductId = (productId ?? sku);
      if (resolvedProductId == null || resolvedProductId.isEmpty) {
        throw Exception('Invalid productId');
      }
      final response = await _dio.post('/ppob/transaction',
          data: {
            'productId': resolvedProductId,
            if (amount != null) 'amount': amount,
            'customerId': customerId,
            if (commands != null) 'commands': commands,
            if (refId != null) 'refId': refId
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));

      if (!_isSuccess(response.data)) throw Exception(response.data['message']);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 402) {
        throw Exception('Saldo tidak mencukupi');
      }
      throw Exception('Transaksi Gagal: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> checkDigitalStatus(String refId) async {
    try {
      final response = await _dio.get('/ppob/status/$refId',
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      throw Exception('Cek status gagal');
    }
  }

  // --- Reporting (Hybrid) ---
  Future<Map<String, dynamic>> getDashboardStats(
      {required String date, String? storeId}) async {
    try {
      final response = await _dio.get('/reports/dashboard',
          queryParameters: {'date': date, 'storeId': storeId},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats');
    }
  }

  Future<Map<String, dynamic>> getProfitLoss(
      {required String startDate, required String endDate}) async {
    try {
      final response = await _dio.get('/reports/profit-loss',
          queryParameters: {'startDate': startDate, 'endDate': endDate},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to fetch P&L');
    }
  }
}
