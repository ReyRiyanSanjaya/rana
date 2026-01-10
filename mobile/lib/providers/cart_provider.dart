import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart'; // [NEW]
import 'package:rana_merchant/services/sync_service.dart';

class CartItem {
  final String productId;
  final String name;
  final String? sku; // [NEW] Snapshot
  final String? imageUrl; // [NEW] Snapshot
  final double price;
  final double basePrice; // [NEW] Snapshot (costPrice)
  int quantity;
  final int maxStock;

  CartItem({
    required this.productId,
    required this.name,
    this.sku,
    this.imageUrl,
    required this.price,
    this.basePrice = 0,
    this.quantity = 1,
    this.maxStock = 999999,
  });

  double get total => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double _discount = 0.0;
  double _taxRate = 0.0; // 0.1 for 10%
  String? _customerName;
  String? _notes;

  String? get customerName => _customerName;
  String? get notes => _notes;

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

  void setCustomerName(String? name) {
    final normalized = name?.trim();
    _customerName =
        (normalized == null || normalized.isEmpty) ? null : normalized;
    notifyListeners();
  }

  void setNotes(String? value) {
    final normalized = value?.trim();
    _notes = (normalized == null || normalized.isEmpty) ? null : normalized;
    notifyListeners();
  }

  void addItem(String productId, String name, double price,
      {int maxStock = 999999,
      String? sku,
      String? imageUrl,
      double basePrice = 0}) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          productId: existing.productId,
          name: existing.name,
          sku: existing.sku,
          imageUrl: existing.imageUrl,
          price: existing.price,
          basePrice: existing.basePrice,
          quantity: existing.quantity + 1,
          maxStock: existing.maxStock,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          productId: productId,
          name: name,
          sku: sku,
          imageUrl: imageUrl,
          price: price,
          basePrice: basePrice,
          maxStock: maxStock,
        ),
      );
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = 0;
    _taxRate = 0;
    _customerName = null;
    _notes = null;
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
          sku: existing.sku,
          imageUrl: existing.imageUrl,
          price: existing.price,
          basePrice: existing.basePrice,
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
      // [NEW] Enforce maxStock
      final validQuantity =
          quantity > existing.maxStock ? existing.maxStock : quantity;

      _items.update(
        productId,
        (_) => CartItem(
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          quantity: validQuantity,
          maxStock: existing.maxStock,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> checkout(String tenantId, String storeId, String cashierId,
      {String paymentMethod = 'CASH',
      String? customerName,
      String? notes}) async {
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
      'customerName': (customerName ?? _customerName), // For Kasbon/Struk
      'notes': (notes ?? _notes)
    };

    // 2. Prepare Items
    final txnItems = _items.values
        .map((item) => {
              // 'id': const Uuid().v4(), // [FIX] Removed, let DB autoincrement
              'transactionOfflineId': offlineId,
              'productId': item.productId,
              'name': item.name, // [FIX] Added missing name
              'sku': item.sku, // [NEW] Snapshot
              'imageUrl': item.imageUrl, // [NEW] Snapshot
              'quantity': item.quantity,
              'price': item.price,
              'costPrice': item.basePrice // [NEW] Snapshot
            })
        .toList();

    // 3. Save to Local DB
    await DatabaseHelper.instance.queueTransaction(txn, txnItems);

    // 4. Trigger Sync (Fire and Forget)
    SyncService().syncTransactions();

    clear();
  }
}
