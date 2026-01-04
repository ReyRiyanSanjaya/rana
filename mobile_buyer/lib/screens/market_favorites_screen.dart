import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/config/theme_config.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/auth_provider.dart';
import 'package:rana_market/providers/favorites_provider.dart';
import 'package:rana_market/screens/product_detail_screen.dart';

class MarketFavoritesScreen extends StatefulWidget {
  const MarketFavoritesScreen({super.key});

  @override
  State<MarketFavoritesScreen> createState() => _MarketFavoritesScreenState();
}

class _MarketFavoritesScreenState extends State<MarketFavoritesScreen> {
  bool _loading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final phone = auth.user?['phone'] as String?;
    
    if (phone == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final list = await MarketApiService().getFavorites(phone);
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
        
        
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada favorit',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return _buildFavoriteItem(item);
                  },
                ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> item) {
    final price = (item['sellingPrice'] as num?)?.toDouble() ?? 0;
    final imageUrl = MarketApiService().resolveFileUrl(item['imageUrl']);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: item,
              storeId: item['storeId'] ?? '',
              storeName: item['store']?['name'] ?? 'Toko',
            ),
          ),
        ).then((_) => _loadData()); // Reload when returning
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${price.toInt()}',
                    style: const TextStyle(
                        color: ThemeConfig.brandColor,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['store']?['name'] ?? 'Toko',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                 final auth = Provider.of<AuthProvider>(context, listen: false);
                 final phone = auth.user?['phone'] as String?;
                 
                 // Update Provider
                 Provider.of<FavoritesProvider>(context, listen: false)
                    .toggleFavorite(item['id'], phone: phone);
                 
                 // Remove locally from list
                 setState(() {
                   _products.remove(item);
                 });
              },
            )
          ],
        ),
      ),
    );
  }
}
