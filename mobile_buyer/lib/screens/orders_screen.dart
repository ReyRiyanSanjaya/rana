import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/services/realtime_service.dart';
import 'package:rana_market/screens/order_detail_screen.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/screens/login_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) _initialLoad();
      if (!auth.isAuthenticated && mounted) setState(() => _loading = false);
    });
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
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pesanan Saya')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Masuk untuk melihat pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Riwayat pesanan tersimpan di akun kamu.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        if (ok == true && context.mounted) {
                          setState(() => _loading = true);
                          await _initialLoad();
                        }
                      },
                      child: const Text('Masuk'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
