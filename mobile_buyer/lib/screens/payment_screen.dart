import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:rana_market/screens/order_detail_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;

  const PaymentScreen({super.key, required this.orderId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  String? _qrisUrl;
  String? _bankInfo;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      final info = await MarketApiService().getPaymentInfo();
      setState(() {
        _qrisUrl = info['qrisUrl'];
        _bankInfo = info['bankInfo'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Eror: $e')));
      }
    }
  }

  Future<void> _confirmPayment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true || !context.mounted) return;
    }
    setState(() => _isLoading = true);
    try {
      // Logic for File Upload would go here.
      // For now, we confirm directly.
      final order = await MarketApiService().confirmPayment(widget.orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran Dikonfirmasi!')));
        Navigator.pop(context); // Close Payment
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Total Pembayaran',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Rp ${widget.amount}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo)),
                  const SizedBox(height: 32),
                  const Text('Ambil di Toko',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                      'Setelah pembayaran terkonfirmasi, tunjukkan Kode QR ke kasir untuk mengambil pesanan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  const Text('Scan QRIS Platform',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (_qrisUrl != null)
                    Image.network(
                      _qrisUrl!,
                      height: 250,
                      loadingBuilder: (ctx, child, prog) => prog == null
                          ? child
                          : const CircularProgressIndicator(),
                      errorBuilder: (ctx, _, __) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Atau Transfer Bank:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_bankInfo ?? '-', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _confirmPayment,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('SAYA SUDAH BAYAR'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bayar Nanti'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
