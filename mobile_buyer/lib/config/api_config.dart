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

  // [USER CONFIG] Ganti IP ini dengan IP Laptop Anda jika testing di HP Fisik
  static const String _localIp = '192.168.1.x';
  static const String _devUrlLan = 'http://$_localIp:4000/api';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Resolver
  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) return override;

    if (_isProduction) return _prodUrl;

    // Jika testing di HP Fisik dan _localIp sudah diatur (bukan default)
    if (!kIsWeb && _localIp != '192.168.1.x') {
      return _devUrlLan;
    }

    if (kIsWeb) {
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

  static String get serverUrl {
    final url = baseUrl;
    if (url.endsWith('/api')) {
      return url.substring(0, url.length - 4);
    }
    return url;
  }
}
