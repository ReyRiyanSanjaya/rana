import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';

import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';

import 'package:rana_merchant/data/local/database_helper.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class WholesaleCheckoutScreen extends StatefulWidget {
  const WholesaleCheckoutScreen({super.key});

  @override
  State<WholesaleCheckoutScreen> createState() =>
      _WholesaleCheckoutScreenState();
}

class _WholesaleCheckoutScreenState extends State<WholesaleCheckoutScreen> {
  String _paymentMethod = 'Transfer Bank (BCA)';
  bool _isProcessing = false;
  final TextEditingController _couponController = TextEditingController();
  bool _applyingCoupon = false;
  bool _isPickup = false;
  File? _transferProof;

  Future<void> _pickTransferProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _transferProof = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<WholesaleCartProvider>(context);
    final fmtPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Mock Distance Logic (In real app, calculate from LatLng)
    double distanceKm = 5.2;
    double shippingCost = _isPickup ? 0 : distanceKm * cart.shippingCostPerKm;
    double serviceFee = cart.serviceFee;

    // Total calculation
    // Cart total - Discount + Shipping + Service Fee
    // Note: If discount is fixed/percentage, it applies to cart subtotal.
    // If free shipping, shipping is 0.
    // Backend logic: "totalAmount = subtotal + finalShippingCost - discountAmount".
    // Check provider discountAmount logic.
    // If FREE_SHIPPING type, provider sets discountAmount = 0 (based on my validation logic? No wait).
    // Let's recheck validation logic in Controller.
    // Controller: if FREE_SHIPPING, discount = 0.
    // BUT Controller createOrder: if FREE_SHIPPING, discountAmount = finalShippingCost.
    // So UI should display: Subtotal + Shipping (15k) - Discount (15k) = Total.
    // OR: Subtotal + Shipping (0) = Total.

    // Let's stick to visual:
    // Subtotal: 100
    // Shipping: 15
    // Voucher: -15 (if free ship) OR -10 (if discount)
    // Total: ...

    double displayDiscount = cart.discountAmount;

    if (cart.isFreeShipping) {
      displayDiscount = shippingCost;
    }

    double total =
        cart.totalAmount + shippingCost + serviceFee - displayDiscount;
    if (total < 0) total = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengiriman & Pembayaran',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Address
            _buildSectionHeader('Alamat Pengiriman'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Toko Kelontong Berkah (Bpk. Riyan)',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold)),
                        Text('Jl. Sudirman No. 45, Jakarta Pusat',
                            style: GoogleFonts.poppins(color: Colors.grey)),
                        Text('0812-3456-7890',
                            style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Ubah'))
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Shipping Method
            _buildSectionHeader('Metode Pengiriman'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPickup = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_isPickup
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color: !_isPickup
                                ? Colors.blue
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text('Dikirim',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      !_isPickup ? Colors.blue : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPickup = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isPickup
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color:
                                _isPickup ? Colors.blue : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.store, color: Colors.blue),
                          const SizedBox(height: 8),
                          Text('Ambil Sendiri',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isPickup ? Colors.blue : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!_isPickup)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "Ongkir dihitung berdasarkan jarak (${distanceKm}km)",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.orange[800])))
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // 3. Voucher
            _buildSectionHeader('Voucher / Kode Promo'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: cart.couponCode != null
                        ? Text("Digunakan: ${cart.couponCode}",
                            style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                        : TextField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                                hintText: 'Masukan kode voucher',
                                border: InputBorder.none,
                                isDense: true),
                          ),
                  ),
                  if (cart.couponCode != null)
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => cart.removeCoupon())
                  else
                    TextButton(
                        onPressed: _applyingCoupon
                            ? null
                            : () async {
                                if (_couponController.text.isEmpty) return;
                                setState(() => _applyingCoupon = true);
                                try {
                                  await cart
                                      .applyCoupon(_couponController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Voucher berhasil dipasang"),
                                          backgroundColor: Colors.green));
                                  _couponController.clear();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red));
                                } finally {
                                  setState(() => _applyingCoupon = false);
                                }
                              },
                        child: _applyingCoupon
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Pakai'))
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Payment
            _buildSectionHeader('Metode Pembayaran'),
            Column(
              children: cart.paymentMethods
                  .map((method) => _buildPaymentOption(method))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // 5. Summary
            _buildSectionHeader('Ringkasan Pembayaran'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildSummaryRow('Total Harga (${cart.itemCount} Barang)',
                      fmtPrice.format(cart.totalAmount)),
                  _buildSummaryRow(
                      'Ongkos Kirim', fmtPrice.format(shippingCost)),
                  _buildSummaryRow(
                      'Biaya Layanan', fmtPrice.format(serviceFee)),
                  if (displayDiscount > 0)
                    _buildSummaryRow('Diskon Voucher',
                        '-${fmtPrice.format(displayDiscount)}',
                        color: Colors.green),
                  const Divider(),
                  _buildSummaryRow('Total Tagihan', fmtPrice.format(total),
                      isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);

                        try {
                          // Check if transfer proof is needed
                          if (_paymentMethod.contains('Transfer') &&
                              _transferProof == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Mohon upload bukti transfer terlebih dahulu"),
                                    backgroundColor: Colors.red));
                            setState(() => _isProcessing = false);
                            return;
                          }

                          // Fetch real tenant ID
                          final db = DatabaseHelper.instance;
                          final tenant = await db.getTenantInfo();
                          final tenantId =
                              tenant != null ? tenant['id'] : 'demo-tenant-id';

                          String? proofUrl;
                          if (_transferProof != null) {
                            proofUrl = await ApiService()
                                .uploadTransferProof(_transferProof!.path);
                          }

                          await cart.checkout(
                              tenantId,
                              _paymentMethod,
                              'Jl. Sudirman No. 45, Jakarta Pusat',
                              shippingCost,
                              serviceFee,
                              proofUrl: proofUrl);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Pesanan Berhasil Dibuat!"),
                                    backgroundColor: Colors.green));

                            // Navigate to Order History
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        WholesaleOrderListScreen(
                                            tenantId: tenantId)));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Gagal membuat pesanan: $e'),
                                backgroundColor: Colors.red));
                          }
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade900),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('BUAT PESANAN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
      child: Text(title,
          style:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildPaymentOption(String title) {
    final isSelected = _paymentMethod == title;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
            border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.poppins(color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: isBold ? Colors.black : color ?? Colors.grey.shade700,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: isBold ? Colors.blue.shade900 : color ?? Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
