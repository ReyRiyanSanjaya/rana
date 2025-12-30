import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _ids = {};

  bool isFavorite(dynamic id) {
    final s = id?.toString();
    if (s == null) return false;
    return _ids.contains(s);
  }

  void toggleFavorite(dynamic id) {
    final s = id?.toString();
    if (s == null) return;
    if (_ids.contains(s)) {
      _ids.remove(s);
    } else {
      _ids.add(s);
    }
    notifyListeners();
  }
}

