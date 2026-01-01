import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/widgets/product_card.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:rana_merchant/screens/scan_screen.dart';
import 'package:rana_merchant/screens/payment_screen.dart';
import 'package:rana_merchant/services/sync_service.dart';
import 'package:flutter/services.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getAllProducts();

    final Set<String> uniqueCats = {'All'};
    for (var p in data) {
      if (p['category'] != null && p['category'].toString().isNotEmpty) {
        uniqueCats.add(p['category']);
      }
    }

    if (mounted) {
      setState(() {
        _products = data;
        _categories = uniqueCats.toList();
        _filterProducts();
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchCat = _selectedCategory == 'All' ||
            (p['category'] ?? 'Lainnya') == _selectedCategory;
        final matchQuery = p['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            p['sku']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        return matchCat && matchQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Soft Beige
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        centerTitle: false,
        title: Text('Kasir',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE07A5F),
                fontSize: 24)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
              color: const Color(0xFFE07A5F).withOpacity(0.1), height: 1.0),
        ),
        actions: [
          _buildActionButton(Icons.qr_code_scanner, () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ScanScreen()));
          }),
          const SizedBox(width: 8),
          _buildActionButton(Icons.sync, () async {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sinkronisasi data...')));
            try {
              await SyncService().syncTransactions();
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sinkronisasi Selesai'),
                    backgroundColor: Color(0xFF81B29A)));
            } catch (e) {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal Sync: $e'),
                    backgroundColor: Color(0xFFE07A5F)));
            }
          }),
          const SizedBox(width: 8),
          Stack(
            children: [
              _buildActionButton(Icons.shopping_bag_outlined,
                  () => _showCartSheet(context, cart)),
              if (cart.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE07A5F), shape: BoxShape.circle),
                    child: Text('${cart.itemCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ).animate().scale(duration: 200.ms),
                )
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // -- Search & Categories --
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari Produk...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE07A5F)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterProducts();
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                              _filterProducts();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE07A5F).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE07A5F)
                                        : Colors.grey.shade300,
                                    width: 1.5)),
                            child: Text(
                              cat,
                              style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? const Color(0xFFE07A5F)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),

          // -- Product Grid --
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE07A5F)))
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Produk tidak ditemukan',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[400]))
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (ctx, i) {
                          final product = _filteredProducts[i];
                          final qty = cart.items[product['id']]?.quantity ?? 0;
                          return ProductCard(
                            product: product,
                            quantity: qty,
                            onTap: () {
                              SoundService.playBeep();
                              cart.addItem(product['id'], product['name'],
                                  product['sellingPrice']);
                            },
                          ).animate().fadeIn(delay: (30 * i).ms).scale();
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context, cart),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                  '${cart.itemCount} Item  •  ${currency.format(cart.totalAmount)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFE07A5F),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ).animate().slideY(begin: 1, curve: Curves.easeOutBack)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  void _showCartSheet(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Keranjang',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),

            const Divider(height: 1),

            // Customer Selector (Outlined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: InkWell(
                onTap: () async {
                  // ... existing customer logic ...
                  final controller =
                      TextEditingController(text: cart.customerName ?? '');
                  final result = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: const Text('Pelanggan'),
                            content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                    labelText: 'Nama',
                                    border: OutlineInputBorder())),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, null),
                                  child: const Text('Umum')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(
                                      ctx, controller.text.trim()),
                                  child: const Text('Simpan')),
                            ],
                          ));
                  cart.setCustomerName(result);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Color(0xFFE07A5F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cart.customerName ?? 'Pelanggan Umum',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            // Items
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount == 0) {
                    return Center(
                        child: Text('Keranjang Kosong',
                            style: GoogleFonts.poppins(color: Colors.grey)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Dismissible(
                        key: Key(item.productId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => cart.removeItem(item.productId),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE07A5F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_outline,
                              color: Color(0xFFE07A5F)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0)
                                            .format(item.price),
                                        style: GoogleFonts.poppins(
                                            color: const Color(0xFFE07A5F),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.grey),
                                    onPressed: () =>
                                        cart.removeSingleItem(item.productId),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final controller = TextEditingController(
                                          text: '${item.quantity}');
                                      final newQty = await showDialog<int>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Ubah Jumlah'),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Jumlah',
                                              border: OutlineInputBorder(),
                                            ),
                                            autofocus: true,
                                            onSubmitted: (val) {
                                              Navigator.pop(
                                                  context, int.tryParse(val));
                                            },
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(
                                                  context,
                                                  int.tryParse(
                                                      controller.text)),
                                              child: const Text('Simpan'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (newQty != null) {
                                        cart.setItemQuantity(
                                            item.productId, newQty);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Text('${item.quantity}',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Color(0xFFE07A5F)),
                                    onPressed: () => cart.addItem(
                                        item.productId, item.name, item.price),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[600])),
                        Consumer<CartProvider>(
                          builder: (_, cart, __) => Text(
                            NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0)
                                .format(cart.totalAmount),
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PaymentScreen(cart: cart),
                        );
                        if (result == true) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A5F),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Bayar Sekarang',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
