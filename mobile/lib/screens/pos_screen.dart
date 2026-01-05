import 'dart:async';
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
import 'package:rana_merchant/widgets/cart_widget.dart';

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
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // [NEW] Listen for real-time stock updates
    _syncSubscription = SyncService().onDataChanged.listen((_) {
      if (mounted) _loadProducts();
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600; // Adjusted breakpoint for tablets

    // Adjust grid count based on layout
    int gridCrossAxisCount = 2;
    double gridChildAspectRatio = 0.66;

    final availableGridWidth = isTablet ? screenWidth - 380 : screenWidth;

    if (availableGridWidth >= 1000) {
      gridCrossAxisCount = 4;
      gridChildAspectRatio = 0.9;
    } else if (availableGridWidth >= 600) {
      gridCrossAxisCount = 3;
      gridChildAspectRatio = 0.82;
    }

    final productBody = Column(
      children: [
        // -- Search & Categories --
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
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
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
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
                          SoundService.playBeep(); // [FIX] Add sound
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
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: 1.5)),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
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
              ? Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary))
              : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Produk tidak ditemukan',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]))
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        childAspectRatio: gridChildAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (ctx, i) {
                        final product = _filteredProducts[i];
                        final qty = cart.items[product['id']]?.quantity ?? 0;
                        final stock = (product['stock'] ?? 0) as int;
                        return ProductCard(
                          product: product,
                          quantity: qty,
                          onTap: () {
                            if (stock <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Stok produk ini sudah habis')),
                              );
                              SoundService.playError();
                              return;
                            }
                            if (qty >= stock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Maksimal stok tersedia hanya $stock')),
                              );
                              SoundService.playError();
                              return;
                            }
                            SoundService.playBeep();
                            cart.addItem(product['id'], product['name'],
                                product['sellingPrice'],
                                maxStock: stock);
                          },
                        ).animate().fadeIn(delay: (30 * i).ms).scale();
                      },
                    ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text('Kasir',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              height: 1.0),
        ),
        actions: [
          _buildActionButton(context, Icons.qr_code_scanner, () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ScanScreen()));
          }),
          const SizedBox(width: 8),
          _buildActionButton(context, Icons.sync, () async {
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
          // Only show cart button on mobile
          if (!isTablet)
            Stack(
              children: [
                _buildActionButton(context, Icons.shopping_bag_outlined,
                    () => _showCartSheet(context, cart)),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle),
                      child: Text('${cart.itemCount}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ).animate().scale(duration: 200.ms),
                  )
              ],
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: isTablet
          ? Row(
              children: [
                Expanded(child: productBody),
                SizedBox(
                  width: 380,
                  child: CartWidget(
                    isEmbedded: true,
                    onCheckoutSuccess: _loadProducts,
                  ),
                )
              ],
            )
          : productBody,
      floatingActionButton: (!isTablet && cart.itemCount > 0)
          ? FloatingActionButton.extended(
              onPressed: () => _showCartSheet(context, cart),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                  '${cart.itemCount} Item  •  ${currency.format(cart.totalAmount)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ).animate().slideY(begin: 1, curve: Curves.easeOutBack)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
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
    final media = MediaQuery.of(context);
    final isTablet = media.size.width >= 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final sheetHeightFactor = isTablet ? 0.9 : 0.85;

        return Center(
            child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
          ),
          height: media.size.height * sheetHeightFactor,
          child: CartWidget(
            onClose: () => Navigator.pop(context),
            onCheckoutSuccess: _loadProducts,
          ),
        ));
      },
    );
  }
}
