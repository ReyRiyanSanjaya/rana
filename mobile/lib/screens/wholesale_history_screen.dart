import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/data/local/database_helper.dart';

class WholesaleHistoryScreen extends StatefulWidget {
  const WholesaleHistoryScreen({super.key});

  @override
  State<WholesaleHistoryScreen> createState() => _WholesaleHistoryScreenState();
}

class _WholesaleHistoryScreenState extends State<WholesaleHistoryScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      // Get Tenant ID from DB
      final db = DatabaseHelper.instance;
      final tenant = await db.getTenantInfo();
      if (tenant != null) {
        final orders = await ApiService().getMyWholesaleOrders(tenant['id']);
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat pesanan: $e")));
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'PENDING') return Colors.orange;
    if (status == 'PAID') return Colors.blue;
    if (status == 'PROCESSED') return Colors.indigo;
    if (status == 'SHIPPED') return Colors.purple;
    if (status == 'DELIVERED') return Colors.green;
    if (status == 'CANCELLED') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Riwayat Kulakan', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Belum ada pesanan", style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final date = DateTime.parse(order['createdAt']);
                    final fmtDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                    final total = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order['totalAmount']);
                    final statusColor = _getStatusColor(order['status']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order['items'].length} Barang', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    order['status'],
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(fmtDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const Divider(height: 24),
                            // Items Preview (First 2)
                            ... (order['items'] as List).take(2).map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item['quantity']}x ${item['product']['name']}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item['price'] * item['quantity']),
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                      ),
                                    ],
                                  ),
                                )),
                            if ((order['items'] as List).length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("+ ${(order['items'] as List).length - 2} barang lainnya...", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Belanja"),
                                Text(total, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade800)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
