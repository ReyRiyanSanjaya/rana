import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/screens/market_cart_screen.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/store_detail_screen.dart';
import 'package:rana_market/providers/search_history_provider.dart';
import 'package:rana_market/providers/reviews_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:rana_market/providers/orders_provider.dart';
import 'package:rana_market/screens/order_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  String _address = 'Mencari Lokasi...';
  List<dynamic> _nearbyStores = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _flashSaleProducts = []; // [NEW]
  bool _isLoading = true;
  bool _annLoading = true;
  bool _flashLoading = true; // [NEW]
  String _selectedCategory = 'All';
  List<String> _categories = const ['All'];
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;
  Timer? _flashTimer;
  Duration _timeLeft = Duration.zero;
  DateTime? _flashEndTime;

  // Filters
  String _sortBy = 'distance'; // distance, rating
  double _minRating = 0;
  bool _promoOnly = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _initLocation();
    _startFlashTimer();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = (prefs.getString('buyer_phone') ?? '').trim();
    if (phone.isEmpty) return;

    // Silent fetch to update orders if needed
    try {
      final list = await MarketApiService().getMyOrders(phone: phone);
      if (!mounted) return;
      Provider.of<OrdersProvider>(context, listen: false).setAll(list);
    } catch (_) {}
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Sedang Diproses';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_TO_PICKUP':
        return 'Siap Diambil';
      case 'READY':
        return 'Siap Diambil';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'REJECTED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'PROCESSING':
        return Colors.blue;
      case 'READY_TO_PICKUP':
      case 'READY':
        return Colors.green;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(num number) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(number);
  }

  String _getItemSummary(Map<String, dynamic> order) {
    final items = order['transactionItems'] as List<dynamic>? ?? [];
    if (items.isEmpty) return 'Tidak ada item';

    final summaries = items.map((item) {
      final qty = item['quantity'] ?? 1;
      String name = 'Item';
      if (item['productName'] != null) {
        name = item['productName'];
      } else if (item['name'] != null) {
        name = item['name'];
      } else if (item['product'] is Map) {
        name = item['product']['name'] ?? 'Item';
      }
      return '$qty x $name';
    }).toList();

    if (summaries.length <= 1) {
      return summaries.join(', ');
    } else {
      return '${summaries.first} +${summaries.length - 1} lainnya';
    }
  }

  void _startFlashTimer() {
    _flashTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_flashEndTime != null) {
            final now = DateTime.now();
            if (_flashEndTime!.isAfter(now)) {
              _timeLeft = _flashEndTime!.difference(now);
            } else {
              _timeLeft = Duration.zero;
            }
          }
        });
      }
    });
  }

  Future<void> _loadAnnouncements() async {
    final list = await MarketApiService().getAnnouncements();
    final items =
        list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (!mounted) return;
    setState(() {
      _announcements = items;
      _annLoading = false;
    });
  }

  Future<void> _initLocation() async {
    // 1. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // 2. Get Position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _address = 'Lat: ${position.latitude.toStringAsFixed(4)}');

      // 3. Fetch API
      await Future.wait([
        _fetchNearby(position.latitude, position.longitude),
        _loadFlashSale(position.latitude, position.longitude), // [NEW]
      ]);
    } else {
      setState(() {
        _address = 'Lokasi Ditolak';
        _isLoading = false;
        _flashLoading = false;
      });
    }
  }

  Future<void> _loadFlashSale(double lat, double long) async {
    final products = await MarketApiService().getFlashSaleProducts(lat, long);
    if (!mounted) return;

    DateTime? endTime;
    if (products.isNotEmpty) {
      // Get the earliest end time from the products list to be safe,
      // or just take the first one since they are usually grouped.
      // We'll verify if flashSaleEndAt exists.
      for (final p in products) {
        if (p['flashSaleEndAt'] != null) {
          final dt = DateTime.tryParse(p['flashSaleEndAt'].toString());
          if (dt != null) {
            // If endTime is null or this dt is sooner than current endTime?
            // Usually we want to show the timer for the active flash sale.
            // Let's just pick the first valid one for now as the main timer.
            endTime = dt;
            break;
          }
        }
      }
    }

    setState(() {
      _flashSaleProducts =
          products.map((e) => Map<String, dynamic>.from(e)).toList();
      _flashLoading = false;
      _flashEndTime = endTime;
      if (_flashEndTime != null) {
        final now = DateTime.now();
        if (_flashEndTime!.isAfter(now)) {
          _timeLeft = _flashEndTime!.difference(now);
        } else {
          _timeLeft = Duration.zero;
        }
      }
    });
  }

  Future<void> _fetchNearby(double lat, double long) async {
    final stores = await MarketApiService().getNearbyStores(lat, long);
    final cats = _extractCategories(stores);
    setState(() {
      _nearbyStores = stores;
      _categories = cats;
      if (!_categories.contains(_selectedCategory)) _selectedCategory = 'All';
      _isLoading = false;
    });
  }

  List<String> _extractCategories(List<dynamic> stores) {
    final set = <String>{};
    for (final s in stores) {
      if (s is! Map) continue;
      final c = s['category']?.toString().trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _flashTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter & Urutkan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Urutkan Berdasarkan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Terdekat'),
                        selected: _sortBy == 'distance',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'distance');
                          setState(() {});
                        },
                        selectedColor: const Color(0xFFE07A5F).withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: _sortBy == 'distance'
                                ? const Color(0xFFE07A5F)
                                : Colors.black),
                      ),
                      ChoiceChip(
                        label: const Text('Rating Tertinggi'),
                        selected: _sortBy == 'rating',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'rating');
                          setState(() {});
                        },
                        selectedColor: const Color(0xFFE07A5F).withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: _sortBy == 'rating'
                                ? const Color(0xFFE07A5F)
                                : Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Rating Minimal',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _minRating.toString(),
                    activeColor: const Color(0xFFE07A5F),
                    onChanged: (val) {
                      setModalState(() => _minRating = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Hanya Promo'),
                    value: _promoOnly,
                    activeColor: const Color(0xFFE07A5F),
                    onChanged: (val) {
                      setModalState(() => _promoOnly = val);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManualLocationDialog() {
    final controller = TextEditingController(text: _address);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Lokasi Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat kamu',
                helperText:
                    'Catatan: Toko terdekat tetap berdasarkan GPS terakhir.',
                helperMaxLines: 3,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _address = controller.text.trim();
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: _showManualLocationDialog,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE07A5F), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Lokasi Kamu',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.normal)),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: Colors.grey.shade600),
                      ],
                    ),
                    Text(_address,
                        style: const TextStyle(
                            fontSize: 14, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )
            ],
          ),
        ),
        actions: [
          Consumer<MarketCartProvider>(
            builder: (context, cart, _) {
              final count = cart.items.values
                  .fold<int>(0, (acc, it) => acc + it.quantity);
              return Stack(
                children: [
                  IconButton(
                      icon: const Icon(Icons.shopping_bag, // Solid icon
                          color: Colors.black),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MarketCartScreen()))),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE07A5F),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                        .animate(key: ValueKey(count))
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          if (!_annLoading) setState(() => _annLoading = true);
          await _loadAnnouncements();
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
            await _fetchNearby(pos.latitude, pos.longitude);
          } else {
            await _initLocation();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 300), () {
                          setState(() => _query = val.toLowerCase().trim());
                        });
                      },
                      onSubmitted: (val) {
                        Provider.of<SearchHistoryProvider>(context,
                                listen: false)
                            .addQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Butuh apa hari ini?',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: _showFilterSheet,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Active Filters
                    if (_sortBy != 'distance' || _minRating > 0 || _promoOnly)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_sortBy == 'rating')
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: const Text('Rating Tertinggi'),
                                  onDeleted: () =>
                                      setState(() => _sortBy = 'distance'),
                                  backgroundColor:
                                      const Color(0xFFE07A5F).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                      color: Color(0xFFE07A5F), fontSize: 12),
                                  deleteIconColor: const Color(0xFFE07A5F),
                                ),
                              ),
                            if (_minRating > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text('Rating $_minRating+'),
                                  onDeleted: () =>
                                      setState(() => _minRating = 0),
                                  backgroundColor:
                                      const Color(0xFFE07A5F).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                      color: Color(0xFFE07A5F), fontSize: 12),
                                  deleteIconColor: const Color(0xFFE07A5F),
                                ),
                              ),
                            if (_promoOnly)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: const Text('Promo'),
                                  onDeleted: () =>
                                      setState(() => _promoOnly = false),
                                  backgroundColor:
                                      const Color(0xFFE07A5F).withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                      color: Color(0xFFE07A5F), fontSize: 12),
                                  deleteIconColor: const Color(0xFFE07A5F),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Consumer<SearchHistoryProvider>(
                      builder: (context, hist, _) {
                        if (!hist.loaded || hist.history.isEmpty)
                          return const SizedBox.shrink();
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final q in hist.history)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    label: Text(q),
                                    onPressed: () {
                                      _searchCtrl.text = q;
                                      setState(() => _query = q.toLowerCase());
                                    },
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.2),
                              TextButton(
                                onPressed: () => hist.clear(),
                                child: const Text('Hapus Riwayat'),
                              )
                            ],
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),

              // Active Order Widget
              Consumer<OrdersProvider>(
                builder: (context, prov, _) {
                  final activeOrders = prov.orders.where((o) {
                    final s = o['orderStatus'] ?? 'PENDING';
                    return [
                      'PENDING',
                      'ACCEPTED',
                      'PROCESSING',
                      'READY_TO_PICKUP',
                      'READY'
                    ].contains(s);
                  }).toList();

                  if (activeOrders.isEmpty) return const SizedBox.shrink();

                  final o = activeOrders.first;
                  final status = o['orderStatus'] ?? 'PENDING';
                  final items = o['transactionItems'] as List<dynamic>? ?? [];
                  String? imageUrl;
                  if (items.isNotEmpty) {
                    final p = items.first['product'];
                    if (p is Map) {
                      final raw = p['imageUrl'] ?? p['image'];
                      if (raw != null) {
                        imageUrl =
                            MarketApiService().resolveFileUrl(raw.toString());
                      }
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: o))),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    _getStatusColor(status).withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Row(
                          children: [
                            // Image
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.fastfood,
                                                  color: Colors.grey)))
                                  : const Icon(Icons.fastfood,
                                      color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Text('Pesanan Berjalan',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Text(_getStatusText(status),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_getItemSummary(o),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  Text(o['store']?['name'] ?? 'Toko',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0);
                },
              ),

              // Banner Carousel
              if (_annLoading)
                const SizedBox(
                  height: 150,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE07A5F))),
                )
              else if (_announcements.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: PageView(
                    children: [
                      for (var i = 0; i < _announcements.length && i < 5; i++)
                        _buildAnnouncementBanner(_announcements[i], i),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 24),

              // Flash Sale Section
              if (_flashSaleProducts.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Stack(
                          children: [
                            // Dynamic Gradient Background
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFE07A5F).withOpacity(0.25),
                                    const Color(0xFFF4DCD6),
                                    const Color(0xFFE07A5F).withOpacity(0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .tint(
                                    color: const Color(0xFFFFCCBC)
                                        .withOpacity(0.3),
                                    duration: 4.seconds),

                            // Lottie Fire/Energy Effect (Subtle)
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Opacity(
                                opacity: 0.15,
                                child: Lottie.network(
                                  'https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json', // Fire
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(),
                                ),
                              ),
                            ),

                            // Lottie Sparkles (Overlay)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.2,
                                child: Lottie.network(
                                  'https://assets4.lottiefiles.com/packages/lf20_s2lryxtd.json', // Particles
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.flash_on_rounded,
                                        color: Color(0xFFE07A5F), size: 28)
                                    .animate(onPlay: (c) => c.repeat())
                                    .shimmer(
                                        duration: 1200.ms, color: Colors.yellow)
                                    .shake(hz: 4, curve: Curves.easeInOutCubic),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Flash Sale',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Color(0xFFE07A5F))),
                                    Text('Berakhir dalam',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE07A5F),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE07A5F)
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer_outlined,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_timeLeft.inHours.toString().padLeft(2, '0')} : ${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')} : ${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 280, // Increased height
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              scrollDirection: Axis.horizontal,
                              itemCount: _flashSaleProducts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final p = _flashSaleProducts[index];
                                final price =
                                    (p['sellingPrice'] as num).toDouble();
                                final original =
                                    (p['originalPrice'] as num).toDouble();
                                final discount =
                                    (p['discountPercentage'] as num).toInt();
                                final imageUrl = MarketApiService()
                                    .resolveFileUrl(
                                        p['imageUrl'] ?? p['image']);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
                                                  product: p,
                                                  storeId: p['storeId'],
                                                  storeName: p['storeName'],
                                                  storeAddress:
                                                      p['storeAddress'],
                                                  storeLat:
                                                      (p['storeLat'] as num?)
                                                          ?.toDouble(),
                                                  storeLong:
                                                      (p['storeLong'] as num?)
                                                          ?.toDouble(),
                                                )));
                                  },
                                  child: Container(
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(20)),
                                                child: imageUrl.isEmpty
                                                    ? Container(
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Center(
                                                            child: Icon(
                                                                Icons.fastfood,
                                                                color: Colors
                                                                    .grey)))
                                                    : Image.network(
                                                        imageUrl,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __,
                                                                ___) =>
                                                            Container(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200),
                                                      ),
                                              ),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.red
                                                              .withOpacity(0.4),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        )
                                                      ]),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .local_fire_department,
                                                          color: Colors.white,
                                                          size: 12),
                                                      const SizedBox(width: 2),
                                                      Text('$discount%',
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                )
                                                    .animate(
                                                        onPlay: (c) => c.repeat(
                                                            reverse: true))
                                                    .scale(
                                                        begin:
                                                            const Offset(1, 1),
                                                        end: const Offset(
                                                            1.1, 1.1),
                                                        duration: 1000.ms),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(p['name'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              const SizedBox(height: 6),
                                              Text('Rp ${original.toInt()}',
                                                  style: const TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 11)),
                                              Text('Rp ${price.toInt()}',
                                                  style: const TextStyle(
                                                      color: Color(0xFFE07A5F),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 16)),
                                              const SizedBox(height: 10),
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 6,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                    ),
                                                  ),
                                                  FractionallySizedBox(
                                                    widthFactor: 0.85,
                                                    child: Container(
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                                colors: [
                                                              Color(0xFFE07A5F),
                                                              Colors.redAccent
                                                            ]),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Row(
                                                children: [
                                                  Icon(Icons.whatshot,
                                                      size: 12,
                                                      color: Colors.red),
                                                  SizedBox(width: 4),
                                                  Text('Segera Habis',
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                                    .animate(delay: (index * 100).ms)
                                    .fadeIn()
                                    .slideX(
                                        begin: 0.2, curve: Curves.easeOutBack);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Untuk Kamu',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220, // Increased height for better card ratio
                child: Consumer2<ReviewsProvider, SearchHistoryProvider>(
                  builder: (context, rev, hist, _) {
                    final all = <Map<String, dynamic>>[];
                    for (final s in _nearbyStores) {
                      if (s is! Map) continue;
                      final prods =
                          (s['products'] as List<dynamic>? ?? const []);
                      for (final p in prods) {
                        if (p is! Map) continue;
                        final map = Map<String, dynamic>.from(p);
                        map['__storeId'] = s['id'];
                        map['__storeName'] = s['name'];
                        map['__storeDistance'] = s['distance'];
                        map['__storeAddress'] =
                            (s['address'] ?? s['location'] ?? s['alamat'])
                                ?.toString();
                        map['__storeLat'] = (s['latitude'] as num?)?.toDouble();
                        map['__storeLong'] =
                            (s['longitude'] as num?)?.toDouble();
                        all.add(map);
                      }
                    }
                    final lastQuery =
                        (hist.history.isNotEmpty ? hist.history.first : '')
                            .toLowerCase();

                    // Filter logic
                    final filteredAll = all.where((p) {
                      final avg = rev.getAverage(p['id']);
                      if (avg < _minRating) return false;
                      if (_promoOnly) {
                        // Check if discount exists
                        final price =
                            (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                        final original =
                            (p['originalPrice'] as num?)?.toDouble();
                        if (original == null || original <= price) return false;
                      }
                      return true;
                    }).toList();

                    filteredAll.sort((a, b) {
                      final ar = rev.getAverage(a['id']);
                      final br = rev.getAverage(b['id']);

                      // Sort by selected criteria
                      if (_sortBy == 'rating') {
                        if (ar != br) return br.compareTo(ar);
                      } else {
                        // Distance
                        final ad =
                            (a['__storeDistance'] as num?)?.toDouble() ?? 99999;
                        final bd =
                            (b['__storeDistance'] as num?)?.toDouble() ?? 99999;
                        if (ad != bd) return ad.compareTo(bd);
                      }

                      final am = lastQuery.isEmpty
                          ? 0
                          : ((a['name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(lastQuery)
                              ? 1
                              : 0);
                      final bm = lastQuery.isEmpty
                          ? 0
                          : ((b['name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains(lastQuery)
                              ? 1
                              : 0);

                      return bm.compareTo(am);
                    });
                    final list = filteredAll.take(12).toList();
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final avg = rev.getAverage(p['id']);
                        final imageUrl = MarketApiService()
                            .resolveFileUrl(p['imageUrl'] ?? p['image']);
                        final dynamic distV = p['__storeDistance'];
                        final distNum = (distV is num)
                            ? distV.toDouble()
                            : double.tryParse(distV?.toString() ?? '');
                        final distText = distNum?.toStringAsFixed(1);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                          product: p,
                                          storeId: p['__storeId'],
                                          storeName: p['__storeName'],
                                          storeAddress: p['__storeAddress'],
                                          storeLat: p['__storeLat'],
                                          storeLong: p['__storeLong'],
                                        )));
                          },
                          child: Container(
                            width: 180, // Wider card
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3, // More space for image
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: imageUrl.isEmpty
                                        ? Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                                child: Icon(Icons.fastfood,
                                                    size: 30,
                                                    color: Colors.grey)),
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                    child: Icon(Icons.fastfood,
                                                        size: 30,
                                                        color: Colors.grey)),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p['name'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        Row(
                                          children: [
                                            Icon(Icons.star_rounded, // Solid
                                                size: 16,
                                                color: const Color(0xFFF2CC8F)),
                                            const SizedBox(width: 4),
                                            Text(avg.toStringAsFixed(1),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12)),
                                            const Spacer(),
                                            if (distText != null) ...[
                                              Icon(Icons.place,
                                                  size: 14,
                                                  color: Colors.grey.shade400),
                                              const SizedBox(width: 2),
                                              Text('$distText km',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .grey.shade600)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                            .animate(delay: (i * 100).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.1);
                      },
                    );
                  },
                ),
              ),

              // Categories
              if (_categories.length > 1) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Kategori',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final label = cat == 'All' ? 'Semua' : cat;
                      return _buildCategoryItem(
                        _iconForCategory(cat),
                        label,
                        _colorForCategory(cat),
                        category: cat,
                        isSelected: _selectedCategory == cat,
                        index: index,
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Nearby Merchants
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Merchant Terdekat ${_selectedCategory == 'All' ? '' : '($_selectedCategory)'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    if (_isLoading)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Real List
              _nearbyStores.isEmpty && !_isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada toko di sekitar.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyStores.length,
                      itemBuilder: (context, index) {
                        final store = _nearbyStores[index];

                        // Client-side filter
                        if (_selectedCategory != 'All' &&
                            store['category'] != _selectedCategory) {
                          return const SizedBox.shrink();
                        }

                        final dynamic distV = store['distance'];
                        final distNum = (distV is num)
                            ? distV.toDouble()
                            : double.tryParse(distV?.toString() ?? '');
                        final dist = distNum?.toStringAsFixed(1) ?? '-';
                        final prods = store['products'] as List<dynamic>? ?? [];
                        final filtered = _query.isEmpty
                            ? prods
                            : prods
                                .where((p) => (p['name'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(_query))
                                .toList();
                        if (_query.isNotEmpty && filtered.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final storeAddr = (store['address'] ??
                                    store['location'] ??
                                    store['alamat'])
                                ?.toString() ??
                            '-';
                        final storeImageUrl = MarketApiService().resolveFileUrl(
                            store['imageUrl'] ??
                                store['storeImageUrl'] ??
                                store['image']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Store Header
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade100))),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50, // Bigger store icon
                                      height: 50,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: storeImageUrl.isEmpty
                                          ? const Icon(Icons.store,
                                              color: Colors.grey)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                storeImageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Icon(Icons.store,
                                                      color: Colors.grey);
                                                },
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(store['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          const SizedBox(height: 2),
                                          Text(storeAddr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFE07A5F)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(store['category'],
                                              style: const TextStyle(
                                                  color: Color(0xFFE07A5F),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.place,
                                                size: 12,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text('$dist km',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        Colors.grey.shade700)),
                                          ],
                                        ),
                                        TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          StoreDetailScreen(
                                                              store: store)));
                                            },
                                            child: const Text('Kunjungi',
                                                style: TextStyle(fontSize: 12)))
                                      ],
                                    )
                                  ],
                                ),
                              ),

                              // Product Horizontal List
                              if ((filtered).isNotEmpty)
                                Container(
                                  height: 160, // Taller for cards
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(16)),
                                  ),
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (ctx, i) {
                                      final p = filtered[i];
                                      return Consumer2<FavoritesProvider,
                                          ReviewsProvider>(
                                        builder: (context, fav, rev, _) {
                                          final isFav = fav.isFavorite(p['id']);
                                          final avg = rev.getAverage(p['id']);
                                          final imageUrl = MarketApiService()
                                              .resolveFileUrl(
                                                  p['imageUrl'] ?? p['image']);
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          ProductDetailScreen(
                                                            product: p,
                                                            storeId:
                                                                store['id'],
                                                            storeName:
                                                                store['name'],
                                                            storeAddress: (store[
                                                                        'address'] ??
                                                                    store[
                                                                        'location'] ??
                                                                    store[
                                                                        'alamat'])
                                                                ?.toString(),
                                                            storeLat: ((store[
                                                                            'latitude'] ??
                                                                        store[
                                                                            'lat'])
                                                                    is num)
                                                                ? (store['latitude'] ??
                                                                        store[
                                                                            'lat'])
                                                                    .toDouble()
                                                                : null,
                                                            storeLong: ((store[
                                                                            'longitude'] ??
                                                                        store[
                                                                            'long'] ??
                                                                        store['lng'])
                                                                    is num)
                                                                ? (store['longitude'] ??
                                                                        store[
                                                                            'long'] ??
                                                                        store[
                                                                            'lng'])
                                                                    .toDouble()
                                                                : null,
                                                          )));
                                            },
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: 130,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.1),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        )
                                                      ]),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          12)),
                                                          child:
                                                              imageUrl.isEmpty
                                                                  ? Container(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade200,
                                                                      child: const Center(
                                                                          child: Icon(
                                                                              Icons.fastfood,
                                                                              size: 30,
                                                                              color: Colors.grey)),
                                                                    )
                                                                  : Image
                                                                      .network(
                                                                      imageUrl,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      width: double
                                                                          .infinity,
                                                                      errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) {
                                                                        return Container(
                                                                          color: Colors
                                                                              .grey
                                                                              .shade200,
                                                                          child:
                                                                              const Center(child: Icon(Icons.fastfood, size: 30, color: Colors.grey)),
                                                                        );
                                                                      },
                                                                    ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(p['name'],
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12)),
                                                            Text(
                                                                'Rp ${p['sellingPrice']}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Color(
                                                                        0xFFE07A5F),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .star_rounded,
                                                                    size: 14,
                                                                    color: const Color(
                                                                        0xFFF2CC8F)),
                                                                Text(
                                                                    avg.toStringAsFixed(
                                                                        1),
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12)),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 4,
                                                  top: 4,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                          isFav
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: isFav
                                                              ? Colors.red
                                                              : Colors.grey),
                                                      onPressed: () =>
                                                          fav.toggleFavorite(
                                                              p['id']),
                                                      iconSize: 18,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ).animate(delay: (index * 50).ms).fadeIn().slideY(
                              begin: 0.1,
                              duration: 400.ms,
                              curve: Curves.easeOutQuad,
                            );
                      },
                    ),

              const SizedBox(height: 80), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner(Map<String, dynamic> a, int index) {
    final palette = <Color>[
      const Color(0xFFE07A5F),
      const Color(0xFF81B29A),
      const Color(0xFFF2CC8F),
      const Color(0xFF3D405B),
    ];
    final bg = palette[index % palette.length];
    final title = (a['title'] ?? a['name'] ?? '-').toString();
    final subtitle = (a['content'] ?? a['message'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.campaign,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white)),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c == 'all') return Icons.store;
    if (c.contains('apotik') || c.contains('pharmacy'))
      return Icons.local_pharmacy;
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai'))
      return Icons.restaurant;
    if (c.contains('baju') || c.contains('fashion')) return Icons.checkroom;
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp'))
      return Icons.smartphone;
    if (c.contains('kelontong') || c.contains('grocery'))
      return Icons.storefront;
    return Icons.category;
  }

  Color _colorForCategory(String category) {
    final c = category.toLowerCase();
    // Soft Earthy/Pastel Palette based on Brand Color #E07A5F
    if (c == 'all') return const Color(0xFFE07A5F);
    if (c.contains('apotik') || c.contains('pharmacy'))
      return const Color(0xFF81B29A); // Soft Green
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai'))
      return const Color(0xFFE07A5F); // Brand Color
    if (c.contains('baju') || c.contains('fashion'))
      return const Color(0xFFF4A261); // Soft Orange
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp'))
      return const Color(0xFF9D8189); // Soft Mauve
    if (c.contains('kelontong') || c.contains('grocery'))
      return const Color(0xFFF2CC8F); // Soft Yellow
    return const Color(0xFFE07A5F);
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color,
      {required String category, bool isSelected = false, required int index}) {
    return GestureDetector(
      onTap: () => setState(() {
        if (category != 'All' && isSelected) {
          _selectedCategory = 'All';
        } else {
          _selectedCategory = category;
        }
      }),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : color.withOpacity(0.1), // Soft background
              borderRadius: BorderRadius.circular(16),
              // Removed border for softer look
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12, // Softer shadow
                          offset: const Offset(0, 6))
                    ]
                  : [],
            ),
            child: Icon(icon, color: isSelected ? Colors.white : color),
          )
              .animate(target: isSelected ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? color
                      : Colors.grey.shade600, // Colored text when selected
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}
