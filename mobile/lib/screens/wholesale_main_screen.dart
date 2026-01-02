import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/screens/wholesale_cart_screen.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';
import 'package:rana_merchant/screens/purchase_screen.dart';
import 'package:rana_merchant/screens/settings_screen.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';
import 'package:rana_merchant/screens/wholesale_scan_screen.dart';
import 'package:rana_merchant/utils/format_utils.dart';
import 'package:rana_merchant/models/wholesale_product.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class WholesaleMainScreen extends StatefulWidget {
  const WholesaleMainScreen({super.key});

  @override
  State<WholesaleMainScreen> createState() => _WholesaleMainScreenState();
}

class _WholesaleMainScreenState extends State<WholesaleMainScreen> {
  bool _isLoading = false;
  List<WholesaleProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final rawProducts = await ApiService().getWholesaleProducts();
      setState(() {
        _products =
            rawProducts.map((p) => WholesaleProduct.fromJson(p)).toList();
      });
    } catch (e) {
      debugPrint('Failed to load products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat produk kulakan')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Rana Grosir',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFFE07A5F))),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WholesaleCartScreen()),
                  );
                },
              ),
              Consumer<WholesaleCartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount == 0) return const SizedBox();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE07A5F),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Show product details
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatUtils.formatCurrency(
                                      product.wholesalePrice),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFE07A5F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Provider.of<WholesaleCartProvider>(
                                              context,
                                              listen: false)
                                          .addItem(
                                              product.id,
                                              product.name,
                                              product.wholesalePrice,
                                              product.image,
                                              product.supplier);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${product.name} ditambahkan ke keranjang'),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor:
                                              const Color(0xFFE07A5F),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE07A5F),
                                      side: const BorderSide(
                                          color: Color(0xFFE07A5F)),
                                    ),
                                    child: const Text('Tambah'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.store_outlined, 'Belanja', true),
            _buildNavItem(Icons.receipt_long_outlined, 'Pesanan', false,
                onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WholesaleOrderListScreen()),
              );
            }),
            _buildNavItem(Icons.qr_code_scanner, 'Scan', false, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WholesaleScanScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected,
      {VoidCallback? onTap}) {
    final color = isSelected
        ? const Color(0xFFE07A5F)
        : const Color(0xFFE07A5F).withOpacity(0.5);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
