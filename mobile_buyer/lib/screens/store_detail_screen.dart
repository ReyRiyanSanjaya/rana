import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/providers/reviews_provider.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/screens/market_cart_screen.dart';
import 'package:rana_market/providers/market_cart_provider.dart';

class StoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _storeDetail = {};
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _reviews = [];
  Map<String, dynamic> _reviewStats = {};

  bool _loading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _storeDetail = widget.store;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final storeId = widget.store['id'];

      // Load Catalog (Store Info + Products + Categories)
      final catalog = await MarketApiService().getStoreCatalog(storeId);

      // Load Reviews
      final reviewsData = await MarketApiService().getStoreReviews(storeId);

      if (!mounted) return;

      setState(() {
        if (catalog['store'] != null) {
          _storeDetail = {
            ..._storeDetail,
            ...catalog['store'],
          };
        }
        _products = catalog['products'] ?? [];
        _categories = ['Semua', ...(catalog['categories'] ?? [])];

        _reviews = reviewsData['reviews'] ?? [];
        _reviewStats = reviewsData['stats'] ?? {};

        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading store data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim().toLowerCase();
    });
  }

  List<dynamic> get _filteredProducts {
    return _products.where((p) {
      final matchCat = _selectedCategory == 'Semua' ||
          (p['category']?['name'] == _selectedCategory);
      final matchSearch =
          _query.isEmpty || (p['name'] ?? '').toLowerCase().contains(_query);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    return Scaffold(
      backgroundColor: ThemeConfig.beigeBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(scale),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMenuTab(scale),
            _buildReviewsTab(scale),
            _buildInfoTab(scale),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double scale) {
    final bannerUrl =
        MarketApiService().resolveFileUrl(_storeDetail['bannerUrl']);
    final logoUrl = MarketApiService().resolveFileUrl(_storeDetail['imageUrl']);
    final hasBanner = bannerUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 200 * scale,
      pinned: true,
      backgroundColor: ThemeConfig.brandColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketCartScreen()),
                );
              },
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Consumer<MarketCartProvider>(
                builder: (context, cart, _) {
                  if (cart.itemCount == 0) return const SizedBox.shrink();
                  return Container(
                    padding: EdgeInsets.all(4 * scale),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasBanner)
              Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: ThemeConfig.brandColor),
              )
            else
              Container(
                color: ThemeConfig.brandColor,
                child: const Center(
                  child: Icon(Icons.store, size: 64, color: Colors.white24),
                ),
              ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Store Info Content
            Positioned(
              bottom: 16,
              left: 16 * scale,
              right: 16 * scale,
              child: Row(
                children: [
                  Container(
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      image: logoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(logoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: logoUrl.isEmpty
                        ? const Icon(Icons.store, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _storeDetail['name'] ?? 'Toko',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4 * scale),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Colors.amber, size: 16 * scale),
                            SizedBox(width: 4 * scale),
                            Text(
                              '${(_reviewStats['averageRating'] ?? 0).toStringAsFixed(1)} (${_reviewStats['totalReviews'] ?? 0})',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12 * scale),
                            ),
                            SizedBox(width: 12 * scale),
                            Icon(Icons.location_on,
                                color: Colors.white70, size: 16 * scale),
                            SizedBox(width: 4 * scale),
                            Expanded(
                              child: Text(
                                _storeDetail['location'] ??
                                    _storeDetail['address'] ??
                                    '-',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12 * scale),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48 * scale),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: ThemeConfig.brandColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ThemeConfig.brandColor,
            tabs: [
              Tab(
                  child: Text('Menu',
                      style: TextStyle(fontSize: 14 * scale))),
              Tab(
                  child: Text('Ulasan',
                      style: TextStyle(fontSize: 14 * scale))),
              Tab(
                  child: Text('Info',
                      style: TextStyle(fontSize: 14 * scale))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab(double scale) {
    final products = _filteredProducts;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(16 * scale),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari di toko ini...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16 * scale),
                  ),
                ),
              ),
              // Categories
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 40 * scale,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: 8 * scale),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat,
                            style: TextStyle(fontSize: 12 * scale)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: ThemeConfig.brandColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        backgroundColor: Colors.white,
                      );
                    },
                  ),
                ),
              SizedBox(height: 16 * scale),
            ],
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          SliverFillRemaining(
            child: Center(
                child: Text('Produk tidak ditemukan',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14 * scale))),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: 16 * scale, vertical: 8 * scale),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    ThemeConfig.isTablet(context) ? 3 : 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12 * scale,
                crossAxisSpacing: 12 * scale,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildProductCard(products[index]);
                },
                childCount: products.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 80 * scale)),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return Consumer2<FavoritesProvider, ReviewsProvider>(
      builder: (context, fav, rev, _) {
        final isFav = fav.isFavorite(p['id']);
        final avg =
            (p['averageRating'] as num?)?.toDouble() ?? rev.getAverage(p['id']);
        final imageUrl =
            MarketApiService().resolveFileUrl(p['imageUrl'] ?? p['image']);
        final selling = (p['sellingPrice'] as num?)?.toDouble() ?? 0;
        final original = (p['originalPrice'] as num?)?.toDouble();
        final hasPromo = original != null && original > selling && original > 0;
        final discountPct =
            hasPromo ? ((1 - selling / original) * 100).round() : null;

        final scale = ThemeConfig.tabletScale(context, mobile: 1.0);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  product: p,
                  storeId: _storeDetail['id'],
                  storeName: _storeDetail['name'],
                  storeAddress: (_storeDetail['address'] ??
                          _storeDetail['location'] ??
                          _storeDetail['alamat'])
                      ?.toString(),
                  storeLat:
                      ((_storeDetail['latitude'] ?? _storeDetail['lat']) is num)
                          ? (_storeDetail['latitude'] ?? _storeDetail['lat'])
                              .toDouble()
                          : null,
                  storeLong: ((_storeDetail['longitude'] ??
                          _storeDetail['long'] ??
                          _storeDetail['lng']) is num)
                      ? (_storeDetail['longitude'] ??
                              _storeDetail['long'] ??
                              _storeDetail['lng'])
                          .toDouble()
                      : null,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: imageUrl.isEmpty
                            ? Container(color: Colors.grey.shade200)
                            : Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey.shade200),
                              ),
                      ),
                      if (discountPct != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6 * scale, vertical: 2 * scale),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountPct%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            fav.toggleFavorite(p['id'],
                                phone: auth.user?['phone'] as String?);
                          },
                          child: Container(
                            padding: EdgeInsets.all(6 * scale),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 18 * scale,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4 * scale),
                      if (hasPromo) ...[
                        Text(
                          'Rp ${original.toInt()}',
                          style: TextStyle(
                            fontSize: 10 * scale,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      Text(
                        'Rp ${selling.toInt()}',
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.brandColor,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 12 * scale, color: Colors.amber),
                          SizedBox(width: 2 * scale),
                          Text(
                            avg.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 11 * scale,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(double scale) {
    if (_reviews.isEmpty) {
      return Center(
        child: Text(
          'Belum ada ulasan',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14 * scale,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16 * scale),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final r = _reviews[index];
        final product = r['product'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 16 * scale,
                  child: Text(
                    (r['userName'] ?? 'U')[0].toUpperCase(),
                    style:
                        TextStyle(color: Colors.grey, fontSize: 14 * scale),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['userName'] ?? 'Pengguna',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (r['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 14 * scale,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(r['createdAt']),
                  style: TextStyle(
                      fontSize: 10 * scale,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
            if (product != null) ...[
              SizedBox(height: 8 * scale),
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (product['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          MarketApiService()
                              .resolveFileUrl(product['imageUrl']),
                          width: 30 * scale,
                          height: 30 * scale,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => SizedBox(
                              width: 30 * scale, height: 30 * scale),
                        ),
                      ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style: TextStyle(
                            fontSize: 11 * scale, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (r['comment'] != null && r['comment'].isNotEmpty) ...[
              SizedBox(height: 8 * scale),
              Text(
                r['comment'],
                style: TextStyle(fontSize: 13 * scale),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoTab(double scale) {
    return ListView(
      padding: EdgeInsets.all(16 * scale),
      children: [
        _buildInfoItem(Icons.store, 'Deskripsi',
            _storeDetail['description'] ?? 'Tidak ada deskripsi'),
        const Divider(),
        _buildInfoItem(Icons.location_on, 'Alamat',
            _storeDetail['address'] ?? _storeDetail['location'] ?? '-'),
        const Divider(),
        _buildInfoItem(Icons.access_time, 'Jam Buka',
            _storeDetail['openingHours'] ?? 'Setiap Hari'),
        const Divider(),
        _buildInfoItem(
            Icons.category, 'Kategori Toko', _storeDetail['category'] ?? '-'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: ThemeConfig.brandColor, size: 20 * scale),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * scale)),
                SizedBox(height: 4 * scale),
                Text(value,
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13 * scale)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
