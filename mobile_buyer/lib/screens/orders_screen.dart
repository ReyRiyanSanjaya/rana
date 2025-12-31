import 'package:flutter/material.dart';
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
    final list = await MarketApiService().getMyOrders(phone: phone);
    prov.setAll(list);
    for (final o in prov.orders) {
      _rt.watchOrderStatus(o['id'], onUpdate: (data) {
        prov.updateFromSocket(o['id'], data);
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _rt.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_phone != null) await _initialLoad();
        },
        child: Consumer<OrdersProvider>(
          builder: (ctx, prov, _) {
            if (_loading) return const Center(child: CircularProgressIndicator());
            if (_phone == null) {
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
            if (prov.orders.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada pesanan')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final o = prov.orders[i];
                final status = o['orderStatus'] ?? 'PENDING';
                final total = o['totalAmount'] ?? 0;
                return ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white,
                  title: Text('Order ${o['id'].toString().substring(0, 8)}'),
                  subtitle: Text('Status: $status'),
                  trailing: Text('Rp $total',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: o))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
