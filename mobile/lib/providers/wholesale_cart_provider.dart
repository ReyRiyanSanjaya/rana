import 'package:flutter/material.dart';

class WholesaleCartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;
  final String supplier;

  WholesaleCartItem({
    required this.id, 
    required this.name, 
    required this.price, 
    required this.image,
    required this.quantity,
    required this.supplier
  });
}

class WholesaleCartProvider with ChangeNotifier {
  final Map<String, WholesaleCartItem> _items = {};

  Map<String, WholesaleCartItem> get items => _items;

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

  void addItem(String id, String name, double price, String image, String supplier) {
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
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
