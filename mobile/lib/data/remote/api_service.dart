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
  static const String _webDevUrl = 'http://localhost:4000/api';

  // Set this to TRUE for production build
  static const bool _isProduction = false;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _isProduction
        ? 'https://api.rana-app.com/api' // Replace with real domain
        : (kIsWeb ? _webDevUrl : _devUrl),
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  ApiService._internal() {
    // [NEW] Add Logger
    _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: true,
        responseBody: true,
        error: true));
  }

  Dio get dio => _dio;

  String? _token;
  String? get token => _token; // [NEW] Getter

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] =
        'Bearer $token'; // Set global header
  }

  // --- Auth ---
  Future<void> register({
    required String businessName,
    required String email,
    required String password,
    required String waNumber,
    required String category, // [NEW]
    double? lat,
    double? long,
    String? address,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'businessName': businessName,
        'email': email,
        'password': password,
        'waNumber': waNumber,
        'category': category, // [NEW]
        'latitude': lat,
        'longitude': long,
        'address': address
      });

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }

  Future<dynamic> login(
      {required String email, required String password}) async {
    try {
      final response = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
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
      if (response.data['status'] == 'success') {
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
      String? latitude,
      String? longitude}) async {
    try {
      await _dio.put('/auth/store',
          data: {
            'businessName': businessName,
            'waNumber': waNumber,
            'address': address,
            'latitude': latitude,
            'longitude': longitude
          },
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
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

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
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
      throw Exception(response.data['message'] ?? 'Failed to create flash sale');
    }
    return response.data['data'];
  }

  Future<List<dynamic>> getMyFlashSales() async {
    final response = await _dio.get(
      '/products/flashsales',
      options: Options(headers: {'Authorization': 'Bearer ${_token}'}),
    );
    if (response.data['status'] != 'success') {
      throw Exception(response.data['message'] ?? 'Failed to fetch flash sales');
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

      if (response.data['status'] != 'success') {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Stock Adjustment Failed: $e');
    }
  }

  Future<void> scanQrOrder(String code) async {
    try {
      final response = await _dio.post('/orders/scan',
          data: {'pickupCode': code},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['status'] != 'success')
        throw Exception(response.data['message']);
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
      if (e is DioException && e.response != null) {
        throw Exception(
            e.response!.data['message'] ?? 'Failed to create ticket');
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
      String? couponCode}) async {
    try {
      await _dio.post('/wholesale/orders', data: {
        'tenantId': tenantId,
        'items': items,
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        'shippingCost': shippingCost,
        'couponCode': couponCode
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

      if (response.data['status'] != 'success')
        throw Exception(response.data['message']);
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
