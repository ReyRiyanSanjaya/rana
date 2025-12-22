import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';
import 'package:rana_merchant/screens/wholesale_cart_screen.dart'; // We will create this next

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final List<String> _categories = ['Semua', 'Sembako', 'Minuman', 'Rokok', 'Perlengkapan'];
  String _selectedCat = 'Semua';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allItems = [
    { 'id': '1', 'name': 'Beras Premium 50Kg (Karung)', 'price': 650000, 'category': 'Sembako', 'supplier': 'Agen Beras Makmur', 'image': 'https://via.placeholder.com/300', 'rating': '4.8', 'sold': '1.2rb' },
    { 'id': '2', 'name': 'Minyak Goreng 2L (Dus isi 6)', 'price': 180000, 'category': 'Sembako', 'supplier': 'Sembako Jaya', 'image': 'https://via.placeholder.com/300', 'rating': '4.9', 'sold': '850' },
    { 'id': '3', 'name': 'Gula Pasir 1Kg (Dus isi 20)', 'price': 320000, 'category': 'Sembako', 'supplier': 'Sembako Jaya', 'image': 'https://via.placeholder.com/300', 'rating': '4.7', 'sold': '500+' },
    { 'id': '4', 'name': 'Indomie Goreng (Dus isi 40)', 'price': 115000, 'category': 'Sembako', 'supplier': 'Indo Grosir', 'image': 'https://via.placeholder.com/300', 'rating': '5.0', 'sold': '2rb' },
    { 'id': '5', 'name': 'Telur Ayam Ras (Peti 15kg)', 'price': 385000, 'category': 'Sembako', 'supplier': 'Peternakan Sejahtera', 'image': 'https://via.placeholder.com/300', 'rating': '4.6', 'sold': '300+' },
    { 'id': '6', 'name': 'Tepung Terigu (Karung 25kg)', 'price': 210000, 'category': 'Sembako', 'supplier': 'Boga Sari Agent', 'image': 'https://via.placeholder.com/300', 'rating': '4.8', 'sold': '400' },
    { 'id': '7', 'name': 'Teh Pucuk Harum (Dus)', 'price': 65000, 'category': 'Minuman', 'supplier': 'Indo Grosir', 'image': 'https://via.placeholder.com/300', 'rating': '4.5', 'sold': '1rb' },
    { 'id': '8', 'name': 'Gudang Garam Surya (Slop)', 'price': 320000, 'category': 'Rokok', 'supplier': 'Agen Rokok 88', 'image': 'https://via.placeholder.com/300', 'rating': '4.9', 'sold': '5rb' },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    return _allItems.where((item) {
      final matchCat = _selectedCat == 'Semua' || item['category'] == _selectedCat;
      final matchSearch = item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Rana Grosir (B2B)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Consumer<WholesaleCartProvider>(
            builder: (ctx, cart, _) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'), 
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: Colors.blue.shade900),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WholesaleCartScreen())),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar (Functional)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari barang grosir...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),

            // 2. Banner
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBanner(Colors.blue, "Diskon Juragan", "Potongan 50rb!", Icons.discount),
                  const SizedBox(width: 12),
                  _buildBanner(Colors.orange, "Gratis Ongkir", "Min. Blj 1 Juta", Icons.local_shipping),
                   const SizedBox(width: 12),
                  _buildBanner(Colors.green, "Produk Baru", "Harga Perkenalan", Icons.new_releases),
                ],
              ),
            ),

            // 3. Categories (Functional)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _selectedCat == c,
                      onSelected: (val) => setState(() => _selectedCat = c),
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(color: _selectedCat == c ? Colors.blue.shade900 : Colors.black87),
                    ),
                  )).toList(),
                ),
              ),
            ),

            // 4. Product Grid
            if (_filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('Barang tidak ditemukan', style: GoogleFonts.poppins(color: Colors.grey))),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70, // Taller for better info
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) => _buildProductCard(_filteredItems[index]),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(Color color, String title, String sub, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color.withOpacity(0.8))),
                Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  child: const Text('CEK SEKARANG', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          Icon(icon, size: 64, color: color.withOpacity(0.2))
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final fmtPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['price']);
    
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context, 
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => _ProductDetailSheet(item: item)
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: const DecorationImage(image: NetworkImage('https://via.placeholder.com/300'), fit: BoxFit.cover) 
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text(item['category'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700)),
                  ),
                  const SizedBox(height: 4),
                  Text(item['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(fmtPrice, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item['supplier'], style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       const Icon(Icons.star, size: 12, color: Colors.amber),
                       Text(' ${item['rating']} ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                       Text('| ${item['sold']} Terjual', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BOTTOM SHEET DETAIL
// ==========================================
class _ProductDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ProductDetailSheet({required this.item});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
     final fmtPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.item['price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'), 
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
           Expanded(
             child: SingleChildScrollView(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   Container(height: 300, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 120, color: Colors.grey)),
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(fmtPrice, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                         const SizedBox(height: 8),
                         Text(widget.item['name'], style: GoogleFonts.poppins(fontSize: 18, height: 1.3)),
                         const SizedBox(height: 16),
                         const Divider(),
                         ListTile(
                           contentPadding: EdgeInsets.zero,
                           leading: const CircleAvatar(child: Icon(Icons.store)),
                           title: Text(widget.item['supplier'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                           subtitle: Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Text(' ${widget.item['rating']} (999+ Ulasan)', style: TextStyle(fontSize: 12)),
                              ],
                           ),
                           trailing: OutlinedButton(onPressed: (){}, child: const Text('Kunjungi')),
                         ),
                         const Divider(),
                         const SizedBox(height: 16),
                         Text('Deskripsi Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                         const SizedBox(height: 8),
                         Text(
                           "Barang original langsung dari pabrik/distributor resmi. Kualitas terjamin dan harga termurah untuk para juragan UMKM.\n\nSpesifikasi:\n- Berat: 50Kg/Dus\n- Expired: Masih Lama (2026)\n- Pengiriman: Kargo / Kurir Instan\n\nGaransi retur jika barang rusak saat diterima. Wajib video unboxing untuk klaim.",
                           style: GoogleFonts.poppins(color: Colors.grey.shade700, height: 1.6),
                         ),
                       ],
                     ),
                   )
                 ],
               ),
             ),
           ),
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.white,
               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-2))]
             ),
             child: Row(
               children: [
                 Container(
                   decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                   child: Row(
                     children: [
                       IconButton(onPressed: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1), icon: const Icon(Icons.remove)),
                       Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       IconButton(onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add)),
                     ],
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: FilledButton(
                     onPressed: () {
                        // ADD TO PROVIDER
                        Provider.of<WholesaleCartProvider>(context, listen: false).addItem(
                          widget.item['id'], 
                          widget.item['name'], 
                          (widget.item['price'] as int).toDouble(), 
                          widget.item['image'], 
                          widget.item['supplier']
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil masuk keranjang!'), backgroundColor: Colors.green));
                     },
                     style: FilledButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: Colors.blue.shade800,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                     ),
                     child: const Text('Tambah ke Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                 )
               ],
             ),
           )
        ],
      ),
    );
  }
}
