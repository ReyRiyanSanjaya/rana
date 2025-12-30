import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryProvider with ChangeNotifier {
  final List<String> _history = [];
  bool _loaded = false;

  List<String> get history => List.unmodifiable(_history);
  bool get loaded => _loaded;

  SearchHistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('search_history') ?? [];
    _history
      ..clear()
      ..addAll(list);
    _loaded = true;
    notifyListeners();
  }

  Future<void> addQuery(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    _history.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    _history.insert(0, query);
    if (_history.length > 10) {
      _history.removeRange(10, _history.length);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _history);
  }

  Future<void> clear() async {
    _history.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }
}

