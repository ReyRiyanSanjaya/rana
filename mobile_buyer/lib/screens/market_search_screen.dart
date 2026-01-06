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
  String _activeSort = 'relevance';
  String _activeRatingFilter = 'Semua';
  double? _lat;
  double? _long;
  List<String> _availableCategories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery ?? '';
    _activeCategory = widget.initialCategory ?? 'Semua';
    final initialCat = _activeCategory.trim();
    if (initialCat.isNotEmpty && initialCat != 'Semua') {
      _availableCategories = ['Semua', initialCat];
    }
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
        List<dynamic> filtered = res;
        double? minRating;
        if (_activeRatingFilter == '4+') {
          minRating = 4;
        } else if (_activeRatingFilter == '4.5+') {
          minRating = 4.5;
        }
        if (minRating != null) {
          filtered = res.where((item) {
            final rating = (item['averageRating'] as num?)?.toDouble() ?? 0;
            return rating >= minRating!;
          }).toList();
        }
        final categorySet = <String>{};
        for (final item in filtered) {
          final fromTopLevel = (item['category'] ?? '').toString().trim();
          final fromStore =
              (item['store']?['category'] ?? '').toString().trim();
          if (fromTopLevel.isNotEmpty) {
            categorySet.add(fromTopLevel);
          }
          if (fromStore.isNotEmpty) {
            categorySet.add(fromStore);
          }
        }
        final initialCat = widget.initialCategory?.trim();
        if (initialCat != null &&
            initialCat.isNotEmpty &&
            initialCat != 'Semua') {
          categorySet.add(initialCat);
        }
        final categories = categorySet.toList()..sort();
        setState(() {
          _results = filtered;
          _availableCategories =
              categories.isEmpty ? ['Semua'] : ['Semua', ...categories];
          if (!_availableCategories.contains(_activeCategory)) {
            _activeCategory = 'Semua';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = ThemeConfig.tabletScale(context, mobile: 1.0);
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
          _buildFilters(scale),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState(scale)
                    : _buildGrid(scale),
      ),
        ],
      ),
    );
  }

  Widget _buildFilters(double scale) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          children: [
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
                const PopupMenuItem(
                    value: 'rating_desc', child: Text('Rating Tertinggi')),
                const PopupMenuItem(value: 'distance', child: Text('Terdekat')),
              ],
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale, vertical: 6 * scale),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16 * scale),
                    SizedBox(width: 4 * scale),
                    Text(
                      'Urutkan',
                      style: TextStyle(fontSize: 13 * scale),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            ..._availableCategories.map((label) {
              final isActive = _activeCategory == label;
              return Padding(
                padding: EdgeInsets.only(right: 8 * scale),
                child: FilterChip(
                  label: Text(
                    label,
                    style: TextStyle(fontSize: 12 * scale),
                  ),
                  selected: isActive,
                  onSelected: (val) {
                    setState(() => _activeCategory = val ? label : 'Semua');
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
            FilterChip(
              label: Text(
                '4+ bintang',
                style: TextStyle(fontSize: 12 * scale),
              ),
              selected: _activeRatingFilter == '4+',
              onSelected: (val) {
                setState(() {
                  _activeRatingFilter = val ? '4+' : 'Semua';
                });
                _doSearch();
              },
              backgroundColor: Colors.white,
              selectedColor: ThemeConfig.brandColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: _activeRatingFilter == '4+'
                    ? ThemeConfig.brandColor
                    : Colors.black87,
                fontWeight: _activeRatingFilter == '4+'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: _activeRatingFilter == '4+'
                      ? ThemeConfig.brandColor
                      : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
            SizedBox(width: 8 * scale),
            FilterChip(
              label: Text(
                '4.5+ bintang',
                style: TextStyle(fontSize: 12 * scale),
              ),
              selected: _activeRatingFilter == '4.5+',
              onSelected: (val) {
                setState(() {
                  _activeRatingFilter = val ? '4.5+' : 'Semua';
                });
                _doSearch();
              },
              backgroundColor: Colors.white,
              selectedColor: ThemeConfig.brandColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: _activeRatingFilter == '4.5+'
                    ? ThemeConfig.brandColor
                    : Colors.black87,
                fontWeight: _activeRatingFilter == '4.5+'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: _activeRatingFilter == '4.5+'
                      ? ThemeConfig.brandColor
                      : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    // Show history if query is empty
    if (_searchCtrl.text.isEmpty) {
      return Consumer<SearchHistoryProvider>(
        builder: (context, history, _) {
          if (history.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: 64 * scale, color: Colors.grey.shade300),
                  SizedBox(height: 16 * scale),
                  Text(
                    'Mulai pencarian...',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14 * scale),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pencarian Terakhir',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * scale),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<SearchHistoryProvider>().clear(),
                      child: Text('Hapus',
                          style: TextStyle(
                              color: Colors.red, fontSize: 13 * scale)),
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
                      leading:
                          const Icon(Icons.history, color: Colors.grey),
                      title: Text(
                        q,
                        style: TextStyle(fontSize: 13 * scale),
                      ),
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
          Icon(Icons.search_off,
              size: 64 * scale, color: Colors.grey.shade300),
          SizedBox(height: 16 * scale),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 14 * scale),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(double scale) {
    final isTab = ThemeConfig.isTablet(context);
    final cols = ThemeConfig.gridColumns(context, mobile: 2);
    final ratio = isTab ? 0.75 : 0.7;
    return GridView.builder(
      padding: EdgeInsets.all(16 * scale),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16 * scale,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        final reviewCount = (item['reviewCount'] ?? 0) as num;
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
                            bottom: 8 * scale,
                            right: 8 * scale,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale, vertical: 2 * scale),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(item['distance'] as num).toStringAsFixed(1)} km',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10 * scale),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scale),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Rp ${item['sellingPrice']}',
                        style: TextStyle(
                          color: ThemeConfig.brandColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 12, color: ThemeConfig.colorRating),
                          SizedBox(width: 4 * scale),
                          Text(
                            ((item['averageRating'] ?? 0) as num)
                                .toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Colors.grey,
                            ),
                          ),
                          if (reviewCount > 0) ...[
                            SizedBox(width: 4 * scale),
                            Text(
                              '(${reviewCount.toInt()})',
                              style: TextStyle(
                                fontSize: 10 * scale,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          SizedBox(width: 8 * scale),
                          Icon(Icons.store,
                              size: 12 * scale, color: Colors.grey),
                          SizedBox(width: 4 * scale),
                          Expanded(
                            child: Text(
                              item['store']?['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11 * scale),
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
