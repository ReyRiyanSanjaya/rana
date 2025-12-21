import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

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
          await ApiService().scanQrOrder(code);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Verified! Saldo Masuk.'), backgroundColor: Colors.green));
            Navigator.pop(context, true); // Return success
          }
        } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
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
      appBar: AppBar(title: const Text('Scan QR Pickup')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
