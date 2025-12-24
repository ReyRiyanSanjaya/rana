import 'package:dio/dio.dart';
import 'package:rana_merchant/data/local/database_helper.dart';

class ApiService {
  // Singleton Pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:4000/api', // Use localhost for Windows/Web. Use 10.0.2.2 for Android Emulator.
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  
  String? _token;

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token'; // Set global header
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
      
      if (response.data['success'] != true) {
         throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }

  Future<dynamic> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
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

  Future<void> createPurchase({required String supplierName, required List<Map<String, dynamic>> items}) async {
    try {
      await _dio.post('/purchases', data: {
        'supplierName': supplierName,
        'items': items
      });
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }


  // --- Product Sync (Downlink) ---
  Future<void> fetchAndSaveProducts() async {
    try {
      // 1. Fetch from Server
      final response = await _dio.get('/products');
      final List<dynamic> serverProducts = response.data['data'];

      final db = DatabaseHelper.instance;
      
      // 2. Save to SQLite
      for (var p in serverProducts) {
        await db.insertProduct({
            'id': p['id'],
            'tenantId': p['tenantId'],
            'sku': p['sku'],
            'name': p['name'],
            'costPrice': p['costPrice'], // Ensure server sends numbers
            'sellingPrice': p['sellingPrice'],
            'trackStock': (p['trackStock'] == true) ? 1 : 1, // Default to 1 (True) as we are enabling stock feature
            'stock': p['stock'] ?? 0,
            'category': (p['category'] is Map) 
                ? (p['category']['name'] ?? 'All') 
                : (p['category']?.toString() ?? 'All')
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

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
      await _dio.put('/products/$id', data: data);
  }

  Future<void> deleteProduct(String id) async {
      await _dio.delete('/products/$id');
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
        final response = await _dio.get('/subscriptions/status', options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
        return response.data['data'];
      } catch (e) {
        throw Exception('Failed to get subscription status');
      }
  }

  Future<void> requestSubscription(String proofUrl) async {
      try {
        await _dio.post('/subscriptions/request', data: {
          'proofUrl': proofUrl
        }, options: Options(headers: {'Authorization': 'Bearer ${_token}'})); // Ensure token is sent
      } catch (e) {
        throw Exception('Failed to request subscription: $e');
      }
  }

  // --- Sync ---
  // --- Wallet & O2O ---
  Future<Map<String, dynamic>> getWalletData() async {
    try {
      final response = await _dio.get('/wallet', options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['success'] == true) return response.data['data'];
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Get Wallet Failed: $e');
    }
  }

  Future<void> requestWithdrawal({required double amount, required String bankName, required String accountNumber}) async {
    try {
      final response = await _dio.post('/wallet/withdraw',
          data: {'amount': amount, 'bankName': bankName, 'accountNumber': accountNumber},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['success'] != true) throw Exception(response.data['message']);
    } catch (e) {
       throw Exception('Withdraw Request Failed: $e');
    }
  }

  // --- Inventory ---
  Future<void> adjustStock({required String productId, required int quantity, required String type, String? reason}) async {
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
      if (response.data['success'] != true) throw Exception(response.data['message']);
    } catch (e) {
       throw Exception('Scan Order Failed: $e');
    }
  }

  Future<void> syncOfflineTransactions() async {
    final db = DatabaseHelper.instance;
    final pending = await db.getPendingTransactions();

    for (var txn in pending) {
      try {
        final items = await db.getItemsForTransaction(txn['offlineId']);
        
        final payload = {
          ...txn,
          'items': items
        };

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
      final response = await _dio.get('/announcements/active'); // Assuming public or merchant route
      // If admin route '/admin/announcements' was used for all, we need a merchant-specific one or reuse.
      // Let's assume we need to adjust server or use what we have. 
      // Admin Controller `getAnnouncements` returns all. We might want a filtering one. 
      // For now, let's use the one we built or a new one? 
      // Wait, in previous turn I only made ADMIN routes. I need CLIENT routes for these!
      // Checking server routes...
      // I only added /admin/tickets and /admin/announcements. 
      // I need to add /api/tickets and /api/announcements for MERCHANTS.
      // I will add the client code here assuming I will fix the server next.
      
      final res = await _dio.get('/announcements'); 
      return res.data['data'];
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

  Future<void> createTicket(String subject, String message, {String priority = 'NORMAL'}) async {
    try {
      await _dio.post('/tickets', data: {
        'subject': subject,
        'message': message,
        'priority': priority
      });
    } catch (e) {
      throw Exception('Failed to create ticket');
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
      await _dio.post('/tickets/$id/reply', data: { 'message': message });
    } catch (e) {
      throw Exception('Failed to send reply');
    }
  }

  // 3. System Settings (Bank Info)
  Future<Map<String, String>> getSystemSettings() async {
    try {
      final response = await _dio.get('/settings/public'); // Need a public/merchant route
      final List<dynamic> list = response.data['data'];
      // Convert list to map
      final Map<String, String> settings = {};
      for (var item in list) {
        settings[item['key']] = item['value'];
      }
      return settings;
    } catch (e) {
      return {};
    }
  }
  // 4. Kulakan (Wholesale)
  Future<List<dynamic>> getWholesaleProducts({String? category, String? search}) async {
    try {
      final response = await _dio.get('/wholesale/products', queryParameters: {
        'category': category,
        'search': search
      });
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

  Future<Map<String, dynamic>> validateCoupon(String code, double totalAmount) async {
    try {
      final response = await _dio.post('/wholesale/validate-coupon', data: {
        'code': code,
        'totalAmount': totalAmount
      });
      return response.data['data'];
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Failed to validate coupon');
    }
  }

  Future<void> createWholesaleOrder({
    required String tenantId, 
    required List<Map<String, dynamic>> items, 
    required String paymentMethod, 
    required String shippingAddress,
    required double shippingCost,
    String? couponCode
  }) async {
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
      final response = await _dio.get('/wholesale/orders', queryParameters: {'tenantId': tenantId});
      return response.data['data'] ?? [];
    } catch (e) {
      return []; // Return empty on error
    }
  }
}
