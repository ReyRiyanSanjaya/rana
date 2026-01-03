import 'package:flutter/foundation.dart';
import 'package:rana_market/data/market_api_service.dart';

class MarketCartItem {
  final String productId;
  final String name;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  int quantity;

  MarketCartItem(
      {required this.productId,
      required this.name,
      required this.price,
      this.originalPrice,
      this.imageUrl,
      this.quantity = 1});
}

class MarketCartProvider with ChangeNotifier {
  // StoreId -> ItemId -> Item
  // Complex: Marketplace carts usually split by Store.
  // MVP: Single Store Cart for simplicity (Like GoFood, one store at a time).
  String? _activeStoreId;
  String? _activeStoreName;
  String? _activeStoreAddress;
  double? _activeStoreLat;
  double? _activeStoreLong;
  final Map<String, MarketCartItem> _items = {};

  String? get activeStoreName => _activeStoreName;
  String? get activeStoreAddress => _activeStoreAddress;
  double? get activeStoreLat => _activeStoreLat;
  double? get activeStoreLong => _activeStoreLong;
  Map<String, MarketCartItem> get items => _items;
  double _serviceFeeValue = 0;
  String _serviceFeeType = 'FLAT';
  double? _serviceFeeCapMin;
  double? _serviceFeeCapMax;

  double get serviceFee {
    final subtotal = totalAmount;
    if (subtotal <= 0) return 0;

    double fee = 0;
    if (_serviceFeeType == 'PERCENT') {
      fee = subtotal * (_serviceFeeValue / 100);
    } else {
      fee = _serviceFeeValue;
    }
    if (_serviceFeeCapMin != null && fee < _serviceFeeCapMin!) {
      fee = _serviceFeeCapMin!;
    }
    if (_serviceFeeCapMax != null && fee > _serviceFeeCapMax!) {
      fee = _serviceFeeCapMax!;
    }
    return fee;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  double get totalOriginalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += (item.originalPrice ?? item.price) * item.quantity;
    });
    return total;
  }

  double get totalDiscount => totalOriginalAmount - totalAmount;

  double get grandTotal => totalAmount + serviceFee;

  Future<void> fetchServiceFee() async {
    try {
      final config = await MarketApiService().getAppConfig();
      if (config.containsKey('buyerServiceFee')) {
        _serviceFeeValue = (config['buyerServiceFee'] as num).toDouble();
      }
      if (config.containsKey('buyerServiceFeeType')) {
        _serviceFeeType =
            (config['buyerServiceFeeType'] as String?)?.toUpperCase() ?? 'FLAT';
      }
      if (config.containsKey('buyerFeeCapMin')) {
        final v = config['buyerFeeCapMin'];
        if (v is num) _serviceFeeCapMin = v.toDouble();
      }
      if (config.containsKey('buyerFeeCapMax')) {
        final v = config['buyerFeeCapMax'];
        if (v is num) _serviceFeeCapMax = v.toDouble();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching service fee: $e');
    }
  }

  void addToCart(
    String storeId,
    String storeName,
    String productId,
    String name,
    double price, {
    String? storeAddress,
    double? storeLat,
    double? storeLong,
    double? originalPrice,
    String? imageUrl,
  }) {
    // If adding from different store, confirm reset
    if (_activeStoreId != null && _activeStoreId != storeId) {
      throw Exception('DIFFERENT_STORE');
    }

    _activeStoreId = storeId;
    _activeStoreName = storeName;
    _activeStoreAddress = storeAddress ?? _activeStoreAddress;
    _activeStoreLat = storeLat ?? _activeStoreLat;
    _activeStoreLong = storeLong ?? _activeStoreLong;

    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
    } else {
      _items[productId] = MarketCartItem(
          productId: productId,
          name: name,
          price: price,
          originalPrice: originalPrice,
          imageUrl: imageUrl);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      _items.remove(productId);
      if (_items.isEmpty) clearCart();
    } else {
      _items[productId]!.quantity = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _activeStoreId = null;
    _activeStoreName = null;
    _activeStoreAddress = null;
    _activeStoreLat = null;
    _activeStoreLong = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOrder(
      {required String customerName, required String phone}) async {
    if (_items.isEmpty || _activeStoreId == null) throw Exception('Empty');

    final orderItems = _items.values
        .map((i) => {
              'productId': i.productId,
              'quantity': i.quantity,
              'price': i.price
            })
        .toList();

    final result = await MarketApiService().createOrder(
        storeId: _activeStoreId!,
        items: orderItems,
        customerName: customerName,
        customerPhone: phone,
        deliveryAddress: '-',
        fulfillmentType: 'PICKUP');

    clearCart();
    return result;
  }
}
