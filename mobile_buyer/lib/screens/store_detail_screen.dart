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
    return Scaffold(
      backgroundColor: ThemeConfig.beigeBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMenuTab(),
            _buildReviewsTab(),
            _buildInfoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final bannerUrl =
        MarketApiService().resolveFileUrl(_storeDetail['bannerUrl']);
    final logoUrl = MarketApiService().resolveFileUrl(_storeDetail['imageUrl']);
    final hasBanner = bannerUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 200,
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
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
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
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _storeDetail['name'] ?? 'Toko',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${(_reviewStats['averageRating'] ?? 0).toStringAsFixed(1)} (${_reviewStats['totalReviews'] ?? 0})',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _storeDetail['location'] ??
                                    _storeDetail['address'] ??
                                    '-',
                                style: const TextStyle(color: Colors.white),
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
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: ThemeConfig.brandColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ThemeConfig.brandColor,
            tabs: const [
              Tab(text: 'Menu'),
              Tab(text: 'Ulasan'),
              Tab(text: 'Info'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    final products = _filteredProducts;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              // Categories
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Produk tidak ditemukan')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildProductCard(products[index]);
                },
                childCount: products.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountPct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (hasPromo) ...[
                        Text(
                          'Rp ${original.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      Text(
                        'Rp ${selling.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.brandColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
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

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Text('Belum ada ulasan', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
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
                  radius: 16,
                  child: Text(
                    (r['userName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['userName'] ?? 'Pengguna',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (r['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(r['createdAt']),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (product != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
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
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 30, height: 30),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (r['comment'] != null && r['comment'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r['comment']),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ThemeConfig.brandColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: Colors.grey.shade700)),
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
