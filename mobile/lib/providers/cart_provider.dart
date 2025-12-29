import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart'; // [NEW]

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;

  CartItem({required this.productId, required this.name, required this.price, this.quantity = 1});
  
  double get total => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double _discount = 0.0;
  double _taxRate = 0.0; // 0.1 for 10%

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.total;
    });
    return total;
  }

  double get discountAmount => _discount;
  double get taxRate => _taxRate;
  
  // Tax applied after discount
  double get taxAmount => (subtotal - _discount) * _taxRate;

  double get totalAmount => (subtotal - _discount) + taxAmount;

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  void addItem(String productId, String name, double price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(productId: productId, name: name, price: price),
      );
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = 0;
    _taxRate = 0;
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void setItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    if (_items.containsKey(productId)) {
      final existing = _items[productId]!;
      _items.update(
        productId,
        (_) => CartItem(
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          quantity: quantity,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> checkout(
      String tenantId, 
      String storeId, 
      String cashierId, 
      {
        String paymentMethod = 'CASH', 
        String? customerName, 
        String? notes
      }
  ) async {
    final offlineId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    
    // 1. Prepare Transaction Header
    final txn = {
      'offlineId': offlineId,
      'tenantId': tenantId,
      'storeId': storeId,
      'cashierId': cashierId,
      'totalAmount': totalAmount, // [FIX] Was 'total'
      'discount': _discount,
      'tax': taxAmount,
      'occurredAt': now,
      'status': 'PENDING_SYNC',
      // New Fields for UMKM Features
      'paymentMethod': paymentMethod, // CASH, QRIS, KASBON
      // 'customerId' removed as it doesn't exist in local DB schema yet
      'customerName': customerName, // For Kasbon/Struk
      'notes': notes
    };

    // 2. Prepare Items
    final txnItems = _items.values.map((item) => {
      // 'id': const Uuid().v4(), // [FIX] Removed, let DB autoincrement
      'transactionOfflineId': offlineId,
      'productId': item.productId,
      'name': item.name, // [FIX] Added missing name
      'quantity': item.quantity,
      'price': item.price
    }).toList();

    // 3. Save to Local DB
    await DatabaseHelper.instance.queueTransaction(txn, txnItems);

    clear();
  }
}
