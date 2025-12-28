import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart'; // [NEW]
import 'package:rana_merchant/providers/wallet_provider.dart'; // [NEW]
import 'package:rana_merchant/data/remote/api_service.dart'; // [FIX] Added import
import 'package:rana_merchant/services/shopee_service.dart';
import 'package:rana_merchant/screens/wallet_screen.dart'; // [NEW] Import WalletScreen
import 'package:intl/intl.dart'; 

class PpobScreen extends StatefulWidget {
  const PpobScreen({super.key});

  @override
  State<PpobScreen> createState() => _PpobScreenState();
}

class _PpobScreenState extends State<PpobScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock Data
  final List<Map<String, dynamic>> _services = [
    {'icon': Icons.phone_android, 'label': 'Pulsa', 'color': Colors.redAccent},
    {'icon': Icons.wifi, 'label': 'Paket Data', 'color': Colors.blueAccent},
    {'icon': Icons.lightbulb_outline, 'label': 'Listrik PLN', 'color': Colors.orange},
    {'icon': Icons.water_drop_outlined, 'label': 'Air PDAM', 'color': Colors.blue},
    {'icon': Icons.health_and_safety_outlined, 'label': 'BPJS', 'color': Colors.green},
    {'icon': Icons.tv, 'label': 'TV Kabel', 'color': Colors.purple},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'E-Wallet', 'color': Colors.indigo},
    {'icon': Icons.sports_esports, 'label': 'Voucher Game', 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch Wallet Data on Init
    Future.microtask(() => context.read<WalletProvider>().loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('PPOB & Tagihan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            Text('Powered by Shopee Partner', style: GoogleFonts.poppins(fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.8), fontSize: 10)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white), // [FIX] Ensure Back Arrow is White
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white, // [FIX] Indicator to White
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white), // [FIX] Label White
            unselectedLabelColor: Colors.white.withOpacity(0.6), // [FIX] Unselected Light White
            tabs: const [
               Tab(text: "Layanan"),
               Tab(text: "Riwayat Transaksi"),
            ]
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Wallet Balance Card (Mini)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, // [FIX] Use Theme Primary Color
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Consumer<WalletProvider>( // [NEW] Consume Wallet
              builder: (context, wallet, _) {
                final balanceFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Saldo Aktif', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                         const SizedBox(height: 4),
                         // Show Real Balance
                         Text(balanceFormat.format(wallet.balance), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                       ],
                     ),
                     ElevatedButton(
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())), // [FIX] Navigate to Wallet
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white, 
                         foregroundColor: Theme.of(context).primaryColor, // [FIX] Text color matches theme
                         shape: const StadiumBorder()
                       ),
                       child: const Text('Top Up'),
                     )
                  ],
                );
              }
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 24),

          // 2. Services Grid
          Text('Produk Digital', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              childAspectRatio: 0.8,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final s = _services[index];
              return InkWell(
                onTap: () => _showTransactionModal(context, s['label'], s['color']),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 1)]
                      ),
                      child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(s['label'] as String, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2)
                  ],
                ),
              );
            },
          ).animate().fade(duration: 600.ms).scale(),

          const SizedBox(height: 24),

          // 3. Promo Banner Carousel (Static for now)
          Text('Promo Spesial', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPromoCard(Colors.blue, 'Diskon Pulsa', 'Potongan 5rb all operator'),
                _buildPromoCard(Colors.orange, 'Token PLN', 'Cashback 2% Token Listrik'),
                _buildPromoCard(Colors.green, 'Bayar BPJS', 'Bebas admin bulan ini'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Color color, String title, String subtitle) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text('PROMO', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        final ppobHistory = wallet.history.where((txn) {
          // Filter history for PPOB relates entries
          // Server category: EXPENSE_PURCHASE for PPOB
          // Or description contains "Beli"
          final cat = txn['category'] ?? '';
          final desc = txn['description'] ?? '';
          return cat == 'EXPENSE_PURCHASE' || desc.contains('Beli');
        }).toList();

        if (ppobHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_edu, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Belum ada transaksi PPOB', style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ppobHistory.length,
          itemBuilder: (context, index) {
            final txn = ppobHistory[index];
            final date = DateTime.tryParse(txn['occurredAt'] ?? '') ?? DateTime.now();
            final fmtDate = DateFormat('dd MMM HH:mm').format(date);
            final amount = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(txn['amount']);

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long, color: Colors.blue.shade700),
                ),
                title: Text(txn['description'] ?? 'Transaksi PPOB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(fmtDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            );
          },
        );
      }
    );
  }

  void _showTransactionModal(BuildContext context, String serviceName, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _TransactionSheet(serviceName: serviceName, color: color),
    );
  }
}

// [NEW] Separated Widget for Dynamic Loading
class _TransactionSheet extends StatefulWidget {
  final String serviceName;
  final Color color;
  const _TransactionSheet({required this.serviceName, required this.color});

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  List<Map<String, dynamic>>? _products;
  bool _isLoading = true;
  String? _selectedSku;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final prods = await ShopeeService().getProducts(widget.serviceName);
    if (mounted) setState(() { _products = prods; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.payment, color: widget.color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Text(widget.serviceName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
               const Text("Powered by Shopee", style: TextStyle(fontSize: 10, color: Colors.orange))
            ])
          ]),
          const SizedBox(height: 24),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nomor Pelanggan / ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              suffixIcon: const Icon(Icons.contact_phone_outlined)
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
             const Center(child: CircularProgressIndicator())
          else if (_products != null && _products!.isNotEmpty)
             Container(
               height: 200, // Limit height
               decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
               child: ListView.separated(
                 itemCount: _products!.length,
                 separatorBuilder: (_,__) => const Divider(height: 1),
                 itemBuilder: (ctx, i) {
                   final p = _products![i];
                   final isSelected = _selectedSku == p['id'];
                   return ListTile(
                     selected: isSelected,
                     selectedTileColor: widget.color.withOpacity(0.1),
                     title: Text(p['name']),
                     subtitle: p['promo'] == true ? const Text('Promo Hemat!', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)) : null,
                     trailing: Text('Rp ${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                     onTap: () => setState(() => _selectedSku = p['id']),
                   );
                 },
               ),
             )
          else
             TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                prefixText: 'Rp '
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            child: Consumer<WalletProvider>(
              builder: (context, wallet, _) {
                return ElevatedButton(
                  onPressed: wallet.isLoading ? null : () async {
                     final amountInput = _products != null && _selectedSku != null 
                        ? _products!.firstWhere((p) => p['id'] == _selectedSku)['price']
                        : 0.0;
                     
                     if (amountInput == 0) return;

                     try {
                        // 1. Call API
                        await ApiService().purchaseDigitalProduct(
                          sku: _selectedSku!, 
                          amount: (amountInput as num).toDouble(),
                          customerId: '08123456789' 
                        );

                        // 2. Reload Wallet
                        await wallet.loadData();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran Sukses!'), backgroundColor: Colors.green));
                        }
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red));
                     }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: widget.color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: wallet.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Lanjutkan Pembayaran'),
                );
              }
            ),
          )
        ],
      ),
    );
  }
}
