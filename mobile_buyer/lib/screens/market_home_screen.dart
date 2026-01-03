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
  String _selectedCategory = 'All';
  List<String> _categories = const ['All'];
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;
  Timer? _flashTimer;
  Duration _timeLeft = Duration.zero;
  DateTime? _flashEndTime;
  List<String> _recentProductIds = [];

  // Filters
  String _sortBy = 'distance'; // distance, rating
  double _minRating = 0;
  bool _promoOnly = false;

  String _greetingTitle() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Rekomendasi Pagi Ini';
    if (hour >= 11 && hour < 15) return 'Pilihan Siang Hari';
    if (hour >= 15 && hour < 19) return 'Ngemil Sore & Malam';
    return 'Untuk Kamu';
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _initLocation();
    _startFlashTimer();
    _loadOrders();
    _loadRecentViewed();
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

  Future<void> _loadRecentViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        prefs.getStringList('buyer_recent_products_v1') ?? const [];
    if (!mounted) return;
    setState(() {
      _recentProductIds = list;
    });
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
      if (!mounted || _flashEndTime == null) return;
      final now = DateTime.now();
      final end = _flashEndTime;
      setState(() {
        if (end != null && end.isAfter(now)) {
          _timeLeft = end.difference(now);
        } else {
          _timeLeft = Duration.zero;
        }
      });
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
      // Flash loading finished
      _flashEndTime = endTime;
      final end = _flashEndTime;
      if (end != null) {
        final now = DateTime.now();
        _timeLeft = end.isAfter(now)
            ? end.difference(now)
            : Duration.zero;
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
                        selectedColor:
                            const Color(0xFFE07A5F).withValues(alpha: 0.2),
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
                        selectedColor:
                            const Color(0xFFE07A5F).withValues(alpha: 0.2),
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
                    activeTrackColor:
                        const Color(0xFFE07A5F).withValues(alpha: 0.5),
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
          await _loadRecentViewed();
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: const Text('Makan Siang dekat sini'),
                              onPressed: () {
                                const q = 'makan siang';
                                _searchCtrl.text = q;
                                setState(
                                    () => _query = q.toLowerCase().trim());
                                Provider.of<SearchHistoryProvider>(context,
                                        listen: false)
                                    .addQuery(q);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: const Text('Cemilan'),
                              onPressed: () {
                                const q = 'cemilan';
                                _searchCtrl.text = q;
                                setState(
                                    () => _query = q.toLowerCase().trim());
                                Provider.of<SearchHistoryProvider>(context,
                                        listen: false)
                                    .addQuery(q);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: const Text('Obat & Vitamin'),
                              onPressed: () {
                                const q = 'obat';
                                _searchCtrl.text = q;
                                setState(
                                    () => _query = q.toLowerCase().trim());
                                Provider.of<SearchHistoryProvider>(context,
                                        listen: false)
                                    .addQuery(q);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: const Text('Minuman dingin'),
                              onPressed: () {
                                const q = 'minuman dingin';
                                _searchCtrl.text = q;
                                setState(
                                    () => _query = q.toLowerCase().trim());
                                Provider.of<SearchHistoryProvider>(context,
                                        listen: false)
                                    .addQuery(q);
                              },
                            ),
                          ),
                        ],
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
                                  backgroundColor: const Color(0xFFE07A5F)
                                      .withValues(alpha: 0.1),
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
                                  backgroundColor: const Color(0xFFE07A5F)
                                      .withValues(alpha: 0.1),
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
                                  backgroundColor: const Color(0xFFE07A5F)
                                      .withValues(alpha: 0.1),
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
                        if (!hist.loaded || hist.history.isEmpty) {
                          return const SizedBox.shrink();
                        }
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
                                color: _getStatusColor(status)
                                    .withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.05),
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
                                    const Color(0xFFE07A5F)
                                        .withValues(alpha: 0.25),
                                    const Color(0xFFF4DCD6),
                                    const Color(0xFFE07A5F)
                                        .withValues(alpha: 0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .tint(
                                    color: const Color(0xFFFFCCBC)
                                        .withValues(alpha: 0.3),
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
                                              .withValues(alpha: 0.4),
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
                                          storeAddress: p['storeAddress'],
                                          storeLat:
                                              (p['storeLat'] as num?)?.toDouble(),
                                          storeLong:
                                              (p['storeLong'] as num?)?.toDouble(),
                                        ),
                                      ),
                                    ).then((_) => _loadRecentViewed());
                                  },
                                  child: Container(
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
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
                                                              .withValues(alpha: 0.4),
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

              Consumer<OrdersProvider>(
                builder: (context, prov, _) {
                  final completed = prov.orders.where((o) {
                    final s = (o['orderStatus'] ?? '').toString();
                    return s == 'COMPLETED';
                  }).toList();

                  if (completed.isEmpty) return const SizedBox.shrink();

                  final nearbyStoreMap = <String, Map<String, dynamic>>{};
                  for (final s in _nearbyStores) {
                    if (s is! Map) continue;
                    final sid = s['id']?.toString();
                    if (sid == null) continue;
                    nearbyStoreMap[sid] = Map<String, dynamic>.from(s);
                  }

                  final counts = <String, int>{};
                  final products = <String, Map<String, dynamic>>{};
                  final lastTime = <String, DateTime>{};

                  for (final o in completed) {
                    if (o is! Map) continue;

                    Map<String, dynamic>? store;
                    String? storeId;
                    final storeRaw = o['store'];
                    if (storeRaw is Map) {
                      store = Map<String, dynamic>.from(storeRaw);
                      final rawId = store['id'] ?? store['storeId'];
                      if (rawId != null) {
                        storeId = rawId.toString();
                      }
                    } else {
                      final rawId = o['storeId'];
                      if (rawId != null) {
                        storeId = rawId.toString();
                      }
                    }

                    if (storeId != null) {
                      final nearby = nearbyStoreMap[storeId];
                      if (nearby != null) {
                        store ??= <String, dynamic>{};
                        store.addAll(nearby);
                      }
                    }

                    DateTime? createdAt;
                    if (o['createdAt'] != null) {
                      createdAt = DateTime.tryParse(o['createdAt'].toString());
                    }

                    final items =
                        o['transactionItems'] as List<dynamic>? ?? [];
                    for (final it in items) {
                      if (it is! Map) continue;

                      String? pid;
                      if (it['productId'] != null) {
                        pid = it['productId'].toString();
                      } else if (it['product'] is Map &&
                          (it['product']['id'] != null)) {
                        pid = it['product']['id'].toString();
                      } else if (it['product'] is String) {
                        pid = it['product'].toString();
                      }
                      if (pid == null) continue;

                      final qty = it['quantity'] as int? ?? 1;
                      counts[pid] = (counts[pid] ?? 0) + qty;

                      if (createdAt != null) {
                        final prev = lastTime[pid];
                        if (prev == null || createdAt.isAfter(prev)) {
                          lastTime[pid] = createdAt;
                        }
                      }

                      if (!products.containsKey(pid)) {
                        String name = 'Item';
                        if (it['productName'] != null) {
                          name = it['productName'].toString();
                        } else if (it['name'] != null) {
                          name = it['name'].toString();
                        } else if (it['product'] is Map &&
                            (it['product']['name'] != null)) {
                          name = it['product']['name'].toString();
                        }

                        double price = (it['price'] as num?)?.toDouble() ??
                            (it['sellingPrice'] as num?)?.toDouble() ??
                            (it['product'] is Map
                                ? (it['product']['sellingPrice'] as num?)
                                    ?.toDouble()
                                : null) ??
                            0;

                        double? original =
                            (it['originalPrice'] as num?)?.toDouble();
                        if (original == null && it['product'] is Map) {
                          final pMap = it['product'] as Map;
                          final orig = pMap['originalPrice'] ??
                              pMap['price'] ??
                              pMap['sellingPrice'];
                          if (orig is num) {
                            original = orig.toDouble();
                          }
                        }

                        dynamic rawImg;
                        if (it['product'] is Map) {
                          rawImg = (it['product']['imageUrl'] ??
                              it['product']['image']);
                        }
                        final imageUrl = rawImg != null
                            ? MarketApiService()
                                .resolveFileUrl(rawImg.toString())
                            : '';

                        String? storeName;
                        String? storeAddress;
                        double? storeLat;
                        double? storeLong;
                        dynamic distV;
                        if (store != null) {
                          storeName = store['name']?.toString();
                          storeAddress = (store['address'] ??
                                  store['location'] ??
                                  store['alamat'])
                              ?.toString();
                          final lat = store['latitude'];
                          final long = store['longitude'];
                          if (lat is num) {
                            storeLat = lat.toDouble();
                          }
                          if (long is num) {
                            storeLong = long.toDouble();
                          }
                          distV = store['distance'];
                        }

                        double? storeDist;
                        if (distV is num) {
                          storeDist = distV.toDouble();
                        } else if (distV != null) {
                          storeDist =
                              double.tryParse(distV.toString());
                        }

                        products[pid] = {
                          'id': pid,
                          'name': name,
                          'sellingPrice': price,
                          if (original != null) 'originalPrice': original,
                          'imageUrl': imageUrl,
                          '__storeId': storeId,
                          '__storeName': storeName,
                          '__storeAddress': storeAddress,
                          '__storeLat': storeLat,
                          '__storeLong': storeLong,
                          '__storeDistance': storeDist,
                        };
                      }
                    }
                  }

                  if (products.isEmpty) return const SizedBox.shrink();

                  final entries = counts.entries.toList()
                    ..sort((a, b) {
                      final cmp = b.value.compareTo(a.value);
                      if (cmp != 0) return cmp;
                      final ta = lastTime[a.key];
                      final tb = lastTime[b.key];
                      if (ta == null || tb == null) return 0;
                      return tb.compareTo(ta);
                    });

                  final takeIds =
                      entries.take(10).map((e) => e.key).toList();
                  final list = <Map<String, dynamic>>[];
                  for (final id in takeIds) {
                    final p = products[id];
                    if (p != null) list.add(p);
                  }

                  if (list.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Sering Kamu Beli',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: Consumer2<FavoritesProvider, ReviewsProvider>(
                          builder: (context, fav, rev, _) {
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final p = list[i];
                                final imageUrl = MarketApiService()
                                    .resolveFileUrl(
                                        p['imageUrl'] ?? p['image']);
                                final dynamic distV =
                                    p['__storeDistance'];
                                final distNum = (distV is num)
                                    ? distV.toDouble()
                                    : double.tryParse(
                                        distV?.toString() ?? '');
                                final distText =
                                    distNum?.toStringAsFixed(1);
                                final avg = rev.getAverage(p['id']);
                                final selling =
                                    (p['sellingPrice'] as num?)?.toDouble() ??
                                        0;
                                final original =
                                    (p['originalPrice'] as num?)
                                        ?.toDouble();
                                final hasPromo = original != null &&
                                    original > selling &&
                                    original > 0;
                                final discountPct = hasPromo
                                    ? ((1 - selling / original) * 100)
                                        .round()
                                    : null;
                                final isFav = fav.isFavorite(p['id']);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailScreen(
                                          product: p,
                                          storeId: p['__storeId'],
                                          storeName: p['__storeName'],
                                          storeAddress:
                                              p['__storeAddress'],
                                          storeLat: p['__storeLat'],
                                          storeLong: p['__storeLong'],
                                        ),
                                      ),
                                    ).then((_) => _loadRecentViewed());
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 160,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8,
                                              offset:
                                                  const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                  top:
                                                      Radius.circular(16),
                                                ),
                                                child: imageUrl.isEmpty
                                                    ? Container(
                                                        color: Colors
                                                            .grey.shade200,
                                                        child:
                                                            const Center(
                                                          child: Icon(
                                                            Icons.fastfood,
                                                            size: 30,
                                                            color: Colors
                                                                .grey,
                                                          ),
                                                        ),
                                                      )
                                                    : Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Image
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
                                                                      const Center(
                                                                    child:
                                                                        Icon(
                                                                      Icons.fastfood,
                                                                      size:
                                                                          30,
                                                                      color:
                                                                          Colors.grey,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          if (discountPct !=
                                                              null)
                                                            Positioned(
                                                              left: 8,
                                                              top: 8,
                                                              child:
                                                                  Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                  horizontal:
                                                                      6,
                                                                  vertical:
                                                                      2,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color(
                                                                          0xFFE07A5F)
                                                                      .withValues(
                                                                          alpha:
                                                                              0.9),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          10),
                                                                ),
                                                                child: Text(
                                                                  '-$discountPct%',
                                                                  style: const TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(
                                                        12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      p['name'] ?? '',
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style:
                                                          const TextStyle(
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (original != null &&
                                                        original > selling)
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            _formatCurrency(
                                                                original),
                                                            style:
                                                                const TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color: Colors
                                                                  .grey,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatCurrency(
                                                                selling),
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFFE07A5F),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    else
                                                      Text(
                                                        _formatCurrency(
                                                            selling),
                                                        style:
                                                            const TextStyle(
                                                          color: Color(
                                                              0xFFE07A5F),
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .star_rounded,
                                                          size: 16,
                                                          color: const Color(
                                                              0xFFF2CC8F),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          avg.toStringAsFixed(
                                                              1),
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        if (distText != null) ...[
                                                          Icon(
                                                            Icons.place,
                                                            size: 14,
                                                            color: Colors
                                                                .grey
                                                                .shade400,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            '$distText km',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                                alpha: 0.85),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => fav
                                                .toggleFavorite(p['id']),
                                            iconSize: 18,
                                            padding:
                                                const EdgeInsets.all(4),
                                            constraints:
                                                const BoxConstraints(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate(
                                      delay: (i * 80).ms,
                                    )
                                    .fadeIn(
                                      duration: 350.ms,
                                    )
                                    .slideX(
                                      begin: 0.1,
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              Builder(builder: (context) {
                final all = <Map<String, dynamic>>[];
                for (final s in _nearbyStores) {
                  if (s is! Map) continue;
                  final prods = (s['products'] as List<dynamic>? ?? const []);
                  for (final p in prods) {
                    if (p is! Map) continue;
                    final price =
                        (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                    final original =
                        (p['originalPrice'] as num?)?.toDouble();
                    if (original == null || original <= price) continue;
                    final map = Map<String, dynamic>.from(p);
                    map['__storeId'] = s['id'];
                    map['__storeName'] = s['name'];
                    map['__storeDistance'] = s['distance'];
                    map['__storeAddress'] =
                        (s['address'] ?? s['location'] ?? s['alamat'])
                            ?.toString();
                    map['__storeLat'] =
                        (s['latitude'] as num?)?.toDouble();
                    map['__storeLong'] =
                        (s['longitude'] as num?)?.toDouble();
                    all.add(map);
                  }
                }
                if (all.isEmpty) return const SizedBox.shrink();

                all.sort((a, b) {
                  final ap =
                      (a['sellingPrice'] as num?)?.toDouble() ?? 0;
                  final ao =
                      (a['originalPrice'] as num?)?.toDouble() ?? ap;
                  final bp =
                      (b['sellingPrice'] as num?)?.toDouble() ?? 0;
                  final bo =
                      (b['originalPrice'] as num?)?.toDouble() ?? bp;
                  final ad =
                      ao > 0 ? (1 - ap / ao) : 0;
                  final bd =
                      bo > 0 ? (1 - bp / bo) : 0;
                  return bd.compareTo(ad);
                });

                final list = all.take(12).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text('Promo di Sekitar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final p = list[index];
                          final price =
                              (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                          final original =
                              (p['originalPrice'] as num?)?.toDouble() ??
                                  price;
                          final imageUrl = MarketApiService()
                              .resolveFileUrl(
                                  p['imageUrl'] ?? p['image']);
                          final dynamic distV = p['__storeDistance'];
                          final distNum = (distV is num)
                              ? distV.toDouble()
                              : double.tryParse(
                                  distV?.toString() ?? '');
                          final distText = distNum?.toStringAsFixed(1);
                          final hasPromo =
                              original > price && original > 0;
                          final discountPct = hasPromo
                              ? ((1 - price / original) * 100).round()
                              : null;

                          return Consumer2<FavoritesProvider, ReviewsProvider>(
                            builder: (context, fav, rev, _) {
                              final avg = rev.getAverage(p['id']);
                              final isFav = fav.isFavorite(p['id']);

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
                                      ),
                                    ),
                                  ).then((_) => _loadRecentViewed());
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 170,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius
                                                          .vertical(
                                                      top:
                                                          Radius.circular(16)),
                                              child: imageUrl.isEmpty
                                                  ? Container(
                                                      color: Colors
                                                          .grey.shade200,
                                                      child: const Center(
                                                          child: Icon(
                                                              Icons.fastfood,
                                                              size: 30,
                                                              color:
                                                                  Colors.grey)),
                                                    )
                                                  : Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child:
                                                              Image.network(
                                                            imageUrl,
                                                            fit: BoxFit.cover,
                                                            width: double
                                                                .infinity,
                                                            errorBuilder:
                                                                (context,
                                                                    error,
                                                                    stackTrace) {
                                                              return Container(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                                child: const Center(
                                                                    child: Icon(
                                                                        Icons.fastfood,
                                                                        size:
                                                                            30,
                                                                        color: Colors
                                                                            .grey)),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        if (discountPct != null)
                                                          Positioned(
                                                            top: 8,
                                                            left: 8,
                                                            child: Container(
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFFE07A5F)
                                                                    .withValues(
                                                                        alpha:
                                                                            0.9),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              child: Text(
                                                                '-$discountPct%',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: 10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(p['name'] ?? '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14)),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          _formatCurrency(
                                                              original),
                                                          style: const TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 11)),
                                                      Text(
                                                          _formatCurrency(
                                                              price),
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFFE07A5F),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 14)),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons.star_rounded,
                                                          size: 16,
                                                          color: const Color(
                                                              0xFFF2CC8F)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                          avg.toStringAsFixed(
                                                              1),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12)),
                                                      const Spacer(),
                                                      if (distText != null) ...[
                                                        Icon(Icons.place,
                                                            size: 14,
                                                            color: Colors
                                                                .grey.shade400),
                                                        const SizedBox(
                                                            width: 2),
                                                        Text('$distText km',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600)),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white
                                                  .withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey),
                                          onPressed: () =>
                                              fav.toggleFavorite(p['id']),
                                          iconSize: 18,
                                          padding:
                                              const EdgeInsets.all(4),
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(delay: (index * 80).ms)
                                  .fadeIn(duration: 350.ms)
                                  .slideX(begin: 0.1);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),

              Builder(builder: (context) {
                final fav = Provider.of<FavoritesProvider>(context);
                final favIds = fav.ids;
                if (favIds.isEmpty) {
                  return const SizedBox.shrink();
                }

                final rev = Provider.of<ReviewsProvider>(context);

                final storesMap = <String, dynamic>{};
                final storeRatings = <String, double>{};
                final storeCounts = <String, int>{};
                final storeDistances = <String, double?>{};

                for (final s in _nearbyStores) {
                  if (s is! Map) continue;
                  final sid = s['id']?.toString();
                  if (sid == null) continue;
                  final prods =
                      (s['products'] as List<dynamic>? ?? const []);
                  bool hasFavProduct = false;
                  double sum = 0;
                  int count = 0;

                  for (final p in prods) {
                    if (p is! Map) continue;
                    final id = p['id']?.toString();
                    if (id != null && favIds.contains(id)) {
                      hasFavProduct = true;
                    }
                    final avg = rev.getAverage(p['id']);
                    if (avg > 0) {
                      sum += avg;
                      count++;
                    }
                  }

                  if (!hasFavProduct) continue;
                  storesMap[sid] = s;

                  final dynamic distV = s['distance'];
                  final distNum = (distV is num)
                      ? distV.toDouble()
                      : double.tryParse(distV?.toString() ?? '');
                  storeDistances[sid] = distNum;

                  if (count > 0) {
                    storeRatings[sid] = sum / count;
                    storeCounts[sid] = count;
                  }
                }

                if (storesMap.isEmpty) {
                  return const SizedBox.shrink();
                }

                final entries = storesMap.entries.toList()
                  ..sort((a, b) {
                    final ar = storeRatings[a.key] ?? 0;
                    final br = storeRatings[b.key] ?? 0;
                    if (ar != br) return br.compareTo(ar);
                    final ad = storeDistances[a.key] ?? 99999;
                    final bd = storeDistances[b.key] ?? 99999;
                    return ad.compareTo(bd);
                  });

                final list = entries.take(10).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Toko Favoritmu',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final entry = list[index];
                          final store = entry.value;
                          final sid = entry.key;
                          final name =
                              store['name']?.toString() ?? 'Toko';
                          final addr = (store['address'] ??
                                      store['location'] ??
                                      store['alamat'])
                                  ?.toString() ??
                              '-';
                          final dynamic distV = store['distance'];
                          final distNum = (distV is num)
                              ? distV.toDouble()
                              : double.tryParse(
                                  distV?.toString() ?? '');
                          final distText = distNum?.toStringAsFixed(1);
                          final rating = storeRatings[sid];
                          final ratingCount = storeCounts[sid] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoreDetailScreen(
                                      store: Map<String, dynamic>.from(
                                          store as Map)),
                                ),
                              );
                            },
                            child: Container(
                              width: 220,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE07A5F)
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.store,
                                          color: Color(0xFFE07A5F),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    addr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (rating != null &&
                                          rating > 0) ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Color(0xFFF2CC8F),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                        if (ratingCount > 0) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '($ratingCount)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors
                                                  .grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                      const Spacer(),
                                      if (distText != null) ...[
                                        Icon(
                                          Icons.place,
                                          size: 13,
                                          color: Colors
                                              .grey.shade500,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$distText km',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                    _greetingTitle(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
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
                        final price =
                            (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                        final original =
                            (p['originalPrice'] as num?)?.toDouble();
                        if (original == null || original <= price) {
                          return false;
                        }
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
                        final selling =
                            (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                        final original =
                            (p['originalPrice'] as num?)?.toDouble();
                        final hasPromo =
                            original != null && original > selling && original > 0;
                        final discountPct = hasPromo
                            ? ((1 - selling / original) * 100).round()
                            : null;
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
                                ),
                              ),
                            ).then((_) => _loadRecentViewed());
                          },
                          child: Container(
                            width: 180, // Wider card
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
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
                                        : Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                          child: Icon(
                                                              Icons.fastfood,
                                                              size: 30,
                                                              color:
                                                                  Colors.grey)),
                                                    );
                                                  },
                                                ),
                                              ),
                                              if (discountPct != null)
                                                Positioned(
                                                  left: 8,
                                                  top: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFE07A5F)
                                                          .withValues(
                                                              alpha: 0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Text(
                                                      '-$discountPct%',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                            ],
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
                                        Text(
                                            p['name'],
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 14)),
                                        if (original != null &&
                                            original > selling)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  _formatCurrency(
                                                      original),
                                                  style: const TextStyle(
                                                      decoration:
                                                          TextDecoration
                                                              .lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 11)),
                                              Text(
                                                  _formatCurrency(
                                                      selling),
                                                  style: const TextStyle(
                                                      color: Color(
                                                          0xFFE07A5F),
                                                      fontWeight:
                                                          FontWeight
                                                              .w700,
                                                      fontSize: 14)),
                                            ],
                                          )
                                        else
                                          Text(
                                              _formatCurrency(
                                                  selling),
                                              style: const TextStyle(
                                                  color: Color(
                                                      0xFFE07A5F),
                                                  fontWeight:
                                                      FontWeight.w700,
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

              Consumer2<FavoritesProvider, ReviewsProvider>(
                builder: (context, fav, rev, _) {
                  final favIds = fav.ids;
                  if (favIds.isEmpty) return const SizedBox.shrink();

                  final all = <Map<String, dynamic>>[];
                  for (final s in _nearbyStores) {
                    if (s is! Map) continue;
                    final prods = (s['products'] as List<dynamic>? ?? const []);
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

                  final favorites = all.where((p) {
                    final id = p['id']?.toString();
                    if (id == null) return false;
                    return favIds.contains(id);
                  }).toList();

                  if (favorites.isEmpty) return const SizedBox.shrink();

                  favorites.sort((a, b) {
                    final ar = rev.getAverage(a['id']);
                    final br = rev.getAverage(b['id']);
                    if (ar != br) return br.compareTo(ar);
                    final ad =
                        (a['__storeDistance'] as num?)?.toDouble() ?? 99999;
                    final bd =
                        (b['__storeDistance'] as num?)?.toDouble() ?? 99999;
                    return ad.compareTo(bd);
                  });

                  final list = favorites.take(12).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text('Favorit Kamu',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
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
                            final selling =
                                (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                            final original =
                                (p['originalPrice'] as num?)?.toDouble();
                            final hasPromo = original != null &&
                                original > selling &&
                                original > 0;
                            final discountPct = hasPromo
                                ? ((1 - selling / original) * 100).round()
                                : null;
                            final isFav = fav.isFavorite(p['id']);

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
                                    ),
                                  ),
                                ).then((_) => _loadRecentViewed());
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(16)),
                                            child: imageUrl.isEmpty
                                                ? Container(
                                                    color:
                                                        Colors.grey.shade200,
                                                    child: const Center(
                                                        child: Icon(
                                                            Icons.fastfood,
                                                            size: 30,
                                                            color:
                                                                Colors.grey)),
                                                  )
                                                : Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                          errorBuilder: (context,
                                                              error,
                                                              stackTrace) {
                                                            return Container(
                                                              color: Colors.grey
                                                                  .shade200,
                                                              child: const Center(
                                                                  child: Icon(
                                                                      Icons
                                                                          .fastfood,
                                                                      size: 30,
                                                                      color: Colors
                                                                          .grey)),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      if (discountPct != null)
                                                        Positioned(
                                                          left: 8,
                                                          top: 8,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                      0xFFE07A5F)
                                                                  .withValues(
                                                                      alpha:
                                                                          0.9),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: Text(
                                                              '-$discountPct%',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(p['name'],
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14)),
                                                if (original != null &&
                                                    original > selling)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          _formatCurrency(
                                                              original),
                                                          style: const TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 11)),
                                                      Text(
                                                          _formatCurrency(
                                                              selling),
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFFE07A5F),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 14)),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                      _formatCurrency(selling),
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFFE07A5F),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14)),
                                                Row(
                                                  children: [
                                                    Icon(Icons.star_rounded,
                                                        size: 16,
                                                        color: const Color(
                                                            0xFFF2CC8F)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        avg.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12)),
                                                    const Spacer(),
                                                    if (distText != null) ...[
                                                      Icon(Icons.place,
                                                          size: 14,
                                                          color: Colors
                                                              .grey.shade400),
                                                      const SizedBox(width: 2),
                                                      Text('$distText km',
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey
                                                                  .shade600)),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white
                                                .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFav
                                                ? Colors.red
                                                : Colors.grey),
                                        onPressed: () =>
                                            fav.toggleFavorite(p['id']),
                                        iconSize: 18,
                                        padding: const EdgeInsets.all(4),
                                        constraints:
                                            const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(delay: (i * 80).ms)
                                .fadeIn(duration: 350.ms)
                                .slideX(begin: 0.1);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              Builder(builder: (context) {
                if (_recentProductIds.isEmpty) {
                  return const SizedBox.shrink();
                }

                final all = <Map<String, dynamic>>[];
                for (final s in _nearbyStores) {
                  if (s is! Map) continue;
                  final prods = (s['products'] as List<dynamic>? ?? const []);
                  for (final p in prods) {
                    if (p is! Map) continue;
                    final map = Map<String, dynamic>.from(p);
                    map['__storeId'] = s['id'];
                    map['__storeName'] = s['name'];
                    map['__storeDistance'] = s['distance'];
                    map['__storeAddress'] =
                        (s['address'] ?? s['location'] ?? s['alamat'])
                            ?.toString();
                    map['__storeLat'] =
                        (s['latitude'] as num?)?.toDouble();
                    map['__storeLong'] =
                        (s['longitude'] as num?)?.toDouble();
                    all.add(map);
                  }
                }

                final byId = <String, Map<String, dynamic>>{};
                for (final p in all) {
                  final id = p['id']?.toString();
                  if (id != null && !byId.containsKey(id)) {
                    byId[id] = p;
                  }
                }

                final list = <Map<String, dynamic>>[];
                for (final id in _recentProductIds) {
                  final p = byId[id];
                  if (p != null) list.add(p);
                }

                if (list.isEmpty) return const SizedBox.shrink();

                final take = list.take(10).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Baru Kamu Lihat',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: Consumer2<FavoritesProvider, ReviewsProvider>(
                        builder: (context, fav, rev, _) {
                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemCount: take.length,
                            itemBuilder: (context, i) {
                              final p = take[i];
                              final imageUrl = MarketApiService()
                                  .resolveFileUrl(
                                      p['imageUrl'] ?? p['image']);
                              final dynamic distV = p['__storeDistance'];
                              final distNum = (distV is num)
                                  ? distV.toDouble()
                                  : double.tryParse(
                                      distV?.toString() ?? '');
                              final distText = distNum?.toStringAsFixed(1);
                              final avg = rev.getAverage(p['id']);
                              final selling =
                                  (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                              final original =
                                  (p['originalPrice'] as num?)?.toDouble();
                              final hasPromo =
                                  original != null && original > selling && original > 0;
                              final discountPct = hasPromo
                                  ? ((1 - selling / original) * 100).round()
                                  : null;
                              final isFav = fav.isFavorite(p['id']);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(
                                        product: p,
                                        storeId: p['__storeId'],
                                        storeName: p['__storeName'],
                                        storeAddress:
                                            p['__storeAddress'],
                                        storeLat: p['__storeLat'],
                                        storeLong: p['__storeLong'],
                                      ),
                                    ),
                                  ).then((_) => _loadRecentViewed());
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius
                                                    .vertical(
                                                    top: Radius
                                                        .circular(
                                                            16)),
                                            child: imageUrl.isEmpty
                                                ? Container(
                                                    color: Colors
                                                        .grey.shade200,
                                                    child: const Center(
                                                        child: Icon(
                                                            Icons
                                                                .fastfood,
                                                            size: 30,
                                                            color: Colors
                                                                .grey)),
                                                  )
                                                : Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          width:
                                                              double.infinity,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              color: Colors.grey
                                                                  .shade200,
                                                              child: const Center(
                                                                  child: Icon(
                                                                      Icons.fastfood,
                                                                      size: 30,
                                                                      color: Colors
                                                                          .grey)),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      if (discountPct != null)
                                                        Positioned(
                                                          left: 8,
                                                          top: 8,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                      0xFFE07A5F)
                                                                  .withValues(
                                                                      alpha:
                                                                          0.9),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: Text(
                                                              '-$discountPct%',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                          ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(
                                                      12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      p['name'] ?? '',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          fontSize:
                                                              14)),
                                                  if (original != null &&
                                                      original > selling)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            _formatCurrency(
                                                                original),
                                                            style: const TextStyle(
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                                color:
                                                                    Colors.grey,
                                                                fontSize:
                                                                    11)),
                                                        Text(
                                                            _formatCurrency(
                                                                selling),
                                                            style: const TextStyle(
                                                                color: Color(
                                                                    0xFFE07A5F),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    14)),
                                                      ],
                                                    )
                                                  else
                                                    Text(
                                                        _formatCurrency(
                                                            selling),
                                                        style: const TextStyle(
                                                            color:
                                                                Color(0xFFE07A5F),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 14)),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .star_rounded,
                                                          size: 16,
                                                          color: const Color(
                                                              0xFFF2CC8F)),
                                                      const SizedBox(
                                                          width: 4),
                                                      Text(
                                                          avg
                                                              .toStringAsFixed(
                                                                  1),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize:
                                                                  12)),
                                                      const Spacer(),
                                                      if (distText != null) ...[
                                                        Icon(
                                                            Icons.place,
                                                            size: 14,
                                                            color: Colors
                                                                .grey
                                                                .shade400),
                                                        const SizedBox(
                                                            width:
                                                                2),
                                                        Text(
                                                            '$distText km',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade600)),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey),
                                          onPressed: () =>
                                              fav.toggleFavorite(p['id']),
                                          iconSize: 18,
                                          padding:
                                              const EdgeInsets.all(4),
                                          constraints:
                                              const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(
                                      delay:
                                          (i * 80).ms)
                                  .fadeIn(
                                      duration:
                                          350.ms)
                                  .slideX(
                                      begin:
                                          0.1);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),

              Consumer<OrdersProvider>(
                builder: (context, prov, _) {
                  final history = prov.orders.where((o) {
                    final s = (o['orderStatus'] ?? '').toString();
                    return s == 'COMPLETED';
                  }).toList();

                  if (history.isEmpty) return const SizedBox.shrink();

                  final order = history.first;
                  final storeRaw = order['store'];
                  if (storeRaw is! Map) return const SizedBox.shrink();
                  final store = Map<String, dynamic>.from(storeRaw);
                  if (store['address'] == null) {
                    store['address'] =
                        (store['address'] ?? store['location'] ?? store['alamat'])
                            ?.toString();
                  }

                  String? imageUrl;
                  final items =
                      order['transactionItems'] as List<dynamic>? ?? [];
                  if (items.isNotEmpty) {
                    final p = items.first['product'];
                    if (p is Map) {
                      final raw = p['imageUrl'] ?? p['image'];
                      if (raw != null) {
                        imageUrl = MarketApiService()
                            .resolveFileUrl(raw.toString());
                      }
                    }
                  }

                  DateTime? createdAt;
                  if (order['createdAt'] != null) {
                    createdAt =
                        DateTime.tryParse(order['createdAt'].toString());
                  }
                  final createdText = createdAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt)
                      : null;

                  final total = order['totalAmount'] as num?;
                  final totalText =
                      total != null ? _formatCurrency(total) : null;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StoreDetailScreen(store: store)));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
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
                                                  color: Colors.grey)),
                                    )
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
                                        child: Text('Belanja Lagi',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      if (createdText != null)
                                        Text(createdText,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(store['name']?.toString() ?? 'Toko',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  if (totalText != null)
                                    Text('Total terakhir $totalText',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            StoreDetailScreen(store: store)));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE07A5F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Belanja Lagi',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                },
              ),

              Builder(builder: (context) {
                final counts = <String, int>{};
                for (final s in _nearbyStores) {
                  if (s is! Map) continue;
                  final raw = s['category']?.toString().trim();
                  if (raw == null || raw.isEmpty) continue;
                  counts[raw] = (counts[raw] ?? 0) + 1;
                }
                if (counts.isEmpty) return const SizedBox.shrink();
                final items = counts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final top = items.take(6).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Kategori Populer di Sekitar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (final e in top)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  e.key,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = e.key;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),

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
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 160,
                            child: Lottie.network(
                              'https://assets10.lottiefiles.com/packages/lf20_tno6cg2w.json',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.store_mall_directory,
                                size: 72,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07A5F)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Belum ada toko di sekitar titik ini',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE07A5F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Coba nyalakan GPS dan perbarui lokasi, atau pilih alamat lain secara manual.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Geser peta ke area lain untuk mencari lebih banyak toko di sekitarmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                await _initLocation();
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('Gunakan Lokasi Saat Ini'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showManualLocationDialog,
                              icon: const Icon(Icons.edit_location_alt),
                              label: const Text('Pilih Lokasi Manual'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _nearbyStores.length,
                      itemBuilder: (context, index) {
                        final store = _nearbyStores[index];

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

                        final fav = Provider.of<FavoritesProvider>(context);
                        final rev = Provider.of<ReviewsProvider>(context);

                        double? storeAvg;
                        var sumRating = 0.0;
                        var countRating = 0;
                        for (final p in prods) {
                          if (p is! Map) continue;
                          final a = rev.getAverage(p['id']);
                          if (a > 0) {
                            sumRating += a;
                            countRating++;
                          }
                        }
                        if (countRating > 0) {
                          storeAvg = sumRating / countRating;
                        }

                        bool hasFav = false;
                        double? minPrice;
                        for (final p in prods) {
                          if (p is! Map) continue;
                          if (!hasFav && fav.isFavorite(p['id'])) {
                            hasFav = true;
                          }
                          final price =
                              (p['sellingPrice'] as num?)?.toDouble();
                          if (price != null && price > 0) {
                            if (minPrice == null || price < minPrice) {
                              minPrice = price;
                            }
                          }
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
                          shadowColor:
                              Colors.black.withValues(alpha: 0.1),
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
                                          if (minPrice != null)
                                            Text(
                                              'Mulai dari ${_formatCurrency(minPrice)}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500),
                                            ),
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
                                                  .withValues(alpha: 0.1),
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
                                        if (storeAvg != null &&
                                            storeAvg > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 14,
                                                  color: Color(0xFFF2CC8F),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  storeAvg
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                if (hasFav) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(8),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.favorite,
                                                          size: 10,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          'Favoritmu',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
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
                                                    storeId: store['id'],
                                                    storeName: store['name'],
                                                    storeAddress: (store[
                                                                'address'] ??
                                                            store['location'] ??
                                                            store['alamat'])
                                                        ?.toString(),
                                                    storeLat: ((store['latitude'] ??
                                                                store['lat'])
                                                            is num)
                                                        ? (store['latitude'] ??
                                                                store['lat'])
                                                            .toDouble()
                                                        : null,
                                                    storeLong: ((store['longitude'] ??
                                                                store['long'] ??
                                                                store['lng'])
                                                            is num)
                                                        ? (store['longitude'] ??
                                                                store['long'] ??
                                                                store['lng'])
                                                            .toDouble()
                                                        : null,
                                                  ),
                                                ),
                                              ).then((_) => _loadRecentViewed());
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
                                                              .withValues(alpha: 0.1),
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
                                                          .withValues(alpha: 0.8),
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
            color: bg.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14)),
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
    if (c == 'all') {
      return Icons.store;
    }
    if (c.contains('apotik') || c.contains('pharmacy')) {
      return Icons.local_pharmacy;
    }
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai')) {
      return Icons.restaurant;
    }
    if (c.contains('baju') || c.contains('fashion')) {
      return Icons.checkroom;
    }
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp')) {
      return Icons.smartphone;
    }
    if (c.contains('kelontong') || c.contains('grocery')) {
      return Icons.storefront;
    }
    return Icons.category;
  }

  Color _colorForCategory(String category) {
    final c = category.toLowerCase();
    // Soft Earthy/Pastel Palette based on Brand Color #E07A5F
    if (c == 'all') {
      return const Color(0xFFE07A5F);
    }
    if (c.contains('apotik') || c.contains('pharmacy')) {
      return const Color(0xFF81B29A); // Soft Green
    }
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai')) {
      return const Color(0xFFE07A5F); // Brand Color
    }
    if (c.contains('baju') || c.contains('fashion')) {
      return const Color(0xFFF4A261); // Soft Orange
    }
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp')) {
      return const Color(0xFF9D8189); // Soft Mauve
    }
    if (c.contains('kelontong') || c.contains('grocery')) {
      return const Color(0xFFF2CC8F); // Soft Yellow
    }
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
                  : color.withValues(alpha: 0.1), // Soft background
              borderRadius: BorderRadius.circular(16),
              // Removed border for softer look
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4),
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
