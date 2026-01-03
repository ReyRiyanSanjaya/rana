import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void toggleFavorite(dynamic id) {
    final s = id?.toString();
    if (s == null) return;
    if (_ids.contains(s)) _ids.remove(s);
    else _ids.add(s);
    notifyListeners();
    _persist();
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
