import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/providers/reviews_provider.dart';

class StoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initProducts();
  }

  Future<void> _initProducts() async {
    final initial = widget.store['products'] as List<dynamic>? ?? [];
    _products = initial
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    setState(() {
      _loading = true;
    });
    try {
      final res =
          await MarketApiService().getStoreCatalog(widget.store['id'] ?? '');
      final list = res['products'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _products = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts({String? search}) async {
    setState(() {
      _loading = true;
    });
    try {
      final res = await MarketApiService()
          .getStoreCatalog(widget.store['id'] ?? '', search: search);
      final list = res['products'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _products = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts(search: _query.isEmpty ? null : _query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final products = _products;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(store['name'] ?? 'Toko'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.store, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store['name'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(store['address'] ?? '-',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(store['category'] ?? '-',
                      style: const TextStyle(
                          color: Color(0xFFE07A5F),
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Produk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Cari menu/produk di toko ini',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3 / 4,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Consumer2<FavoritesProvider, ReviewsProvider>(
                  builder: (context, fav, rev, _) {
                    final isFav = fav.isFavorite(p['id']);
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                      product: p,
                                      storeId: store['id'],
                                      storeName: store['name'],
                                      storeAddress: (store['address'] ??
                                              store['location'] ??
                                              store['alamat'])
                                          ?.toString(),
                                      storeLat: ((store['latitude'] ??
                                              store['lat']) is num)
                                          ? (store['latitude'] ?? store['lat'])
                                              .toDouble()
                                          : null,
                                      storeLong: ((store['longitude'] ??
                                              store['long'] ??
                                              store['lng']) is num)
                                          ? (store['longitude'] ??
                                                  store['long'] ??
                                                  store['lng'])
                                              .toDouble()
                                          : null,
                                    )));
                      },
                      child: Stack(
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
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
                                                    size: 40,
                                                    color: Colors.grey)),
                                          )
                                        : Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Center(
                                                          child: Icon(
                                                              Icons.fastfood,
                                                              size: 40,
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
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      if (original != null &&
                                          original > selling)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Rp ${original.toInt()}',
                                                style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(
                                                'Rp ${selling.toInt()}',
                                                style: const TextStyle(
                                                    color: Color(0xFFE07A5F),
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        )
                                      else
                                        Text(
                                            'Rp ${selling.toInt()}',
                                            style: const TextStyle(
                                                color: Color(0xFF81B29A),
                                                fontWeight:
                                                    FontWeight.bold)),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              size: 14,
                                              color: Color(0xFFF2CC8F)),
                                          Text(avg.toStringAsFixed(1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton(
                              icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav
                                      ? const Color(0xFFE07A5F)
                                      : Colors.grey),
                              onPressed: () => fav.toggleFavorite(p['id']),
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
  }
}
