import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:flutter/services.dart';

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
  XFile? _transferProof;
  double _shippingCost = 0;
  Map<String, dynamic>? _tenant;
  bool _paymentInitialized = false;

  // Simulated distance for "Real Data" integration
  final double _simulatedDistance = 5.0; // 5 KM

  Future<void> _pickTransferProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _transferProof = pickedFile;
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
      if (_addressController.text.trim().isEmpty)
        _addressController.text = addr;
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

    // Calculate Shipping Cost based on Admin Settings
    if (_isPickup) {
      _shippingCost = 0;
    } else {
      _shippingCost = _simulatedDistance * cart.shippingCostPerKm;
    }

    double serviceFee = cart.serviceFee;
    double displayDiscount = cart.discountAmount;

    if (cart.isFreeShipping) {
      displayDiscount = _shippingCost;
    }

    double total =
        cart.totalAmount + _shippingCost + serviceFee - displayDiscount;
    if (total < 0) total = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Pengiriman & Pembayaran',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFFE07A5F))),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        elevation: 0,
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
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFE07A5F),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_tenant?['businessName']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ??
                                      false)
                                  ? _tenant!['businessName'].toString()
                                  : 'Toko',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                            if ((_tenant?['phone']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ??
                                false))
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
                      labelText: 'Alamat Lengkap',
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: !_isPickup
                            ? const Color(0xFFE07A5F).withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color: !_isPickup
                                ? const Color(0xFFE07A5F)
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.local_shipping,
                              color: Color(0xFFE07A5F), size: 32),
                          const SizedBox(height: 8),
                          Text('Dikirim',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: !_isPickup
                                      ? const Color(0xFFE07A5F)
                                      : Colors.grey)),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isPickup
                            ? const Color(0xFFE07A5F).withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color: _isPickup
                                ? const Color(0xFFE07A5F)
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.store,
                              color: Color(0xFFE07A5F), size: 32),
                          const SizedBox(height: 8),
                          Text('Ambil Sendiri',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: _isPickup
                                      ? const Color(0xFFE07A5F)
                                      : Colors.grey)),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biaya Pengiriman',
                              style: GoogleFonts.poppins(color: Colors.grey)),
                          Text(
                              'Estimasi Jarak: ${_simulatedDistance.toStringAsFixed(0)} KM',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFE07A5F))),
                        ],
                      ),
                      Text(
                        fmtPrice.format(_shippingCost),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE07A5F),
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
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: Color(0xFFE07A5F)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: cart.couponCode != null
                        ? Text("Digunakan: ${cart.couponCode}",
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF81B29A),
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
                        icon: const Icon(Icons.close, color: Color(0xFFE07A5F)),
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
                                          backgroundColor: Color(0xFF81B29A)));
                                  _couponController.clear();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll('Exception: ', '')),
                                          backgroundColor: Color(0xFFE07A5F)));
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
                            : const Text('Pakai',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE07A5F))))
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Payment
            _buildSectionHeader('Metode Pembayaran'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: cart.paymentMethods
                    .map((method) => _buildPaymentOption(method))
                    .toList(),
              ),
            ),
            if (_paymentMethod.contains('Transfer')) ...[
              const SizedBox(height: 12),
              if (cart.bankName.isNotEmpty && cart.bankAccountNumber.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE07A5F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Silakan transfer ke:',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cart.bankName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold)),
                              Text(cart.bankAccountNumber,
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE07A5F))),
                              if (cart.bankAccountName.isNotEmpty)
                                Text('a.n. ${cart.bankAccountName}',
                                    style: GoogleFonts.poppins(fontSize: 14)),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: cart.bankAccountNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Nomor rekening disalin!"),
                                      duration: Duration(seconds: 1)));
                            },
                            icon: const Icon(Icons.copy,
                                color: Color(0xFFE07A5F)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              _buildSectionHeader('Bukti Transfer'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_transferProof != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _transferProof!.path,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_transferProof!.path),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _transferProof == null
                                ? 'Belum ada bukti'
                                : 'Bukti Terpilih',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _transferProof == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _pickTransferProof,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label:
                              Text(_transferProof == null ? 'Pilih' : 'Ganti'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE07A5F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 5. Summary
            _buildSectionHeader('Ringkasan Pembayaran'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: Column(
                children: [
                  _buildSummaryRow('Total Harga (${cart.itemCount} Barang)',
                      fmtPrice.format(cart.totalAmount)),
                  _buildSummaryRow(
                      'Ongkos Kirim', fmtPrice.format(_shippingCost)),
                  _buildSummaryRow(
                      'Biaya Layanan', fmtPrice.format(serviceFee)),
                  if (displayDiscount > 0)
                    _buildSummaryRow('Diskon Voucher',
                        '-${fmtPrice.format(displayDiscount)}',
                        color: const Color(0xFF81B29A)),
                  const Divider(height: 24),
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
                        // Check if transfer proof is needed
                        if (_paymentMethod.contains('Transfer') &&
                            _transferProof == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  "Mohon upload bukti transfer terlebih dahulu"),
                              backgroundColor: Color(0xFFE07A5F)));
                          return;
                        }

                        setState(() => _isProcessing = true);

                        try {
                          final db = DatabaseHelper.instance;
                          final latestTenant =
                              _tenant ?? await db.getTenantInfo();
                          final tenantId = latestTenant?['id']?.toString();
                          if (tenantId == null || tenantId.isEmpty) {
                            throw Exception(
                                'Tenant tidak ditemukan. Silakan login ulang.');
                          }

                          final address = _addressController.text.trim();
                          if (address.isEmpty) {
                            throw Exception('Alamat pengiriman wajib diisi.');
                          }

                          String? proofUrl;
                          if (_transferProof != null) {
                            // Upload proof first
                            try {
                              if (kIsWeb) {
                                final bytes =
                                    await _transferProof!.readAsBytes();
                                proofUrl = await ApiService()
                                    .uploadTransferProof(_transferProof!.path,
                                        fileBytes: bytes,
                                        fileName: _transferProof!.name);
                              } else {
                                proofUrl = await ApiService()
                                    .uploadTransferProof(_transferProof!.path);
                              }
                            } catch (e) {
                              throw Exception(
                                  'Gagal upload bukti transfer: ${e.toString().replaceAll("Exception: ", "")}');
                            }
                          }

                          await cart.checkout(tenantId, _paymentMethod, address,
                              _shippingCost, serviceFee,
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
                              content: Text(
                                  e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red));
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFE07A5F)),
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
            ),
            const SizedBox(height: 24),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE07A5F).withOpacity(0.05)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? const Color(0xFFE07A5F) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: isBold ? Colors.black : color ?? Colors.grey.shade600,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: GoogleFonts.poppins(
                  color:
                      isBold ? const Color(0xFFE07A5F) : color ?? Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }
}
