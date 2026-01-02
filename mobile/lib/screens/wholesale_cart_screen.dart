import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rana_merchant/providers/wholesale_cart_provider.dart';
import 'package:rana_merchant/screens/wholesale_checkout_screen.dart'; // Next step
import 'package:rana_merchant/screens/wholesale_scan_screen.dart';
import 'package:rana_merchant/screens/wholesale_order_list_screen.dart';
import 'package:rana_merchant/data/remote/api_service.dart';
import 'package:rana_merchant/utils/format_utils.dart';

class WholesaleCartScreen extends StatelessWidget {
  const WholesaleCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text('Keranjang Belanja',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFFE07A5F))),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE07A5F)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<WholesaleCartProvider>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Keranjang kosong',
                            style:
                                GoogleFonts.poppins(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items.values.toList()[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: Color(0xFFE07A5F)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    FormatUtils.formatCurrency(item.price),
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFE07A5F),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.grey[600],
                                  onPressed: () => cart.updateQuantity(
                                      item.id, item.quantity - 1),
                                ),
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
                                          title: Text('Ubah Jumlah',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold)),
                                          content: TextField(
                                            controller: qtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Jumlah',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final newQty = int.tryParse(
                                                    qtyController.text);
                                                if (newQty != null &&
                                                    newQty > 0) {
                                                  cart.updateQuantity(
                                                      item.id, newQty);
                                                }
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Simpan'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      '${item.quantity}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: const Color(0xFFE07A5F),
                                  onPressed: () => cart.updateQuantity(
                                      item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Consumer<WholesaleCartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            FormatUtils.formatCurrency(cart.totalAmount),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE07A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WholesaleCheckoutScreen(),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFE07A5F)),
                          child: Text('Lanjut ke Pembayaran',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
