import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/product_detail_screen.dart';
import 'package:rana_market/providers/reviews_provider.dart';

class StoreDetailScreen extends StatelessWidget {
  final Map<String, dynamic> store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final products = store['products'] as List<dynamic>? ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(store['name'] ?? 'Toko'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.store, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(store['address'] ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(store['category'] ?? '-', style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3/4,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Consumer2<FavoritesProvider, ReviewsProvider>(
                  builder: (context, fav, rev, _) {
                    final isFav = fav.isFavorite(p['id']);
                    final avg = rev.getAverage(p['id']);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(
                            product: p,
                            storeId: store['id'],
                            storeName: store['name'],
                          ))
                        );
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12))
                                    ),
                                    child: const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Rp ${p['sellingPrice']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      Row(
                                        children: [
                                          Icon(Icons.star, size: 14, color: Colors.orange.shade400),
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
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
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
