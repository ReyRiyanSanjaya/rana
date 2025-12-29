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
import 'package:rana_merchant/providers/wallet_provider.dart'; // [FIX] Added missing import
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
import 'package:rana_merchant/screens/notification_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/blog_detail_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/blog_list_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/subscription_pending_screen.dart'; // [NEW] Lock Screen
import 'dart:async'; // For Timer
import 'package:flutter/services.dart';




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
  Future<List<dynamic>>? _appMenusFuture; // [NEW]
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // [FIX] Added Key

  // [NEW] Icon Mapper
  IconData _getIcon(String name) {
    switch (name.toUpperCase()) {
      case 'POS': return Icons.point_of_sale;
      case 'PRODUCT': return Icons.inventory_2;
      case 'REPORT': return Icons.bar_chart;
      case 'STOCK': return Icons.inventory_2; // [NEW]
      case 'ADS': return Icons.campaign;
      case 'SUPPORT': return Icons.support_agent;
      case 'SETTINGS': return Icons.settings;
      case 'KULAKAN': return Icons.storefront;
      case 'PPOB': return Icons.payment;
      case 'WALLET': return Icons.account_balance_wallet;
      case 'SCAN': return Icons.qr_code_scanner;
      case 'ORDER': return Icons.shopping_bag;
      default: return Icons.circle;
    }
  }

  // [NEW] Route Mapper
  Widget _getScreen(String route) {
    switch (route) {
      case '/pos': return const PosScreen();
      case '/products': return const AddProductScreen();
      case '/reports': return const ReportScreen();
      case '/stock': return const StockOpnameScreen(); // [NEW]
      case '/marketing': return const MarketingScreen();
      case '/support': return const SupportScreen();
      case '/settings': return const SettingsScreen();
      case '/kulakan': return const PurchaseScreen();
      case '/ppob': return const PpobScreen();
      case '/wallet': return const WalletScreen();
      case '/orders': return const OrderListScreen();
      default: return const Scaffold(body: Center(child: Text("Feature not available")));
    }
  }

  // [NEW] Color Mapper (Simple hash or predefined)
  Color _getColor(String key) {
     final colors = [const Color(0xFFF59E0B), const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFEC4899), const Color(0xFF8B5CF6), const Color(0xFF06B6D4), const Color(0xFF6366F1)];
     return colors[key.length % colors.length];
  }



  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadInsight();
    _appMenusFuture = ApiService().fetchAppMenus();
    // [NEW] Load Wallet Data for Home Card
    Future.microtask(() => context.read<WalletProvider>().loadData());
    
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
    Timer.periodic(const Duration(seconds: 1), (timer) async {
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
    final sub = Provider.of<SubscriptionProvider>(context);

    // [SECURITY] Hard Lock if Expired
    if (sub.isLocked) {
       return Scaffold(
         body: Container(
           width: double.infinity,
           padding: const EdgeInsets.all(32),
           decoration: const BoxDecoration(
             gradient: LinearGradient(colors: [Color(0xFF991B1B), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight)
           ),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                 child: const Icon(Icons.lock_person, size: 64, color: Color(0xFF991B1B)),
               ),
               const SizedBox(height: 32),
               Text('Akses Terkunci', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
               const SizedBox(height: 16),
               Text(
                 'Masa uji coba atau paket berlangganan Anda telah habis. Silakan perbarui langganan untuk melanjutkan operasional toko.', 
                 textAlign: TextAlign.center,
                 style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9))
               ),
               const SizedBox(height: 48),
               SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: const Color(0xFF991B1B),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                   ),
                   child: Text('Perpanjang Sekarang', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                 ),
               ),
               const SizedBox(height: 24),
               TextButton(
                  onPressed: () => sub.codeCheckSubscription(), // Retry
                  child: const Text('Refresh Status', style: TextStyle(color: Colors.white70))
               )
             ],
           ),
         ),
       );
    }
    
    // [NEW] Lock if Pending
    if (sub.status == SubscriptionStatus.pending) {
      return const SubscriptionPendingScreen();
    }

    return Scaffold(
      key: _scaffoldKey, // [FIX] Assigned Key
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
                       InkWell(
                         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
                         child: Text('Lihat Semua', style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600))
                       ,
                       )
                     ],
                   ),
                 ),
                 const SizedBox(height: 16),
                 _buildInfoTerkini().animate().fade(delay: 400.ms).slideX(begin: 0.2),
                 const SizedBox(height: 24),
                 _buildBlogCarousel().animate().fade(delay: 500.ms).slideX(begin: 0.2),
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
  // [UPDATED] Animated Sliver AppBar without Search - Red Theme
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140, // Slightly taller for better effect
      pinned: true,
      backgroundColor: const Color(0xFFBF092F), // Red Brand
      stretch: true, // Enable stretch effect
      // [NEW] Fixed Title and Actions so they don't scroll away
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('Selamat Pagi,', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
            Text('Rana Store', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: (){ 
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          }, 
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2))
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), // Go to profile/settings
          child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFFBF092F)))
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dynamic Background Gradient (Red Theme)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9F0013), Color(0xFFBF092F), Color(0xFFE11D48)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
                )
              ),
            ),
            
            // 2. Animated Orbs/Glows (Tuned for Red)
            Positioned(
              top: -50, right: -50, 
              child: Container(
                width: 200, height: 200, 
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.withOpacity(0.15), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 80, spreadRadius: 10)])
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 3.seconds, begin: const Offset(1,1), end: const Offset(1.2,1.2))
            ),
            Positioned(
              bottom: 0, left: -30, 
              child: Container(
                width: 150, height: 150, 
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 80, spreadRadius: 5)])
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(duration: 4.seconds, begin: 0, end: -20)
            ),
          ],
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
  
  // [UPDATED] Red Glassmorphism Wallet Card
  Widget _buildWalletCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFBF092F), Color(0xFFE11D48)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFFBF092F).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo Dompet', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          // TODO: Connect to Provider for Real Balance
                          Consumer<WalletProvider>(
                            builder: (context, provider, _) => Text(
                              NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0).format(provider.balance), 
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                            )
                          ),
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text('Merchant Pro', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10))),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet, color: Colors.white54, size: 32)
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     _buildGlassAction(Icons.add_circle_outline, 'Top Up', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))), // Direct to wallet for now
                     _buildGlassAction(Icons.arrow_circle_up_outlined, 'Transfer', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                     _buildGlassAction(Icons.history, 'Riwayat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                     _buildGlassAction(Icons.qr_code_scanner, 'Scan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()))),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGlassAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))
        ],
      ),
    );
  }

  // [UPDATED] Feature Grid with Soft Colors
  // [UPDATED] Feature Grid with Soft Colors
  // [UPDATED] Feature Grid with Dynamic Menus
  Widget _buildFeatureGrid(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _appMenusFuture,
      builder: (context, snapshot) {
        List<dynamic> menuItems = [];

        // FALLBACK if error or empty (Offline First approach: Use defaults if API fails and no cache - effectively simpler here)
        // Ideally we should cache this list in SQLite/Prefs. For V1 we fallback to defaults.
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
           // Default Static Menu
           menuItems = [
             {'label': 'Kasir', 'key': 'POS', 'route': '/pos'},
             {'label': 'Produk', 'key': 'PRODUCT', 'route': '/products'},
             {'label': 'Laporan', 'key': 'REPORT', 'route': '/reports'},
             {'label': 'Stok', 'key': 'STOCK', 'route': '/stock'}, // [NEW] Restored Stock Menu
             {'label': 'Kulakan', 'key': 'KULAKAN', 'route': '/kulakan'},
             {'label': 'Iklan', 'key': 'ADS', 'route': '/marketing'},
             {'label': 'Bantuan', 'key': 'SUPPORT', 'route': '/support'},
             {'label': 'PPOB', 'key': 'PPOB', 'route': '/ppob'},
           ];
        } else {
           menuItems = List.from(snapshot.data!);
           menuItems.removeWhere((m) => m['key'] == 'SETTINGS'); // [FIX] Remove Setting menu as requested
           // [FIX] Force "Stok" menu if missing from backend
           if (!menuItems.any((m) => m['key'] == 'STOCK')) {
              // Insert at index 3 (after Laporan) or append
              if (menuItems.length >= 3) {
                 menuItems.insert(3, {'label': 'Stok', 'key': 'STOCK', 'route': '/stock'});
              } else {
                 menuItems.add({'label': 'Stok', 'key': 'STOCK', 'route': '/stock'});
              }
           }
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
           padding: const EdgeInsets.symmetric(horizontal: 24),
           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
             crossAxisCount: 4, 
             mainAxisSpacing: 24, 
             crossAxisSpacing: 16, 
             childAspectRatio: 0.8
           ),
           itemCount: menuItems.length,
           itemBuilder: (ctx, i) {
              final m = menuItems[i];
              final String label = m['label'] ?? 'Menu';
              final String key = m['key'] ?? '';
              final String route = m['route'] ?? '';
              final String iconName = m['icon'] ?? key; // Use key as fallback for icon map
              
              final IconData icon = _getIcon(iconName);
              final Color color = _getColor(key);
              final Color bg = color.withOpacity(0.08); // Softer background
              
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                   final screen = _getScreen(route);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
                          BoxShadow(color: Colors.white, blurRadius: 0, spreadRadius: -2) // Inner glow trick
                        ]
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ).animate(target: 1).scale(duration: 200.ms, curve: Curves.easeOutBack), // Slight bounce on load
                    const SizedBox(height: 12),
                    Text(
                      label, 
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)), 
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis
                    )
                  ],
                ),
              ).animate().fade(duration: 400.ms, delay: (50 * i).ms).slideY(begin: 0.2, end: 0); // Staggered entrance
           },
        );
      }
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

  // [NEW] Info Terkini Widget (Announcements)
  Widget _buildInfoTerkini() {
     return FutureBuilder<List<dynamic>>(
       future: ApiService().getAnnouncements(),
       builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Belum ada info terkini.", style: GoogleFonts.poppins(color: Colors.blue[900])))
                ],
              ),
            );
          }
          
          // Display top 3
          final items = snapshot.data!.take(3).toList();
          
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
               final item = items[index];
               return Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                 ),
                 child: Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                       child: const Icon(Icons.notifications_active, color: Colors.blue, size: 20),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(item['title'] ?? 'Info', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                           const SizedBox(height: 4),
                           Text(
                             item['content'] ?? '', 
                             style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                             maxLines: 2, overflow: TextOverflow.ellipsis,
                           )
                         ],
                       ),
                     )
                   ],
                 ),
               );
            },
          );
       }
     );
  }

  // [NEW] Dynamic Blog Carousel (Renamed from _buildInfoCarousel)
  Widget _buildBlogCarousel() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Berita & Edukasi", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogListScreen())),
                child: Text("Lihat Semua", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFBF092F)))
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List
        FutureBuilder<List<dynamic>>(
      future: ApiService().getBlogPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final posts = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: posts.map((post) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BlogDetailScreen(post: post)));
                },
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with Hero
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))
                          ]
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (post['imageUrl'] != null && post['imageUrl'] != '')
                              Image.network(post['imageUrl'], fit: BoxFit.cover)
                            else
                              Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.article, size: 64, color: Color(0xFFCBD5E1))),
                            
                            // Overlay gradient
                            Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)]
                                    )
                                )
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Meta
                      Row(
                        children: [
                          Text(
                            post['tags']?.isNotEmpty == true ? post['tags'][0].toUpperCase() : 'NEWS', 
                            style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, size: 4, color: Colors.grey[300]),
                          const SizedBox(width: 8),
                          Text(
                            post['readTime'] ?? '3 min read', 
                            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['title'] ?? 'No Title', 
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), height: 1.4), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 8),
                      // Extract plain text summary from content if summary not provided (simple logic)
                      Text(
                        post['summary'] ?? (post['content'] ?? '').replaceAll(RegExp(r'<[^>]*>'), '').substring(0, 50) + '...', // Strip HTML tags basically
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    )
      ],
    );
  }

  Widget _buildStaticInfoCard(Color color, String title, String sub) { // Renamed old helper just in case

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
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF9F0013), Color(0xFFBF092F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
          )
      ),
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
            const Spacer(), // Replaces TextField
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen())),
              icon: const Icon(Icons.campaign, color: Colors.white),
              tooltip: 'Iklan Otomatis',
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())),
              icon: const Icon(Icons.storefront, color: Colors.white),
              tooltip: 'Kulakan',
            ),
            IconButton(
              onPressed: () async {
                setState(() => isLoading = true);
                await ApiService().syncAllData();
                _loadProducts(); 
              },
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sync Data',
            ),
            // [NEW] Notification Icon
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'Notifikasi',
            ),
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: 'Keranjang',
            ),
            IconButton(
              onPressed: () {}, // Logout placeholder
              icon: const Icon(Icons.logout, color: Colors.white),
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
                backgroundColor: isSelected ? const Color(0xFFBF092F) : Colors.grey[100],
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
    ).animate().fadeIn(duration: 500.ms); // Fade in the whole grid, items have their own animations inside ProductCard
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
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFFBF092F)),
                  const SizedBox(width: 8),
                  const Text('Keranjang Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFBF092F))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12)), // Light Red
                child: Text('${cart.itemCount} Items', style: const TextStyle(color: Color(0xFFBF092F), fontSize: 12, fontWeight: FontWeight.bold)),
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
                            InkWell(
                              onTap: () async {
                                final ctrl = TextEditingController(text: item.quantity.toString());
                                final result = await showDialog<int>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Set Jumlah'),
                                    content: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(hintText: 'Masukkan qty'),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                      FilledButton(
                                        onPressed: () {
                                          final val = int.tryParse(ctrl.text);
                                          Navigator.pop(context, val);
                                        },
                                        child: const Text('Simpan'),
                                      )
                                    ],
                                  ),
                                );
                                if (result != null) {
                                  cart.setItemQuantity(item.productId, result);
                                }
                              },
                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
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
                    backgroundColor: const Color(0xFFBF092F), // [FIX] Red Brand
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
