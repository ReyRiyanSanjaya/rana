import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/screens/market_cart_screen.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/store_detail_screen.dart';
import 'package:rana_market/providers/search_history_provider.dart';
import 'package:rana_market/providers/reviews_provider.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  String _address = 'Mencari Lokasi...';
  List<dynamic> _nearbyStores = [];
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  bool _annLoading = true;
  String _selectedCategory = 'All';
  List<String> _categories = const ['All'];
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _initLocation();
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
      _fetchNearby(position.latitude, position.longitude);
    } else {
      setState(() {
        _address = 'Lokasi Ditolak';
        _isLoading = false;
      });
    }
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
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFE07A5F), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi Kamu',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal)),
                Text(_address, style: const TextStyle(fontSize: 14)),
              ],
            )
          ],
        ),
        actions: [
          Consumer<MarketCartProvider>(
            builder: (context, cart, _) {
              final count = cart.items.values
                  .fold<int>(0, (acc, it) => acc + it.quantity);
              return Stack(
                children: [
                  IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined,
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
                    ),
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
                        hintText: 'Mau makan apa hari ini?',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                ),
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
                  height: 150,
                  child: PageView(
                    children: [
                      for (var i = 0; i < _announcements.length && i < 5; i++)
                        _buildAnnouncementBanner(_announcements[i], i),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Untuk Kamu',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
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
                        all.add(map);
                      }
                    }
                    final lastQuery =
                        (hist.history.isNotEmpty ? hist.history.first : '')
                            .toLowerCase();
                    all.sort((a, b) {
                      final ar = rev.getAverage(a['id']);
                      final br = rev.getAverage(b['id']);
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
                      // Prioritize match, then rating desc
                      if (am != bm) return bm.compareTo(am);
                      return br.compareTo(ar);
                    });
                    final list = all.take(12).toList();
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                        final lastQuery = Provider.of<SearchHistoryProvider>(
                                    context,
                                    listen: false)
                                .history
                                .isNotEmpty
                            ? Provider.of<SearchHistoryProvider>(context,
                                    listen: false)
                                .history
                                .first
                                .toLowerCase()
                            : '';
                        final match = lastQuery.isNotEmpty &&
                            (p['name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(lastQuery);
                        return Container(
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
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
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 14, color: Color(0xFFF2CC8F)),
                                        Text(avg.toStringAsFixed(1),
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    if (distText != null)
                                      Row(
                                        children: [
                                          Icon(Icons.place,
                                              size: 14,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 2),
                                          Text('$distText km',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    if (match)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFE07A5F)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: const Text(
                                            'Cocok dengan pencarian',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFE07A5F))),
                                      )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
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
                  height: 90,
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
                    const Text('Resto Terdekat',
                        style: TextStyle(
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
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Store Header
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade100))),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: storeImageUrl.isEmpty
                                          ? const Icon(Icons.store,
                                              color: Colors.grey)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                          Text(storeAddr,
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
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFE07A5F)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(store['category'],
                                              style: const TextStyle(
                                                  color: Color(0xFFE07A5F),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.place,
                                                  size: 12,
                                                  color: Colors.grey.shade700),
                                              const SizedBox(width: 4),
                                              Text('$dist km',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .grey.shade700)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${prods.length} produk',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.grey.shade700)),
                                        const SizedBox(height: 8),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          StoreDetailScreen(
                                                              store: store)));
                                            },
                                            child: const Text('Lihat Toko'))
                                      ],
                                    )
                                  ],
                                ),
                              ),

                              // Product Horizontal List
                              if ((filtered).isNotEmpty)
                                Container(
                                  height: 140, // Taller for cards
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  color: Colors.grey.shade50,
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
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade200)),
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
                                                                          8)),
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
                                                                    color: Colors
                                                                        .green)),
                                                            Row(
                                                              children: [
                                                                Icon(Icons.star,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .orange
                                                                        .shade400),
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
                                                    iconSize: 20,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
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
      const Color(0xFFE07A5F).withOpacity(0.2),
      const Color(0xFFE07A5F).withOpacity(0.15),
      const Color(0xFFE07A5F).withOpacity(0.1),
      const Color(0xFFE07A5F).withOpacity(0.05),
    ];
    final bg = palette[index % palette.length];
    final title = (a['title'] ?? a['name'] ?? '-').toString();
    final subtitle = (a['content'] ?? a['message'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade800)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c == 'all') return Icons.store;
    if (c.contains('apotik') || c.contains('pharmacy'))
      return Icons.local_pharmacy;
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai'))
      return Icons.lunch_dining;
    if (c.contains('baju') || c.contains('fashion')) return Icons.shopping_bag;
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp'))
      return Icons.phone_android;
    if (c.contains('kelontong') || c.contains('grocery'))
      return Icons.storefront;
    return Icons.category;
  }

  Color _colorForCategory(String category) {
    final c = category.toLowerCase();
    if (c == 'all') return Colors.grey;
    if (c.contains('apotik') || c.contains('pharmacy'))
      return const Color(0xFF81B29A);
    if (c.contains('makan') || c.contains('resto') || c.contains('kedai'))
      return const Color(0xFFF2CC8F);
    if (c.contains('baju') || c.contains('fashion'))
      return const Color(0xFFE07A5F);
    if (c.contains('ponsel') || c.contains('phone') || c.contains('hp'))
      return const Color(0xFF3D405B);
    if (c.contains('kelontong') || c.contains('grocery'))
      return const Color(0xFFE07A5F);
    return const Color(0xFF3D405B);
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color,
      {required String category, bool isSelected = false}) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: color, width: 2) : null),
            child: Icon(icon, color: isSelected ? Colors.white : color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
