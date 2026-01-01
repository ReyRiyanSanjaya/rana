import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/services/realtime_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final RealtimeService _realtime = RealtimeService();
  late Map<String, dynamic> _order;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _realtime.watchOrderStatus(_order['id'], onUpdate: (data) {
      if (!mounted) return;
      setState(() {
        _order = {..._order, ...data};
      });
    });
  }

  Future<void> _openMapsForOrderStore() async {
    final store = _order['store'];
    String? address;
    double? lat;
    double? long;
    if (store is Map) {
      address = (store['address'] ?? store['location'] ?? store['alamat'])
          ?.toString();
      final dynamic latV = store['latitude'] ?? store['lat'];
      final dynamic longV = store['longitude'] ?? store['long'] ?? store['lng'];
      if (latV is num) lat = latV.toDouble();
      if (longV is num) long = longV.toDouble();
    }
    final query = (lat != null && long != null)
        ? '${lat.toStringAsFixed(6)},${long.toStringAsFixed(6)}'
        : (address ?? '');
    if (query.trim().isEmpty) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _refreshOrder() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final fromUser =
          (auth.user?['phone'] ?? auth.user?['phoneNumber'])?.toString().trim();
      String? phone =
          (fromUser != null && fromUser.isNotEmpty) ? fromUser : null;
      if (phone == null) {
        final prefs = await SharedPreferences.getInstance();
        final p = (prefs.getString('buyer_phone') ?? '').trim();
        if (p.isNotEmpty) phone = p;
      }
      if (phone == null) return;
      final list = await MarketApiService().getMyOrders(phone: phone);
      final id = _order['id'];
      final found = list.whereType<Map>().cast<Map>().firstWhere(
            (e) => e['id'] == id,
            orElse: () => const {},
          );
      if (found.isNotEmpty && mounted) {
        setState(() {
          _order = {..._order, ...Map<String, dynamic>.from(found)};
        });
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['orderStatus'] ?? 'PENDING';
    final type = _order['fulfillmentType'] ?? 'PICKUP';
    final pickupCode = _order['pickupCode'];
    final items = _order['transactionItems'] ?? [];
    final store = _order['store'];
    final storeName = (store is Map ? store['name'] : null)?.toString();
    final storeAddress = (store is Map
            ? (store['address'] ?? store['location'] ?? store['alamat'])
            : null)
        ?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              Card(
                color: status == 'COMPLETED'
                    ? const Color(0xFF81B29A).withOpacity(0.1)
                    : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                          status == 'COMPLETED'
                              ? Icons.check_circle
                              : Icons.access_time,
                          size: 48,
                          color: status == 'COMPLETED'
                              ? Color(0xFF81B29A)
                              : const Color(0xFFE07A5F)),
                      const SizedBox(height: 8),
                      Text(status,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Order ID: ${_order['id']}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              if (type == 'PICKUP') ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lokasi Pengambilan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if ((storeName ?? '').trim().isNotEmpty)
                          Text(storeName!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        if ((storeAddress ?? '').trim().isNotEmpty)
                          Text(storeAddress!,
                              style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _openMapsForOrderStore,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Buka Maps'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // QR Code for Pickup
              if (type == 'PICKUP' &&
                  status != 'COMPLETED' &&
                  status != 'CANCELLED')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Wajib Scan QR saat Pengambilan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text(
                          'Tunjukkan QR ini ke kasir. QR akan di-scan oleh aplikasi merchant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (_order['paymentStatus'] != 'PAID')
                        const Text(
                            'Silakan selesaikan pembayaran untuk mendapatkan QR.',
                            textAlign: TextAlign.center)
                      else if (status != 'READY_TO_PICKUP')
                        Column(
                          children: [
                            const Text(
                              'Pesanan sedang disiapkan toko. QR akan muncul saat pesanan siap diambil.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _refreshing ? null : _refreshOrder,
                              icon: const Icon(Icons.refresh),
                              label:
                                  Text(_refreshing ? 'Memuat...' : 'Refresh'),
                            ),
                          ],
                        )
                      else if (pickupCode == null)
                        Column(
                          children: [
                            const Text('Menyiapkan QR...',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _refreshing ? null : _refreshOrder,
                              icon: const Icon(Icons.refresh),
                              label:
                                  Text(_refreshing ? 'Memuat...' : 'Refresh'),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            QrImageView(
                              data: pickupCode.toString().trim(),
                              version: QrVersions.auto,
                              size: 220.0,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                                'Jangan bagikan QR ini. Kasir akan memverifikasi keabsahan QR.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Items:",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final prodName = item['product'] != null
                      ? item['product']['name']
                      : 'Product #${item['productId']}';
                  return ListTile(
                    title: Text(prodName),
                    trailing: Text('x${item['quantity']}'),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
