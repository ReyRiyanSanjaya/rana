import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/services/realtime_service.dart';
import 'package:rana_market/screens/order_detail_screen.dart';
import 'package:rana_market/data/market_api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final RealtimeService _rt = RealtimeService();
  final List<VoidCallback> _unwatchers = [];
  bool _loading = true;
  String? _phone;
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString('buyer_phone') ?? '').trim();
    if (!mounted) return;
    setState(() {
      _phone = raw.isEmpty ? null : raw;
      _phoneCtrl.text = _phone ?? '';
    });
    if (_phone != null) {
      await _initialLoad();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buyer_phone', phone);
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _phoneCtrl.text = phone;
    });
  }

  Future<void> _initialLoad() async {
    final phone = (_phone ?? '').trim();
    if (phone.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final prov = Provider.of<OrdersProvider>(context, listen: false);

    // Clear old watchers
    for (final u in _unwatchers) u();
    _unwatchers.clear();

    final list = await MarketApiService().getMyOrders(phone: phone);
    prov.setAll(list);
    for (final o in prov.orders) {
      _unwatchers.add(_rt.watchOrderStatus(o['id'], onUpdate: (data) {
        prov.updateFromSocket(o['id'], data);
      }));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final u in _unwatchers) u();
    _unwatchers.clear();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_TO_PICKUP':
      case 'READY':
        return 'Siap Diambil';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
      case 'REJECTED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'PROCESSING':
        return Colors.blue;
      case 'READY_TO_PICKUP':
      case 'READY':
        return Colors.green;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(num number) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(number);
  }

  String _getItemSummary(Map<String, dynamic> order) {
    final items = order['transactionItems'] as List<dynamic>? ?? [];
    if (items.isEmpty) return 'Tidak ada item';

    final summaries = items.map((item) {
      final qty = item['quantity'] ?? 1;
      // Robust Name Resolution
      String name = 'Item';
      if (item['productName'] != null) {
        name = item['productName'];
      } else if (item['name'] != null) {
        name = item['name'];
      } else if (item['product'] is Map) {
        name = item['product']['name'] ?? 'Item';
      }
      return '$qty x $name';
    }).toList();

    if (summaries.length <= 2) {
      return summaries.join(', ');
    } else {
      return '${summaries.take(2).join(', ')} +${summaries.length - 2} lainnya';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_phone != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() => _loading = true);
                await _initialLoad();
              },
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_phone != null) await _initialLoad();
        },
        child: Consumer<OrdersProvider>(
          builder: (ctx, prov, _) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_phone == null) {
              return _buildLoginView();
            }
            if (prov.orders.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada pesanan aktif',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final o = prov.orders[i];
                final status = o['orderStatus'] ?? 'PENDING';
                final statusText = _getStatusText(status);
                final statusColor = _getStatusColor(status);
                final total = o['totalAmount'] ?? 0;
                final storeName = o['store']?['name'] ?? 'Toko';
                final date = o['createdAt'] != null
                    ? DateTime.tryParse(o['createdAt'].toString())
                    : null;
                final dateStr =
                    date != null ? DateFormat('dd MMM HH:mm').format(date) : '';

                final items = o['transactionItems'] as List<dynamic>? ?? [];
                // Get first product image if available
                String? firstImage;
                if (items.isNotEmpty) {
                  final firstItem = items.first;
                  final product = firstItem['product'];
                  if (product is Map) {
                    final raw = product['imageUrl'] ?? product['image'];
                    if (raw != null) {
                      firstImage =
                          MarketApiService().resolveFileUrl(raw.toString());
                    }
                  }
                }

                return InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: o))),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Store Name & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.store,
                                      size: 18, color: Color(0xFFE07A5F)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      storeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Item Summary
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: firstImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        firstImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                                size: 24),
                                      ),
                                    )
                                  : const Icon(Icons.shopping_bag_outlined,
                                      color: Colors.grey, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getItemSummary(o),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (dateStr.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        dateStr,
                                        style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Footer: Total Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Belanja',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                                Text(
                                  _formatCurrency(total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFFE07A5F)),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Masukkan nomor WhatsApp',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Nomor ini dipakai untuk menampilkan riwayat pesanan kamu.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final phone = _phoneCtrl.text.trim();
            if (phone.isEmpty) return;
            setState(() => _loading = true);
            await _savePhone(phone);
            await _initialLoad();
          },
          child: const Text('Lihat Pesanan'),
        ),
      ],
    );
  }
}
