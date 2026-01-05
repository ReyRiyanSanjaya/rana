import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URLs
  static const String _prodUrl = 'https://api.rana-app.com/api';
  static const String _devUrlAndroid = 'http://10.0.2.2:4000/api';
  static const String _devUrlWeb = 'http://localhost:4000/api';

  // Environment Flags
  static const bool _isProduction =
      bool.fromEnvironment('RANA_PROD', defaultValue: kReleaseMode);
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Resolver
  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;

    if (_isProduction) return _prodUrl;

    if (kIsWeb) {
      // Logic for web debugging on device vs localhost
      // Note: In strict 'const' context we can't use Uri.base easily in static const.
      // So this is a getter.
      try {
        final host = Uri.base.host;
        if (host.isNotEmpty && host != 'localhost') {
          return 'http://$host:4000/api';
        }
      } catch (_) {}
      return _devUrlWeb;
    }

    return _devUrlAndroid;
  }

  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authStore = '/auth/store';
  static const String authChangePassword = '/auth/change-password';

  // Wholesale & Inventory
  static const String wholesaleUploadProof = '/wholesale/upload-proof';
  static const String flashSalesStatus =
      '/products/flashsales'; // Base for status update
  static const String inventoryAdjust = '/inventory/adjust';

  static const String purchases = '/purchases';
  static const String transactionsSync = '/transactions/sync';
  static const String transactionHistory = '/transactions/history'; // [NEW]
  static const String wholesaleOrdersScan = '/wholesale/orders/scan';

  static const String products = '/products';
  static const String flashSales = '/products/flashsales';

  static const String wallet = '/wallet';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTopup = '/wallet/topup';
  static const String walletTransfer = '/wallet/transfer';
  static const String walletTransaction = '/wallet/transaction';

  static const String orders = '/orders';
  static const String ordersStatus = '/orders/status';
  static const String ordersScan = '/orders/scan';

  static const String subscriptionsPackages = '/subscriptions/packages';
  static const String subscriptionsStatus = '/subscriptions/status';
  static const String subscriptionsRequest = '/subscriptions/request';

  static const String referralMe = '/referral/me';
  static const String referralReferrals = '/referral/me/referrals';

  static String get serverUrl {
    final url = baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }
}
