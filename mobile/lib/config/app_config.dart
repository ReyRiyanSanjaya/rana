class AppConfig {
  static const String appName = 'Rana Merchant';
  static const String appVersion = '1.0.0'; // Should match pubspec.yaml

  // Business Logic Constants
  static const List<String> productCategories = [
    'All',
    'Beverage',
    'Food',
    'Beans',
    'Merchandise',
    'Snack',
    'Non-Coffee'
  ];

  static const String defaultCurrency = 'IDR';
  static const String defaultLanguage = 'id_ID';

  // Feature Flags
  static const bool enableStockTracking = true;
  static const bool enableFlashSales = true;
  static const bool enableSubscriptions = true;

  // External URLs
  static const String privacyPolicyUrl = 'https://rana-app.com/privacy-policy';
  static const String supportWhatsAppUrl = 'https://wa.me/628887992299';
  static const String supportWhatsAppNumber = '628887992299';
  static const String openMeteoBaseUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String whatsappAppUrl = 'whatsapp://send';
  static const String whatsappWebUrl = 'https://wa.me';
}
