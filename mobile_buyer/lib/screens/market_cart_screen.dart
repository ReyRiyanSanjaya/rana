import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/screens/payment_screen.dart'; // [NEW]
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketCartScreen extends StatefulWidget {
  const MarketCartScreen({super.key});

  @override
  State<MarketCartScreen> createState() => _MarketCartScreenState();
}

class _MarketCartScreenState extends State<MarketCartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _openStoreMaps(MarketCartProvider cart) async {
    final lat = cart.activeStoreLat;
    final long = cart.activeStoreLong;
    final address = cart.activeStoreAddress;
    final query = (lat != null && long != null)
        ? '${lat.toStringAsFixed(6)},${long.toStringAsFixed(6)}'
        : (address ?? '');
    if (query.trim().isEmpty) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<MarketCartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Belanja')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang Kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Pesanan dari: ${cart.activeStoreName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if ((cart.activeStoreAddress ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cart.activeStoreAddress!,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (cart.activeStoreLat != null ||
                          cart.activeStoreAddress != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => _openStoreMaps(cart),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Buka Maps'),
                          ),
                        ),
                      ],
                      const Divider(),
                      ...cart.items.values.map((item) => ListTile(
                            title: Text(item.name),
                            subtitle:
                                Text('Rp ${item.price} x ${item.quantity}'),
                            trailing: Text('Rp ${item.price * item.quantity}'),
                          )),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bayar',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('Rp ${cart.totalAmount}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ]),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Informasi Pengambilan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Nama', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Nomor WhatsApp',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      const Text(
                          'Setelah bayar, Anda akan mendapatkan Kode QR untuk di-scan di kasir.',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final auth = Provider.of<AuthProvider>(
                                      context,
                                      listen: false);
                                  if (!auth.isAuthenticated) {
                                    final ok = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()),
                                    );
                                    if (ok != true || !context.mounted) return;
                                    final refreshedAuth =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    if (_nameCtrl.text.isEmpty) {
                                      _nameCtrl.text =
                                          (refreshedAuth.user?['name'] ?? '')
                                              .toString();
                                    }
                                    if (_phoneCtrl.text.isEmpty) {
                                      _phoneCtrl.text =
                                          (refreshedAuth.user?['phone'] ?? '')
                                              .toString();
                                    }
                                  }
                                  // Validation
                                  if (_nameCtrl.text.isEmpty ||
                                      _phoneCtrl.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Mohon isi nama dan kontak')));
                                    return;
                                  }

                                  setState(() => _isLoading = true);
                                  try {
                                    final storeName = cart.activeStoreName;
                                    final storeAddress =
                                        cart.activeStoreAddress;
                                    final storeLat = cart.activeStoreLat;
                                    final storeLong = cart.activeStoreLong;
                                    // Submit and Get Order Data
                                    final order = await cart.submitOrder(
                                      customerName: _nameCtrl.text,
                                      phone: _phoneCtrl.text,
                                    );
                                    if (storeName != null) {
                                      order['store'] = {
                                        'name': storeName,
                                        if (storeAddress != null)
                                          'address': storeAddress,
                                        if (storeLat != null)
                                          'latitude': storeLat,
                                        if (storeLong != null)
                                          'longitude': storeLong,
                                      };
                                    }

                                    if (context.mounted) {
                                      // Add to orders list
                                      Provider.of<OrdersProvider>(context,
                                              listen: false)
                                          .add(order);
                                      // Navigate to Payment
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => PaymentScreen(
                                                  orderId: order['id'],
                                                  amount: (order['totalAmount']
                                                          as num)
                                                      .toDouble())));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Gagal: $e')));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('BAYAR & AMBIL'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
