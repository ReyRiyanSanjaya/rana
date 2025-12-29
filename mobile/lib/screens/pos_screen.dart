import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/widgets/product_card.dart';
import 'package:rana_merchant/services/sound_service.dart';
import 'package:rana_merchant/screens/scan_screen.dart';
import 'package:rana_merchant/screens/payment_screen.dart'; // [NEW] Refactored
import 'package:rana_merchant/providers/auth_provider.dart'; // [NEW] Import AuthProvider
import 'package:rana_merchant/services/sync_service.dart'; // [NEW] For manual sync
import 'package:flutter/services.dart';


class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> _categories = ['All']; // [FIX] Dynamic Categories

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    
    // [FIX] Extract Unique Categories
    final Set<String> uniqueCats = {'All'};
    for (var p in data) {
      if (p['category'] != null && p['category'].toString().isNotEmpty) {
        uniqueCats.add(p['category']);
      }
    }

    setState(() {
      _products = data;
      _categories = uniqueCats.toList(); // Update UI with real categories
      _filterProducts();
      _isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((p) {
        final matchCat = _selectedCategory == 'All' || (p['category'] ?? 'Lainnya') == _selectedCategory;
        final matchQuery = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           p['sku'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchCat && matchQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Mesin Kasir', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () async {
                 await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
               // Ideally, scan screen should return a code, and we add it to cart here
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Transaksi',
            onPressed: () async {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi data...')));
               try {
                 await SyncService().syncTransactions();
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi Selesai'), backgroundColor: Colors.green));
               } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Sync: $e'), backgroundColor: Colors.red));
               }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(context, cart),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari Produk...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16)
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterProducts();
                  },
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          _selectedCategory = cat;
                          _filterProducts();
                        },
                        checkmarkColor: Colors.white,
                        selectedColor: Colors.indigoAccent,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _filteredProducts.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.search_off, size: 64, color: Colors.grey), Text('Produk tidak ditemukan')]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (ctx, i) {
                final product = _filteredProducts[i];
                final qty = cart.items[product['id']]?.quantity ?? 0;
                return ProductCard(
                  product: product,
                  quantity: qty,
                  onTap: () {
                    SoundService.playBeep();
                    cart.addItem(product['id'], product['name'], product['sellingPrice']);
                  },
                ).animate().scale(delay: (30 * i).ms, duration: 200.ms);
              },
            ),
       bottomNavigationBar: cart.itemCount > 0 ? Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4))]),
         child: SafeArea(
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('${cart.itemCount} Item', style: const TextStyle(color: Colors.grey)),
                   Text(currency.format(cart.totalAmount), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                 ],
               ),
               FilledButton.icon(
                 onPressed: () => _showCartSheet(context, cart),
                 icon: const Icon(Icons.shopping_bag),
                 label: const Text('Lihat Pesanan'),
                 style: FilledButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
               )
             ],
           ),
         ),
       ).animate().slideY(begin: 1, end: 0) : null,
    );
  }

  void _showCartSheet(BuildContext context, CartProvider cart) {
    // This reuses the logic similar to HomeScreen but in a bottom sheet for mobile POS
    // For simplicity, we can implement a basic list here or reuse the existing cart widget logic if separated
    // Since HomeScreen has _buildCartSidebar specific to it, I'll implement a simple one here for now
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Padding(
               padding: const EdgeInsets.all(16),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Consumer<CartProvider>(
                     builder: (context, cart, child) => Text('Keranjang (${cart.itemCount})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold))
                   ),
                   IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                 ],
               ),
            ),
            const Divider(height: 1),
            
            // [RESTORED] Customer Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: (){
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Pilih Pelanggan (Segera Hadir)')));
                }, 
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.indigo, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                             Text('Pelanggan', style: TextStyle(color: Colors.grey, fontSize: 10)),
                             Text('Umum (Cash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        )
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            // [FIX] Wrap in Consumer to listen to updates inside Modal
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return cart.itemCount == 0 
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Keranjang kosong')]))
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_,__) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Dismissible(
                        key: Key(item.productId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          cart.removeItem(item.productId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item dihapus dari keranjang')));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50, height: 50, 
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.price), style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(onPressed: () => cart.removeSingleItem(item.productId), icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 24)),
                                  InkWell(
                                    onTap: () async {
                                      final ctrl = TextEditingController(text: item.quantity.toString());
                                      final result = await showDialog<int>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Set Jumlah'),
                                          content: TextField(
                                            controller: ctrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: const InputDecoration(hintText: 'Masukkan qty'),
                                            onSubmitted: (valStr){
                                              final val = int.tryParse(valStr);
                                              Navigator.pop(context, val);
                                            },
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                            FilledButton(
                                              onPressed: () {
                                                final val = int.tryParse(ctrl.text);
                                                Navigator.pop(context, val);
                                              },
                                              child: const Text('Simpan'),
                                            )
                                          ],
                                        ),
                                      );
                                      if (result != null) {
                                        cart.setItemQuantity(item.productId, result);
                                      }
                                    },
                                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  IconButton(
                                    tooltip: 'Set Qty',
                                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                    onPressed: () async {
                                      final ctrl = TextEditingController(text: item.quantity.toString());
                                      final result = await showDialog<int>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Set Jumlah'),
                                          content: TextField(
                                            controller: ctrl,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: const InputDecoration(hintText: 'Masukkan qty'),
                                            onSubmitted: (valStr){
                                              final val = int.tryParse(valStr);
                                              Navigator.pop(context, val);
                                            },
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                            FilledButton(
                                              onPressed: () {
                                                final val = int.tryParse(ctrl.text);
                                                Navigator.pop(context, val);
                                              },
                                              child: const Text('Simpan'),
                                            )
                                          ],
                                        ),
                                      );
                                      if (result != null) {
                                        cart.setItemQuantity(item.productId, result);
                                      }
                                    },
                                  ),
                                  IconButton(onPressed: () => cart.addItem(item.productId, item.name, item.price), icon: const Icon(Icons.add_circle, color: Colors.green, size: 24)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
            
            // Re-use logic for button layout but nicer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Column(
                    children: [
                       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cart.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                       const SizedBox(height: 16),
                       SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: cart.itemCount == 0 ? null : () {
                             Navigator.pop(context);
                             _processPayment(context, cart);
                          },
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: const Color(0xFF4F46E5)),
                          child: const Text('LANJUT PEMBAYARAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                }
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: PaymentScreen(cart: cart),
        )
      )
    );


    if (success == true && context.mounted) {
       // Backup notification
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Transaksi Berhasil!'), backgroundColor: Colors.green, duration: Duration(seconds: 2))
       );
       SoundService.playSuccess();
       showDialog(context: context, builder: (_) => const TransactionSuccessDialog());
       cart.clear(); 
    }
  }
}
