import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Berlangganan Rana', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Plan Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 48),
                  const SizedBox(height: 16),
                  Text('Rana Premium', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Rp 99.000 / bulan', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 24),
                  _buildBenefitRow('✅ Unlimited Produk'),
                  _buildBenefitRow('✅ Rana AI Smart Insight'),
                  _buildBenefitRow('✅ Laporan Bisnis Lengkap'),
                  _buildBenefitRow('✅ Multi-User'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Status Handling
            if (sub.status == SubscriptionStatus.active)
              _buildActiveState()
            else if (sub.status == SubscriptionStatus.pending)
              _buildPendingState()
            else
              _buildPaymentSection(context, sub),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)))]),
    );
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('Akun Anda Premium!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Terima kasih telah berlangganan.', style: GoogleFonts.poppins(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPendingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.av_timer, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text('Menunggu Verifikasi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Admin sedang memverifikasi pembayaran Anda. Mohon tunggu 1x24 jam.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, SubscriptionProvider sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Transfer Pembayaran', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BCA: 123-456-7890', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('a.n. PT Rana Nusantara', style: GoogleFonts.poppins(color: Colors.grey)),
              const Divider(height: 24),
              Text('Mandiri: 098-765-4321', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('a.n. PT Rana Nusantara', style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            // Simulate Upload Logic
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Simulasi Upload'),
                content: const Text('Anggap user sudah upload bukti transfer. Lanjutkan?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  FilledButton(
                    onPressed: () {
                      sub.requestUpgrade();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti terkirim! Menunggu verifikasi.')));
                    }, 
                    child: const Text('Kirim Bukti')
                  ),
                ],
              )
            );
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Upload Bukti Transfer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
