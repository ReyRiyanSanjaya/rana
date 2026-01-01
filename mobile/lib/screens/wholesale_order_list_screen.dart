import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/screens/wholesale_scan_screen.dart'; // Reuse scan screen

import 'package:rana_merchant/data/local/database_helper.dart';

class WholesaleOrderListScreen extends StatefulWidget {
  final String? tenantId;
  const WholesaleOrderListScreen({super.key, this.tenantId});

  @override
  State<WholesaleOrderListScreen> createState() =>
      _WholesaleOrderListScreenState();
}

class _WholesaleOrderListScreenState extends State<WholesaleOrderListScreen> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }

  Future<List<dynamic>> _fetchOrders() async {
    String id = widget.tenantId ?? '';
    if (id.isEmpty) {
      final db = DatabaseHelper.instance;
      final tenant = await db.getTenantInfo();
      if (tenant != null) {
        id = tenant['id'];
      }
    }
    if (id.isEmpty) return [];

    return ApiService().getMyWholesaleOrders(id);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFE07A5F);
      case 'PAID':
        return const Color(0xFFE07A5F);
      case 'PROCESSED':
        return const Color(0xFFE07A5F);
      case 'SHIPPED':
        return const Color(0xFFE07A5F);
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmtPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Pesanan Kulakan',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFFE07A5F))),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Terima Barang',
            onPressed: () async {
              final code = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WholesaleScanScreen()),
              );

              if (code != null && context.mounted) {
                try {
                  await ApiService().scanQrOrder(code);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Pesanan Berhasil Diterima!"),
                        backgroundColor: Colors.green));
                    _refreshOrders();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Gagal Scan: $e"),
                        backgroundColor: Colors.red));
                  }
                }
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Gagal memuat pesanan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Belum ada pesanan kulakan',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          // Sort by date desc
          orders.sort((a, b) => DateTime.parse(b['createdAt'])
              .compareTo(DateTime.parse(a['createdAt'])));

          return RefreshIndicator(
            onRefresh: () async => _refreshOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = order['items'] as List;
                final status = order['status'] ?? 'PENDING';
                final total = order['totalAmount'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order['id'] ?? '-',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE07A5F)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 16, color: Color(0xFFE07A5F)),
                                    const SizedBox(width: 8),
                                    Text("${item['quantity']}x ",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold)),
                                    Expanded(
                                        child: Text(
                                            item['productName'] ?? 'Produk',
                                            style: GoogleFonts.poppins(),
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Belanja',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                            Text(fmtPrice.format(total),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE07A5F))),
                          ],
                        ),
                        if (status == 'SHIPPED' || status == 'PROCESSED') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE07A5F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: Color(0xFFE07A5F)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        "Scan QR Code dari kurir saat barang sampai.",
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFFE07A5F)))),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
