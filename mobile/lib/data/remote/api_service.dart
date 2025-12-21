import 'package:dio/dio.dart';
import 'package:rana_merchant/data/local/database_helper.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:4000/api', // Use localhost for Windows/Web. Use 10.0.2.2 for Android Emulator.
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  
  String? _token;

  void setToken(String token) {
    _token = token;
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
      
      if (!response.data['success']) {
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
            'trackStock': p['trackStock'] ? 1 : 0
        });
      }
      print('Products Synced (Downlink): ${serverProducts.length}');
      
    } catch (e) {
      print('Product Sync Failed: $e');
    }
  }

  // --- Product Management ---
  Future<void> createProduct(Map<String, dynamic> data) async {
      // data: {sku, name, sellingPrice, costPrice}
      await _dio.post('/products', data: data);
  }

  Future<List<dynamic>> getSubscriptionPackages() async {
    try {
      final response = await _dio.get('/subscriptions/packages');
      return response.data['data'];
    } catch (e) {
      return []; // Return empty on error
    }
  }

  // --- Sync ---
  // --- Wallet & O2O ---
  Future<Map<String, dynamic>> getWalletData() async {
    try {
      final response = await _dio.get('/wallet', options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (response.data['success']) return response.data['data'];
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
      if (!response.data['success']) throw Exception(response.data['message']);
    } catch (e) {
       throw Exception('Withdraw Request Failed: $e');
    }
  }

  Future<void> scanQrOrder(String code) async {
    try {
      final response = await _dio.post('/orders/scan',
          data: {'pickupCode': code},
          options: Options(headers: {'Authorization': 'Bearer ${_token}'}));
      if (!response.data['success']) throw Exception(response.data['message']);
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
}
