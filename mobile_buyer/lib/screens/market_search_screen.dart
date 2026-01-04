import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/search_history_provider.dart';

class MarketSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const MarketSearchScreen(
      {super.key, this.initialQuery, this.initialCategory});

  @override
  State<MarketSearchScreen> createState() => _MarketSearchScreenState();
}

class _MarketSearchScreenState extends State<MarketSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _api = MarketApiService();

  List<dynamic> _results = [];
  bool _isLoading = false;
  String _activeCategory = 'Semua';
  String _activeSort =
      'relevance'; // relevance, price_asc, price_desc, distance
  double? _lat;
  double? _long;

  final List<Map<String, String>> _categories = [
    {'id': 'Semua', 'label': 'Semua'},
    {'id': 'Makanan', 'label': 'Makanan'},
    {'id': 'Minuman', 'label': 'Minuman'},
    {'id': 'Belanja', 'label': 'Belanja'},
    {'id': 'Kesehatan', 'label': 'Kesehatan'},
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery ?? '';
    _activeCategory = widget.initialCategory ?? 'Semua';
    _loadLocationAndSearch();
  }

  Future<void> _loadLocationAndSearch() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _long = pos.longitude;
        });
        _doSearch();
      }
    } catch (e) {
      _doSearch();
    }
  }

  Future<void> _doSearch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final res = await _api.searchGlobal(
        query: _searchCtrl.text,
        category: _activeCategory,
        sort: _activeSort,
        lat: _lat,
        long: _long,
      );
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.beigeBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: TextField(
          controller: _searchCtrl,
          autofocus:
              widget.initialQuery == null && widget.initialCategory == null,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _doSearch(),
          decoration: InputDecoration(
            hintText: 'Cari produk, makanan...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ThemeConfig.brandColor),
            onPressed: _doSearch,
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Sort Button
            PopupMenuButton<String>(
              initialValue: _activeSort,
              onSelected: (val) {
                setState(() => _activeSort = val);
                _doSearch();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'relevance', child: Text('Relevansi')),
                const PopupMenuItem(
                    value: 'price_asc', child: Text('Termurah')),
                const PopupMenuItem(
                    value: 'price_desc', child: Text('Termahal')),
                const PopupMenuItem(value: 'distance', child: Text('Terdekat')),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sort, size: 16),
                    SizedBox(width: 4),
                    Text('Urutkan'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Category Chips
            ..._categories.map((cat) {
              final isActive = _activeCategory == cat['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat['label']!),
                  selected: isActive,
                  onSelected: (val) {
                    setState(
                        () => _activeCategory = val ? cat['id']! : 'Semua');
                    _doSearch();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: ThemeConfig.brandColor.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isActive ? ThemeConfig.brandColor : Colors.black87,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isActive
                          ? ThemeConfig.brandColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Show history if query is empty
    if (_searchCtrl.text.isEmpty) {
      return Consumer<SearchHistoryProvider>(
        builder: (context, history, _) {
          if (history.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Mulai pencarian...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pencarian Terakhir',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<SearchHistoryProvider>().clear(),
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: history.history.length,
                  itemBuilder: (context, index) {
                    final q = history.history[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(q),
                      onTap: () {
                        _searchCtrl.text = q;
                        _doSearch();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final isTab = ThemeConfig.isTablet(context);
    final cols = ThemeConfig.gridColumns(context, mobile: 2);
    final ratio = isTab ? 0.75 : 0.7;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return GestureDetector(
          onTap: () {
            // Re-map to match ProductDetailScreen expectations
            // Note: ProductDetailScreen might expect specific fields
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
                  storeLat:
                      (item['store']?['latitude'] ?? item['store']?['lat'])
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isTab
                            ? Hero(
                                tag: item['id'] ?? item['imageUrl'] ?? index,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      _api.resolveFileUrl(item['imageUrl']),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: Colors.grey.shade200),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: _api.resolveFileUrl(item['imageUrl']),
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: Colors.grey.shade200),
                              ),
                        if (item['distance'] != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(item['distance'] as num).toStringAsFixed(1)} km',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${item['sellingPrice']}',
                        style: const TextStyle(
                          color: ThemeConfig.brandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item['store']?['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
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
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }
}
