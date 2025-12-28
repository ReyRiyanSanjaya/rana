import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  XFile? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = picked);
  }
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<SubscriptionProvider>(context, listen: false).fetchPackages()
    );
  }

  String _formatPrice(dynamic price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
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
            // Show subscription status info if available
            if (sub.daysRemaining != null) ...[
              _buildSubscriptionInfo(sub),
              const SizedBox(height: 24),
            ],
            
            if (sub.isLoading)
               const Center(child: CircularProgressIndicator())
            else if (sub.packages.isEmpty)
               Center(child: Text("Belum ada paket tersedia", style: GoogleFonts.poppins()))
            else
               ...sub.packages.map((pkg) => _buildPackageCard(pkg, sub)).toList(),
            
            const SizedBox(height: 32),
            
            // Status Handling
            if (sub.status == SubscriptionStatus.active)
              _buildActiveState(sub)
            else if (sub.status == SubscriptionStatus.pending)
              _buildPendingState()
            else
              _buildPaymentSection(context, sub),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo(SubscriptionProvider sub) {
    final isActive = sub.status == SubscriptionStatus.active;
    final isTrial = sub.status == SubscriptionStatus.trial;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : (isTrial ? Colors.blue.shade50 : Colors.orange.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green.shade200 : (isTrial ? Colors.blue.shade200 : Colors.orange.shade200)),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.verified : (isTrial ? Icons.timer : Icons.warning),
            color: isActive ? Colors.green : (isTrial ? Colors.blue : Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Premium Active' : (isTrial ? 'Trial Period' : 'Status'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${sub.daysRemaining} hari tersisa',
                  style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(dynamic pkg, SubscriptionProvider sub) {
    final isSelected = sub.selectedPackage?['id'] == pkg['id'];
    final benefits = (pkg['benefits'] as List<dynamic>?) ?? [];
    final price = pkg['price'];
    final durationDays = pkg['durationDays'] ?? 30;
    
    return GestureDetector(
      onTap: () => sub.selectPackage(Map<String, dynamic>.from(pkg)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFEF5350)])
            : LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade600]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg['name'] ?? 'Paket',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '$durationDays hari',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatPrice(price),
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              ...benefits.take(5).map((b) => _buildBenefitRow('✓ $b')),
            ],
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Dipilih',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildActiveState(SubscriptionProvider sub) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('Akun Anda Premium!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Terima kasih telah berlangganan.', style: GoogleFonts.poppins(color: Colors.grey)),
        if (sub.expiryDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Berakhir: ${sub.expiryDate!.day}/${sub.expiryDate!.month}/${sub.expiryDate!.year}',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
          ),
        ],
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
    final hasSelectedPackage = sub.selectedPackage != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show selected package summary
        if (hasSelectedPackage) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.selectedPackage!['name'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_formatPrice(sub.selectedPackage!['price'])} / ${sub.selectedPackage!['durationDays']} hari',
                        style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilih paket di atas terlebih dahulu',
                    style: GoogleFonts.poppins(color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
        
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
        
        // Image Picker UI
        Text('Bukti Transfer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: hasSelectedPackage ? _pickImage : null,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: hasSelectedPackage ? Colors.grey.shade50 : Colors.grey.shade200
            ),
            child: _imageFile == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cloud_upload, color: hasSelectedPackage ? Colors.grey : Colors.grey[400], size: 40),
                  Text(
                    hasSelectedPackage ? 'Tap untuk upload bukti' : 'Pilih paket dulu',
                    style: TextStyle(color: hasSelectedPackage ? Colors.grey : Colors.grey[400])
                  )
                ])
              : ClipRRect(
                  borderRadius: BorderRadius.circular(11), 
                  child: kIsWeb 
                    ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                ),
          ),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: (_imageFile == null || !hasSelectedPackage) ? null : () async {
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
            backgroundColor: (_imageFile == null || !hasSelectedPackage) ? Colors.grey : const Color(0xFFD32F2F)
          ),
          child: sub.isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Text('Kirim Bukti Transfer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
