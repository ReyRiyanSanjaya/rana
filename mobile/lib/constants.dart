import 'package:rana_merchant/config/api_config.dart';
import 'package:rana_merchant/config/app_config.dart';

// Deprecated: Use AppConfig or ApiConfig instead
class AppConstants {
  static String get baseUrl => ApiConfig.baseUrl;

  static const List<String> productCategories = AppConfig.productCategories;
}
