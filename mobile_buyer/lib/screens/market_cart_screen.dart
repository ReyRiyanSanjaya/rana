import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MarketCartScreen extends StatefulWidget {
  const MarketCartScreen({super.key});

  @override
  State<MarketCartScreen> createState() => _MarketCartScreenState();
}

class _MarketCartScreenState extends State<MarketCartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    _loadSavedContact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketCartProvider>().fetchServiceFee();
    });
  }

  void _prefillUserData() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.user != null) {
      final user = auth.user!;
      debugPrint('DEBUG: User Data in Cart: $user');
      if (_nameCtrl.text.isEmpty) {
        _nameCtrl.text = user['name'] ?? '';
      }
      if (_phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = user['phone'] ??
            user['phoneNumber'] ??
            user['telp'] ??
            user['hp'] ??
            user['mobile'] ??
            '';
      }
    }
  }

  Future<void> _loadSavedContact() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('buyer_name') ?? '';
    final phone = prefs.getString('buyer_phone') ?? '';
    if (!mounted) return;

    // Only fill if empty (User data takes precedence if set, but local storage is good fallback)
    if (_nameCtrl.text.isEmpty && name.trim().isNotEmpty) _nameCtrl.text = name;
    if (_phoneCtrl.text.isEmpty && phone.trim().isNotEmpty) {
      _phoneCtrl.text = phone;
    }
  }

  Future<void> _saveContact(
      {required String name, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('buyer_name', name);
    await prefs.setString('buyer_phone', phone);
  }

  Future<void> _openStoreMaps(MarketCartProvider cart) async {
    final lat = cart.activeStoreLat;
    final long = cart.activeStoreLong;
    final address = cart.activeStoreAddress;
    final query = (lat != null && long != null)
        ? '${lat.toStringAsFixed(6)},${long.toStringAsFixed(6)}'
        : (address ?? '');
    if (query.trim().isEmpty) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<MarketCartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Debug print for user data
    if (auth.isAuthenticated && auth.user != null) {
      // print('DEBUG: Rendering Cart with User: ${auth.user}');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Keranjang Belanja',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_qh5z2v.json', // Empty Cart Animation
                    width: 200,
                    height: 200,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                  Text('Keranjang masih kosong',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Store Header
                      _buildStoreHeader(cart),
                      const SizedBox(height: 16),

                      // Items
                      ...cart.items.values.map((item) => _buildCartItem(item)),

                      const SizedBox(height: 24),

                      // Payment Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rincian Pembayaran',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            _buildSummaryRow(
                                'Total Harga', cart.totalOriginalAmount),
                            if (cart.totalDiscount > 0)
                              _buildSummaryRow(
                                  'Total Diskon', -cart.totalDiscount,
                                  color: Colors.green),
                            _buildSummaryRow('Biaya Layanan', cart.serviceFee),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Bayar',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('Rp ${cart.grandTotal.toInt()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFFE07A5F))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // User Info / Pickup Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Informasi Pengambilan',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),

                            // Always show input fields to allow editing/correction
                            TextField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                    labelText: 'Nama Pemesan',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12))),
                            const SizedBox(height: 12),
                            TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                    labelText: 'Nomor WhatsApp / HP',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    prefixIcon: const Icon(Icons.phone_android),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12))),

                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 20, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                        'Pastikan nomor HP benar untuk konfirmasi pesanan.',
                                        style: TextStyle(
                                            color: Colors.blue.shade800,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Pembayaran',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text('Rp ${cart.grandTotal.toInt()}',
                                  style: const TextStyle(
                                      color: Color(0xFFE07A5F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: FilledButton(
                            onPressed: _isLoading
                                ? null
                                : () => _handleCheckout(context, cart, auth),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE07A5F),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Pesan Sekarang',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStoreHeader(MarketCartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: Color(0xFFE07A5F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cart.activeStoreName ?? 'Toko',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          if (cart.activeStoreAddress != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cart.activeStoreAddress!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                if (cart.activeStoreLat != null)
                  TextButton(
                    onPressed: () => _openStoreMaps(cart),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Lihat Maps',
                        style: TextStyle(fontSize: 12)),
                  )
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCartItem(MarketCartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey)),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                if (item.originalPrice != null &&
                    item.originalPrice! > item.price)
                  Text(
                    'Rp ${item.originalPrice!.toInt()}',
                    style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11),
                  ),
                Text('Rp ${item.price.toInt()}',
                    style: const TextStyle(
                        color: Color(0xFFE07A5F),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          // Quantity Control
          GestureDetector(
            onTap: () => _showQuantityDialog(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  Text('${item.quantity}x',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            '${value < 0 ? '-' : ''}Rp ${value.abs().toInt()}',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color ?? Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showQuantityDialog(MarketCartItem item) {
    final controller = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Jumlah'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            border: OutlineInputBorder(),
            helperText: 'Masukkan 0 untuk hapus',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                final qty = int.tryParse(controller.text) ?? item.quantity;
                Provider.of<MarketCartProvider>(context, listen: false)
                    .updateQuantity(item.productId, qty);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan')),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(
      BuildContext context, MarketCartProvider cart, AuthProvider auth) async {
    // 1. Check Login
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Silakan login terlebih dahulu untuk melanjutkan transaksi')));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // 2. Validation
    final finalName = _nameCtrl.text.trim();
    final finalPhone = _phoneCtrl.text.trim();

    if (finalName.isEmpty || finalPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon lengkapi nama dan nomor HP')));
      return;
    }

    // Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: const Text(
            'Pesanan akan dibuat dengan metode Bayar Ditempat. Pastikan kamu berada di lokasi toko.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Pesan')),
        ],
      ),
    );

    if (confirm != true) return;

    // Show Custom Processing Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => const _ProcessingDialog(),
    );

    setState(() => _isLoading = true);
    try {
      await _saveContact(name: finalName, phone: finalPhone);

      // Submit Order
      // Minimized delay because the dialog has its own pacing
      await Future.delayed(const Duration(seconds: 4));

      final order = await cart.submitOrder(
        customerName: finalName,
        phone: finalPhone,
      );

      if (context.mounted) {
        // Dismiss Processing Dialog
        Navigator.of(context).pop();

        // Add to orders list
        Provider.of<OrdersProvider>(context, listen: false).add(order);

        // Show Success Dialog with QR Code
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _SuccessDialog(order: order),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss Processing Dialog

        // Parse and refine error message
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('Quantity exceeds flash sale limit')) {
          msg =
              'Pembelian dibatasi untuk produk Flash Sale! Mohon kurangi jumlah barang.';
        } else if (msg.toLowerCase().contains('out of stock')) {
          msg = 'Stok barang telah habis.';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Custom Processing Dialog
class _ProcessingDialog extends StatefulWidget {
  const _ProcessingDialog();

  @override
  State<_ProcessingDialog> createState() => _ProcessingDialogState();
}

class _ProcessingDialogState extends State<_ProcessingDialog> {
  int _step = 0;
  final List<String> _steps = [
    'Menghubungi Server...',
    'Memverifikasi Stok...',
    'Membuat Pesanan...',
    'Generate QR Code...',
  ];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_step < _steps.length - 1) {
        setState(() => _step++);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_p8bfn5to.json', // Scanner / Processing
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _steps[_step],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07A5F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    color: Color(0xFFE07A5F),
                    backgroundColor: Color(0xFFFBE4DE),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Success Dialog
class _SuccessDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  const _SuccessDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final qrData = order['pickupCode'] ?? order['id'] ?? 'ERROR';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ticket Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE07A5F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text('Pesanan Berhasil!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Ticket Body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Text('Tunjukkan QR Code ini kepada kasir',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // QR Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(qrData,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close cart screen
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Selesai',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
