import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_market/data/market_api_service.dart';

class ReviewsProvider with ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _reviews = {};
  bool _loaded = false;
  final Map<String, int> _pages = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, String> _sort = {};
  final Map<String, bool> _loading = {};

  bool get loaded => _loaded;
  bool isLoading(dynamic productId) => _loading[productId?.toString() ?? ''] ?? false;
  bool hasMore(dynamic productId) => _hasMore[productId?.toString() ?? ''] ?? true;
  String sortFor(dynamic productId) => _sort[productId?.toString() ?? ''] ?? 'newest';

  List<Map<String, dynamic>> getReviews(dynamic productId) {
    final id = productId?.toString() ?? '';
    return List<Map<String, dynamic>>.from(_reviews[id] ?? const []);
  }

  double getAverage(dynamic productId) {
    final list = getReviews(productId);
    if (list.isEmpty) return 0.0;
    final sum = list.fold<int>(0, (acc, e) => acc + (e['rating'] as int? ?? 0));
    return sum / list.length;
  }
  
  int getCount(dynamic productId) {
    return getReviews(productId).length;
  }
  
  Map<int, int> getDistribution(dynamic productId) {
    final list = getReviews(productId);
    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in list) {
      final val = r['rating'] as int? ?? 0;
      if (map.containsKey(val)) {
        map[val] = map[val]! + 1;
      }
    }
    return map;
  }

  ReviewsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reviews_storage');
    if (raw != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(raw);
        data.forEach((key, value) {
          _reviews[key] = List<Map<String, dynamic>>.from(value as List);
        });
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> loadReviews(dynamic productId) async {
    final id = productId?.toString() ?? '';
    if (id.isEmpty) return;
    final page = _pages[id] ?? 1;
    final limit = 10;
    final sort = _sort[id] ?? 'newest';
    _loading[id] = true;
    notifyListeners();
    try {
      final list = await MarketApiService().getProductReviews(id, page: page, limit: limit, sort: sort);
      final converted = List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e)));
      if (page == 1) {
        _reviews[id] = converted;
      } else {
        _reviews.putIfAbsent(id, () => []);
        _reviews[id]!.addAll(converted);
      }
      _hasMore[id] = converted.length >= limit;
      _pages[id] = page;
      notifyListeners();
    } catch (_) {
    } finally {
      _loading[id] = false;
      notifyListeners();
    }
  }

  Future<void> loadInitial(dynamic productId, {String sort = 'newest'}) async {
    final id = productId?.toString() ?? '';
    if (id.isEmpty) return;
    _pages[id] = 1;
    _sort[id] = sort;
    await loadReviews(id);
  }

  Future<void> loadMore(dynamic productId) async {
    final id = productId?.toString() ?? '';
    if (id.isEmpty) return;
    if (!(_hasMore[id] ?? true) || (_loading[id] ?? false)) return;
    _pages[id] = (_pages[id] ?? 1) + 1;
    await loadReviews(id);
  }

  Future<void> addReview({
    required dynamic productId,
    required int rating,
    required String comment,
    String? userName,
  }) async {
    final id = productId?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      await MarketApiService().addProductReview(id, rating: rating, comment: comment);
      _pages[id] = 1; // Refresh from first page after submit
      await loadReviews(id);
    } catch (_) {
      // Fail soft to local cache
      _reviews.putIfAbsent(id, () => []);
      _reviews[id]!.insert(0, {
        'rating': rating,
        'comment': comment,
        'userName': userName ?? 'Pengguna',
        'createdAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reviews_storage', jsonEncode(_reviews));
    }
  }
}
