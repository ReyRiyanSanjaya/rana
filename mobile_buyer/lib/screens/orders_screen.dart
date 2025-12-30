import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final prov = Provider.of<OrdersProvider>(context, listen: false);
    final list = await MarketApiService().getMyOrders();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: RefreshIndicator(
        onRefresh: _initialLoad,
        child: Consumer<OrdersProvider>(
          builder: (ctx, prov, _) {
            if (_loading) return const Center(child: CircularProgressIndicator());
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
