import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final anns = await _api.getAnnouncements();
      final notifs = await _api.fetchNotifications();
      await _api.markAllNotificationsRead();

      final merged = <Map<String, dynamic>>[];

      for (final a in anns.whereType<Map>()) {
        final m = Map<String, dynamic>.from(a);
        merged.add({
          'title': m['title'] ?? '-',
          'body': m['content'] ?? m['body'] ?? '',
          'createdAt': m['createdAt'],
          'type': 'ANNOUNCEMENT',
        });
      }

      for (final n in notifs.whereType<Map>()) {
        final m = Map<String, dynamic>.from(n);
        merged.add({
          'title': m['title'] ?? '-',
          'body': m['body'] ?? m['message'] ?? '',
          'createdAt': m['createdAt'],
          'type': 'NOTIFICATION',
          'isRead': m['isRead'] ?? false,
        });
      }

      merged.sort((a, b) {
        final ad = a['createdAt'];
        final bd = b['createdAt'];
        DateTime? at;
        DateTime? bt;

        if (ad is String) {
          at = DateTime.tryParse(ad);
        } else if (ad is DateTime) {
          at = ad;
        }

        if (bd is String) {
          bt = DateTime.tryParse(bd);
        } else if (bd is DateTime) {
          bt = bd;
        }

        final av = at?.millisecondsSinceEpoch ?? 0;
        final bv = bt?.millisecondsSinceEpoch ?? 0;
        return bv.compareTo(av);
      });

      if (!mounted) return;
      setState(() {
        _notifications = merged;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Notifikasi',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Belum ada notifikasi',
                                style: GoogleFonts.outfit(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final created = n['createdAt'];
                      DateTime? createdAt;
                      if (created is String) {
                        createdAt = DateTime.tryParse(created);
                      } else if (created is DateTime) {
                        createdAt = created;
                      }

                      final timeLabel = createdAt != null
                          ? DateFormat('dd MMM HH:mm').format(createdAt)
                          : '';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07A5F).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none_rounded,
                                color: Color(0xFFE07A5F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n['title']?.toString() ?? 'Info',
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(n['body']?.toString() ?? '',
                                    style: GoogleFonts.outfit(
                                        color: Colors.grey[600], fontSize: 14)),
                                const SizedBox(height: 8),
                                if (timeLabel.isNotEmpty)
                                  Text(
                                    timeLabel,
                                    style: GoogleFonts.outfit(
                                        fontSize: 10, color: Colors.grey[400]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
