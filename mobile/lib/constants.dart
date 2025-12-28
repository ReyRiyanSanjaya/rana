import 'package:flutter/foundation.dart';

class AppConstants {
  // API Base URL - matches ApiService configuration
  static const String _devUrl = 'http://10.0.2.2:4000';
  static const String _webDevUrl = 'http://localhost:4000';
  static const bool _isProduction = false;
  
  static String get baseUrl => _isProduction 
      ? 'https://api.rana-app.com' 
      : (kIsWeb ? _webDevUrl : _devUrl);

  static const List<String> productCategories = [
    'All',
    'Beverage',
    'Food',
    'Beans',
    'Merchandise',
    'Snack',
    'Non-Coffee'
  ];
}
