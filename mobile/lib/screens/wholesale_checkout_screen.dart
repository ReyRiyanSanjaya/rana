import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';

class WholesaleCheckoutScreen extends StatefulWidget {
  const WholesaleCheckoutScreen({super.key});

  @override
  State<WholesaleCheckoutScreen> createState() => _WholesaleCheckoutScreenState();
}

class _WholesaleCheckoutScreenState extends State<WholesaleCheckoutScreen> {
  String _paymentMethod = 'Transfer Bank (BCA)';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<WholesaleCartProvider>(context);
    final fmtPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double shippingCost = 15000;
    double total = cart.totalAmount + shippingCost;

    return Scaffold(
      appBar: AppBar(title: Text('Pengiriman & Pembayaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Address
            _buildSectionHeader('Alamat Pengiriman'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toko Kelontong Berkah (Bpk. Riyan)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Text('Jl. Sudirman No. 45, Jakarta Pusat', style: GoogleFonts.poppins(color: Colors.grey)),
                        Text('0812-3456-7890', style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: (){}, child: const Text('Ubah'))
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Shipping
            _buildSectionHeader('Ekspedisi'),
            Container(
               padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                   const Icon(Icons.local_shipping, color: Colors.orange),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text('Kargo SiCepat (2-3 Hari)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          Text('Rp 15.000 (30 Kg)', style: GoogleFonts.poppins(color: Colors.grey)),
                       ],
                     ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Payment
            _buildSectionHeader('Metode Pembayaran'),
            Column(
              children: [
                _buildPaymentOption('Transfer Bank (BCA)'),
                _buildPaymentOption('Transfer Bank (Mandiri)'),
                _buildPaymentOption('Bayar di Tempat (COD)'),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Summary
            _buildSectionHeader('Ringkasan Pembayaran'),
             Container(
              padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
               child: Column(
                 children: [
                   _buildSummaryRow('Total Harga (${cart.itemCount} Barang)', fmtPrice.format(cart.totalAmount)),
                   _buildSummaryRow('Ongkos Kirim', fmtPrice.format(shippingCost)),
                   const Divider(),
                   _buildSummaryRow('Total Tagihan', fmtPrice.format(total), isBold: true),
                 ],
               ),
             ),
             const SizedBox(height: 32),

             // Button
             SizedBox(
               width: double.infinity,
               child: FilledButton(
                 onPressed: _isProcessing ? null : () async {
                   setState(() => _isProcessing = true);
                   await Future.delayed(const Duration(seconds: 2)); // Simulate API
                   
                   if(mounted) {
                     cart.clear();
                     showDialog(
                       context: context,
                       barrierDismissible: false,
                       builder: (_) => AlertDialog(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         content: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.check_circle, size: 80, color: Colors.green),
                             const SizedBox(height: 16),
                             Text('Pesanan Berhasil Dibuat!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                             const SizedBox(height: 8),
                             Text('Silakan lakukan pembayaran sesuai instruksi yang dikirim ke WhatsApp Anda.', style: GoogleFonts.poppins(color: Colors.grey), textAlign: TextAlign.center),
                             const SizedBox(height: 24),
                             FilledButton(onPressed: () {
                               Navigator.pop(context); // Close dialog
                               Navigator.pop(context); // Close checkout
                               Navigator.pop(context); // Close cart
                             }, child: const Text('KEMBALI KE BERANDA'))
                           ],
                         ),
                       )
                     );
                   }
                   setState(() => _isProcessing = false);
                 },
                 style: FilledButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   backgroundColor: Colors.blue.shade900
                 ),
                 child: _isProcessing 
                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                   : const Text('BUAT PESANAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentOption(String title) {
    return RadioListTile(
      value: title,
      groupValue: _paymentMethod,
      onChanged: (val) => setState(() => _paymentMethod = val.toString()),
      title: Text(title, style: GoogleFonts.poppins()),
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blue.shade900,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: isBold ? Colors.black : Colors.grey.shade700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: GoogleFonts.poppins(color: isBold ? Colors.blue.shade900 : Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
