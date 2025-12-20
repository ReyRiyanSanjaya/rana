import 'package:flutter/foundation.dart';
import 'package:rana_market/data/market_api_service.dart';

class MarketCartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;

  MarketCartItem({required this.productId, required this.name, required this.price, this.quantity = 1});
}

class MarketCartProvider with ChangeNotifier {
  // StoreId -> ItemId -> Item
  // Complex: Marketplace carts usually split by Store. 
  // MVP: Single Store Cart for simplicity (Like GoFood, one store at a time).
  String? _activeStoreId;
  String? _activeStoreName;
  final Map<String, MarketCartItem> _items = {};

  String? get activeStoreName => _activeStoreName;
  Map<String, MarketCartItem> get items => _items;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  void addToCart(String storeId, String storeName, String productId, String name, double price) {
    // If adding from different store, confirm reset
    if (_activeStoreId != null && _activeStoreId != storeId) {
      throw Exception('DIFFERENT_STORE'); 
    }

    _activeStoreId = storeId;
    _activeStoreName = storeName;

    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
    } else {
      _items[productId] = MarketCartItem(productId: productId, name: name, price: price);
    }
    notifyListeners();
  }
  
  void clearCart() {
    _items.clear();
    _activeStoreId = null;
    _activeStoreName = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOrder({required String customerName, required String phone, required String address, bool isPickup = false}) async {
    if (_items.isEmpty || _activeStoreId == null) throw Exception('Empty');
    
    final orderItems = _items.values.map((i) => {
      'productId': i.productId,
      'quantity': i.quantity,
      'price': i.price
    }).toList();

    final result = await MarketApiService().createOrder(
      storeId: _activeStoreId!,
      items: orderItems,
      customerName: customerName,
      customerPhone: phone,
      deliveryAddress: address,
      fulfillmentType: isPickup ? 'PICKUP' : 'DELIVERY'
    );

    clearCart();
    return result;
  }
}
