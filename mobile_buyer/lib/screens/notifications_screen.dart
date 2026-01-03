import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsProvider>(context, listen: false).load();
    });
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = (createdAt is String)
        ? DateTime.tryParse(createdAt)
        : (createdAt is DateTime ? createdAt : null);
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
    if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
    if (diff.inDays < 7) return '${diff.inDays}h yang lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _getIcon(String source) {
    switch (source) {
      case 'ANNOUNCEMENT':
        return Icons.campaign_outlined;
      case 'REALTIME':
        return Icons.notifications_active_outlined;
      case 'ORDER_UPDATE':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColor(String source) {
    switch (source) {
      case 'ANNOUNCEMENT':
        return Colors.orange;
      case 'REALTIME':
        return Colors.blue;
      case 'ORDER_UPDATE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai semua dibaca',
            onPressed: () {
              Provider.of<NotificationsProvider>(context, listen: false)
                  .markAllAsRead();
            },
          )
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prov.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pemberitahuan pesanan dan promo\nakan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: prov.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final n = prov.items[i];
                final source = (n['source'] ?? '').toString();
                final isRead = n['isRead'] == true;

                return Container(
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            _getColor(source).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(source),
                          color: _getColor(source), size: 24),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (n['title'] ?? '-').toString(),
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          (n['message'] ?? '').toString(),
                          style: TextStyle(
                              color: Colors.grey.shade700, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(n['createdAt']),
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
