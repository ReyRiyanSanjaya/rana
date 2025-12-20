import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/screens/payment_screen.dart'; // [NEW]

class MarketCartScreen extends StatefulWidget {
  const MarketCartScreen({super.key});

  @override
  State<MarketCartScreen> createState() => _MarketCartScreenState();
}

class _MarketCartScreenState extends State<MarketCartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isPickup = false; // [NEW]

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
                    Text('Pesanan dari: ${cart.activeStoreName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    ...cart.items.values.map((item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text('Rp ${item.price} x ${item.quantity}'),
                      trailing: Text('Rp ${item.price * item.quantity}'),
                    )),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           Text('Rp ${cart.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
                child: Column(
                  children: [
                    // [NEW] Fulfillment Toggle
                     SwitchListTile(
                       title: const Text('Ambil di Toko (Pickup)'),
                       subtitle: const Text('Tanpa ongkir, scan QR di kasir'),
                       value: _isPickup,
                       onChanged: (val) => setState(() => _isPickup = val),
                     ),
                    const SizedBox(height: 16),
                    if (!_isPickup) ...[
                      const Text('Informasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Penerima', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor WhatsApp', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: _addrCtrl, decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()), maxLines: 2),
                    ] 
                    else 
                      const Text('Anda akan mendapatkan Kode QR untuk di scan di toko.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 24),
                    SizedBox(
                       width: double.infinity,
                       child: FilledButton(
                         onPressed: _isLoading ? null : () async {
                            // Validation
                            if (!_isPickup && (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _addrCtrl.text.isEmpty)) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi alamat pengiriman')));
                               return;
                            }
                            if (_isPickup && (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty)) {
                               // Still need basic contacts
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nama dan kontak')));
                               return;
                            }

                            setState(() => _isLoading = true);
                            try {
                               // Submit and Get Order Data
                               final order = await cart.submitOrder(
                                 customerName: _nameCtrl.text,
                                 phone: _phoneCtrl.text,
                                 address: _isPickup ? '-' : _addrCtrl.text,
                                 isPickup: _isPickup
                               );
                               
                               if (context.mounted) {
                                 // Navigate to Payment
                                 Navigator.push(
                                   context, 
                                   MaterialPageRoute(
                                     builder: (_) => PaymentScreen(
                                       orderId: order['id'], 
                                       amount: (order['totalAmount'] as num).toDouble()
                                     )
                                   )
                                 );
                               }
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                         },
                         style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                         child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('BAYAR & PESAN'),
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
