import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rana_merchant/services/order_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        final code = barcode.rawValue!;

        try {
          final order = await OrderService().scanQrOrder(code);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Scan berhasil! Pesanan sudah terverifikasi.'),
                backgroundColor: Colors.green));
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context, order);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Scan gagal, coba lagi ya. ($e)'),
                backgroundColor: Colors.red));
            await Future.delayed(const Duration(seconds: 2));
            setState(() => _isProcessing = false);
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Pickup',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE07A5F))),
        backgroundColor: const Color(0xFFFFF8F0),
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        centerTitle: true,
        elevation: 0,
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
