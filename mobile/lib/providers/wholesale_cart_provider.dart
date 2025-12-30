import 'package:flutter/material.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class WholesaleCartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;
  final String supplier;

  WholesaleCartItem(
      {required this.id,
      required this.name,
      required this.price,
      required this.image,
      required this.quantity,
      required this.supplier});
}

class WholesaleCartProvider with ChangeNotifier {
  final Map<String, WholesaleCartItem> _items = {};

  WholesaleCartProvider() {
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final settings = await ApiService().getSystemSettings();
      if (settings.containsKey('WHOLESALE_SERVICE_FEE')) {
        _serviceFee =
            double.tryParse(settings['WHOLESALE_SERVICE_FEE']!) ?? 2500;
      }
      if (settings.containsKey('WHOLESALE_SHIPPING_COST_PER_KM')) {
        _shippingCostPerKm =
            double.tryParse(settings['WHOLESALE_SHIPPING_COST_PER_KM']!) ??
                3000;
      }
      if (settings.containsKey('WHOLESALE_PAYMENT_METHODS')) {
        final methods = settings['WHOLESALE_PAYMENT_METHODS']!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (methods.isNotEmpty) {
          _paymentMethods = methods;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch wholesale settings: $e');
    }
  }

  // Coupon State
  String? _couponCode;
  double _discountAmount = 0;
  bool _isFreeShipping = false;

  // New Business Logic State
  double _serviceFee = 2500; // Default, should be fetched from settings
  double _shippingCostPerKm = 3000; // Default
  List<String> _paymentMethods = [
    'Transfer Bank (BCA)',
    'Transfer Bank (Mandiri)',
    'Bayar di Tempat (COD)'
  ];

  Map<String, WholesaleCartItem> get items => _items;
  String? get couponCode => _couponCode;
  double get discountAmount => _discountAmount;
  bool get isFreeShipping => _isFreeShipping;
  double get serviceFee => _serviceFee;
  double get shippingCostPerKm => _shippingCostPerKm;
  List<String> get paymentMethods => _paymentMethods;

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
      String id, String name, double price, String image, String supplier) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existingCartItem) => WholesaleCartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          image: existingCartItem.image,
          quantity: existingCartItem.quantity + 1,
          supplier: existingCartItem.supplier,
        ),
      );
    } else {
      _items.putIfAbsent(
        id,
        () => WholesaleCartItem(
          id: id,
          name: name,
          price: price,
          image: image,
          quantity: 1,
          supplier: supplier,
        ),
      );
    }
    _resetCoupon(); // Reset coupon on cart change to re-validate via user action if needed (or auto-recalculate, but simplest is reset)
    notifyListeners();
  }

  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) {
      return;
    }
    if (_items[id]!.quantity > 1) {
      _items.update(
          id,
          (existingCartItem) => WholesaleCartItem(
              id: existingCartItem.id,
              name: existingCartItem.name,
              price: existingCartItem.price,
              image: existingCartItem.image,
              quantity: existingCartItem.quantity - 1,
              supplier: existingCartItem.supplier));
    } else {
      _items.remove(id);
    }
    _resetCoupon();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    _resetCoupon();
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (!_items.containsKey(id)) {
      return;
    }
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    _items.update(
        id,
        (existingCartItem) => WholesaleCartItem(
            id: existingCartItem.id,
            name: existingCartItem.name,
            price: existingCartItem.price,
            image: existingCartItem.image,
            quantity: quantity,
            supplier: existingCartItem.supplier));
    _resetCoupon();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _resetCoupon();
    notifyListeners();
  }

  void _resetCoupon() {
    _couponCode = null;
    _discountAmount = 0;
    _isFreeShipping = false;
  }

  Future<void> applyCoupon(String code) async {
    try {
      final result = await ApiService().validateCoupon(code, totalAmount);
      _couponCode = result['coupon']['code'];
      _discountAmount = (result['discount'] as num).toDouble();
      _isFreeShipping = result['coupon']['type'] == 'FREE_SHIPPING';
      notifyListeners();
    } catch (e) {
      _resetCoupon();
      notifyListeners();
      rethrow;
    }
  }

  void removeCoupon() {
    _resetCoupon();
    notifyListeners();
  }

  Future<void> checkout(String tenantId, String paymentMethod, String address,
      double shippingCost, double serviceFee,
      {String? proofUrl}) async {
    final List<Map<String, dynamic>> orderItems = [];
    _items.forEach((key, item) {
      orderItems.add({
        'productId': item.id,
        'quantity': item.quantity,
        'price': item.price
      });
    });

    if (orderItems.isEmpty) return;

    await ApiService().createWholesaleOrder(
        tenantId: tenantId,
        items: orderItems,
        paymentMethod: paymentMethod,
        shippingAddress: address,
        shippingCost: shippingCost,
        serviceFee: serviceFee,
        couponCode: _couponCode,
        proofUrl: proofUrl);

    clear();
  }
}
