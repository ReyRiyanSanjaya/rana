import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/data/local/database_helper.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  final ApiService _api = ApiService();
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
        _products = data;
        _totalProducts = data.length;
        _lowStockCount = low;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdjustDialog(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController();
    String type = 'IN'; // IN, OUT
    String? reason;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Atur Stok: ${product['name']}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Stok Saat Ini: ${product['stock'] ?? 0}', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 24),
              
              // Action Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!)
                ),
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
                            color: type == 'IN' ? Colors.green[100] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('Masuk (+)', style: TextStyle(color: type == 'IN' ? Colors.green[800] : Colors.grey[600], fontWeight: FontWeight.bold))),
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
                            color: type == 'OUT' ? Colors.red[100] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('Keluar (-)', style: TextStyle(color: type == 'OUT' ? Colors.red[800] : Colors.grey[600], fontWeight: FontWeight.bold))),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                onChanged: (v) => reason = v,
                decoration: InputDecoration(
                  labelText: 'Catatan / Alasan',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAdjustment(String productId, int qty, String type, String? reason) async {
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
        await _api.adjustStock(productId: productId, quantity: qty, type: type, reason: reason);
      } catch (e) {
        print('Background sync failed: $e'); 
        // We could show a "Saved Locally" message here if we differentiate
      }
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok berhasil diperbarui!'), backgroundColor: Colors.green));
      
      // 4. Refresh List from Local DB
      await _refreshData(); 
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal database lokal: $e'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                            child: _buildStatCard('Total Produk', '$_totalProducts', Icons.inventory_2, Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard('Stok Menipis', '$_lowStockCount', Icons.warning_amber_rounded, Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Title List
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Text('Daftar Produk', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
                           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(16),
                             boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                             ],
                             border: Border.all(color: Colors.grey[100]!)
                           ),

                           child: Material(
                             color: Colors.transparent,
                             child: InkWell(
                               borderRadius: BorderRadius.circular(16),
                               onTap: () => _showAdjustDialog(p),
                               child: Padding(
                                 padding: const EdgeInsets.all(16.0),
                                 child: Row(
                                   children: [
                                     // Icon / Image Placeholder
                                     Container(
                                       width: 48, height: 48,
                                       decoration: BoxDecoration(
                                         color: isLow ? Colors.orange[50] : Colors.blue[50],
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Icon(
                                         Icons.local_cafe, // Generic icon, dynamic later
                                         color: isLow ? Colors.orange : Colors.blue,
                                       ),
                                     ),
                                     const SizedBox(width: 16),
                                     
                                     // Text Info
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             p['name'], 
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                                             maxLines: 1, overflow: TextOverflow.ellipsis
                                           ),
                                           const SizedBox(height: 4),
                                           Text('SKU: ${p['sku'] ?? '-'}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                         ],
                                       ),
                                     ),
                                     
                                     // Stock Badge
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.end,
                                       children: [
                                         Text('$stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLow ? Colors.orange[800] : const Color(0xFF111827))),
                                         Text('Unit', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                       ],
                                     ),
                                     const SizedBox(width: 12),
                                     Icon(Icons.chevron_right, color: Colors.grey[300])
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         ).animate().fadeIn(delay: (30 * index).ms).slideX(begin: 0.1, curve: Curves.easeOut);
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

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              // Maybe a trend icon?
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
