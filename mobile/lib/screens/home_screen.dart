import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart'; // [NEW]
import 'package:provider/provider.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/screens/expense_screen.dart';
import 'package:rana_merchant/screens/add_product_screen.dart';
import 'package:rana_merchant/screens/report_screen.dart';
import 'package:rana_merchant/screens/history_screen.dart';
import 'package:rana_merchant/screens/marketing_screen.dart';
import 'package:rana_merchant/screens/settings_screen.dart';
import 'package:rana_merchant/screens/subscription_screen.dart';
import 'package:rana_merchant/screens/stock_opname_screen.dart';
import 'package:rana_merchant/screens/purchase_screen.dart';
import 'package:rana_merchant/screens/order_list_screen.dart';
import 'package:rana_merchant/screens/wallet_screen.dart';
import 'package:rana_merchant/screens/scan_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:rana_merchant/services/notification_service.dart';
import 'package:rana_merchant/widgets/product_card.dart';
import 'package:rana_merchant/constants.dart';
import 'package:rana_merchant/services/ai_service.dart';
import 'package:rana_merchant/providers/subscription_provider.dart'; // [NEW]
import 'package:rana_merchant/screens/subscription_screen.dart'; // [NEW]

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String _selectedCategory = 'All';
  Map<String, dynamic>? _aiInsight; // [NEW]

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadInsight();
    
    // Check Subscription after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      if (sub.isLocked) {
        _showSubscriptionModal(); 
      }
    });
  }

  void _showSubscriptionModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // Force them to interact
      enableDrag: false,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Masa Uji Coba Habis', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Silakan berlangganan untuk melanjutkan menggunakan fitur lengkap Rana.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                }, 
                child: const Text('Berlangganan Sekarang')
              ),
            )
          ],
        ),
      )
    );
  }

  Future<void> _loadInsight() async {
    final insight = await AiService().generateDailyInsight();
    if (mounted) setState(() => _aiInsight = insight);
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    final localProds = await DatabaseHelper.instance.getAllProducts();
    
    if (localProds.isEmpty) {
      await ApiService().fetchAndSaveProducts();
      final freshProds = await DatabaseHelper.instance.getAllProducts();
      setState(() {
        products = freshProds;
        isLoading = false;
      });
    } else {
      setState(() {
        products = localProds;
        isLoading = false;
      });
    }
  }

  String _searchQuery = '';
  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = products;
    
    // Filter by Category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) {
        final cat = p['category'] ?? 'All';
        return cat == _selectedCategory;
      }).toList();
    }

    // Filter by Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || p['sku'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), 
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                // ... Navigation Rail (unchanged) ...
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: 0, 
                        minWidth: 72,
                        labelType: NavigationRailLabelType.all,
                        onDestinationSelected: (int index) {
                           // ... navigation logic ...
                           if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((val) { if (val == true) _loadProducts(); });
                           if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); 
                           if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen()));
                           if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen()));
                           if (index == 5) Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                           if (index == 6) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                           if (index == 7) Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen()));
                        },
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Icon(Icons.store, color: Theme.of(context).primaryColor, size: 32),
                        ),
                        destinations: const [
                          NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('POS')),
                          NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Tambah')),
                          NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Laporan')),
                          NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Stock')),
                          NavigationRailDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: Text('Pesanan')),
                          NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Dompet')),
                          NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Setting')),
                          NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Iklan')),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(thickness: 1, width: 1, color: Colors.grey[200]),

                // MAIN CONTENT (Left Side)
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      // if (_aiInsight != null) _buildAiCard(context), // REMOVED (Moved to Header)
                      _buildCategoryTabs(),
                      Expanded(
                        child: _buildProductGrid(context, cart, crossAxisCount: 4, aspectRatio: 0.8),
                      ),
                    ],
                  ),
                ),
// ... Cart Sidebar (unchanged) ...
              ],
            );
          } else {
            // MOBILE LAYOUT
            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, isMobile: true),
                    // if (_aiInsight != null) _buildAiCard(context), // REMOVED
                    _buildCategoryTabs(),
                    Expanded(
                      child: _buildProductGrid(context, cart, crossAxisCount: 2, aspectRatio: 0.75),
                    ),
                  ],
                ),
// ... Floating Action Button (unchanged) ...
              ],
            );
          }
        },
      ),
    );
  }

  // [NEW] AI Card Widget
  Widget _buildAiCard(BuildContext context) {
    bool isAlert = _aiInsight!['type'] == 'ALERT';
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAlert 
            ? [Colors.red.shade50, Colors.white] 
            : [Colors.indigo.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? Colors.red.shade100 : Colors.indigo.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAlert ? Colors.red.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAlert ? Icons.warning_amber_rounded : Icons.auto_awesome, 
              color: isAlert ? Colors.red : Colors.indigo,
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Rana AI Insight', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.indigo)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)), child: const Text('BETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_aiInsight!['message'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
          if (_aiInsight!['action'] == 'KULAKAN')
            FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Belanja'),
            )
        ],
      ),
    );
  }


  void _showAiInsightModal(BuildContext context) {
    // [NEW] Check Subscription
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!sub.canAccessFeature('ai')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        bool isAlert = _aiInsight!['type'] == 'ALERT';
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isAlert ? Colors.red.shade50 : Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(isAlert ? Icons.warning_amber : Icons.auto_awesome, size: 48, color: isAlert ? Colors.red : Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(_aiInsight!['title'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_aiInsight!['message'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))),
                  if (_aiInsight!['action'] == 'KULAKAN') ...[
                    const SizedBox(width: 16),
                    Expanded(child: FilledButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())); }, child: const Text('Belanja Sekarang'))),
                  ]
                ],
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1E293B), // Dark Header like screenshot
      child: SafeArea( // For mobile status bar
        bottom: false,
        child: Row(
          children: [
            if (isMobile) IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu, color: Colors.white)),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rana POS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('CONNECTED', style: TextStyle(color: Colors.greenAccent[100], fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(width: 32),
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari produk (Nama atau SKU)...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen())),
              icon: const Icon(Icons.campaign, color: Colors.pinkAccent),
              tooltip: 'Iklan Otomatis',
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())),
              icon: const Icon(Icons.storefront, color: Colors.tealAccent),
              tooltip: 'Kulakan',
            ),
            IconButton(
              onPressed: () async {
                setState(() => isLoading = true);
                await ApiService().syncAllData();
                _loadProducts(); 
              },
              icon: const Icon(Icons.sync, color: Colors.white70),
              tooltip: 'Sync Data',
            ),
            IconButton(
              onPressed: () {}, // Logout placeholder
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Logout',
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: AppConstants.productCategories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: Text(cat),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
                backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.grey[100],
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => setState(() => _selectedCategory = cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, CartProvider cart, {required int crossAxisCount, required double aspectRatio}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.search_off, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey))
      ]));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final qty = cart.items[product['id']]?.quantity ?? 0;
        
        return ProductCard(
          product: product, 
          quantity: qty, 
          onTap: () {
             SoundService.playBeep(); // [NEW] Sound
             cart.addItem(product['id'], product['name'], product['sellingPrice']);
          },
        );
      },
    );
  }

  // --- Cart Sidebar Logic ---
  Widget _buildCartSidebar(BuildContext context, CartProvider cart, {ScrollController? scrollController, VoidCallback? onClose}) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Column(
      children: [
        // Cart Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  const Text('Keranjang Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: Text('${cart.itemCount} Items', style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),

        // Customer Selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: InkWell(
            onTap: (){}, // TODO: Open Customer Modal
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Pilih Pelanggan (Umum)', style: TextStyle(color: Colors.grey))),
                  const Icon(Icons.add, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        ),

        // Items List
        Expanded(
          child: cart.itemCount == 0 
           ? Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[200]),
                   const SizedBox(height: 16),
                   Text('Belum ada item dipilih', style: TextStyle(color: Colors.grey[400])),
                 ],
               )
             )
           : ListView.separated(
             controller: scrollController,
             padding: const EdgeInsets.symmetric(horizontal: 20),
             itemCount: cart.items.length,
             separatorBuilder: (_,__) => const Divider(height: 1),
             itemBuilder: (context, index) {
                final item = cart.items.values.toList()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Qty Controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Column(
                          children: [
                            InkWell(onTap: () => cart.addItem(item.productId, item.name, item.price), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.keyboard_arrow_up, size: 16))),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            InkWell(onTap: () => cart.removeSingleItem(item.productId), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.keyboard_arrow_down, size: 16))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(currency.format(item.price), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(currency.format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
             },
           ),
        ),
        
        // Footer (Totals)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal', style: TextStyle(color: Colors.grey[600])), Text(currency.format(cart.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pajak', style: TextStyle(color: Colors.grey[600])), const Text('-', style: TextStyle(fontWeight: FontWeight.bold))]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(currency.format(cart.totalAmount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, 
                child: FilledButton(
                  onPressed: cart.itemCount == 0 
                    ? null 
                    : () async {
                         final success = await _processPayment(context, cart);
                         if (success == true && onClose != null) onClose();
                      },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF818CF8), // Periwinkle Blue/Purple like screenshot
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currency.format(cart.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  )
                )
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showCartModal(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: _buildCartSidebar(context, cart, scrollController: ctrl, onClose: () => Navigator.pop(context)),
        )
      )
    );
  }

  Future<bool> _processPayment(BuildContext context, CartProvider cart) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: PaymentScreen(cart: cart, scrollController: ScrollController()),
        )
      )
    );

    if (success == true && context.mounted) {
       SoundService.playSuccess(); // [NEW] Sound
       showDialog(context: context, builder: (_) => const TransactionSuccessDialog());
       cart.clear(); // Clear AFTER success
       return true;
    }
    return false;
  }


  Widget _buildDrawer(BuildContext context) {
      return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E293B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.store, color: Colors.indigo.shade100, size: 48),
                  const SizedBox(height: 8),
                  const Text('Rana Merchant', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
             ListTile(leading: const Icon(Icons.point_of_sale), title: const Text('Kasir (POS)'), onTap: () => Navigator.pop(context)),
             ListTile(leading: const Icon(Icons.add_box), title: const Text('Tambah Produk'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((val) { if (val == true) _loadProducts(); }); }),
             ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Laporan & Grafik'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); }),
             ListTile(leading: const Icon(Icons.inventory), title: const Text('Stock Opname'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen())); }),
             ListTile(leading: const Icon(Icons.shopping_bag), title: const Text('Pesanan Online (Baru!)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen())); }),
             ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Dompet Merchant'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())); }),
             ListTile(leading: const Icon(Icons.campaign), title: const Text('Iklan Otomatis'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen())); }),
             ListTile(leading: const Icon(Icons.storefront), title: const Text('Belanja Stok'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())); }),
             const Divider(),
             ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
        ],
      ),
    );
  }
}

// Re-use PaymentScreen and TransactionSuccessDialog from previous implementation
// But adapted to be used in Dialog for Desktop
class PaymentScreen extends StatefulWidget {
  final CartProvider cart;
  final ScrollController scrollController;
  
  const PaymentScreen({super.key, required this.cart, required this.scrollController});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'CASH';
  double payAmount = 0;
  bool _isProcessing = false;
  
  void setAmount(double val) {
     setState(() => payAmount = val);
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.totalAmount;
    double change = payAmount - total;
    
    // Quick cash suggestions
    final suggestions = [total, 20000.0, 50000.0, 100000.0];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMethodCard('CASH', Icons.payments, true),
              const SizedBox(width: 12),
              _buildMethodCard('QRIS', Icons.qr_code_2, false),
            ],
          ),
          
          if (method == 'CASH') ...[
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal Diterima',
                border: OutlineInputBorder()
              ),
              onChanged: (v) => setAmount(double.tryParse(v) ?? 0),
              controller: TextEditingController(text: payAmount == 0 ? '' : payAmount.toStringAsFixed(0))..selection = TextSelection.fromPosition(TextPosition(offset: (payAmount == 0 ? '' : payAmount.toStringAsFixed(0)).length)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: suggestions.map((amt) {
                if (amt < total && amt != total) return const SizedBox.shrink(); 
                return ActionChip(
                  label: Text('Rp ${amt.toStringAsFixed(0)}'),
                  onPressed: () => setAmount(amt),
                  backgroundColor: payAmount == amt ? Colors.green[100] : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: change >= 0 ? Colors.green[50] : Colors.red[50],
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: change >= 0 ? Colors.green[200]! : Colors.red[200]!)
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Kembalian', style: TextStyle(fontSize: 16)),
                   Text('Rp ${change < 0 ? 0 : change.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 ],
               ),
             )
          ],
          
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isProcessing || (method == 'CASH' && payAmount < total) ? null : () async {
              setState(() => _isProcessing = true);
              try {
                await widget.cart.checkout('tenant-1', 'store-1', 'cashier-1', paymentMethod: method);
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('SELESAIKAN'),
          )
        ],
      ),
    );
  }
  
  Widget _buildMethodCard(String id, IconData icon, bool selected) {
    final isSelected = method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { method = id; payAmount = 0; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
             color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 24),
              const SizedBox(height: 8),
              Text(id, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionSuccessDialog extends StatelessWidget {
  const TransactionSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) Navigator.of(context).pop();
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

