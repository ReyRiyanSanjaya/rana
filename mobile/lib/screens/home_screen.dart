import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/providers/cart_provider.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/screens/expense_screen.dart';
import 'package:rana_merchant/screens/add_product_screen.dart';
import 'package:rana_merchant/screens/report_screen.dart';
import 'package:rana_merchant/screens/history_screen.dart';
import 'package:rana_merchant/screens/settings_screen.dart';
import 'package:rana_merchant/screens/subscription_screen.dart';
import 'package:rana_merchant/screens/stock_opname_screen.dart';

import 'package:rana_merchant/screens/purchase_screen.dart';
import 'package:rana_merchant/screens/order_list_screen.dart';
import 'package:rana_merchant/screens/wallet_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/scan_screen.dart'; // [NEW]
import 'package:lottie/lottie.dart'; // [NEW] Lottie for animations
import 'package:rana_merchant/services/notification_service.dart'; // [NEW]

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    // 1. Try fetch from local DB first
    final localProds = await DatabaseHelper.instance.getAllProducts();
    
    if (localProds.isEmpty) {
      // 2. If empty, try sync downlink
      await ApiService().fetchAndSaveProducts();
      final freshProds = await DatabaseHelper.instance.getAllProducts();
      setState(() {
        products = freshProds;
        isLoading = false;
      });
    } else {
      setState(() {
        products = localProds;
        isLoading = false;
      });
    }
  }

  String _searchQuery = '';
  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _showCartModal(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Consumer<CartProvider>( // [FIX] Listen to changes
          builder: (context, cart, child) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
               children: [
                 const SizedBox(height: 12),
                 Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                 Expanded(child: _buildCartSidebar(context, cart, scrollController: scrollController)),
               ]
            ),
          ),
        ),
      )
    );
  }

  Widget _buildCartSidebar(BuildContext context, CartProvider cart, {ScrollController? scrollController}) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => cart.clear(), icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Clear Cart')
            ],
          ),
        ),
        
        // Items
        Expanded(
          child: cart.itemCount == 0 
           ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]), SizedBox(height: 16), Text('Cart is empty', style: TextStyle(color: Colors.grey[400]))]))
           : ListView.separated(
             controller: scrollController,
             itemCount: cart.items.length,
             separatorBuilder: (_,__) => const Divider(height: 1),
             itemBuilder: (context, index) {
                final item = cart.items.values.toList()[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Rp ${item.price} x ${item.quantity}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton.filledTonal(onPressed: () => cart.removeSingleItem(item.productId), icon: const Icon(Icons.remove, size: 16), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
                       SizedBox(width: 24, child: Center(child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)))),
                       IconButton.filled(onPressed: () => cart.addItem(item.productId, item.name, item.price), icon: const Icon(Icons.add, size: 16), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
                    ],
                  ),
                );
             },
           ),
        ),
        
        // Footer
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('Rp ${cart.totalAmount}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, 
                child: FilledButton(
                  onPressed: cart.itemCount == 0 ? null : () async {
                    final success = await _showPaymentModal(context, cart);
                    if (success == true && context.mounted) {
                      Navigator.pop(context); // Close Cart Modal on Success
                      
                      // Show Success Dialog from the main screen context
                      showDialog(
                        context: context, 
                        barrierDismissible: false,
                        builder: (ctx) => const TransactionSuccessDialog()
                      );
                      
                      // Show System Notification
                      await NotificationService().showNotification(
                        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        title: 'Transaksi Berhasil!',
                        body: 'Pembayaran sebesar Rp ${cart.totalAmount} telah diterima.',
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: const Color(0xFFFF2C2C), // [FIX] Requested Red Color
                  ), 
                  child: const Text('PROCEED TO PAYMENT')
                )
              ),
            ],
          ),
        )
      ],
    );
  }

  // Modified to return success status
  Future<bool?> _showPaymentModal(BuildContext context, CartProvider cart) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4, 
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Expanded(
                child: PaymentScreen(cart: cart, scrollController: scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.store, color: Colors.indigo.shade100, size: 48),
                  const SizedBox(height: 8),
                  const Text('Rana Merchant', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
             ListTile(leading: const Icon(Icons.point_of_sale), title: const Text('Kasir (POS)'), onTap: () => Navigator.pop(context)),
             ListTile(leading: const Icon(Icons.add_box), title: const Text('Tambah Produk'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((val) { if (val == true) _loadProducts(); }); }),
             ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Laporan & Grafik'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); }),
             ListTile(leading: const Icon(Icons.local_shipping), title: const Text('Kulakan (Stok Masuk)'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())); }),
             ListTile(leading: const Icon(Icons.inventory), title: const Text('Stock Opname'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen())); }),
             ListTile(leading: const Icon(Icons.notifications_active), title: const Text('Pesanan Online (Baru!)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen())); }),
             ListTile(leading: const Icon(Icons.qr_code_scanner), title: const Text('Scan QR Pickup', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())); }),
             ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Dompet Merchant'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())); }),
             const Divider(),
             ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
        ],
      ),
    );
  }

  // ... (buildHeader, buildProductGrid, buildDrawer remain similar but make sure _showPaymentModal isn't broken)

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    var auth = Provider.of<AuthProvider>(context, listen: false); // kept for potential use

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            // MOBILE LAYOUT: Full Width Grid + FAB Cart
            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildProductGrid(context, cart, crossAxisCount: 2, aspectRatio: 0.75)),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showCartModal(context, cart),
                    icon: const Icon(Icons.shopping_cart),
                    label: Text('${cart.itemCount} Items - Rp ${cart.totalAmount}'),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                )
              ],
            );
          } else {
            // DESKTOP/TABLET LAYOUT: Split View
            return Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(child: _buildProductGrid(context, cart, crossAxisCount: 3, aspectRatio: 0.75)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _buildCartSidebar(context, cart),
                  ),
                )
              ],
            );
          }
        },
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari Produk...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () async {
              setState(() => isLoading = true);
              await ApiService().syncAllData();
              _loadProducts(); // Reload from local DB
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi Selesai')));
            }, 
            icon: const Icon(Icons.sync), 
            tooltip: 'Sinkronisasi Data'
          ),
          IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu)),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, CartProvider cart, {required int crossAxisCount, required double aspectRatio}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey[500]))
      ]));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final qty = cart.items[product['id']]?.quantity ?? 0;
        return GestureDetector(
          onTap: () => cart.addItem(product['id'], product['name'], product['sellingPrice']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              border: qty > 0 ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Text(
                        product['name'].substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rp ${product['sellingPrice']}', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 12)),
                          if (qty > 0)
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (30 * index).ms).scale(duration: 200.ms),
        );
      },
    );
  }

  } // End of _HomeScreenState

// Advanced Payment Screen Widget
class PaymentScreen extends StatefulWidget {
  final CartProvider cart;
  final ScrollController scrollController;
  
  const PaymentScreen({super.key, required this.cart, required this.scrollController});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'CASH';
  double payAmount = 0;
  bool _isProcessing = false;
  
  void setAmount(double val) {
     setState(() => payAmount = val);
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.cart.totalAmount;
    double change = payAmount - total;
    
    // Quick cash suggestions
    final suggestions = [total, 20000.0, 50000.0, 100000.0];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMethodCard('CASH', Icons.payments, true),
            const SizedBox(width: 12),
            _buildMethodCard('QRIS', Icons.qr_code_2, false),
            const SizedBox(width: 12),
            _buildMethodCard('KASBON', Icons.book, false),
          ],
        ),
        
        if (method == 'CASH') ...[
          const SizedBox(height: 32),
          const Text('Nominal Diterima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              hintText: '0',
            ),
            onChanged: (v) => setAmount(double.tryParse(v) ?? 0),
            controller: TextEditingController(text: payAmount == 0 ? '' : payAmount.toStringAsFixed(0))..selection = TextSelection.fromPosition(TextPosition(offset: (payAmount == 0 ? '' : payAmount.toStringAsFixed(0)).length)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: suggestions.map((amt) {
              if (amt < total && amt != total) return const SizedBox.shrink(); // Don't show less than total unless exact
              return ActionChip(
                label: Text('Rp ${amt.toStringAsFixed(0)}'),
                onPressed: () => setAmount(amt),
                backgroundColor: payAmount == amt ? Colors.green[100] : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
           Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: change >= 0 ? Colors.green[50] : Colors.red[50],
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: change >= 0 ? Colors.green[200]! : Colors.red[200]!)
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Kembalian', style: TextStyle(fontSize: 18)),
                 Text('Rp ${change < 0 ? 0 : change.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               ],
             ),
           )
        ],
        
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _isProcessing || (method == 'CASH' && payAmount < total) ? null : () async {
            setState(() => _isProcessing = true);
            
            try {
              // 1. Process Transaction
              await widget.cart.checkout(
                'tenant-1', 'store-1', 'cashier-1', 
                paymentMethod: method,
              );
              
              if (!mounted) return;
              
              // 2. Close Payment Sheet and Return Success = true
              Navigator.pop(context, true);
              
            } catch (e) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF2C2C), // [FIX] Requested Red Color
             padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          child: _isProcessing 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text('SELESAIKAN TRANSAKSI'),
        )
      ],
    );
  }
  
  Widget _buildMethodCard(String id, IconData icon, bool selected) {
    final isSelected = method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { method = id; payAmount = 0; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
             color: isSelected ? Colors.indigo : Colors.white,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: isSelected ? Colors.indigo : Colors.grey[300]!),
             boxShadow: isSelected ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,4))] : null
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 32),
              const SizedBox(height: 8),
              Text(id, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionSuccessDialog extends StatelessWidget {
  const TransactionSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) Navigator.of(context).pop();
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use a network Lottie for now, or asset if available. 
            // Using a common public success lottie.
            Lottie.network(
              'https://lottie.host/560f9488-820d-450f-b4f0-4fa9b4221706/kF4x8X5f39.json', // Clean Checkmark Animation
              height: 150,
              repeat: false,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaksi Berhasil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text('Struk sedang diproses...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
