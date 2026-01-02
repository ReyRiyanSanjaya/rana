import 'package:flutter/material.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/services/notification_service.dart';

class NotificationsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  NotificationsProvider() {
    // Listen to realtime notifications
    NotificationService().onNotification.listen((data) {
      _addItem(data);
    });
  }

  void _addItem(Map<String, dynamic> item) {
    // Avoid duplicates if possible (simple check by ID + title)
    final exists = _items.any((e) =>
        e['title'] == item['title'] &&
        e['message'] == item['message'] &&
        (DateTime.now().difference(DateTime.parse(e['createdAt'])).inSeconds < 5)); // Simple debounce
    
    if (!exists) {
      _items.insert(0, item);
      notifyListeners();
    }
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      final api = MarketApiService();
      // Run in parallel
      final results = await Future.wait([
        api.getAnnouncements(),
        api.getNotifications(),
      ]);

      final anns = results[0];
      final notifs = results[1];

      final merged = <Map<String, dynamic>>[];
      
      for (final a in anns.whereType<Map>()) {
        final m = Map<String, dynamic>.from(a);
        merged.add({
          'title': m['title'] ?? '-',
          'message': m['content'] ?? m['message'] ?? '',
          'createdAt': m['createdAt'],
          'source': 'ANNOUNCEMENT',
          'isRead': true, // Historical items assumed read
        });
      }
      
      for (final n in notifs.whereType<Map>()) {
        final m = Map<String, dynamic>.from(n);
        merged.add({
          'title': m['title'] ?? '-',
          'message': m['message'] ?? m['body'] ?? '',
          'createdAt': m['createdAt'],
          'source': 'SYSTEM',
          'isRead': true,
        });
      }

      // Sort by date desc
      merged.sort((a, b) {
        final ad = a['createdAt'];
        final bd = b['createdAt'];
        final at = (ad is String) ? DateTime.tryParse(ad) : (ad is DateTime ? ad : null);
        final bt = (bd is String) ? DateTime.tryParse(bd) : (bd is DateTime ? bd : null);
        final av = at?.millisecondsSinceEpoch ?? 0;
        final bv = bt?.millisecondsSinceEpoch ?? 0;
        return bv.compareTo(av);
      });

      // Keep existing realtime items if any (merge strategy)
      // For simplicity, we just overwrite but maybe we should keep 'REALTIME' ones
      // Actually, reloading from API might miss the local realtime ones if backend doesn't save them yet.
      // So we should merge: API items + _items.where(source == REALTIME)
      
      final realtimeItems = _items.where((i) => i['source'] == 'REALTIME').toList();
      
      _items = [...realtimeItems, ...merged];
      
      // Re-sort
      _items.sort((a, b) {
         final ad = a['createdAt'];
         final bd = b['createdAt'];
         final at = (ad is String) ? DateTime.tryParse(ad) : (ad is DateTime ? ad : null);
         final bt = (bd is String) ? DateTime.tryParse(bd) : (bd is DateTime ? bd : null);
         final av = at?.millisecondsSinceEpoch ?? 0;
         final bv = bt?.millisecondsSinceEpoch ?? 0;
         return bv.compareTo(av);
      });

    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = {..._items[i], 'isRead': true};
    }
    NotificationService.badgeCount.value = 0;
    notifyListeners();
  }
}
