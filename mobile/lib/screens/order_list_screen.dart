import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/screens/scan_screen.dart';
import 'package:rana_merchant/services/order_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final orders = await _orderService.getIncomingOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _getOrdersByStatus(String tab) {
    if (tab == 'Masuk') {
      return _orders.where((o) => o['orderStatus'] == 'PENDING').toList();
    }
    if (tab == 'Disiapkan') {
       return _orders.where((o) => o['orderStatus'] == 'ACCEPTED').toList();
    }
    if (tab == 'Siap Ambil') {
      return _orders.where((o) => o['orderStatus'] == 'READY').toList();
    }
    if (tab == 'Selesai') {
      return _orders.where((o) => o['orderStatus'] == 'COMPLETED').toList();
    }
    return [];
  }

  Future<void> _handleUpdateStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diperbarui: $newStatus')));
      _loadOrders(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleScan() async {
    // Navigate to Scan Screen
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    
    // Result is true if scan successful
    if (result == true) {
       _loadOrders(); // Refresh to move item to 'Selesai'
       _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Transaksi Selesai'),
        content: const Text('Barang berhasil diambil oleh konsumen.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pesanan (Pickup)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD70677),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD70677),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          indicatorColor: const Color(0xFFD70677),
          tabs: const [
            Tab(text: 'Masuk'),
            Tab(text: 'Disiapkan'),
            Tab(text: 'Siap Ambil'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _error != null 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              TextButton(onPressed: _loadOrders, child: const Text('Coba Lagi'))
            ]))
          : TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList('Masuk'),
              _buildOrderList('Disiapkan'),
              _buildOrderList('Siap Ambil'),
              _buildOrderList('Selesai'),
            ],
          ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    final filtered = _getOrdersByStatus(statusFilter);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Tidak ada pesanan $statusFilter', style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_,__) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _OrderCard(
          order: filtered[index], 
          onUpdateStatus: (newStatus) => _handleUpdateStatus(filtered[index]['id'], newStatus),
          onScan: _handleScan,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onUpdateStatus;
  final VoidCallback onScan;

  const _OrderCard({required this.order, required this.onUpdateStatus, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final fmtPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final status = order['orderStatus'];
    Color statusColor = Colors.grey;
    String displayStatus = status;

    if (status == 'PENDING') { statusColor = Colors.blue; displayStatus = 'BARU'; }
    if (status == 'ACCEPTED') { statusColor = Colors.orange; displayStatus = 'DISIAPKAN'; }
    if (status == 'READY') { statusColor = Colors.green; displayStatus = 'SIAP AMBIL'; }
    if (status == 'COMPLETED') { statusColor = Colors.grey; displayStatus = 'SELESAI'; }

    // Safe access to items
    final List items = order['transactionItems'] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text((order['id'] as String).substring(0, 15), style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(displayStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person, color: Colors.white), radius: 20, backgroundColor: Color(0xFFD70677)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['customerName'] ?? 'No Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${order['customerPhone'] ?? '-'}', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      if (order['pickupCode'] != null)
                          Text('Kode: ${order['pickupCode']}', style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Items
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map<Widget>((item) {
                final product = item['product'] ?? {};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item['quantity']}x ${product['name'] ?? 'Item'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(fmtPrice.format((item['price'] ?? 0) * (item['quantity'] ?? 1)), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(color: Color(0xFFD70677)),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Total: ${fmtPrice.format(order['totalAmount'] ?? 0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD70677))),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (status == 'PENDING')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onUpdateStatus('ACCEPTED'), 
                  icon: const Icon(Icons.soup_kitchen),
                  label: const Text('Siapkan Pesanan'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD70677))
                ),
              ),

            if (status == 'ACCEPTED')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onUpdateStatus('READY'), 
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai Disiapkan'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700)
                ),
              ),

            if (status == 'READY')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onScan, 
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Konsumen'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.all(16)),
                ),
              ),
            
            if (status == 'READY')
               Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: Center(child: Text('Tunggu konsumen datang dan scan QR mereka.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic))),
               ),

            if (status == 'COMPLETED')
               Center(
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: const [
                     Icon(Icons.task_alt, color: Colors.green),
                     SizedBox(width: 8),
                     Text('Transaksi Berhasil', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ],
                 ),
               )
          ],
        ),
      ),
    );
  }
}
