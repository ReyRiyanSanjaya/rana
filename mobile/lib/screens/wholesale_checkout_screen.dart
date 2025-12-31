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
  final TextEditingController _addressController = TextEditingController();
  bool _applyingCoupon = false;
  bool _isPickup = false;
  File? _transferProof;
  double _shippingCost = 0;
  Map<String, dynamic>? _tenant;
  bool _paymentInitialized = false;

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
  void initState() {
    super.initState();
    _loadTenantInfo();
  }

  Future<void> _loadTenantInfo() async {
    final db = DatabaseHelper.instance;
    Map<String, dynamic>? tenant = await db.getTenantInfo();
    if (tenant == null) {
      try {
        final profile = await ApiService().getProfile();
        final tenantId = (profile['tenantId'] ?? profile['id'])?.toString();
        if (tenantId != null && tenantId.isNotEmpty) {
          await db.upsertTenant({
            'id': tenantId,
            'businessName': profile['businessName']?.toString(),
            'email': profile['email']?.toString(),
            'phone': (profile['waNumber'] ?? profile['phone'])?.toString(),
            'address': profile['address']?.toString(),
          });
          tenant = await db.getTenantInfo();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _tenant = tenant;
      final addr = tenant?['address']?.toString() ?? '';
      if (_addressController.text.trim().isEmpty) _addressController.text = addr;
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<WholesaleCartProvider>(context);
    final fmtPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (!_paymentInitialized && cart.paymentMethods.isNotEmpty) {
      _paymentInitialized = true;
      _paymentMethod = cart.paymentMethods.first;
    }

    double shippingCost = _isPickup ? 0 : _shippingCost;
    double serviceFee = cart.serviceFee;

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
        backgroundColor: const Color(0xFFD70677),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_tenant?['businessName']?.toString().trim().isNotEmpty ?? false)
                                  ? _tenant!['businessName'].toString()
                                  : 'Toko',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            if ((_tenant?['phone']?.toString().trim().isNotEmpty ?? false))
                              Text(
                                _tenant!['phone'].toString(),
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Pengiriman',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    minLines: 2,
                    maxLines: 3,
                  ),
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
                            ? Colors.blue.withValues(alpha: 26)
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
                            ? Colors.blue.withValues(alpha: 26)
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
                      color: Colors.orange.withValues(alpha: 26),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Isi ongkos kirim (Rp)',
                            isDense: true,
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[900]),
                          onChanged: (v) {
                            final parsed = double.tryParse(v.replaceAll(',', '').trim()) ?? 0;
                            setState(() => _shippingCost = parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fmtPrice.format(shippingCost),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
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
                                final code = _couponController.text;
                                setState(() => _applyingCoupon = true);
                                try {
                                  await cart.applyCoupon(code);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Voucher berhasil dipasang"),
                                          backgroundColor: Colors.green));
                                  _couponController.clear();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red));
                                } finally {
                                  if (mounted) {
                                    setState(() => _applyingCoupon = false);
                                  }
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
            if (_paymentMethod.contains('Transfer')) ...[
              const SizedBox(height: 12),
              _buildSectionHeader('Bukti Transfer'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _transferProof == null
                            ? 'Belum ada bukti'
                            : _transferProof!.path.split(Platform.pathSeparator).last,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _transferProof == null ? Colors.grey : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickTransferProof,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                    if (_transferProof != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => setState(() => _transferProof = null),
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Hapus',
                      ),
                    ]
                  ],
                ),
              ),
            ],
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

                          final db = DatabaseHelper.instance;
                          final latestTenant = _tenant ?? await db.getTenantInfo();
                          final tenantId = latestTenant?['id']?.toString();
                          if (tenantId == null || tenantId.isEmpty) {
                            throw Exception('Tenant tidak ditemukan. Silakan login ulang.');
                          }

                          final address = _addressController.text.trim();
                          if (address.isEmpty) {
                            throw Exception('Alamat pengiriman wajib diisi.');
                          }

                          String? proofUrl;
                          if (_transferProof != null) {
                            proofUrl = await ApiService()
                                .uploadTransferProof(_transferProof!.path);
                          }

                          await cart.checkout(
                              tenantId,
                              _paymentMethod,
                              address,
                              shippingCost,
                              serviceFee,
                              proofUrl: proofUrl);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Pesanan Berhasil Dibuat!"),
                                  backgroundColor: Colors.green));

                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      WholesaleOrderListScreen(
                                          tenantId: tenantId)));
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Gagal membuat pesanan: $e'),
                              backgroundColor: Colors.red));
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFD70677)),
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
            color: isSelected ? Colors.blue.withValues(alpha: 26) : Colors.white,
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
