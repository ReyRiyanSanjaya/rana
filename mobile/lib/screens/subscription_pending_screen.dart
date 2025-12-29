import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';

class SubscriptionPendingScreen extends StatelessWidget {
  const SubscriptionPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
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
              child: const Icon(Icons.av_timer_rounded, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 32),
            Text(
              'Menunggu Verifikasi',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Terima kasih telah melakukan pembayaran. Admin kami sedang memverifikasi bukti transfer Anda.\n\nProses ini biasanya memakan waktu 1x24 jam.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: sub.isLoading ? null : () async {
                  try {
                    await sub.codeCheckSubscription();
                    if (context.mounted && sub.status == SubscriptionStatus.active) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selamat! Akun Anda sudah aktif.'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat status: $e')));
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: sub.isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : Text('Cek Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
             const SizedBox(height: 24),
             TextButton(
               onPressed: () {
                 // Optional: Logout or Contact Support
               },
               child: Text('Hubungi Bantuan', style: GoogleFonts.poppins(color: Colors.orange.shade900)),
             )
          ],
        ),
      ),
    );
  }
}
