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
import 'package:rana_merchant/config/theme_config.dart';

class WholesaleMainScreen extends StatefulWidget {
  const WholesaleMainScreen({super.key});

  @override
  State<WholesaleMainScreen> createState() => _WholesaleMainScreenState();
}

class _WholesaleMainScreenState extends State<WholesaleMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const WholesaleShopView(),
    const WholesaleOrderListScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _handleScan();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleScan() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WholesaleScanScreen()),
    );

    if (code != null && mounted) {
      try {
        await ApiService().scanQrOrder(code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pesanan Berhasil Diterima!"),
              backgroundColor: Color(0xFFE07A5F),
            ),
          );
          // Refresh orders if on order screen?
          // Since we use IndexedStack, the order screen might not auto refresh unless we tell it to.
          // But for now let's just show success.
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    final isTablet = mediaSize.shortestSide >= 600;
    final isDesktopWidth = mediaSize.width >= 800;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: isDesktopWidth
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: isTablet ? 8 : 4,
                  ),
                  child: NavigationBar(
                    height: isTablet ? 72 : 64,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    indicatorColor:
                        ThemeConfig.brandColor.withOpacity(0.2),
                    selectedIndex: _selectedIndex > 1 ? 0 : _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.store_outlined),
                        selectedIcon: Icon(
                          Icons.store,
                          color: ThemeConfig.brandColor,
                        ),
                        label: 'Belanja',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(
                          Icons.receipt_long,
                          color: Color(0xFFE07A5F),
                        ),
                        label: 'Pesanan',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.qr_code_scanner),
                        label: 'Scan',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class WholesaleShopView extends StatefulWidget {
  const WholesaleShopView({super.key});

  @override
  State<WholesaleShopView> createState() => _WholesaleShopViewState();
}

class _WholesaleShopViewState extends State<WholesaleShopView> {
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
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(
          'Rana Grosir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE07A5F),
          ),
        ),
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
                      builder: (context) => const WholesaleCartScreen(),
                    ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  double childAspectRatio = 0.7;

                  if (isTablet) {
                    if (constraints.maxWidth >= 1200) {
                      crossAxisCount = 5;
                    } else if (constraints.maxWidth >= 1000) {
                      crossAxisCount = 4;
                    } else if (constraints.maxWidth >= 800) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 3;
                    }
                  } else if (isWide) {
                    crossAxisCount = 3;
                  }

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      isTablet ? 32 : 24,
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
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
                            onTap: () {},
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
                                      child: product.image.isNotEmpty
                                          ? Image.network(
                                              product.image,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.inventory_2_outlined,
                                              size: isTablet ? 56 : 48,
                                              color: Colors.grey[400],
                                            ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        FormatUtils.formatCurrency(
                                          product.wholesalePrice,
                                        ),
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
                                              listen: false,
                                            ).addItem(
                                              product.id,
                                              product.name,
                                              product.wholesalePrice,
                                              product.image,
                                              product.supplier,
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${product.name} ditambahkan ke keranjang',
                                                ),
                                                duration: const Duration(
                                                    seconds: 1),
                                                backgroundColor:
                                                    const Color(0xFFE07A5F),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFE07A5F),
                                            side: const BorderSide(
                                              color: Color(0xFFE07A5F),
                                            ),
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
                  );
                },
              ),
            ),
    );
  }
}
