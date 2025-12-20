import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_pos/providers/auth_provider.dart';
import 'package:rana_pos/providers/cart_provider.dart';
import 'package:rana_pos/data/remote/api_service.dart';
import 'package:rana_pos/data/local/database_helper.dart';
import 'package:rana_pos/screens/expense_screen.dart';
import 'package:rana_pos/screens/add_product_screen.dart';
import 'package:rana_pos/screens/report_screen.dart';
import 'package:rana_pos/screens/history_screen.dart';
import 'package:rana_pos/screens/settings_screen.dart';
import 'package:rana_pos/screens/subscription_screen.dart';
import 'package:rana_pos/screens/stock_opname_screen.dart';
import 'package:rana_pos/screens/stock_opname_screen.dart';
import 'package:rana_pos/screens/purchase_screen.dart';
import 'package:rana_pos/screens/order_list_screen.dart';
import 'package:rana_pos/screens/wallet_screen.dart'; // [NEW]
import 'package:rana_pos/screens/scan_screen.dart'; // [NEW]

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

  void _showCheckoutDialog(BuildContext context, CartProvider cart) {
    String paymentMethod = 'CASH';
    TextEditingController nameCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Checkout: Rp ${cart.totalAmount}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment Method Choice
              DropdownButtonFormField<String>(
                value: paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Row(children: [Icon(Icons.money), SizedBox(width: 8), Text('Tunai')])),
                  DropdownMenuItem(value: 'QRIS', child: Row(children: [Icon(Icons.qr_code), SizedBox(width: 8), Text('QRIS')])),
                  DropdownMenuItem(value: 'KASBON', child: Row(children: [Icon(Icons.book), SizedBox(width: 8), Text('Kasbon / Hutang')])),
                ],
                onChanged: (v) => setState(() => paymentMethod = v!),
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
              ),
              const SizedBox(height: 16),
              
              // Conditional Input for Kasbon
              if (paymentMethod == 'KASBON')
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Peminjam',
                    border: OutlineInputBorder(),
                    helperText: 'Wajib diisi untuk Kasbon'
                  ),
                ),
                
               if (paymentMethod == 'QRIS')
                 Container(
                   margin: const EdgeInsets.only(top: 10),
                   height: 150,
                   width: 150,
                   color: Colors.grey[200],
                   child: const Center(child: Text('Scan QRIS Here\n(Static QR)')),
                 )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (paymentMethod == 'KASBON' && nameCtrl.text.isEmpty) {
                   return; // Validate
                }
                
                Navigator.pop(ctx); // Close dialog
                
                await cart.checkout(
                  'tenant-1', 'store-1', 'cashier-1',
                  paymentMethod: paymentMethod,
                  customerName: nameCtrl.text
                );
                
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Transaction Success ($paymentMethod)'),
                         backgroundColor: Colors.green
                       )
                   );
                }
              },
              child: const Text('Confirm & Print'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    var auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rana Merchant'),
        actions: [
          IconButton(
            tooltip: 'Catat Pengeluaran',
            icon: const Icon(Icons.money_off),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()));
            },
          ),
          IconButton(
            tooltip: 'Sync Products & Sales',
             icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...')));
                await ApiService().fetchAndSaveProducts(); // Down
                await ApiService().syncOfflineTransactions(); // Up
                _loadProducts(); // Refresh UI
                if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Complete')));
              } catch (e) {
                 if (e.toString().contains('SUBSCRIPTION_EXPIRED')) {
                    if(context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                 } else {
                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
                 }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.store, color: Colors.indigo.shade100, size: 48), // Updated color for soft theme compatibility
                  SizedBox(height: 8),
                  Text('Rana Merchant', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
             ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Kasir (POS)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Tambah Produk'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((val) {
                   if (val == true) _loadProducts(); // Refresh if added
                 });
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Laporan & Grafik'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Kulakan (Stok Masuk)'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stock Opname'),luaran'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Pesanan Online (Baru!)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Pickup', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Dompet Merchant'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
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
      ),
      body: Row(
        children: [
          // Product Grid
          Expanded(
            flex: 2,
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : products.isEmpty 
                  ? const Center(child: Text('No Products. Press Sync.'))
                  : Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length, // Changed from _products.length to products.length
                      itemBuilder: (context, index) {
                        final product = products[index]; // Changed from _products[index] to products[index]
                        final qty = cart.items[product['id']]?.quantity ?? 0; // Changed from _cart[product['id']] ?? 0 to cart.items[product['id']]?.quantity ?? 0
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => cart.addItem(product['id'], product['name'], product['sellingPrice']), // Changed from _addToCart(product) to cart.addItem(...)
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                    child: Center(
                                      child: Text(
                                        product['name'].substring(0, 1).toUpperCase(),
                                        style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rp ${product['sellingPrice']}', // Changed from product['price'] to product['sellingPrice']
                                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                          if (qty > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
                                              child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                            )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          
          // Cart Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Current Order', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items.values.toList()[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text('x${item.quantity}'),
                          trailing: Text('Rp ${item.total}'),
                          dense: true,
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  // Discount & Tax Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Diskon (Rp):')),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                                onSubmitted: (val) => cart.setDiscount(double.tryParse(val) ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                          children: [
                             const Expanded(child: Text('Pajak (10%):')),
                             Switch(
                               value: cart.taxRate > 0,
                               onChanged: (val) => cart.setTaxRate(val ? 0.1 : 0.0),
                             )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Rp ${cart.totalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Checkout'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: cart.itemCount == 0 ? null : () {
                      _showCheckoutDialog(context, cart);
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
