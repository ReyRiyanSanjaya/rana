import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:rana_merchant/screens/add_product_screen.dart'; // [NEW]
import 'package:rana_merchant/screens/report_screen.dart'; // [NEW]
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  final ApiService _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allProducts = []; // Backup for filtering
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  // Summary Stats
  int _totalProducts = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    // Token is handled by Singleton ApiService now, but good practice to ensure it's set if needed elsewhere
    // _api.setToken(...) is called in AuthProvider login.
    _refreshData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // We mainly read from local DB to be fast and offline-ready.
      // Full sync is done via Home Screen "Sync" button or background worker.
      final data = await DatabaseHelper.instance.getAllProducts();

      // Calculate Stats
      int low = 0;
      for (var p in data) {
        if ((p['stock'] ?? 0) <= 5) low++;
      }

      setState(() {
        _allProducts = data; // Keep full list
        _products = data; // Display list
        _totalProducts = data.length;
        _lowStockCount = low;
      });
      _searchCtrl.text = ''; // Clear search when refreshing
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _products = _allProducts);
      return;
    }
    setState(() {
      _products = _allProducts.where((p) {
        final name = p['name'].toString().toLowerCase();
        final sku = (p['sku'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || sku.contains(q);
      }).toList();
    });
  }

  void _showAdjustDialog(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController();
    String type = 'IN'; // IN, OUT
    String? reason;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Atur Stok: ${product['name']}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Stok Saat Ini: ${product['stock'] ?? 0}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 24),

              // Action Type Toggle
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'IN'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'IN'
                                ? const Color(0xFF81B29A).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                              child: Text('Masuk (+)',
                                  style: TextStyle(
                                      color: type == 'IN'
                                          ? const Color(0xFF2D4A3E)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => type = 'OUT'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'OUT'
                                ? const Color(0xFFE07A5F).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                              child: Text('Keluar (-)',
                                  style: TextStyle(
                                      color: type == 'OUT'
                                          ? const Color(0xFF9A3412)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Qty Input
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                onChanged: (v) => reason = v,
                decoration: InputDecoration(
                  labelText: 'Catatan / Alasan',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  final qty = int.tryParse(qtyCtrl.text);
                  if (qty == null || qty <= 0) return;
                  Navigator.pop(context);
                  _submitAdjustment(product['id'], qty, type, reason);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A5F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Simpan Perubahan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAdjustment(
      String productId, int qty, String type, String? reason) async {
    setState(() => _isLoading = true);

    // 1. Calculate New Stock
    final product = _products.firstWhere((p) => p['id'] == productId);
    int currentStock = product['stock'] ?? 0;
    int newStock = (type == 'IN') ? currentStock + qty : currentStock - qty;

    try {
      // 2. Update Local DB Immediately (Optimistic Update)
      await DatabaseHelper.instance.updateProductStock(productId, newStock);

      // 3. Try to Sync with Server
      // Note: We don't block the UI if this fails, assuming user is potentially offline.
      // Ideally we should queue this action too.
      try {
        await _api.adjustStock(
            productId: productId, quantity: qty, type: type, reason: reason);
      } catch (e) {
        print('Background sync failed: $e');
        // We could show a "Saved Locally" message here if we differentiate
      }

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Stok berhasil diperbarui!'),
            backgroundColor: Color(0xFF81B29A)));

      // 4. Refresh List from Local DB
      await _refreshData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal database lokal: $e'),
            backgroundColor: const Color(0xFFE07A5F)));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Manajemen Stok',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFE07A5F))),
        backgroundColor: const Color(0xFFFFF8F0),
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE07A5F)))
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  // Header Stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                                'Total Produk',
                                '$_totalProducts',
                                Icons.inventory_2,
                                const Color(0xFFE07A5F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                                'Stok Menipis',
                                '$_lowStockCount',
                                Icons.warning_amber_rounded,
                                const Color(0xFFE07A5F)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // [NEW] Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _filterProducts,
                        decoration: InputDecoration(
                          hintText: 'Cari Produk (Nama / SKU)...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                  // Title List
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Text('Daftar Produk',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // Product List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = _products[index];
                        final stock = p['stock'] ?? 0;
                        final isLow = stock <= 5;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                              border: Border.all(color: Colors.grey[100]!)),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showAdjustDialog(p),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isLow
                                            ? const Color(0xFFE07A5F)
                                                .withOpacity(0.1)
                                            : const Color(0xFFE07A5F)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons
                                            .local_cafe, // Generic icon, dynamic later
                                        color: isLow
                                            ? const Color(0xFFE07A5F)
                                            : const Color(0xFFE07A5F),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Text Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF1F2937)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text('SKU: ${p['sku'] ?? '-'}',
                                              style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),

                                    // Stock Badge
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('$stock',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isLow
                                                    ? const Color(0xFFE07A5F)
                                                    : const Color(0xFF111827))),
                                        Text('Unit',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400])),
                                      ],
                                    ),
                                    const SizedBox(width: 4),

                                    // [NEW] Actions Menu
                                    PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.grey[400]),
                                        onSelected: (val) async {
                                          if (val == 'edit') {
                                            // Navigate to Edit Screen
                                            final res = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        AddProductScreen(
                                                            product: p)));
                                            if (res == true) _refreshData();
                                          } else if (val == 'delete') {
                                            _confirmDelete(p);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Edit Data')
                                                  ])),
                                              const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(children: [
                                                    Icon(Icons.delete,
                                                        size: 20,
                                                        color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus Produk',
                                                        style: TextStyle(
                                                            color: Colors.red))
                                                  ])),
                                            ])
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: (30 * index).ms)
                            .slideX(begin: 0.1, curve: Curves.easeOut);
                      },
                      childCount: _products.length,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
            ),
    );
  }

  // [NEW] Delete Logic
  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Hapus Produk?'),
              content: Text(
                  'Anda yakin ingin menghapus "${product['name']}"? Data yang sudah dihapus tidak dapat dikembalikan.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus',
                        style: TextStyle(
                            color: Color(0xFFE07A5F),
                            fontWeight: FontWeight.bold))),
              ],
            ));

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // API Call
        await _api.deleteProduct(product['id']);
        // Local DB
        await DatabaseHelper.instance.deleteProduct(product['id']);

        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk Berhasil Dihapus')));
        _refreshData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal Hapus: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              // Maybe a trend icon?
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    )
        .animate()
        .scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
