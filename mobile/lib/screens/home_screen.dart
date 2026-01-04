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
import 'package:rana_merchant/screens/wholesale_main_screen.dart';
import 'package:rana_merchant/screens/ppob_screen.dart'; // [NEW] feature
import 'package:rana_merchant/screens/notification_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/blog_detail_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/blog_list_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/subscription_pending_screen.dart'; // [NEW] Lock Screen
import 'package:rana_merchant/screens/login_screen.dart';
import 'dart:async'; // For Timer
import 'package:flutter/services.dart';
import 'package:rana_merchant/screens/flash_sales_screen.dart';
import 'package:rana_merchant/screens/promo_hub_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:rana_merchant/services/realtime_service.dart';
import 'package:rana_merchant/services/order_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rana_merchant/config/assets_config.dart';
import 'package:rana_merchant/config/theme_config.dart';

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
  int _newOrdersCount = 0;
  int _unreadNotificationCount = 0;
  String? _storeName;
  String? _storeContact;
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());
  final ScrollController _scrollController =
      ScrollController(); // [NEW] For Sticky Header
  bool _isScrolled = false;
  Map<String, dynamic>? _aiInsight;
  Future<List<dynamic>>? _appMenusFuture; // [NEW]
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // [FIX] Added Key
  Timer? _autoSyncTimer;
  final RealtimeService _realtimeService = RealtimeService();
  final OrderService _orderService = OrderService();
  bool _showBeginnerTip = false;
  bool _shouldShowOnboardingSuccess = false;
  bool _showHomeTour = false;
  int _homeTourStep = 0;
  int _desktopSelectedIndex = 0; // [NEW] Tablet/Desktop Navigation Index

  // [NEW] Icon Mapper
  IconData _getIcon(String name) {
    switch (name.toUpperCase()) {
      case 'POS':
        return Icons.point_of_sale;
      case 'PRODUCT':
        return Icons.inventory_2;
      case 'REPORT':
        return Icons.bar_chart;
      case 'STOCK':
        return Icons.inventory_2; // [NEW]
      case 'ADS':
        return Icons.campaign;
      case 'FLASH_SALE':
        return Icons.flash_on;
      case 'PROMO':
        return Icons.local_offer;
      case 'SUPPORT':
        return Icons.support_agent;
      case 'SETTINGS':
        return Icons.settings;
      case 'KULAKAN':
        return Icons.storefront;
      case 'PPOB':
        return Icons.payment;
      case 'WALLET':
        return Icons.account_balance_wallet;
      case 'SCAN':
        return Icons.qr_code_scanner;
      case 'ORDER':
        return Icons.shopping_bag;
      default:
        return Icons.circle;
    }
  }

  // [NEW] Route Mapper
  Widget _getScreen(String route) {
    switch (route) {
      case '/pos':
        return const PosScreen();
      case '/products':
        return const AddProductScreen();
      case '/reports':
        return const ReportScreen();
      case '/stock':
        return const StockOpnameScreen(); // [NEW]
      case '/marketing':
        return const MarketingScreen();
      case '/flashsale':
        return const FlashSalesScreen();
      case '/promo':
        return const PromoHubScreen();
      case '/support':
        return const SupportScreen();
      case '/settings':
        return const SettingsScreen();
      case '/kulakan':
        return const WholesaleMainScreen();
      case '/ppob':
        return const PpobScreen();
      case '/wallet':
        return const WalletScreen();
      case '/orders':
        return const OrderListScreen();
      default:
        return const Scaffold(
            body: Center(child: Text("Feature not available")));
    }
  }

  // [NEW] Color Mapper (Simple hash or predefined)
  Color _getColor(String key) {
    return const Color(0xFFE07A5F); // Terra Cotta
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadInsight();
    _loadStoreInfo();
    _loadBeginnerTipFlag();
    _maybeStartHomeTour();
    _appMenusFuture = ApiService().fetchAppMenus();
    // [NEW] Load Wallet Data for Home Card
    Future.microtask(() => context.read<WalletProvider>().loadData());

    // Check Subscription after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      try {
        await sub.codeCheckSubscription();
        if (kDebugMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Status: ${sub.status.toString().split('.').last} (Locked: ${sub.isLocked})'),
              backgroundColor: sub.isLocked
                  ? ThemeConfig.brandColor
                  : ThemeConfig.colorSuccess,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (kDebugMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cek langganan: $e')),
          );
        }
      }

      if (sub.isLocked && mounted) {
        _showSubscriptionModal();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled)
        setState(() => _isScrolled = true);
      if (_scrollController.offset <= 50 && _isScrolled)
        setState(() => _isScrolled = false);
    });

    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final isOnline = await ConnectivityService().hasInternetConnection();
      if (isOnline && !SyncService().isSyncing) {
        await SyncService().syncTransactions();
      }
    });

    _refreshNewOrdersCountFromApi();
    _refreshNotificationBadge();
    _realtimeService.init();
    _realtimeService.addTransactionListener(_handleRealtimeOrderEvent);
    _checkOnboardingSuccessFlag();
  }

  Future<void> _loadBeginnerTipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('has_completed_onboarding') ?? false;
    final hasDismissed = prefs.getBool('has_dismissed_beginner_tip') ?? false;
    if (!mounted) return;
    setState(() {
      _showBeginnerTip = hasCompleted && !hasDismissed;
    });
  }

  Future<void> _dismissBeginnerTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_dismissed_beginner_tip', true);
    if (!mounted) return;
    setState(() {
      _showBeginnerTip = false;
    });
  }

  Future<void> _maybeStartHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('has_completed_onboarding') ?? false;
    final hasSeenTour = prefs.getBool('has_seen_home_tour') ?? false;
    if (!mounted || !hasCompleted || hasSeenTour) return;
    setState(() {
      _showHomeTour = true;
      _homeTourStep = 0;
    });
  }

  Future<void> _checkOnboardingSuccessFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final should = prefs.getBool('should_show_onboarding_success') ?? false;
    if (!mounted || !should) return;
    await prefs.setBool('should_show_onboarding_success', false);
    setState(() {
      _shouldShowOnboardingSuccess = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldShowOnboardingSuccess) return;
      _showOnboardingSuccessSheet();
    });
  }

  Future<void> _finishHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_home_tour', true);
    if (!mounted) return;
    setState(() {
      _showHomeTour = false;
    });
  }

  Future<void> _advanceHomeTour() async {
    if (!_showHomeTour) return;
    if (_homeTourStep < 2) {
      setState(() {
        _homeTourStep++;
      });
      return;
    }
    await _finishHomeTour();
  }

  Future<void> _skipHomeTour() async {
    if (!_showHomeTour) return;
    await _finishHomeTour();
  }

  Future<void> _loadStoreInfo() async {
    try {
      final tenant = await DatabaseHelper.instance.getTenantInfo();
      if (!mounted) return;
      setState(() {
        _storeName = tenant?['businessName']?.toString();
        _storeContact = (tenant?['email'] ?? tenant?['phone'])?.toString();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _scrollController.dispose();
    _realtimeService.removeTransactionListener(_handleRealtimeOrderEvent);
    _realtimeService.dispose();
    super.dispose();
  }

  void _switchTab(int idx) {
    if (idx == _bottomNavIndex) {
      _tabNavigatorKeys[idx].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _bottomNavIndex = idx);
  }

  void _handleRealtimeOrderEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    final source = data['source']?.toString();
    if (source == 'MARKET') {
      _refreshNewOrdersCountFromApi();

      // Play Sound
      SoundService.playBeep();

      // Show Notification
      NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Pesanan Baru!',
          body: 'Ada pesanan baru masuk. Segera proses!',
          payload: 'NEW_ORDER');
    }
  }

  Future<void> _refreshNewOrdersCountFromApi() async {
    try {
      final orders = await _orderService.getIncomingOrders();
      final int pendingCount = orders
          .where((o) =>
              o is Map &&
              o['orderStatus'] ==
                  'PENDING') // Count all PENDING orders (including COD)
          .length;
      if (!mounted) return;
      setState(() {
        _newOrdersCount = pendingCount;
      });
    } catch (_) {}
  }

  void _showOnboardingSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: Lottie.asset(
                    AssetsConfig.lottieConfettiSuccess,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Toko Anda siap jualan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Produk pertama Anda sudah dibuat. Tambah produk lagi supaya pelanggan lebih banyak pilihan.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('Masuk ke Beranda'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                    child: const Text('Tambah produk lagi'),
                  ),
                ),
                SizedBox(height: media.viewInsets.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTourOverlay(BuildContext context) {
    String title;
    String description;
    Alignment highlightAlignment;
    IconData stepIcon;
    String stepLabel;

    if (_homeTourStep == 0) {
      title = 'Mulai dari Kasir';
      description =
          'Gunakan menu Kasir untuk mencatat setiap transaksi agar laporan selalu rapi.';
      highlightAlignment = const Alignment(0, -0.1);
      stepIcon = Icons.point_of_sale;
      stepLabel = 'Kasir';
    } else if (_homeTourStep == 1) {
      title = 'Atur Produk';
      description =
          'Kelola stok dan harga produk dari menu Produk supaya jualan lebih teratur.';
      highlightAlignment = const Alignment(0, 0.2);
      stepIcon = Icons.inventory_2;
      stepLabel = 'Produk';
    } else {
      title = 'Lihat Laporan';
      description =
          'Pantau omzet harian dan performa toko melalui menu Laporan.';
      highlightAlignment = const Alignment(0, 0.85);
      stepIcon = Icons.bar_chart;
      stepLabel = 'Laporan';
    }

    return IgnorePointer(
      ignoring: false,
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Stack(
          children: [
            Align(
              alignment: highlightAlignment,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 1.08),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stepIcon,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stepLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Langkah ${_homeTourStep + 1} dari 3',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _advanceHomeTour,
                              child: Text(
                                _homeTourStep == 2 ? 'Mengerti' : 'Lanjut',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _skipHomeTour,
                            child: const Text(
                              'Lewati panduan',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshNotificationBadge() async {
    try {
      final notifs = await ApiService().fetchNotifications();
      final int unreadCount = notifs
          .where((n) => n is Map && (n['isRead'] == false || n['isRead'] == 0))
          .length;
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = unreadCount;
      });
    } catch (_) {}
  }

  Future<T?> _pushInActiveNavigator<T>(Widget screen) {
    final nav = _tabNavigatorKeys[_bottomNavIndex].currentState;
    if (nav != null) {
      return nav.push<T>(MaterialPageRoute(builder: (_) => screen));
    }
    return Navigator.push<T>(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  // [NEW] Helper for online-only navigation
  void _navigateToProtected(Widget screen) async {
    // Show loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Memeriksa koneksi...'),
          duration: Duration(milliseconds: 500)),
    );

    // Add timeout to prevent hanging
    bool isOnline = false;
    try {
      isOnline = await ConnectivityService()
          .hasInternetConnection()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      isOnline = false;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading

    if (isOnline) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NoConnectionScreen(onRetry: () {
                    Navigator.pop(context); // Close NoConnection
                    _navigateToProtected(screen); // Retry
                  })));
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
                  const Icon(Icons.lock_clock,
                      size: 48, color: Color(0xFFE07A5F)),
                  const SizedBox(height: 16),
                  Text('Masa Uji Coba Habis',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'Silakan berlangganan untuk melanjutkan menggunakan fitur lengkap Rana.'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SubscriptionScreen()));
                        },
                        child: const Text('Berlangganan Sekarang')),
                  )
                ],
              ),
            ));
  }

  Future<void> _loadInsight() async {
    double? lat;
    double? lng;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition();
          lat = position.latitude;
          lng = position.longitude;
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    final insight = await AiService().generateDailyInsight(lat: lat, lng: lng);
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
      filtered = filtered
          .where((p) =>
              p['name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p['sku']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
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
              gradient: LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.lock_person,
                    size: 64, color: Color(0xFF991B1B)),
              ),
              const SizedBox(height: 32),
              Text('Akses Terkunci',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              Text(
                  'Masa uji coba atau paket berlangganan Anda telah habis. Silakan perbarui langganan untuk melanjutkan operasional toko.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE07A5F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Text('Perpanjang Sekarang',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                  onPressed: () => sub.codeCheckSubscription(), // Retry
                  child: const Text('Refresh Status',
                      style: TextStyle(color: Colors.white70)))
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
      backgroundColor: const Color(0xFFFFF8F0),
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return _buildDesktopLayout(context, constraints, cart);
          } else {
            final mobile = WillPopScope(
              onWillPop: () async {
                final nav = _tabNavigatorKeys[_bottomNavIndex].currentState;
                if (nav != null && nav.canPop()) {
                  nav.pop();
                  return false;
                }
                return true;
              },
              child: Scaffold(
                body: IndexedStack(
                  index: _bottomNavIndex,
                  children: [
                    _buildTabNavigator(
                        tabIndex: 0,
                        rootBuilder: (ctx) => _buildSuperAppHome(ctx, cart)),
                    _buildTabNavigator(
                        tabIndex: 1,
                        rootBuilder: (_) => const OrderListScreen()),
                    _buildTabNavigator(
                        tabIndex: 2, rootBuilder: (_) => const ScanScreen()),
                    _buildTabNavigator(
                        tabIndex: 3, rootBuilder: (_) => const ReportScreen()),
                    _buildTabNavigator(
                        tabIndex: 4,
                        rootBuilder: (_) => const SettingsScreen()),
                  ],
                ),
                bottomNavigationBar: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home, 'Beranda'),
                      _buildNavItem(
                          1, Icons.shopping_bag_outlined, 'PO Online'),
                      _buildNavItem(2, Icons.qr_code_scanner, 'Scan'),
                      _buildNavItem(3, Icons.bar_chart, 'Laporan'),
                      _buildNavItem(4, Icons.person, 'Akun'),
                    ],
                  ),
                ),
              ),
            );

            if (_showHomeTour) {
              return Stack(
                children: [
                  mobile,
                  _buildHomeTourOverlay(context),
                ],
              );
            }

            return mobile;
          }
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;
    final color = isSelected
        ? const Color(0xFFE07A5F)
        : const Color(0xFFE07A5F).withOpacity(0.5);

    return InkWell(
      onTap: () {
        if (index == _bottomNavIndex) {
          _tabNavigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
          return;
        }
        _switchTab(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 26),
              if (index == 1 && _newOrdersCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        _newOrdersCount > 99
                            ? '99+'
                            : _newOrdersCount.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .shimmer(duration: 1200.ms, delay: 2000.ms),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildTabNavigator(
      {required int tabIndex,
      required Widget Function(BuildContext) rootBuilder}) {
    return Navigator(
      key: _tabNavigatorKeys[tabIndex],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (ctx) => rootBuilder(ctx),
      ),
    );
  }

  // [NEW] Super App Home Body (Pro Version)
  Widget _buildSuperAppHome(BuildContext navContext, CartProvider cart) {
    // Use CustomScrollView for Sticky Header effects
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(navContext),
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (_showBeginnerTip) const SizedBox(height: 16),
              if (_showBeginnerTip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE07A5F).withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE07A5F).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFFE07A5F),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tips untuk kamu',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE07A5F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah lebih banyak produk agar pelanggan mudah memilih.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _dismissBeginnerTip,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showBeginnerTip) const SizedBox(height: 16),
              _buildLiveTicker(), // [NEW] Flash News
              const SizedBox(height: 16),
              _buildWalletCard(navContext).animate().fade().slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              _buildFeatureGrid(navContext)
                  .animate()
                  .fade(delay: 200.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 24),
              if (_aiInsight != null)
                _buildAiCard(navContext).animate().fade(delay: 300.ms).slideX(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Info Terkini',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B))),
                    InkWell(
                      onTap: () => Navigator.push(
                          navContext,
                          MaterialPageRoute(
                              builder: (_) => const AnnouncementsScreen())),
                      child: Text('Lihat Semua',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFE07A5F),
                              fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoTerkini()
                  .animate()
                  .fade(delay: 400.ms)
                  .slideX(begin: 0.2),
              const SizedBox(height: 24),
              _buildBlogCarousel(navContext)
                  .animate()
                  .fade(delay: 500.ms)
                  .slideX(begin: 0.2),
              const SizedBox(height: 100),
            ],
          ),
        )
      ],
    );
  }

  // [FIXED] Sticky Sliver AppBar - Updated
  // [UPDATED] Animated Sliver AppBar without Search - Terra Cotta Theme
  Widget _buildSliverAppBar(BuildContext context) {
    // 1. Dynamic Greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 11) {
      greeting = 'Selamat Pagi,';
    } else if (hour < 15) {
      greeting = 'Selamat Siang,';
    } else if (hour < 18) {
      greeting = 'Selamat Sore,';
    } else {
      greeting = 'Selamat Malam,';
    }

    // 2. Dynamic Store Name
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final storeNameFromAuth = user?['businessName']?.toString();
    final ownerName = user?['name']?.toString();

    final titleName = (_storeName != null && _storeName!.trim().isNotEmpty)
        ? _storeName!.trim()
        : (storeNameFromAuth != null && storeNameFromAuth.trim().isNotEmpty
            ? storeNameFromAuth.trim()
            : (ownerName != null && ownerName.trim().isNotEmpty
                ? ownerName.trim()
                : 'Toko'));

    return SliverAppBar(
      expandedHeight: 140, // Slightly taller for better effect
      pinned: true,
      backgroundColor: const Color(0xFFE07A5F), // Terra Cotta Brand
      stretch: true, // Enable stretch effect
      // [NEW] Fixed Title and Actions so they don't scroll away
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
          Text(titleName,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()));
              if (!mounted) return;
              _refreshNotificationBadge();
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          _unreadNotificationCount > 99
                              ? '99+'
                              : _unreadNotificationCount.toString(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2))),
        const SizedBox(width: 8),
        InkWell(
            onTap: () => _switchTab(4),
            child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, color: Color(0xFFE07A5F)))),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dynamic Background Gradient (Terra Cotta Theme)
            Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                Color(0xFFE07A5F),
                Color(0xFFE07A5F),
                Color(0xFFE07A5F)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),

            // 2. Animated Orbs/Glows (Tuned for Terra Cotta)
            Positioned(
                top: -50,
                right: -50,
                child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 80,
                                  spreadRadius: 10)
                            ]))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        duration: 3.seconds,
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2))),
            Positioned(
                bottom: 0,
                left: -30,
                child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 80,
                                  spreadRadius: 5)
                            ]))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(duration: 4.seconds, begin: 0, end: -20)),
          ],
        ),
      ),
    );
  }

  // [NEW] Live Ticker
  Widget _buildLiveTicker() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getAnnouncements(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find a promo or just take the latest
        final item = snapshot.data!.first;
        final text = "🔥 ${item['title']}: ${item['content']}";

        return Container(
          width: double.infinity,
          color: const Color(0xFFFFF8F0), // Soft Beige
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.campaign, size: 16, color: Color(0xFFE07A5F)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFFE07A5F),
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
            ],
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 3.seconds, delay: 2.seconds),
        );
      },
    );
  }

  // [UPDATED] Terra Cotta Glassmorphism Wallet Card
  Widget _buildWalletCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [ThemeConfig.brandColor, ThemeConfig.brandColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: ThemeConfig.brandColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -20,
              right: -20,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WalletScreen())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo Dompet',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          // TODO: Connect to Provider for Real Balance
                          Consumer<WalletProvider>(
                              builder: (context, provider, _) => Text(
                                  NumberFormat.simpleCurrency(
                                          locale: 'id_ID', decimalDigits: 0)
                                      .format(provider.balance),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('Merchant Pro',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 10))),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet,
                          color: Colors.white54, size: 32)
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassAction(
                        Icons.add_circle_outline,
                        'Top Up',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const WalletScreen()))), // Direct to wallet for now
                    _buildGlassAction(
                        Icons.arrow_circle_up_outlined,
                        'Transfer',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WalletScreen()))),
                    _buildGlassAction(
                        Icons.history,
                        'Riwayat',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WalletScreen()))),
                    _buildGlassAction(
                        Icons.qr_code_scanner, 'Scan', () => _switchTab(2)),
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
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))
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
              {
                'label': 'Stok',
                'key': 'STOCK',
                'route': '/stock'
              }, // [NEW] Restored Stock Menu
              {'label': 'Kulakan', 'key': 'KULAKAN', 'route': '/kulakan'},
              {'label': 'Promosi', 'key': 'PROMO', 'route': '/promo'},
              {'label': 'Bantuan', 'key': 'SUPPORT', 'route': '/support'},
              {'label': 'PPOB', 'key': 'PPOB', 'route': '/ppob'},
            ];
          } else {
            menuItems = List.from(snapshot.data!);
            menuItems.removeWhere((m) =>
                m['key'] ==
                'SETTINGS'); // [FIX] Remove Setting menu as requested
            // [FIX] Force "Stok" menu if missing from backend
            if (!menuItems.any((m) => m['key'] == 'STOCK')) {
              // Insert at index 3 (after Laporan) or append
              if (menuItems.length >= 3) {
                menuItems.insert(
                    3, {'label': 'Stok', 'key': 'STOCK', 'route': '/stock'});
              } else {
                menuItems
                    .add({'label': 'Stok', 'key': 'STOCK', 'route': '/stock'});
              }
            }
            int insertIndex = menuItems.indexWhere((m) =>
                m['key'] == 'ADS' ||
                m['key'] == 'FLASH_SALE' ||
                m['route'] == '/marketing' ||
                m['route'] == '/flashsale');
            if (insertIndex < 0) insertIndex = menuItems.length;
            menuItems.removeWhere((m) =>
                m['key'] == 'ADS' ||
                m['key'] == 'FLASH_SALE' ||
                m['route'] == '/marketing' ||
                m['route'] == '/flashsale');
            if (!menuItems
                .any((m) => m['key'] == 'PROMO' || m['route'] == '/promo')) {
              menuItems.insert(insertIndex,
                  {'label': 'Promosi', 'key': 'PROMO', 'route': '/promo'});
            }
          }

          final width = MediaQuery.of(context).size.width;
          int crossAxisCount = 4;

          if (width >= 1100) {
            crossAxisCount = 6;
          } else if (width >= 800) {
            crossAxisCount = 5;
          } else if (width <= 360) {
            crossAxisCount = 3;
          }

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8),
            itemCount: menuItems.length,
            itemBuilder: (ctx, i) {
              final m = menuItems[i];
              final String label = m['label'] ?? 'Menu';
              final String key = m['key'] ?? '';
              final String route = m['route'] ?? '';
              final String iconName =
                  m['icon'] ?? key; // Use key as fallback for icon map

              final IconData icon = _getIcon(iconName);
              final Color color = _getColor(key);
              final Color bg = color.withOpacity(0.08); // Softer background

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  if (route == '/orders') {
                    _switchTab(1);
                    return;
                  }
                  if (route == '/scan') {
                    _switchTab(2);
                    return;
                  }
                  if (route == '/reports') {
                    _switchTab(3);
                    return;
                  }
                  if (route == '/settings') {
                    _switchTab(4);
                    return;
                  }
                  final screen = _getScreen(route);

                  // [FIX] Use root navigator for Kulakan to hide main bottom bar
                  if (route == '/kulakan') {
                    Navigator.of(context, rootNavigator: true)
                        .push(MaterialPageRoute(builder: (_) => screen));
                    return;
                  }

                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => screen));
                },
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6)),
                                BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 0,
                                    spreadRadius: -2)
                              ]),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        if (route == '/orders' && _newOrdersCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE07A5F),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 20, minHeight: 20),
                              child: Center(
                                child: Text(
                                  _newOrdersCount > 99
                                      ? '99+'
                                      : _newOrdersCount.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                        .animate(target: 1)
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 12),
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ],
                ),
              )
                  .animate()
                  .fade(duration: 400.ms, delay: (50 * i).ms)
                  .slideY(begin: 0.2, end: 0); // Staggered entrance
            },
          );
        });
  }

  // [NEW] Drawer for Mobile Navigation
  Widget _buildDrawer(BuildContext context) {
    final titleName = (_storeName != null && _storeName!.trim().isNotEmpty)
        ? _storeName!.trim()
        : 'Rana Merchant';
    final subtitle = (_storeContact != null && _storeContact!.trim().isNotEmpty)
        ? _storeContact!.trim()
        : '-';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(titleName),
            accountEmail: Text(subtitle),
            currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, color: Color(0xFF1E293B))),
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
          ),
          ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Kasir (POS)'),
              onTap: () {
                Navigator.pop(context);
                _pushInActiveNavigator(const PosScreen());
              }),
          ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Produk'),
              onTap: () {
                Navigator.pop(context);
                _pushInActiveNavigator(const AddProductScreen());
              }),
          ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Laporan'),
              onTap: () {
                Navigator.pop(context);
                _switchTab(3);
              }),
          ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Promosi'),
              onTap: () {
                Navigator.pop(context);
                _pushInActiveNavigator(const PromoHubScreen());
              }),
          ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Bantuan'),
              onTap: () {
                Navigator.pop(context);
                _pushInActiveNavigator(const SupportScreen());
              }),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                _switchTab(4);
              }),
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
              decoration: BoxDecoration(
                  color: const Color(0xFF3D405B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF3D405B)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text("Belum ada info terkini.",
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF3D405B))))
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3D405B).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active,
                          color: Color(0xFF3D405B), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] ?? 'Info',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            item['content'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[600], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        });
  }

  // [NEW] Dynamic Blog Carousel (Renamed from _buildInfoCarousel)
  Widget _buildBlogCarousel(BuildContext navContext) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Berita & Edukasi",
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              TextButton(
                  onPressed: () => Navigator.push(
                      navContext,
                      MaterialPageRoute(
                          builder: (_) => const BlogListScreen())),
                  child: Text("Lihat Semua",
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE07A5F))))
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List
        FutureBuilder<List<dynamic>>(
          future: ApiService().getBlogPosts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const SizedBox.shrink();

            final posts = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: posts.map((post) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          navContext,
                          MaterialPageRoute(
                              builder: (_) => BlogDetailScreen(post: post)));
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
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8))
                                ]),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (post['imageUrl'] != null &&
                                    post['imageUrl'] != '')
                                  Image.network(post['imageUrl'],
                                      fit: BoxFit.cover)
                                else
                                  Container(
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.article,
                                          size: 64, color: Color(0xFFCBD5E1))),

                                // Overlay gradient
                                Container(
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3)
                                    ]))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Meta
                          Row(
                            children: [
                              Text(
                                  post['tags']?.isNotEmpty == true
                                      ? post['tags'][0].toUpperCase()
                                      : 'NEWS',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                              const SizedBox(width: 8),
                              Icon(Icons.circle,
                                  size: 4, color: Colors.grey[300]),
                              const SizedBox(width: 8),
                              Text(post['readTime'] ?? '3 min read',
                                  style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(post['title'] ?? 'No Title',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                  height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          // Extract plain text summary from content if summary not provided (simple logic)
                          Text(
                              post['summary'] ??
                                  (post['content'] ?? '')
                                          .replaceAll(RegExp(r'<[^>]*>'), '')
                                          .substring(0, 50) +
                                      '...', // Strip HTML tags basically
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
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

  Widget _buildStaticInfoCard(Color color, String title, String sub) {
    // Renamed old helper just in case

    return Container(
      width: 240,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2)
        ],
      ),
    );
  }

  Widget _buildAiCard(BuildContext context) {
    if (_aiInsight == null) return const SizedBox.shrink();

    final type = _aiInsight!['type'];
    final iconStr = _aiInsight!['icon'];
    final action = _aiInsight!['action'];

    // Theme Colors
    Color themeColor = const Color(0xFFE07A5F);
    if (type == 'ALERT') themeColor = Colors.redAccent;
    if (type == 'POSITIVE') themeColor = Colors.green;
    if (type == 'TIP') themeColor = Colors.orange;
    if (type == 'INFO') themeColor = Colors.blueAccent;

    // Icon Mapping
    IconData icon = Icons.auto_awesome;
    if (iconStr == 'alert') icon = Icons.warning_amber_rounded;
    if (iconStr == 'percent') icon = Icons.percent;
    if (iconStr == 'trending_up') icon = Icons.trending_up;
    if (iconStr == 'trending_down') icon = Icons.trending_down;
    if (iconStr == 'rain') icon = Icons.cloud;
    if (iconStr == 'sun') icon = Icons.wb_sunny;
    if (iconStr == 'chart') icon = Icons.bar_chart;
    if (iconStr == 'smart_toy') icon = Icons.smart_toy;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: themeColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
          border: Border.all(color: themeColor.withOpacity(0.1), width: 1.5)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Rana AI Insight',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8))),
                        const Spacer(),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(_aiInsight!['short'] ?? 'Insight',
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_aiInsight!['title'] ?? '',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Text(_aiInsight!['message'],
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          if (action != 'NONE') ...[
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      if (action == 'KULAKAN') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PurchaseScreen()));
                      } else if (action == 'PROMO' || action == 'MARKETING') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MarketingScreen()));
                      } else if (action == 'REPORT') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReportScreen()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            action == 'KULAKAN'
                                ? 'Mulai Belanja'
                                : action == 'PROMO'
                                    ? 'Buat Promo'
                                    : action == 'REPORT'
                                        ? 'Lihat Laporan'
                                        : 'Lihat Detail',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18)
                      ],
                    )))
          ]
        ],
      ),
    );
  }

  void _showAiInsightModal(BuildContext context) {
    // [NEW] Check Subscription
    final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!sub.canAccessFeature('ai')) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
      return;
    }

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          bool isAlert = _aiInsight!['type'] == 'ALERT';
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: isAlert ? Colors.red.shade50 : Colors.blue.shade50,
                      shape: BoxShape.circle),
                  child: Icon(
                      isAlert ? Icons.warning_amber : Icons.auto_awesome,
                      size: 48,
                      color: isAlert ? Colors.red : Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(_aiInsight!['title'],
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_aiInsight!['message'],
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'))),
                    if (_aiInsight!['action'] == 'KULAKAN') ...[
                      const SizedBox(width: 16),
                      Expanded(
                          child: FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PurchaseScreen()));
                              },
                              child: const Text('Belanja Sekarang'))),
                    ]
                  ],
                )
              ],
            ),
          );
        });
  }

  Widget _buildHeader(BuildContext context, {bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFE07A5F), Color(0xFFE07A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: SafeArea(
        // For mobile status bar
        bottom: false,
        child: Row(
          children: [
            if (isMobile)
              IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu, color: Colors.white)),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rana POS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF81B29A), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('CONNECTED',
                        style: TextStyle(
                            color: Color(0xFF81B29A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const Spacer(), // Replaces TextField
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PromoHubScreen())),
              icon: const Icon(Icons.local_offer, color: Colors.white),
              tooltip: 'Promosi',
            ),
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PurchaseScreen())),
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
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen())),
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'Notifikasi',
            ),
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: 'Keranjang',
            ),
            IconButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal),
                backgroundColor:
                    isSelected ? const Color(0xFFE07A5F) : Colors.grey[100],
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => setState(() => _selectedCategory = cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, CartProvider cart,
      {required int crossAxisCount, required double aspectRatio}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
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

        final stock = (product['stock'] ?? 0) as int;
        return ProductCard(
          product: product,
          quantity: qty,
          onTap: () {
            if (stock <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stok produk ini sudah habis')),
              );
              return;
            }
            if (qty >= stock) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Maksimal stok tersedia hanya $stock')),
              );
              return;
            }
            SoundService.playBeep();
            cart.addItem(
                product['id'], product['name'], product['sellingPrice']);
          },
        );
      },
    ).animate().fadeIn(
        duration: 500
            .ms); // Fade in the whole grid, items have their own animations inside ProductCard
  }

  // --- Cart Sidebar Logic ---
  Widget _buildCartSidebar(BuildContext context, CartProvider cart,
      {ScrollController? scrollController, VoidCallback? onClose}) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: [
        // Cart Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFFE07A5F)),
                  const SizedBox(width: 8),
                  const Text('Keranjang Belanja',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE07A5F))),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12)), // Light Red
                child: Text('${cart.itemCount} Items',
                    style: const TextStyle(
                        color: Color(0xFFE07A5F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),

        // Customer Selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: InkWell(
            onTap: () async {
              final controller =
                  TextEditingController(text: cart.customerName ?? '');
              final result = await showDialog<String?>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Pelanggan'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Nama pelanggan (opsional)',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Umum'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
              cart.setCustomerName(result);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cart.customerName == null
                          ? 'Pelanggan: Umum'
                          : 'Pelanggan: ${cart.customerName}',
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Text('Belum ada item dipilih',
                        style: TextStyle(color: Colors.grey[400])),
                  ],
                ))
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
                                border: Border.all(color: Colors.grey[200]!)),
                            child: Column(
                              children: [
                                InkWell(
                                    onTap: () {
                                      final product = products.firstWhere(
                                          (p) => p['id'] == item.productId,
                                          orElse: () => {});
                                      final stock =
                                          (product['stock'] ?? 0) as int;
                                      if (stock <= 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Stok produk ini sudah habis')),
                                        );
                                        return;
                                      }
                                      if (item.quantity >= stock) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Maksimal stok tersedia hanya $stock')),
                                        );
                                        return;
                                      }
                                      cart.addItem(item.productId, item.name,
                                          item.price);
                                    },
                                    child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.keyboard_arrow_up,
                                            size: 16))),
                                InkWell(
                                  onTap: () async {
                                    final ctrl = TextEditingController(
                                        text: item.quantity.toString());
                                    final result = await showDialog<int>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Set Jumlah'),
                                        content: TextField(
                                          controller: ctrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          decoration: const InputDecoration(
                                              hintText: 'Masukkan qty'),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Batal')),
                                          FilledButton(
                                            onPressed: () {
                                              final val =
                                                  int.tryParse(ctrl.text);
                                              Navigator.pop(context, val);
                                            },
                                            child: const Text('Simpan'),
                                          )
                                        ],
                                      ),
                                    );
                                    if (result != null) {
                                      final product = products.firstWhere(
                                          (p) => p['id'] == item.productId,
                                          orElse: () => {});
                                      final stock =
                                          (product['stock'] ?? 0) as int;
                                      if (stock > 0 && result > stock) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Jumlah melebihi stok ($stock).')),
                                        );
                                        return;
                                      }
                                      cart.setItemQuantity(
                                          item.productId, result);
                                    }
                                  },
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                                InkWell(
                                    onTap: () =>
                                        cart.removeSingleItem(item.productId),
                                    child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.keyboard_arrow_down,
                                            size: 16))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(currency.format(item.price),
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(currency.format(item.price * item.quantity),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Footer (Totals)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Subtotal', style: TextStyle(color: Colors.grey[600])),
                Text(currency.format(cart.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Pajak', style: TextStyle(color: Colors.grey[600])),
                const Text('-', style: TextStyle(fontWeight: FontWeight.bold))
              ]),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider()),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(currency.format(cart.totalAmount),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5)))
              ]),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: cart.itemCount == 0
                          ? null
                          : () async {
                              final success =
                                  await _processPayment(context, cart);
                              if (success == true && onClose != null) onClose();
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            const Color(0xFFE07A5F), // [FIX] Red Brand
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bayar Sekarang',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(currency.format(cart.totalAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ))),
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
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24))),
                  child: _buildCartSidebar(context, cart,
                      scrollController: ctrl,
                      onClose: () => Navigator.pop(context)),
                )));
  }

  Future<bool> _processPayment(BuildContext context, CartProvider cart) async {
    final success = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 400,
              child: PaymentScreen(cart: cart),
            )));

    if (success == true && context.mounted) {
      await _loadProducts();
      SoundService.playSuccess();
      showDialog(
          context: context, builder: (_) => const TransactionSuccessDialog());
      cart.clear();
      return true;
    }
    return false;
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // --- Tablet/Desktop Layout Support ---

  Widget _buildDesktopLayout(
      BuildContext context, BoxConstraints constraints, CartProvider cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Navigation Rail
        _buildDesktopNavigationRail(),

        // 2. Main Content
        Expanded(
          flex: 7,
          child: _buildDesktopContent(context, cart),
        ),

        // 3. Persistent Cart Sidebar
        Container(
          width: 380, // Fixed width for sidebar
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey[200]!)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(-4, 0))
            ],
          ),
          child: _buildCartSidebar(context, cart),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: NavigationRail(
        selectedIndex: _desktopSelectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _desktopSelectedIndex = index;
            // Map index to mobile bottom nav index for compatibility
            if (index == 0) _bottomNavIndex = 0; // Home
            if (index == 1) _bottomNavIndex = 1; // Activity
            if (index == 2) _bottomNavIndex = 2; // Wallet
            if (index == 3) _bottomNavIndex = 3; // Profile

            // Handle specific routes for other items if needed
            if (index == 4) Navigator.pushNamed(context, '/products');
            if (index == 5) Navigator.pushNamed(context, '/report');
          });
        },
        labelType: NavigationRailLabelType.all,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFFE07A5F).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.storefront,
                color: Color(0xFFE07A5F), size: 28),
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Beranda'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: Text('Aktivitas'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: Text('Keuangan'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profil'),
          ),
          // Extra Tablet Items
          NavigationRailDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: Text('Produk'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Text('Laporan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, CartProvider cart) {
    // If we are on Home tab (0), show the POS grid
    if (_desktopSelectedIndex == 0) {
      return Column(
        children: [
          // Tablet Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kasir',
                        style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B))),
                    Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: GoogleFonts.outfit(
                            color: Colors.grey[500], fontSize: 14))
                  ],
                ),
                const Spacer(),
                // Search Bar
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)),
                  child: TextField(
                    onChanged: _filterProducts,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Data',
                )
              ],
            ),
          ),

          // Categories
          _buildCategoryTabs(),

          // Product Grid
          Expanded(
            child: _buildProductGrid(context, cart,
                crossAxisCount: 4, // 4 items per row on tablet
                aspectRatio: 0.85),
          ),
        ],
      );
    }

    // Placeholder for other tabs
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Fitur ini sedang dikembangkan',
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500]))
        ],
      ),
    );
  }
}
