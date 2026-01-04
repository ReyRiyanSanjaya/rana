import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_market/data/market_api_service.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _ids = {};
  static const _storageKey = 'buyer_favorites_v1';

  FavoritesProvider() {
    _load();
  }

  Set<String> get ids => _ids;

  bool isFavorite(dynamic id) {
    final s = id?.toString();
    if (s == null) return false;
    return _ids.contains(s);
  }

  Future<void> toggleFavorite(dynamic id, {String? phone}) async {
    final s = id?.toString();
    if (s == null) return;
    
    // Optimistic Update
    if (_ids.contains(s)) {
      _ids.remove(s);
    } else {
      _ids.add(s);
    }
    notifyListeners();
    _persist();

    // Server Sync
    if (phone != null && phone.isNotEmpty) {
      try {
        await MarketApiService().toggleFavorite(phone, s);
      } catch (e) {
        debugPrint('Fav Sync Error: $e');
      }
    }
  }

  Future<void> loadFromServer(String phone) async {
    try {
      final items = await MarketApiService().getFavorites(phone);
      final serverIds = items.map((e) => e['id'].toString()).toSet();
      if (serverIds.isNotEmpty) {
        _ids.addAll(serverIds);
        notifyListeners();
        _persist();
      }
    } catch (e) {
      debugPrint('Fav Load Error: $e');
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? const [];
    _ids
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _ids.toList());
  }
}
