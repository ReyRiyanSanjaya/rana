import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rana_market/data/market_api_service.dart';
import 'package:rana_market/providers/market_cart_provider.dart';
import 'package:rana_market/screens/market_cart_screen.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  String _address = 'Mencari Lokasi...';
  List<dynamic> _nearbyStores = [];
  bool _isLoading = true;
  String _selectedCategory = 'All'; // [NEW]

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // 1. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // 2. Get Position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
    setState(() {
      _nearbyStores = stores;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi Kamu', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
                const Text('Jakarta Selatan', style: TextStyle(fontSize: 14)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: (){}),
          IconButton(icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Mau makan apa hari ini?',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            
            // Unused Banners
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text('Promo Spesial Hari Ini!', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            
            const SizedBox(height: 24),
            
            // Categories
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryItem(Icons.store, 'Semua', Colors.grey, isSelected: _selectedCategory == 'All'),
                  const SizedBox(width: 16),
                  _buildCategoryItem(Icons.local_pharmacy, 'Apotik', Colors.green, isSelected: _selectedCategory == 'Apotik'),
                  const SizedBox(width: 16),
                  _buildCategoryItem(Icons.lunch_dining, 'Kedai Makanan', Colors.orange, isSelected: _selectedCategory == 'Kedai Makanan'),
                  const SizedBox(width: 16),
                  _buildCategoryItem(Icons.shopping_bag, 'Toko Baju', Colors.purple, isSelected: _selectedCategory == 'Toko Baju'),
                  const SizedBox(width: 16),
                  _buildCategoryItem(Icons.phone_android, 'Outlet Ponsel', Colors.blue, isSelected: _selectedCategory == 'Outlet Ponsel'),
                   const SizedBox(width: 16),
                  _buildCategoryItem(Icons.storefront, 'Kelontong', Colors.brown, isSelected: _selectedCategory == 'Kelontong'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Nearby Merchants
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Resto Terdekat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  if (_isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Real List
            _nearbyStores.isEmpty && !_isLoading 
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Tidak ada toko di sekitar.'))
              : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nearbyStores.length,
              itemBuilder: (context, index) {
                final store = _nearbyStores[index];
                
                // [NEW] Client-side filter
                if (_selectedCategory != 'All' && store['category'] != _selectedCategory) {
                   return const SizedBox.shrink(); // Hide if mismatch (simple way) or better: Filter list before building
                }
                
                final dist = (store['distance'] as num?)?.toStringAsFixed(1) ?? '0.0';
                final prods = store['products'] as List<dynamic>? ?? [];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      // Store Header
                      Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(0)), // Corner styling fixed
                              image: const DecorationImage(image: NetworkImage('https://via.placeholder.com/150'), fit: BoxFit.cover) // Placeholder
                            ),
                            child: const Icon(Icons.store, size: 40, color: Colors.grey),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(store['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                   const SizedBox(height: 4),
                                   Text('${store['address'] ?? 'No Address'} • $dist km', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                   const SizedBox(height: 4),
                                   if (store['category'] != null)
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                       decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                                       child: Text(store['category'], style: TextStyle(color: Colors.indigo.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                     ),
                                   const SizedBox(height: 8),
                                   Row(
                                     children: [
                                       Icon(Icons.star, size: 14, color: Colors.orange.shade400),
                                       const Text(' 4.8 ', style: TextStyle(fontWeight: FontWeight.bold)),
                                     ],
                                   )
                                 ],
                              ),
                            ),
                          )
                        ],
                      ),
                                   )
                                 ],
                              ),
                            ),
                          )
                        ],
                      ),
                      // Product Teaser
                      if (prods.isNotEmpty)
                        Container(
                           height: 50,
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           color: Colors.grey.shade50,
                           child: ListView.separated(
                             scrollDirection: Axis.horizontal,
                             itemCount: prods.length,
                             separatorBuilder: (_,__) => const SizedBox(width: 10),
                             itemBuilder: (ctx, i) {
                               final p = prods[i];
                               return ActionChip( // Clickable Chip
                                 label: Text('${p['name']} - Rp ${p['sellingPrice']}'), 
                                 backgroundColor: Colors.white, 
                                 side: BorderSide(color: Colors.grey.shade300),
                                 onPressed: () {
                                    try {
                                      // Context is tricky here if builder isn't right, but usually ok
                                      Provider.of<MarketCartProvider>(context, listen: false).addToCart(
                                        store['id'], 
                                        store['name'], 
                                        p['id'], 
                                        p['name'], 
                                        (p['sellingPrice'] as num).toDouble()
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p['name']} masuk keranjang +1')));
                                    } catch (e) {
                                      if (e.toString().contains('DIFFERENT_STORE')) {
                                         // Show dialog to reset (Mock)
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hanya bisa pesan dari 1 Resto sekaligus!')));
                                      }
                                    }
                                 },
                               );
                             },
                           ),
                        )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: Consumer<MarketCartProvider>(
        builder: (ctx, cart, _) => cart.items.isEmpty ? const SizedBox.shrink() : FloatingActionButton.extended(
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketCartScreen()));
          },
          label: Text('${cart.items.length} Item | Rp ${cart.totalAmount}'),
          icon: const Icon(Icons.shopping_basket),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label == 'Semua' ? 'All' : label),
      child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1), 
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : null
          ),
          child: Icon(icon, color: isSelected ? Colors.white : color),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
      ],
    )
    );
  }
}
