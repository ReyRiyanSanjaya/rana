import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // [NEW]
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  File? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<SubscriptionProvider>(context, listen: false).fetchPackages()
    );
  }

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
            if (sub.isLoading)
               const Center(child: CircularProgressIndicator())
            else if (sub.packages.isEmpty)
               Center(child: Text("Belum ada paket tersedia", style: GoogleFonts.poppins()))
            else
               ...sub.packages.map((pkg) => _buildPackageCard(pkg)).toList(),
            
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

  Widget _buildPackageCard(dynamic pkg) {
    final benefits = (pkg['benefits'] as List<dynamic>?) ?? [];
    final price = pkg['price'];
    final fmtPrice = "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          Text(pkg['name'] ?? 'Paket', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('$fmtPrice / ${pkg['interval'] ?? 'bulan'}', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 24),
          ...benefits.map((b) => _buildBenefitRow('✅ $b')),
        ],
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
        const SizedBox(height: 24),
        
        // Image Picker UI
        Text('Bukti Transfer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50
            ),
            child: _imageFile == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.cloud_upload, color: Colors.grey, size: 40), Text('Tap untuk upload bukti', style: TextStyle(color: Colors.grey))])
              : ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_imageFile!, fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: _imageFile == null ? null : () async {
              try {
                await sub.requestUpgrade(_imageFile!);
                if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti terkirim! Menunggu verifikasi.'), backgroundColor: Colors.green));
                }
              } catch (e) {
                  if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
                  }
              }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: _imageFile == null ? Colors.grey : Colors.blue
          ),
          child: sub.isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Text('Kirim Bukti Transfer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
