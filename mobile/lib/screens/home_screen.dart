import 'dart:ui'; // For Glassmorphism
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
import 'package:rana_merchant/screens/announcements_screen.dart'; // [NEW] feature
import 'package:rana_merchant/screens/support_screen.dart'; // [NEW] feature
import 'package:rana_merchant/screens/pos_screen.dart'; // [NEW] feature
import 'package:rana_merchant/screens/payment_screen.dart'; // [NEW] Refactored
import 'package:rana_merchant/services/sync_service.dart'; // [NEW]
import 'package:rana_merchant/services/connectivity_service.dart'; // [NEW]
import 'package:rana_merchant/widgets/no_connection_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/ppob_screen.dart'; // [NEW] feature
import 'dart:async'; // For Timer




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String _selectedCategory = 'All';
  int _bottomNavIndex = 0;
  final ScrollController _scrollController = ScrollController(); // [NEW] For Sticky Header
  bool _isScrolled = false;
  Map<String, dynamic>? _aiInsight;



  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadInsight();
    
    // Check Subscription after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      try {
        await sub.codeCheckSubscription(); 
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text('Debug: Status is ${sub.status.toString().split('.').last} (Locked: ${sub.isLocked})'),
             backgroundColor: sub.isLocked ? Colors.red : Colors.green,
             duration: const Duration(seconds: 3),
           ));
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debug Error: $e'), backgroundColor: Colors.red));
         }
      }

      if (sub.isLocked && mounted) {
        _showSubscriptionModal(); 
      }
    });


    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) setState(() => _isScrolled = true);
      if (_scrollController.offset <= 50 && _isScrolled) setState(() => _isScrolled = false);
    });

    // [NEW] Auto-Sync Loop
    Timer.periodic(const Duration(seconds: 30), (timer) async {
       final isOnline = await ConnectivityService().hasInternetConnection();
       if (isOnline) {
         await SyncService().syncTransactions();
       }
    });
  }

  // [NEW] Helper for online-only navigation
  void _navigateToProtected(Widget screen) async {
    // Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memeriksa koneksi...'), duration: Duration(milliseconds: 500)),
    );

    // Add timeout to prevent hanging
    bool isOnline = false;
    try {
      isOnline = await ConnectivityService().hasInternetConnection().timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      isOnline = false;
    }
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading

    if (isOnline) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NoConnectionScreen(
        onRetry: () {
          Navigator.pop(context); // Close NoConnection
          _navigateToProtected(screen); // Retry
        }
      )));
    }
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
            return Row( // Desktop remains similar for now or can be adapted later
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
            // MOBILE LAYOUT - SUPER APP STYLE
            return Scaffold( 
              body: _bottomNavIndex == 0 ? _buildSuperAppHome(cart) : _buildBodyForNavIndex(_bottomNavIndex),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _bottomNavIndex,
                onDestinationSelected: (idx) => setState(() => _bottomNavIndex = idx),
                backgroundColor: Colors.white,
                indicatorColor: Colors.indigo.shade100,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: 'Beranda'),
                  NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Transaksi'),
                  NavigationDestination(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'), // Center Action
                  NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Laporan'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // [NEW] Super App Home Body (Pro Version)
  Widget _buildSuperAppHome(CartProvider cart) {
      // Use CustomScrollView for Sticky Header effects
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildLiveTicker(), // [NEW] Flash News
                const SizedBox(height: 16),
                _buildWalletCard(context).animate().fade().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                _buildFeatureGrid(context).animate().fade(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 24),
                if (_aiInsight != null) _buildAiCard(context).animate().fade(delay: 300.ms).slideX(),
                const SizedBox(height: 24),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Info Terkini', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                       Text('Lihat Semua', style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 16),
                 _buildInfoCarousel().animate().fade(delay: 400.ms).slideX(begin: 0.2),
                 const SizedBox(height: 100),
              ],
            ),
          )
        ],
      );
  }

  Widget _buildBodyForNavIndex(int index) {
      if (index == 1) return const OrderListScreen(); 
      if (index == 2) return const ScanScreen(); 
      if (index == 3) return const ReportScreen(); 
      if (index == 4) return const SettingsScreen();
      return const SizedBox.shrink();
  }

  // [FIXED] Sticky Sliver AppBar - Updated
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Decorative Gradients
            // Decorative Gradients (Fixed: Use BoxShadow for glow instead of invalid filter param)
            Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.2), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 100, spreadRadius: 10)]))),
            Positioned(bottom: -30, left: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.pink.withOpacity(0.1), boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 100, spreadRadius: 10)]))),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Halo, Juragan!', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)), Text('Rana Store', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
                   Row(children: [IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_outlined, color: Colors.white)), const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white))]),
                ],
              ),
            )
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
           padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
           child: TextField(
             onChanged: (val) => setState(() => _searchQuery = val),
             style: const TextStyle(color: Colors.white),
             decoration: InputDecoration(
               hintText: 'Cari produk atau fitur...',
               hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
               prefixIcon: const Icon(Icons.search, color: Colors.white70),
               suffixIcon: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.mic, color: Colors.white)), // Voice Visual
               filled: true,
               fillColor: Colors.white.withOpacity(0.15),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
               contentPadding: const EdgeInsets.symmetric(horizontal: 20),
               isDense: true,
             ),
           ),
        ),
      ),
    );
  }

  // [NEW] Live Ticker
  Widget _buildLiveTicker() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7), // Amber 100
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
           const Icon(Icons.campaign, size: 16, color: Colors.orange),
           const SizedBox(width: 8),
           Expanded(child: Text("🔥 Promo Spesial: Diskon 50% Printer Thermal hanya hari ini!", style: GoogleFonts.poppins(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, delay: 2.seconds),
    );
  }
  
  // [NEW] Glassmorphism Wallet Card
  Widget _buildWalletCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF818CF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo Dompet', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Rp 2.500.000', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text('Member Bronze', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10))),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet, color: Colors.white54, size: 32)
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     _buildGlassAction(Icons.add_circle_outline, 'Top Up'),
                     _buildGlassAction(Icons.arrow_circle_up_outlined, 'Transfer'),
                     _buildGlassAction(Icons.history, 'Riwayat'),
                     _buildGlassAction(Icons.qr_code_scanner, 'Scan'),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))
      ],
    );
  }

  // [UPDATED] Feature Grid with Soft Colors
  // [UPDATED] Feature Grid with Soft Colors
  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
       {'icon': Icons.point_of_sale, 'label': 'Kasir', 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7), 'dest': const PosScreen(), 'online': false}, 
       {'icon': Icons.inventory_2, 'label': 'Produk', 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF), 'dest': const AddProductScreen(), 'online': false},
       {'icon': Icons.bar_chart, 'label': 'Laporan', 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5), 'dest': const ReportScreen(), 'online': false},
       {'icon': Icons.storefront, 'label': 'Kulakan', 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFDF2F8), 'dest': const PurchaseScreen(), 'online': true}, // Online
       
       {'icon': Icons.campaign, 'label': 'Iklan', 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF), 'dest': const MarketingScreen(), 'online': true}, // Online
       {'icon': Icons.support_agent, 'label': 'Bantuan', 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF), 'dest': const SupportScreen(), 'online': true}, // Online
       {'icon': Icons.settings, 'label': 'Setting', 'color': const Color(0xFF6B7280), 'bg': const Color(0xFFF3F4F6), 'dest': const SettingsScreen(), 'online': false},
       {'icon': Icons.payment, 'label': 'PPOB', 'color': const Color(0xFF6366F1), 'bg': const Color(0xFFEEF2FF), 'dest': const PpobScreen(), 'online': false}, // [UPDATED] PPOB (Offline bypass)
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 24, crossAxisSpacing: 16, childAspectRatio: 0.75),
      itemCount: features.length,
      itemBuilder: (ctx, i) {
         final f = features[i];
         return InkWell(
           borderRadius: BorderRadius.circular(16),
           onTap: f['dest'] != null 
             ? () { 
                 if (f['online'] == true) {
                   _navigateToProtected(f['dest'] as Widget);
                 } else {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => f['dest'] as Widget));
                 }
               } 
             : (){},
           child: Column(
             children: [
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: f['bg'] as Color, // Soft BG
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: [BoxShadow(color: (f['bg'] as Color).withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]
                 ),
                 child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 28),
               ),
               const SizedBox(height: 8),
               Text(f['label'] as String, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)
             ],
           ),
         );
      },
    );



  }

  // [NEW] Drawer for Mobile Navigation
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Rana Merchant'),
            accountEmail: const Text('store@rana.id'),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.store, color: Color(0xFF1E293B))),
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
          ),
          ListTile(leading: const Icon(Icons.point_of_sale), title: const Text('Kasir (POS)'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())); }),
          ListTile(leading: const Icon(Icons.inventory_2), title: const Text('Produk'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())); }),
          ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Laporan'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); }),
          ListTile(leading: const Icon(Icons.campaign), title: const Text('Iklan'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen())); }),
          ListTile(leading: const Icon(Icons.support_agent), title: const Text('Bantuan'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())); }),
          const Divider(),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Pengaturan'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
        ],
      ),
    );
  }

  Widget _buildInfoCarousel() {
     return SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       padding: const EdgeInsets.symmetric(horizontal: 24),
       child: Row(
         children: [
            _buildInfoCard(Colors.blue, "Tips Jualan", "Cara meningkatkan omzet 2x lipat"),
            const SizedBox(width: 16),
            _buildInfoCard(Colors.orange, "Promo Alat", "Diskon printer thermal 50%"),
            const SizedBox(width: 16),
            _buildInfoCard(Colors.green, "Komunitas", "Gabung grup WhatsApp Juragan"),
         ],
       ),
     );
  }

  Widget _buildInfoCard(Color color, String title, String sub) {
    return Container(
      width: 240,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(sub, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2)
        ],
      ),
    );
  }

  Widget _buildAiCard(BuildContext context) { // Modified to fit list

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
          child: PaymentScreen(cart: cart),
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


}
