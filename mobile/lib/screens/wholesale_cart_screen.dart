import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';
import 'package:rana_merchant/screens/wholesale_checkout_screen.dart'; // Next step
import 'package:rana_merchant/screens/wholesale_scan_screen.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';
import 'package:rana_merchant/data/remote/api_service.dart';

class WholesaleCartScreen extends StatelessWidget {
  const WholesaleCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<WholesaleCartProvider>(context);
    final fmtPrice =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang Belanja',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD70677),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Pesanan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WholesaleOrderListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
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
      body: cart.itemCount == 0
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Keranjang masih kosong',
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
              ],
            ))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.items.values.toList()[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8)),
                            child: item.image.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold)),
                                Text(item.supplier,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Text(fmtPrice.format(item.price),
                                    style: GoogleFonts.poppins(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                  onPressed: () => cart.removeItem(item.id),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red)),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        final TextEditingController
                                            qtyController =
                                            TextEditingController(
                                                text: item.quantity.toString());
                                        return AlertDialog(
                                          title: const Text("Ubah Jumlah"),
                                          content: TextField(
                                            controller: qtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                labelText: "Jumlah"),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Batal"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final int? newQty =
                                                    int.tryParse(
                                                        qtyController.text);
                                                if (newQty != null) {
                                                  cart.updateQuantity(
                                                      item.id, newQty);
                                                }
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Simpan"),
                                            ),
                                          ],
                                        );
                                      });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('x${item.quantity}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 13),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ]),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Tagihan',
                              style: GoogleFonts.poppins(fontSize: 16)),
                          Text(fmtPrice.format(cart.totalAmount),
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const WholesaleCheckoutScreen())),
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFD70677)),
                          child: const Text('Lanjut ke Pembayaran',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
