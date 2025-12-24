import 'dart:async';

class ShopeeService {
  // Singleton pattern
  static final ShopeeService _instance = ShopeeService._internal();
  factory ShopeeService() => _instance;
  ShopeeService._internal();

  /// Mock: Get Product List based on Service Type
  /// Returns a list of products with 'id', 'name', 'price', and 'discount' status
  Future<List<Map<String, dynamic>>> getProducts(String category) async {
    // Simulate Network Latency
    await Future.delayed(const Duration(milliseconds: 800)); 

    category = category.toLowerCase();

    if (category.contains('pulsa') || category.contains('data')) {
      return [
        {'id': 'P5', 'name': 'Telkomsel 5.000', 'price': 5250, 'promo': false},
        {'id': 'P10', 'name': 'Telkomsel 10.000', 'price': 10200, 'promo': false},
        {'id': 'P25', 'name': 'Telkomsel 25.000', 'price': 24900, 'promo': true}, // Promo
        {'id': 'P50', 'name': 'Telkomsel 50.000', 'price': 49500, 'promo': true}, // Murah
        {'id': 'P100', 'name': 'Telkomsel 100.000', 'price': 98500, 'promo': false},
        {'id': 'I5', 'name': 'Indosat 5.000', 'price': 5800, 'promo': false},
        {'id': 'I10', 'name': 'Indosat 10.000', 'price': 10800, 'promo': false},
      ];
    } else if (category.contains('listrik') || category.contains('pln')) {
       return [
        {'id': 'PLN20', 'name': 'Token PLN 20.000', 'price': 20500, 'promo': false},
        {'id': 'PLN50', 'name': 'Token PLN 50.000', 'price': 50500, 'promo': false},
        {'id': 'PLN100', 'name': 'Token PLN 100.000', 'price': 100500, 'promo': false},
        {'id': 'PLN200', 'name': 'Token PLN 200.000', 'price': 200500, 'promo': false},
      ];
    } else if (category.contains('game')) {
       return [
        {'id': 'FF70', 'name': 'Free Fire 70 Diamonds', 'price': 9500, 'promo': true},
        {'id': 'FF140', 'name': 'Free Fire 140 Diamonds', 'price': 19000, 'promo': false},
        {'id': 'ML86', 'name': 'Mobile Legends 86 Diamonds', 'price': 22000, 'promo': false},
      ];
    } else {
      // Generic / Bill Payment (Inquiry based)
      return [];
    }
  }

  /// Mock: Inquiry Bill (Check Tagihan)
  Future<Map<String, dynamic>> checkBill(String customerId, String type) async {
    await Future.delayed(const Duration(seconds: 1));
    // Always return success for verified ID
    return {
      'customer_name': 'RANA MERCHANT TEST',
      'bill_amount': 150000,
      'admin_fee': 2500,
      'total': 152500,
      'status': 'UNPAID'
    };
  }
}
