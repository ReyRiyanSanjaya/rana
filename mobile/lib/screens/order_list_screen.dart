import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/screens/scan_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Dummy Data
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-20241222-001',
      'customer': 'Budi Santoso',
      'date': DateTime.now().subtract(const Duration(minutes: 5)),
      'status': 'Baru', // Baru, Sedang Disiapkan, Sudah Disiapkan, Selesai
      'total': 45000.0,
      'items': [
        {'name': 'Nasi Goreng Spesial', 'qty': 1, 'price': 25000},
        {'name': 'Es Teh Manis', 'qty': 2, 'price': 5000},
      ],
      'payment': 'QRIS (Lunas)',
    },
    {
      'id': 'ORD-20241222-002',
      'customer': 'Siti Aminah',
      'date': DateTime.now().subtract(const Duration(minutes: 30)),
      'status': 'Sedang Disiapkan',
      'total': 120000.0,
      'items': [
        {'name': 'Paket Keluarga A', 'qty': 1, 'price': 100000},
        {'name': 'Jus Jeruk', 'qty': 4, 'price': 5000},
      ],
      'payment': 'Transfer BCA (Lunas)',
    },
    {
      'id': 'ORD-20241221-098',
      'customer': 'Riyan (Driver)',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'Sudah Disiapkan',
      'total': 35000.0,
      'items': [
        {'name': 'Ayam Geprek Level 5', 'qty': 1, 'price': 20000},
        {'name': 'Air Mineral', 'qty': 2, 'price': 5000},
      ],
      'payment': 'Tunai (Belum Lunas)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getOrdersByStatus(String tab) {
    if (tab == 'Baru') return _orders.where((o) => o['status'] == 'Baru').toList();
    if (tab == 'Disiapkan') return _orders.where((o) => o['status'] == 'Sedang Disiapkan').toList();
    if (tab == 'Siap Ambil') return _orders.where((o) => o['status'] == 'Sudah Disiapkan').toList();
    if (tab == 'Selesai') return _orders.where((o) => o['status'] == 'Selesai').toList();
    return [];
  }

  Future<void> _handleScan(Map<String, dynamic> order) async {
    // Navigate to Scan Screen
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    
    // Check if result matches order ID (Simulation)
    if (result != null) {
      if (result.toString().contains(order['id']) || result.toString() == 'VALID_QR') { // Mock Check
         setState(() {
           order['status'] = 'Selesai';
         });
         _showSuccessDialog();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR Code Tidak Cocok!'), backgroundColor: Colors.red));
      }
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
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade900,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          indicatorColor: Colors.blue.shade900,
          tabs: const [
            Tab(text: 'Masuk'),
            Tab(text: 'Disiapkan'),
            Tab(text: 'Siap Ambil'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('Baru'),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Tidak ada pesanan $statusFilter', style: GoogleFonts.poppins(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_,__) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(
        order: filtered[index], 
        onUpdateStatus: (newStatus) {
          setState(() {
            filtered[index]['status'] = newStatus;
          });
        },
        onScan: () => _handleScan(filtered[index]),
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
    final status = order['status'];
    Color statusColor = Colors.grey;
    if (status == 'Baru') statusColor = Colors.blue;
    if (status == 'Sedang Disiapkan') statusColor = Colors.orange;
    if (status == 'Sudah Disiapkan') statusColor = Colors.green;
    if (status == 'Selesai') statusColor = Colors.grey;

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
                Text(order['id'], style: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text((status as String).toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person, color: Colors.white), radius: 20, backgroundColor: Colors.blueGrey),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['customer'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Pembayaran: ${order['payment']}', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Items
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (order['items'] as List).map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item['qty']}x ${item['name']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(fmtPrice.format(item['price'] * item['qty']), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Total: ${fmtPrice.format(order['total'])}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (status == 'Baru')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onUpdateStatus('Sedang Disiapkan'), 
                  icon: const Icon(Icons.soup_kitchen),
                  label: const Text('Siapkan Pesanan'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700)
                ),
              ),

            if (status == 'Sedang Disiapkan')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onUpdateStatus('Sudah Disiapkan'), 
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai Disiapkan'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700)
                ),
              ),

            if (status == 'Sudah Disiapkan')
               SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onScan, 
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Konsumen'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.all(16)),
                ),
              ),
            
            if (status == 'Sudah Disiapkan')
               Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: Center(child: Text('Tunggu konsumen datang dan scan QR mereka.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic))),
               ),

            if (status == 'Selesai')
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
