import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/screens/market_cart_screen.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/screens/store_detail_screen.dart';
import 'package:rana_market/screens/market_search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<dynamic> _announcements = [];
  List<dynamic> _flashSales = [];
  List<dynamic> _filteredStores = [];
  List<dynamic> _popularProducts = [];
  bool _isLoading = true;
  String _address = 'Memuat lokasi...';

  Timer? _timer;
  Duration _flashSaleDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      double lat = 0;
      double long = 0;
      String locName = 'Mencari lokasi...';

      // 1. Get Location
      try {
        final position = await _determinePosition();
        lat = position.latitude;
        long = position.longitude;
        locName = 'Lokasi Terdeteksi';
      } catch (e) {
        debugPrint('Location error: $e');
        locName = 'Lokasi Default';
      }

      // Load Announcements
      final announcements = await MarketApiService().getAnnouncements();

      // Load Flash Sales
      final flashSales =
          await MarketApiService().getFlashSaleProducts(lat, long);

      // Load Popular Products
      final popular = await MarketApiService().searchGlobal(
        lat: lat,
        long: long,
        sort: 'rating_desc',
        limit: 10,
      );

      // Load Nearby Stores
      final nearby = await MarketApiService().getNearbyStores(lat, long);

      if (mounted) {
        setState(() {
          _announcements = announcements;
          _flashSales = flashSales;
          _popularProducts = popular;
          _filteredStores = nearby;
          _isLoading = false;
          _address = locName;
          _startTimer();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading home: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak aktif.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen. Cek pengaturan.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _startTimer() {
    if (_flashSales.isEmpty) return;

    // Find the earliest end time
    DateTime? earliestEnd;
    for (final sale in _flashSales) {
      final endAtStr = sale['flashSaleEndAt'];
      if (endAtStr != null) {
        final endAt = DateTime.tryParse(endAtStr);
        if (endAt != null && endAt.isAfter(DateTime.now())) {
          if (earliestEnd == null || endAt.isBefore(earliestEnd)) {
            earliestEnd = endAt;
          }
        }
      }
    }

    if (earliestEnd == null) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(earliestEnd!)) {
        timer.cancel();
        setState(() {
          _flashSaleDuration = Duration.zero;
        });
      } else {
        setState(() {
          _flashSaleDuration = earliestEnd!.difference(now);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.beigeBackground,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(child: _buildAnnouncements()),
            SliverToBoxAdapter(child: _buildCategories()),
            if (_flashSales.isNotEmpty)
              SliverToBoxAdapter(child: _buildFlashSale()),
            if (_popularProducts.isNotEmpty)
              SliverToBoxAdapter(child: _buildPopularProducts()),
            _buildNearbyStoresHeader(),
            _buildNearbyStoresList(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeAppBarDelegate(
        topPadding: topPadding,
        address: _address,
        onSearchTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketSearchScreen()),
          );
        },
        onNotifTap: () {},
        onCartTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketCartScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAnnouncements() {
    if (_announcements.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: ThemeConfig.isTablet(context) ? 240.0 : 150.0,
      child: PageView.builder(
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final item = _announcements[index];
          final imgUrl = MarketApiService().resolveFileUrl(item['imageUrl']);
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusLarge),
              image: DecorationImage(
                image: NetworkImage(imgUrl),
                fit: BoxFit.cover,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.98, 0.98));
        },
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.restaurant, 'label': 'Makanan'},
      {'icon': Icons.local_drink, 'label': 'Minuman'},
      {'icon': Icons.shopping_basket, 'label': 'Belanja'},
      {'icon': Icons.local_offer, 'label': 'Promo'},
    ];

    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MarketSearchScreen(
                    initialCategory: cat['label'] as String,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: ThemeConfig.brandColor,
                    size: 28 * scale,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                    color: ThemeConfig.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashSale() {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: ThemeConfig.colorWarning),
              const SizedBox(width: 8),
              Text(
                'Flash Sale',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.textPrimary,
                ),
              ),
              const Spacer(),
              if (_flashSaleDuration > Duration.zero)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_flashSaleDuration.inHours.toString().padLeft(2, '0')}:${(_flashSaleDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(_flashSaleDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12 * scale,
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: ThemeConfig.isTablet(context) ? 280 : 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _flashSales.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _flashSales[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: product,
                        storeId: product['storeId'] ?? '',
                        storeName: product['storeName'] ?? 'Toko',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: ThemeConfig.isTablet(context) ? 200 : 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(ThemeConfig.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeConfig.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(ThemeConfig.radiusMedium)),
                        child: CachedNetworkImage(
                          imageUrl: MarketApiService()
                              .resolveFileUrl(product['imageUrl']),
                          height: ThemeConfig.isTablet(context) ? 140 : 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                                color: ThemeConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${product['sellingPrice']}',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.brandColor,
                              ),
                            ),
                            if (product['originalPrice'] >
                                product['sellingPrice'])
                              Text(
                                'Rp ${product['originalPrice']}',
                                style: TextStyle(
                                  fontSize: 12 * scale,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularProducts() {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paling Populer',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MarketSearchScreen(initialQuery: ''),
                    ),
                  );
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ThemeConfig.isTablet(context) ? 280 : 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _popularProducts.length,
            itemBuilder: (context, index) {
              final item = _popularProducts[index];
              final imgUrl =
                  MarketApiService().resolveFileUrl(item['imageUrl']);
              final price = (item['sellingPrice'] as num?)?.toDouble() ?? 0;
              final original = (item['originalPrice'] as num?)?.toDouble();
              final hasPromo =
                  original != null && original > price && original > 0;
              final discountPct =
                  hasPromo ? ((1 - price / original) * 100).round() : null;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: item,
                        storeId: item['storeId'] ?? item['store']?['id'] ?? '',
                        storeName: item['store']?['name'] ?? 'Toko',
                        storeAddress: item['store']?['location'] ??
                            item['store']?['address'] ??
                            item['store']?['alamat'],
                        storeLat: (item['store']?['latitude'] ??
                                item['store']?['lat'])
                            ?.toDouble(),
                        storeLong: (item['store']?['longitude'] ??
                                item['store']?['long'] ??
                                item['store']?['lng'])
                            ?.toDouble(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: ThemeConfig.isTablet(context) ? 200 : 160,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: imgUrl,
                              height: ThemeConfig.isTablet(context) ? 140 : 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                            if (discountPct != null)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6 * scale,
                                      vertical: 2 * scale),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$discountPct%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13 * scale,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${price.toInt()}',
                              style: TextStyle(
                                color: ThemeConfig.brandColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * scale,
                              ),
                            ),
                            if (hasPromo)
                              Text(
                                'Rp ${original.toInt()}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 10 * scale,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 12, color: ThemeConfig.colorRating),
                                const SizedBox(width: 4),
                                Text(
                                  (item['averageRating'] ?? 0)
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyStoresHeader() {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 24 * scale, 16, 12 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Toko di Sekitarmu',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyStoresList() {
    if (_filteredStores.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  size: 48 * ThemeConfig.tabletScale(context, mobile: 1.0),
                  color: Colors.grey),
              SizedBox(height: 8 * ThemeConfig.tabletScale(context, mobile: 1.0)),
              Text(
                'Belum ada toko yang sesuai',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14 * ThemeConfig.tabletScale(context, mobile: 1.0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (ThemeConfig.isTablet(context)) {
      final cols = ThemeConfig.gridColumns(context, mobile: 2);
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final store = _filteredStores[index];
              return _StoreCard(store: store);
            },
            childCount: _filteredStores.length,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final store = _filteredStores[index];
            return _StoreCard(store: store);
          },
          childCount: _filteredStores.length,
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final dynamic store;

  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailScreen(store: store),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8 * scale),
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ThemeConfig.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
              child: CachedNetworkImage(
                imageUrl: MarketApiService().resolveFileUrl(store['imageUrl']),
                width: 80 * scale,
                height: 80 * scale,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80 * scale,
                  height: 80 * scale,
                  color: Colors.grey[200],
                  child: const Icon(Icons.store),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'] ?? 'Toko Tanpa Nama',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: ThemeConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: ThemeConfig.colorRating),
                      const SizedBox(width: 4),
                      Text(
                        '${store['rating'] ?? 0.0}',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6 * scale, vertical: 2 * scale),
                        decoration: BoxDecoration(
                          color: ThemeConfig.beigeBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          store['category'] ?? 'Umum',
                          style: TextStyle(
                            fontSize: 10 * scale,
                            color: ThemeConfig.brandColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14 * scale, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store['address'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.98, 0.98)),
    );
  }
}

class _HomeAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final String address;
  final VoidCallback onSearchTap;
  final VoidCallback onNotifTap;
  final VoidCallback onCartTap;

  _HomeAppBarDelegate({
    required this.topPadding,
    required this.address,
    required this.onSearchTap,
    required this.onNotifTap,
    required this.onCartTap,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    // 0.0 -> Expanded, 1.0 -> Collapsed
    final progress = shrinkOffset / (maxExtent - minExtent);
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Fade out location row quickly
    final locOpacity = (1.0 - (clampedProgress * 3.0)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: ThemeConfig.brandColor,
        boxShadow: overlapsContent || clampedProgress > 0.1
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Location & Notif & Cart Row (Top)
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: 50 * scale,
            child: Opacity(
              opacity: locOpacity,
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.white, size: 16 * scale),
                    SizedBox(width: 4 * scale),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Search Bar & Icons (Pinned to bottom)
          Positioned(
            left: 16 * scale,
            right: 16 * scale,
            bottom: 10 * scale,
            height: 48 * scale,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      height: 48 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey, size: 20 * scale),
                          SizedBox(width: 12 * scale),
                          Expanded(
                            child: Text(
                              'Cari makan, jajan, atau toko...',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14 * scale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon:
                      const Icon(Icons.notifications, color: Colors.white),
                  onPressed: onNotifTap,
                ),
                Consumer<MarketCartProvider>(
                  builder: (context, cart, child) {
                    final itemCount = cart.items.values
                        .fold(0, (sum, item) => sum + item.quantity);
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.white),
                          onPressed: onCartTap,
                        ),
                        if (itemCount > 0)
                          Positioned(
                            right: 8 * scale,
                            top: 8 * scale,
                            child: Container(
                              padding: EdgeInsets.all(2 * scale),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16 * scale,
                                minHeight: 16 * scale,
                              ),
                              child: Text(
                                '$itemCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => topPadding + 50 + 60 + 10;

  @override
  double get minExtent => topPadding + 60 + 10;

  @override
  bool shouldRebuild(covariant _HomeAppBarDelegate oldDelegate) {
    return address != oldDelegate.address ||
        topPadding != oldDelegate.topPadding;
  }
}
