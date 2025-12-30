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
          // Play Sound or Haptic (Optional)
          await OrderService().scanQrOrder(code);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Scan Berhasil! Pesanan Terverifikasi.'),
                backgroundColor: Colors.green));
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context, true);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Gagal: $e'), backgroundColor: Colors.red));
            // Delay before allowing next scan to prevent spam
            await Future.delayed(const Duration(seconds: 2));
            setState(() => _isProcessing = false);
          }
        }
        break; // Process only first valid code
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Pickup',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFBF092F),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
            Color(0xFF9F0013),
            Color(0xFFBF092F),
            Color(0xFFE11D48)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
