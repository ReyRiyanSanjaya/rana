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
      appBar: AppBar(
        title: const Text('Scan QR Pickup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFBF092F),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter
            )
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2, // Scan is index 2
        onDestinationSelected: (idx) {
           if (idx == 0) {
              Navigator.of(context).popUntil((route) => route.isFirst);
           }
           // Handle others if needed
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.red.shade100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
