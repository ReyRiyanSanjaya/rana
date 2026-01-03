import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/providers/reviews_provider.dart';
import 'package:rana_market/screens/login_screen.dart';
import 'package:rana_market/screens/store_detail_screen.dart';
import 'package:rana_market/screens/main_screen.dart';
import 'package:rana_market/widgets/buyer_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String storeId;
  final String storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLong;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.storeId,
    required this.storeName,
    this.storeAddress,
    this.storeLat,
    this.storeLong,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _rating = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewsProvider>(context, listen: false)
          .loadInitial(widget.product['id'], sort: 'newest');
    });
    _scrollCtrl.addListener(_onScroll);
    _recordViewed();
  }

  void _onScroll() {
    final rev = Provider.of<ReviewsProvider>(context, listen: false);
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (rev.hasMore(widget.product['id']) &&
          !rev.isLoading(widget.product['id'])) {
        rev.loadMore(widget.product['id']);
      }
    }
  }

  Future<void> _recordViewed() async {
    final id = widget.product['id']?.toString();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'buyer_recent_products_v1';
    final list = prefs.getStringList(key) ?? <String>[];
    list.remove(id);
    list.insert(0, id);
    if (list.length > 20) list.removeRange(20, list.length);
    await prefs.setStringList(key, list);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price =
        (widget.product['sellingPrice'] as num?)?.toDouble() ?? 0;
    final originalPrice =
        (widget.product['originalPrice'] as num?)?.toDouble();
    final hasPromo = originalPrice != null &&
        originalPrice > price &&
        originalPrice > 0;
    final discountPct = hasPromo
        ? ((1 - price / originalPrice) * 100).round()
        : null;
    final savedAmount =
        hasPromo ? (originalPrice - price).toInt() : null;
    final imageUrl = MarketApiService().resolveFileUrl(
      widget.product['imageUrl'] ?? widget.product['image'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: imageUrl.isEmpty
                              ? Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      size: 100, color: Colors.grey),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image,
                                          size: 100, color: Colors.grey),
                                    );
                                  },
                                ),
                        ),
                        if (discountPct != null)
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE07A5F)
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-$discountPct%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Consumer<FavoritesProvider>(
                            builder: (context, fav, _) {
                              final isFav =
                                  fav.isFavorite(widget.product['id']);
                              return Container(
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
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
                                      .toggleFavorite(widget.product['id']),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product['name'],
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
        if (hasPromo) ...[
                          Text(
                            'Rp ${originalPrice.toInt()}',
                            style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Rp ${price.toInt()}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE07A5F)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE07A5F)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '-$discountPct%',
                                  style: const TextStyle(
                                      color: Color(0xFFE07A5F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (savedAmount != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Hemat Rp $savedAmount',
                              style: const TextStyle(
                                  color: Color(0xFF81B29A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ] else
                          Text(
                            'Rp ${price.toInt()}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE07A5F)),
                          ),
                        const SizedBox(height: 8),
                        Consumer<ReviewsProvider>(
                          builder: (context, rev, _) {
                            final avg = rev.getAverage(widget.product['id']);
                            return Row(
                              children: [
                                Icon(Icons.star,
                                    color: Color(0xFFF2CC8F), size: 18),
                                Text(avg.toStringAsFixed(1)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Informasi Toko',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Color(0xFFE07A5F),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.storeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (widget.storeAddress ??
                                              widget.product['storeAddress'])
                                              ?.toString() ??
                                          'Alamat tidak tersedia',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () {
                                  final store = <String, dynamic>{
                                    'id': widget.storeId,
                                    'name': widget.storeName,
                                    'address': (widget.storeAddress ??
                                            widget.product['storeAddress'])
                                        ?.toString(),
                                    'location': (widget.storeAddress ??
                                            widget.product['storeAddress'])
                                        ?.toString(),
                                    'latitude': widget.storeLat,
                                    'longitude': widget.storeLong,
                                  };
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StoreDetailScreen(store: store),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFFE07A5F),
                                ),
                                child: const Text(
                                  'Kunjungi Toko',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product['description'] ??
                              'Tidak ada deskripsi.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        Consumer<ReviewsProvider>(
                          builder: (context, rev, _) {
                            final total = rev.getCount(widget.product['id']);
                            final dist =
                                rev.getDistribution(widget.product['id']);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total ulasan: $total',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                for (int star = 5; star >= 1; star--)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star,
                                            size: 16, color: Color(0xFFF2CC8F)),
                                        const SizedBox(width: 4),
                                        Text('$star'),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: total == 0
                                                ? 0
                                                : (dist[star]! / total),
                                            minHeight: 8,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            color: Color(0xFFF2CC8F),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${dist[star]}'),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Ulasan Pembeli',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Consumer<ReviewsProvider>(
                              builder: (context, rev, _) {
                                final currentSort =
                                    rev.sortFor(widget.product['id']);
                                return DropdownButton<String>(
                                  value: currentSort,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'newest',
                                        child: Text('Terbaru')),
                                    DropdownMenuItem(
                                        value: 'rating_desc',
                                        child: Text('Terbanyak Bintang')),
                                  ],
                                  onChanged: (val) {
                                    if (val == null) return;
                                    Provider.of<ReviewsProvider>(context,
                                            listen: false)
                                        .loadInitial(widget.product['id'],
                                            sort: val);
                                  },
                                );
                              },
                            ),
                            const Spacer(),
                            Consumer<ReviewsProvider>(
                              builder: (context, rev, _) {
                                final canLoad =
                                    rev.hasMore(widget.product['id']) &&
                                        !rev.isLoading(widget.product['id']);
                                return TextButton(
                                  onPressed: canLoad
                                      ? () => rev.loadMore(widget.product['id'])
                                      : null,
                                  child: const Text('Muat lagi'),
                                );
                              },
                            )
                          ],
                        ),
                        Consumer<ReviewsProvider>(
                          builder: (context, rev, _) {
                            final list = rev.getReviews(widget.product['id']);
                            return Column(
                              children: [
                                for (final r in list)
                                  ListTile(
                                    leading: Icon(Icons.star,
                                        color: Color(0xFFF2CC8F)),
                                    title: Text(
                                        '${r['userName']} • ${(r['rating'] as int).toString()}'),
                                    subtitle: Text(r['comment'] ?? ''),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(5, (i) {
                            final val = i + 1;
                            return IconButton(
                              onPressed: () => setState(() => _rating = val),
                              icon: Icon(
                                Icons.star,
                                color: _rating >= val
                                    ? Color(0xFFF2CC8F)
                                    : Colors.grey.shade400,
                              ),
                            );
                          }),
                        ),
                        TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Tulis ulasan'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () async {
                              final auth = Provider.of<AuthProvider>(context,
                                  listen: false);
                              if (!auth.isAuthenticated) {
                                final ok = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                                if (ok != true || !context.mounted) return;
                              }
                              final rev = Provider.of<ReviewsProvider>(context,
                                  listen: false);
                              await rev.addReview(
                                productId: widget.product['id'],
                                rating: _rating,
                                comment: _commentCtrl.text,
                                userName: auth.user?['name'],
                              );
                              _commentCtrl.clear();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Ulasan terkirim')));
                            },
                            child: const Text('Kirim Ulasan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
            child: Row(
              children: [
                // Quantity
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                      ),
                      Text('$_quantity',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Add Button
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      try {
                        final cart = Provider.of<MarketCartProvider>(context,
                            listen: false);

                        // Add quantity times
                        for (var i = 0; i < _quantity; i++) {
                          cart.addToCart(
                            widget.storeId,
                            widget.storeName,
                            widget.product['id'],
                            widget.product['name'],
                            price,
                            storeAddress: widget.storeAddress,
                            storeLat: widget.storeLat,
                            storeLong: widget.storeLong,
                            originalPrice: originalPrice,
                            imageUrl: imageUrl,
                          );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '${widget.product['name']} ditambahkan ke keranjang')));
                        Navigator.pop(context);
                      } catch (e) {
                        if (e.toString().contains('DIFFERENT_STORE')) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Hanya bisa pesan dari 1 Resto sekaligus!')));
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Tambah Keranjang'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: BuyerBottomNav(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 0)),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 1)),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 2)),
              (route) => false,
            );
          } else if (index == 3) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 3)),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
