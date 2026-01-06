import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';
import 'package:rana_merchant/screens/subscription_screen.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 64, color: Colors.red.shade700),
            ),
            const SizedBox(height: 32),
            Text(
              'Akses Terkunci',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Masa uji coba atau paket berlangganan Anda telah habis.\n\nSilakan perbarui langganan untuk melanjutkan operasional toko.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Perpanjang Sekarang',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: sub.isLoading
                  ? null
                  : () async {
                      try {
                        await sub.codeCheckSubscription();
                        if (context.mounted && !sub.isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Status berhasil diperbarui!'),
                                  backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Gagal memuat status: $e'),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
              icon: sub.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red))
                  : Icon(Icons.refresh, color: Colors.red.shade900),
              label: Text(sub.isLoading ? 'Memuat...' : 'Refresh Status',
                  style: GoogleFonts.poppins(color: Colors.red.shade900)),
            )
          ],
        ),
      ),
    );
  }
}
