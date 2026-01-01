import 'package:flutter/material.dart';
import 'package:rana_market/data/market_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = MarketApiService();
    final anns = await api.getAnnouncements();
    final notifs = await api.getNotifications();

    final merged = <Map<String, dynamic>>[];
    for (final a in anns.whereType<Map>()) {
      final m = Map<String, dynamic>.from(a);
      merged.add({
        'title': m['title'] ?? '-',
        'message': m['content'] ?? m['message'] ?? '',
        'createdAt': m['createdAt'],
        'source': 'ANNOUNCEMENT',
      });
    }
    for (final n in notifs.whereType<Map>()) {
      final m = Map<String, dynamic>.from(n);
      merged.add({
        'title': m['title'] ?? '-',
        'message': m['message'] ?? m['body'] ?? '',
        'createdAt': m['createdAt'],
        'source': 'NOTIFICATION',
      });
    }

    merged.sort((a, b) {
      final ad = a['createdAt'];
      final bd = b['createdAt'];
      final at = (ad is String) ? DateTime.tryParse(ad) : (ad is DateTime ? ad : null);
      final bt = (bd is String) ? DateTime.tryParse(bd) : (bd is DateTime ? bd : null);
      final av = at?.millisecondsSinceEpoch ?? 0;
      final bv = bt?.millisecondsSinceEpoch ?? 0;
      return bv.compareTo(av);
    });

    if (!mounted) return;
    setState(() {
      _items = merged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('Belum ada notifikasi')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final n = _items[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        tileColor: Colors.white,
                        title: Text((n['title'] ?? '-').toString()),
                        subtitle: Text((n['message'] ?? '').toString()),
                      );
                    },
                  ),
      ),
    );
  }
}
